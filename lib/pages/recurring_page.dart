import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/recurring_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/recurring_bill.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<RecurringProvider>(context);
    final bills = rp.bills;

    return bills.isEmpty
        ? const _EmptyState()
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: bills.length,
            itemBuilder: (ctx, i) {
              final bill = bills[i];
              return _BillCard(
                bill: bill,
                onToggle: () => rp.toggle(bill),
                onDelete: () => rp.delete(bill.id!),
                onMarkPaid: () {
                  final txp = Provider.of<TransactionProvider>(context, listen: false);
                  rp.markPaid(bill, txp);
                },
              );
            },
          );
  }

  static void showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddBillSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔄', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('还没有周期账单',
              style: TextStyle(color: context.themeSub, fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角 + 添加',
              style: TextStyle(color: context.themeHint, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final RecurringBill bill;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  const _BillCard({
    required this.bill,
    required this.onToggle,
    required this.onDelete,
    required this.onMarkPaid,
  });

  String _categoryIcon(String cat) {
    for (final c in categories) {
      if (c['name'] == cat) return c['icon']!;
    }
    return '📌';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.month}月${d.day}日';
    } catch (_) {
      return dateStr;
    }
  }

  int _daysUntil(String? dateStr) {
    if (dateStr == null) return 999;
    try {
      final due = DateTime.parse(dateStr);
      final now = DateTime.now();
      return due.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) {
      return 999;
    }
  }

  Color _urgencyColor(int days, BuildContext context) {
    if (days <= 3) return expenseRed;
    if (days <= 7) return const Color(0xFFFF9800);
    return Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF999999);
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(bill.nextDueDate);
    final urgency = bill.isActive ? _urgencyColor(days, context) : context.themeHint;

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.themeCard,
            title: Text('确认删除', style: TextStyle(color: context.themeText)),
            content: Text('删除「${bill.name}」？', style: TextStyle(color: context.themeText)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('取消', style: TextStyle(color: context.themeSub))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('删除', style: TextStyle(color: expenseRed))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: expenseRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24)),
        child: const Text('🗑️', style: TextStyle(fontSize: 22)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(24),
          border: bill.isActive && days <= 7
              ? Border.all(color: urgency.withValues(alpha: 0.5))
              : null,
          boxShadow: [
            BoxShadow(
              color: goldColor.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(_categoryIcon(bill.category),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(bill.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: bill.isActive ? context.themeText : context.themeHint)),
                      const SizedBox(width: 8),
                      _FrequencyBadge(label: bill.frequencyLabel),
                      if (!bill.isActive) ...[
                        const SizedBox(width: 6),
                        const _FrequencyBadge(label: '已暂停', paused: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 11, color: urgency),
                      const SizedBox(width: 4),
                      Text(
                        bill.nextDueDate != null
                            ? '${_formatDate(bill.nextDueDate)} · ${days >= 0 ? '还有$days天' : '已过期'}'
                            : '未设置到期日',
                        style: TextStyle(fontSize: 12, color: urgency),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: goldColor),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bill.isActive && bill.nextDueDate != null)
                      GestureDetector(
                        onTap: onMarkPaid,
                        child: const Icon(Icons.check_circle_outline,
                            size: 18, color: incomeGreen),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                        bill.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                        color: context.themeHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  final String label;
  final bool paused;
  const _FrequencyBadge({required this.label, this.paused = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: paused
            ? context.themeDivider
            : goldColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: paused ? context.themeHint : goldColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: paused ? context.themeHint : goldColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Add Bill Bottom Sheet ─────────────────────────────────────────────────────

class _AddBillSheet extends StatefulWidget {
  const _AddBillSheet();

  @override
  State<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<_AddBillSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customDaysCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = categories[0]['name']!;
  String _frequency = 'monthly';
  String? _account;
  DateTime? _nextDueDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _customDaysCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: goldColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  String _defaultNextDue() {
    final now = DateTime.now();
    switch (_frequency) {
      case 'monthly': return _dateStr(DateTime(now.year, now.month + 1, now.day));
      case 'quarterly': return _dateStr(DateTime(now.year, now.month + 3, now.day));
      case 'yearly': return _dateStr(DateTime(now.year + 1, now.month, now.day));
      case 'custom':
        final days = int.tryParse(_customDaysCtrl.text) ?? 30;
        return _dateStr(now.add(Duration(days: days)));
      default: return _dateStr(now.add(const Duration(days: 30)));
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写名称和金额'), backgroundColor: expenseRed));
      return;
    }
    if (_frequency == 'custom') {
      final days = int.tryParse(_customDaysCtrl.text) ?? 0;
      if (days <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请填写有效的自定义天数'), backgroundColor: expenseRed));
        return;
      }
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final bill = RecurringBill(
      name: name,
      amount: amount,
      category: _category,
      frequency: _frequency,
      customDays: _frequency == 'custom'
          ? int.tryParse(_customDaysCtrl.text)
          : null,
      nextDueDate: _nextDueDate != null ? _dateStr(_nextDueDate!) : _defaultNextDue(),
      account: _account,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: _dateStr(now),
    );
    await Provider.of<RecurringProvider>(context, listen: false).add(bill);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('添加周期账单',
                    style: TextStyle(
                        color: goldColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.themeSub)),
              ],
            ),
            const SizedBox(height: 16),
            _field('名称', _nameCtrl, hint: '如：车险续费、网飞订阅'),
            const SizedBox(height: 12),
            _field('金额 (元)', _amountCtrl, numeric: true, hint: '0'),
            const SizedBox(height: 16),
            Text('分类', style: TextStyle(color: context.themeSub, fontSize: 13)),
            const SizedBox(height: 8),
            _categoryPicker(),
            const SizedBox(height: 16),
            Text('频率', style: TextStyle(color: context.themeSub, fontSize: 13)),
            const SizedBox(height: 8),
            _frequencyPicker(),
            if (_frequency == 'custom') ...[
              const SizedBox(height: 12),
              _field('每隔天数', _customDaysCtrl, numeric: true, hint: '30'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                          color: context.themeCard,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: goldColor),
                          const SizedBox(width: 8),
                          Text(
                            _nextDueDate != null
                                ? '${_nextDueDate!.month}月${_nextDueDate!.day}日'
                                : '下次到期日',
                            style: TextStyle(
                                color: _nextDueDate != null
                                    ? Colors.white
                                    : context.themeHint,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _accountDropdown()),
              ],
            ),
            const SizedBox(height: 12),
            _field('备注', _noteCtrl, hint: '可选'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: context.themeText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_saving ? '保存中...' : '添加',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
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
      keyboardType:
          numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: context.themeText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.themeSub),
        hintText: hint,
        hintStyle: TextStyle(color: context.themeHint),
        filled: true,
        fillColor: context.themeCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: goldColor)),
      ),
    );
  }

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final selected = _category == c['name'];
        return GestureDetector(
          onTap: () => setState(() => _category = c['name']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? goldColor.withValues(alpha: 0.2) : context.themeCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? goldColor : Colors.transparent),
            ),
            child: Text(
              '${c['icon']} ${c['name']}',
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? goldColor : context.themeText),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _frequencyPicker() {
    const options = [
      ('monthly', '月'),
      ('quarterly', '季'),
      ('yearly', '年'),
      ('custom', '自定义'),
    ];
    return Row(
      children: options.map((opt) {
        final selected = _frequency == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _frequency = opt.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? goldColor.withValues(alpha: 0.2) : context.themeCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? goldColor : Colors.transparent),
              ),
              alignment: Alignment.center,
              child: Text(
                opt.$2,
                style: TextStyle(
                    fontSize: 13,
                    color: selected ? goldColor : context.themeSub,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _accountDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _account,
          dropdownColor: context.themeCard,
          style: TextStyle(color: context.themeText),
          hint: Text('账户(可选)', style: TextStyle(color: context.themeHint)),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('不指定')),
            ...accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))),
          ],
          onChanged: (v) => setState(() => _account = v),
        ),
      ),
    );
  }
}
