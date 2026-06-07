import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/ai_parser.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AiAccountingPage extends StatefulWidget {
  const AiAccountingPage({super.key});
  @override
  State<AiAccountingPage> createState() => _AiAccountingPageState();
}

class _AiAccountingPageState extends State<AiAccountingPage> {
  final _controller = TextEditingController();
  final _parser = AiAccountParser();
  ParsedResult? _result;
  String _type = 'expense';
  final List<String> _history = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final result = _parser.parse(text);
    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没识别到金额和分类，试试"午饭花了35"这样的说法')),
      );
      return;
    }
    setState(() {
      _result = result;
      _type = result.type;
      _history.insert(0, text);
      if (_history.length > 10) _history.removeLast();
    });
  }

  void _save() {
    if (_result == null) return;
    final r = _result!;
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final txp = Provider.of<TransactionProvider>(context, listen: false);
    final txn = Transaction(
      type: _type, amount: r.amount, category: r.category,
      account: r.account, note: r.note, date: date,
    );
    txp.addTransaction(txn);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ 已记录：${_type == 'income' ? "收入" : "支出"} ¥${r.amount.toStringAsFixed(2)} ${r.category}')),
    );
    setState(() { _result = null; _controller.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themeCard,
        title: const Text('🤖 AI 记账', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration(glowColor: goldColor),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: context.themeText, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '说说今天花了什么...',
                      hintStyle: TextStyle(color: context.themeHint),
                      border: InputBorder.none,
                      suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.mic, color: goldColor), onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🎤 语音输入需要手机端支持，暂时请用文字输入')),
                          );
                        }, tooltip: '语音输入'),
                      ]),
                    ),
                    onSubmitted: (_) => _analyze(),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _analyze,
                  child: const Text('✨ 智能识别', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              Text('支持说法：\n"午饭花了35" / "打车用了28元" / "工资收入8000" / "淘宝买衣服¥199"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: context.themeHint)),
            ]),
          ),
          const SizedBox(height: 16),
          // Result preview
          if (_result != null) ...[
            _ResultCard(
              result: _result!,
              type: _type,
              onTypeChanged: (t) => setState(() => _type = t),
              onSave: _save,
            ),
            const SizedBox(height: 16),
          ],
          // Quick history
          if (_history.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('📝 最近输入', style: TextStyle(fontSize: 13, color: context.themeSub)),
            ),
            const SizedBox(height: 8),
            ..._history.take(5).map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () {
                  _controller.text = h;
                  _analyze();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.themeCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(h, style: TextStyle(fontSize: 13, color: context.themeText)),
                ),
              ),
            )),
          ],
        ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ParsedResult result;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSave;

  const _ResultCard({required this.result, required this.type, required this.onTypeChanged, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(glowColor: type == 'income' ? incomeGreen : expenseRed),
      child: Column(children: [
        // Type toggle
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _TypeChip(label: '💸 支出', selected: type == 'expense', onTap: () => onTypeChanged('expense')),
          const SizedBox(width: 12),
          _TypeChip(label: '💰 收入', selected: type == 'income', onTap: () => onTypeChanged('income')),
        ]),
        const SizedBox(height: 16),
        // Amount
        Text('¥${result.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: type == 'income' ? incomeGreen : expenseRed)),
        const SizedBox(height: 14),
        // Details row
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _DetailChip(emoji: '📂', label: result.category),
          _DetailChip(emoji: '💳', label: result.account),
          if (result.note.isNotEmpty) _DetailChip(emoji: '📝', label: result.note),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'income' ? incomeGreen : goldColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onSave,
            child: const Text('✓ 确认记账', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? goldColor.withValues(alpha: 0.2) : context.themeBg,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: selected ? goldColor : context.themeDivider, width: selected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? goldColor : context.themeSub)),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String emoji, label;
  const _DetailChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: context.themeBg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: context.themeText, fontSize: 13)),
      ]),
    );
  }
}
