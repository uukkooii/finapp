import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/budget.dart';
import '../widgets/month_selector.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});
  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  DateTime _month = DateTime.now();

  String get _monthStr =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BudgetProvider>(context);
    final txp = Provider.of<TransactionProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _monthSelector(),
        SizedBox(height: 16),
        _totalBudgetCard(bp, txp),
        SizedBox(height: 16),
        _categoryBudgetsCard(bp, txp),
      ],
    );
  }

  Widget _monthSelector() {
    return MonthSelector(
      month: _month,
      onChanged: (m) {
        final now = DateTime.now();
        if (m.year < now.year ||
            (m.year == now.year && m.month <= now.month)) {
          setState(() => _month = m);
        }
      },
    );
  }

  Widget _totalBudgetCard(
      BudgetProvider bp, TransactionProvider txp) {
    return FutureBuilder<List>(
      future: Future.wait([
        bp.getTotalBudget(_monthStr),
        txp.getMonthlySummary(_month.year, _month.month),
      ]),
      builder: (ctx, snap) {
        final totalBudget =
            (snap.data != null ? snap.data![0] as double : 0.0);
        final summary = (snap.data != null
                ? snap.data![1] as Map<String, double>
                : <String, double>{});
        final totalSpent = summary['totalExpense'] ?? 0.0;
        final progress = totalBudget > 0
            ? (totalSpent / totalBudget).clamp(0.0, 1.0)
            : 0.0;
        final isOver = totalBudget > 0 && totalSpent > totalBudget;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.themeCard, context.themeCard.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: isOver
                ? Border.all(color: expenseRed, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: (isOver ? expenseRed : goldColor).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('总预算',
                      style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  _editChip(() => _showBudgetDialog(
                      context, bp, '总计', totalBudget,
                      isTotal: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalBudget > 0
                            ? '¥${totalBudget.toStringAsFixed(0)}'
                            : '未设置',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.themeText),
                      ),
                      Text('总额度',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.themeHint)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${totalSpent.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isOver
                                ? expenseRed
                                : incomeGreen),
                      ),
                      Text('已使用',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.themeHint)),
                    ],
                  ),
                ],
              ),
              if (totalBudget > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.themeDivider,
                  valueColor: AlwaysStoppedAnimation(
                      isOver ? expenseRed : incomeGreen),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOver
                          ? '超出 ¥${(totalSpent - totalBudget).toStringAsFixed(0)}'
                          : '还剩 ¥${(totalBudget - totalSpent).toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: isOver
                              ? expenseRed
                              : incomeGreen,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.themeSub)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _categoryBudgetsCard(
      BudgetProvider bp, TransactionProvider txp) {
    const expenseCats = [
      '餐饮', '交通', '购物', '娱乐', '住房', '通讯',
      '医疗', '教育', '人情', '日用', '服饰', '零食'
    ];

    return FutureBuilder<List>(
      future: Future.wait([
        txp.getCategoryBreakdown(_month.year, _month.month),
        bp.getAllBudgets(_monthStr),
      ]),
      builder: (ctx, snap) {
        final spentMap =
            (snap.data != null
                    ? snap.data![0] as Map<String, double>
                    : <String, double>{});
        final budgets =
            (snap.data != null
                    ? snap.data![1] as List<Budget>
                    : <Budget>[]);
        final budgetMap = {
          for (final b in budgets) b.category: b.amount
        };

        final visible = expenseCats
            .where((cat) =>
                budgetMap.containsKey(cat) ||
                (spentMap[cat] ?? 0) > 0)
            .toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('分类预算',
                      style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  TextButton.icon(
                    icon: const Icon(Icons.add,
                        color: goldColor, size: 16),
                    label: const Text('添加',
                        style: TextStyle(
                            color: goldColor, fontSize: 13)),
                    onPressed: () => _showCategoryPicker(
                        context, bp, budgetMap),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text('点击添加分类预算',
                          style: TextStyle(
                              color: context.themeHint))),
                )
              else
                ...visible.map((cat) => _categoryRow(
                    context,
                    bp,
                    cat,
                    budgetMap[cat] ?? 0,
                    spentMap[cat] ?? 0)),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryRow(BuildContext context, BudgetProvider bp,
      String cat, double budget, double spent) {
    final isOver = budget > 0 && spent > budget;
    final progress =
        budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    String icon = '📌';
    for (final c in categories) {
      if (c['name'] == cat) {
        icon = c['icon']!;
        break;
      }
    }

    return GestureDetector(
      onTap: () =>
          _showBudgetDialog(context, bp, cat, budget),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Row(
              children: [
                Text(icon,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cat,
                      style: TextStyle(
                          fontSize: 14, color: context.themeText)),
                ),
                if (isOver)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: expenseRed.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '超 ¥${(spent - budget).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: expenseRed,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  budget > 0
                      ? '¥${spent.toStringAsFixed(0)}/¥${budget.toStringAsFixed(0)}'
                      : '¥${spent.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isOver
                          ? expenseRed
                          : context.themeSub),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: budget > 0 ? progress : 0,
              backgroundColor: context.themeDivider,
              valueColor: AlwaysStoppedAnimation(
                  isOver ? expenseRed : goldColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editChip(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: goldColor.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: goldColor),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: goldColor, size: 13),
            SizedBox(width: 4),
            Text('设置',
                style: TextStyle(
                    color: goldColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, BudgetProvider bp,
      String category, double current,
      {bool isTotal = false}) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
            isTotal ? '💰 设置总预算' : '设置「$category」预算',
            style: const TextStyle(color: goldColor)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true),
          autofocus: true,
          style: TextStyle(
              color: context.themeText, fontSize: 28),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            prefixText: '¥ ',
            prefixStyle: TextStyle(
                color: goldColor, fontSize: 24),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: goldColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: TextStyle(color: context.themeSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: goldColor),
            onPressed: () {
              final amount =
                  double.tryParse(ctrl.text) ?? 0;
              if (amount > 0) {
                if (isTotal) {
                  bp.setBudget(_monthStr, '总计', amount);
                } else {
                  bp.setBudget(
                      _monthStr, category, amount);
                }
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: Text('确认',
                style: TextStyle(color: context.themeText)),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context,
      BudgetProvider bp, Map<String, double> existing) {
    const allCats = [
      '餐饮', '交通', '购物', '娱乐', '住房', '通讯',
      '医疗', '教育', '人情', '日用', '服饰', '零食'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('选择分类',
                style: TextStyle(
                    color: goldColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: allCats.map((cat) {
                String icon = '📌';
                for (final c in categories) {
                  if (c['name'] == cat) {
                    icon = c['icon']!;
                    break;
                  }
                }
                return ListTile(
                  leading: Text(icon,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(cat,
                      style: TextStyle(
                          color: context.themeText)),
                  trailing: existing.containsKey(cat)
                      ? Text(
                          '¥${existing[cat]!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: goldColor))
                      : Icon(Icons.add,
                          color: context.themeHint, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBudgetDialog(
                        context, bp, cat, existing[cat] ?? 0);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
