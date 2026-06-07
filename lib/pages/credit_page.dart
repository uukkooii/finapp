import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/credit_provider.dart';
import '../models/credit_card.dart';

class CreditPage extends StatelessWidget {
  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CreditProvider>(context);
    final cards = cp.cards;

    return cards.isEmpty
        ? _EmptyState()
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                _SummaryCard(cp: cp),
                const SizedBox(height: 16),
                _PaymentCalendar(cp: cp),
                const SizedBox(height: 16),
                ...cards.map((c) => _CardTile(card: c)),
              ],
            ),
          );
  }

  static void showAddSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: ctx.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _AddCardSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💳', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('还没有信用卡', style: TextStyle(color: context.themeSub, fontSize: 16)),
          SizedBox(height: 8),
          Text('点击右下角 + 添加', style: TextStyle(color: context.themeHint, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CreditProvider cp;
  const _SummaryCard({required this.cp});

  @override
  Widget build(BuildContext context) {
    final util = cp.overallUtilization;
    final utilColor = util > 0.7 ? expenseRed : (util > 0.3 ? accentColor : incomeGreen);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.themeCardGradient,
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: expenseRed.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: expenseRed.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('💳', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('总负债', style: TextStyle(color: context.themeSub, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(
              '¥${cp.totalDebt.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: expenseRed),
            ),
            const SizedBox(height: 4),
            Text('总额度 ¥${cp.totalLimit.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: context.themeHint)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: util, minHeight: 7,
                backgroundColor: context.themeDivider,
                valueColor: AlwaysStoppedAnimation(utilColor),
              ),
            ),
            const SizedBox(height: 4),
            Text('综合使用率 ${(util * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: utilColor)),
          ]),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 80, height: 80,
          child: CustomPaint(
            painter: _UtilizationRingPainter(util, utilColor, context.themeDivider),
            child: Center(
              child: Text('${(util * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: utilColor)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _UtilizationRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  const _UtilizationRingPainter(this.progress, this.color, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    canvas.drawCircle(center, radius, Paint()
      ..color = bgColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_UtilizationRingPainter old) =>
      old.progress != progress || old.color != color || old.bgColor != bgColor;
}

class _PaymentCalendar extends StatelessWidget {
  final CreditProvider cp;
  const _PaymentCalendar({required this.cp});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = cp.getUpcomingPayments(15);
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: accentColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📅', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('近15天还款', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        ...upcoming.map((c) {
          final days = c.daysUntilPayment(now);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: days <= 3
                        ? [expenseRed.withValues(alpha: 0.25), expenseRed.withValues(alpha: 0.1)]
                        : [goldColor.withValues(alpha: 0.2), goldColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('${c.paymentDay}',
                    style: TextStyle(
                        color: days <= 3 ? expenseRed : goldColor,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c.name, style: TextStyle(fontSize: 13, color: context.themeText))),
              Text('¥${c.currentBalance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: expenseRed)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (days <= 3 ? expenseRed : context.themeDivider),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  days == 0 ? '今天' : '$days天后',
                  style: TextStyle(
                      fontSize: 10,
                      color: days <= 3 ? Colors.white : context.themeSub),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CreditCard card;
  const _CardTile({required this.card});

  Color _cardColor() {
    try {
      return Color(int.parse('FF${card.color}', radix: 16));
    } catch (_) {
      return goldColor;
    }
  }

  Color _utilColor() {
    final u = card.utilizationRate;
    if (u > 0.7) return expenseRed;
    if (u > 0.3) return accentColor;
    return incomeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CreditProvider>(context, listen: false);
    final color = _cardColor();
    final utilColor = _utilColor();

    return GestureDetector(
      onLongPress: () => _showEditSheet(context, cp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.themeCard, color.withValues(alpha: 0.08)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.credit_card, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.name,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.themeText)),
                Text('${card.bank} ····${card.cardNumber}',
                    style: TextStyle(fontSize: 12, color: context.themeHint)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('¥${card.currentBalance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: expenseRed)),
              Text('/ ¥${card.creditLimit.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: context.themeHint)),
            ]),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: card.utilizationRate, minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(utilColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: utilColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('使用率 ${(card.utilizationRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: utilColor)),
              ),
              Text('可用 ¥${card.availableCredit.toStringAsFixed(0)}  还款日 ${card.paymentDay}号',
                  style: TextStyle(fontSize: 11, color: context.themeHint)),
            ],
          ),
        ]),
      ),
    );
  }

  void _showEditSheet(BuildContext context, CreditProvider cp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _EditCardSheet(card: card, cp: cp),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _billDayCtrl = TextEditingController();
  final _payDayCtrl = TextEditingController();
  String _color = 'D4A574';
  bool _saving = false;

  static const _colorOptions = [
    'D4A574', 'E53935', '4CAF50', '2196F3', '9C27B0',
    'FF9800', '00BCD4', 'F06292',
  ];

  @override
  void dispose() {
    for (final c in [_nameCtrl, _bankCtrl, _numberCtrl, _limitCtrl, _balanceCtrl, _billDayCtrl, _payDayCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final bank = _bankCtrl.text.trim();
    final limit = double.tryParse(_limitCtrl.text) ?? 0;
    final billDay = int.tryParse(_billDayCtrl.text) ?? 0;
    final payDay = int.tryParse(_payDayCtrl.text) ?? 0;

    if (name.isEmpty || bank.isEmpty || limit <= 0 ||
        billDay < 1 || billDay > 28 || payDay < 1 || payDay > 28) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请填写完整信息（账单日和还款日需在1-28之间）'),
          backgroundColor: expenseRed));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final card = CreditCard(
      name: name, bank: bank,
      cardNumber: _numberCtrl.text.trim().isEmpty ? '0000' : _numberCtrl.text.trim(),
      creditLimit: limit,
      currentBalance: double.tryParse(_balanceCtrl.text) ?? 0,
      billDay: billDay, paymentDay: payDay, color: _color,
      createdAt: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    await Provider.of<CreditProvider>(context, listen: false).add(card);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [
                Text('💳', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('添加信用卡',
                    style: TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.themeSub)),
            ]),
            const SizedBox(height: 16),
            _field('卡片名称', _nameCtrl, hint: '如：招行经典白'),
            const SizedBox(height: 12),
            _field('发卡银行', _bankCtrl, hint: '如：招商银行'),
            const SizedBox(height: 12),
            _field('卡号后4位', _numberCtrl, hint: '0000', numeric: true),
            const SizedBox(height: 12),
            _field('信用额度', _limitCtrl, hint: '0', numeric: true),
            const SizedBox(height: 12),
            _field('当前负债', _balanceCtrl, hint: '0', numeric: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('账单日', _billDayCtrl, hint: '1-28', numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('还款日', _payDayCtrl, hint: '1-28', numeric: true)),
            ]),
            const SizedBox(height: 16),
            Text('卡片颜色', style: TextStyle(color: context.themeSub, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((hex) {
                final col = Color(int.parse('FF$hex', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: col, shape: BoxShape.circle,
                      border: _color == hex ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: _color == hex ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 8)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [goldColor, accentColor]),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent, borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _saving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: Text(_saving ? '保存中...' : '💳 添加',
                          style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool numeric = false, String? hint}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: context.themeText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.themeSub),
        hintText: hint,
        hintStyle: TextStyle(color: context.themeHint),
        filled: true, fillColor: context.themeBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: goldColor)),
      ),
    );
  }
}

class _EditCardSheet extends StatefulWidget {
  final CreditCard card;
  final CreditProvider cp;
  const _EditCardSheet({required this.card, required this.cp});

  @override
  State<_EditCardSheet> createState() => _EditCardSheetState();
}

class _EditCardSheetState extends State<_EditCardSheet> {
  late final _balanceCtrl =
      TextEditingController(text: widget.card.currentBalance.toStringAsFixed(0));
  late final _limitCtrl =
      TextEditingController(text: widget.card.creditLimit.toStringAsFixed(0));

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = double.tryParse(_balanceCtrl.text) ?? widget.card.currentBalance;
    final limit = double.tryParse(_limitCtrl.text) ?? widget.card.creditLimit;
    await widget.cp.update(widget.card.copyWith(currentBalance: balance, creditLimit: limit));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🗑️ 确认删除', style: TextStyle(color: expenseRed)),
        content: Text('删除「${widget.card.name}」？', style: TextStyle(color: context.themeText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消', style: TextStyle(color: context.themeSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除', style: TextStyle(color: context.themeText)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await widget.cp.delete(widget.card.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.card.name,
                style: const TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold)),
            Row(children: [
              IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: expenseRed)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.themeSub)),
            ]),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: context.themeText),
            decoration: _inputDecoration('当前负债'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: context.themeText),
            decoration: _inputDecoration('信用额度'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [goldColor, accentColor]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _save,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: Text('保存 ✨',
                        style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.themeSub),
        filled: true, fillColor: context.themeBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: goldColor)),
      );
}
