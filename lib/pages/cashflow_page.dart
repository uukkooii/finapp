import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/budget_provider.dart';

class CashflowPage extends StatefulWidget {
  const CashflowPage({super.key});

  @override
  State<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  final _simCtrl = TextEditingController();
  double? _simAmount;

  @override
  void dispose() {
    _simCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txp = Provider.of<TransactionProvider>(context);
    final rp = Provider.of<RecurringProvider>(context);
    final cp = Provider.of<CreditProvider>(context);
    final bp = Provider.of<BudgetProvider>(context);
    final now = DateTime.now();

    return FutureBuilder<_CashflowData>(
        future: _loadData(txp, rp, cp, bp, now),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }
          final data = snap.data!;
          final simData = _simAmount != null ? _applySimulation(data, _simAmount!) : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(data: simData ?? data),
                const SizedBox(height: 16),
                _BarChart(
                  projections: data.dailyBalances,
                  simProjections: simData?.dailyBalances,
                ),
                if (data.upcomingBillsTotal > 0) ...[
                  const SizedBox(height: 16),
                  _UpcomingBillsCard(rp: rp),
                ],
                const SizedBox(height: 16),
                _StatsRow(data: simData ?? data),
                if (data.totalCreditDebt > 0) ...[
                  const SizedBox(height: 10),
                  _CreditDebtCard(data: data),
                ],
                const SizedBox(height: 16),
                _AlertCard(data: simData ?? data),
                const SizedBox(height: 16),
                _SimulatorCard(
                  controller: _simCtrl,
                  simAmount: _simAmount,
                  onSimulate: (amount) => setState(() => _simAmount = amount),
                  onClear: () => setState(() {
                    _simAmount = null;
                    _simCtrl.clear();
                  }),
                ),
              ],
            ),
          );
        },
      );
  }

  Future<_CashflowData> _loadData(
    TransactionProvider txp,
    RecurringProvider rp,
    CreditProvider cp,
    BudgetProvider bp,
    DateTime now,
  ) async {
    final thisMonth = await txp.getMonthlySummary(now.year, now.month);
    // DateTime normalises month=0 to December of the previous year
    final lastDate = DateTime(now.year, now.month - 1);
    final lastMonth = await txp.getMonthlySummary(lastDate.year, lastDate.month);

    final income = thisMonth['totalIncome'] ?? 0.0;
    final expense = thisMonth['totalExpense'] ?? 0.0;
    final currentBalance = income - expense;
    final avgDailyIncome = ((lastMonth['totalIncome'] ?? 0.0) + income) / 60;
    final avgDailyExpense = ((lastMonth['totalExpense'] ?? 0.0) + expense) / 60;

    // Budget-constrained daily disposable
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final totalBudget = await bp.getTotalBudget(monthStr);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, daysInMonth).toDouble();

    double dailyDisposable = avgDailyIncome - avgDailyExpense;
    if (totalBudget > 0) {
      final remainingBudget = (totalBudget - expense).clamp(0.0, double.infinity);
      final budgetDailyLimit = remainingBudget / remainingDays;
      if (budgetDailyLimit < dailyDisposable) dailyDisposable = budgetDailyLimit;
    }

    // Upcoming recurring bills keyed by date
    final upcoming = rp.getUpcoming(30);
    final billsByDate = <String, double>{};
    for (final b in upcoming) {
      if (b.nextDueDate != null) {
        billsByDate[b.nextDueDate!] = (billsByDate[b.nextDueDate!] ?? 0) + b.amount;
      }
    }

    // Credit card payment dates as future outflows
    double totalCreditDebt = 0;
    for (final card in cp.cards) {
      totalCreditDebt += card.currentBalance;
      if (card.currentBalance > 0) {
        final days = card.daysUntilPayment(now);
        if (days >= 0 && days <= 30) {
          final payDay = now.add(Duration(days: days));
          final dateStr =
              '${payDay.year}-${payDay.month.toString().padLeft(2, '0')}-${payDay.day.toString().padLeft(2, '0')}';
          billsByDate[dateStr] = (billsByDate[dateStr] ?? 0) + card.currentBalance;
        }
      }
    }

    // Build 30-day cumulative balance projection
    final dailyBalances = <double>[];
    double balance = currentBalance;
    for (int i = 0; i < 30; i++) {
      final day = now.add(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      balance += avgDailyIncome - avgDailyExpense;
      balance -= billsByDate[dateStr] ?? 0;
      dailyBalances.add(balance);
    }

    final minBalance = dailyBalances.reduce((a, b) => a < b ? a : b);
    return _CashflowData(
      currentBalance: currentBalance,
      avgDailyIncome: avgDailyIncome,
      avgDailyExpense: avgDailyExpense,
      dailyBalances: dailyBalances,
      minBalance: minBalance,
      dailyDisposable: dailyDisposable,
      upcomingBillsTotal: billsByDate.values.fold(0.0, (a, b) => a + b),
      totalCreditDebt: totalCreditDebt,
      creditUtilization: cp.overallUtilization,
    );
  }

  /// One-time hit on day 0: deduct amount from the starting balance.
  /// Since dailyBalances are cumulative, this shifts every subsequent day
  /// down by the same amount — the lower baseline continues forward.
  _CashflowData _applySimulation(_CashflowData base, double amount) {
    final newBalances = List<double>.generate(
      base.dailyBalances.length,
      (i) => base.dailyBalances[i] - amount,
    );
    return _CashflowData(
      currentBalance: base.currentBalance - amount,
      avgDailyIncome: base.avgDailyIncome,
      avgDailyExpense: base.avgDailyExpense,
      dailyBalances: newBalances,
      minBalance: newBalances.reduce((a, b) => a < b ? a : b),
      dailyDisposable: base.dailyDisposable,
      upcomingBillsTotal: base.upcomingBillsTotal,
      totalCreditDebt: base.totalCreditDebt,
      creditUtilization: base.creditUtilization,
    );
  }
}

class _CashflowData {
  final double currentBalance, avgDailyIncome, avgDailyExpense;
  final List<double> dailyBalances;
  final double minBalance, dailyDisposable, upcomingBillsTotal;
  final double totalCreditDebt, creditUtilization;

  const _CashflowData({
    required this.currentBalance,
    required this.avgDailyIncome,
    required this.avgDailyExpense,
    required this.dailyBalances,
    required this.minBalance,
    required this.dailyDisposable,
    required this.upcomingBillsTotal,
    required this.totalCreditDebt,
    required this.creditUtilization,
  });
}

class _HeaderCard extends StatelessWidget {
  final _CashflowData data;
  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: goldColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('💰', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('本月结余（估算起点）', style: TextStyle(color: context.themeSub, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(
            '¥${data.currentBalance.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.bold,
              color: data.currentBalance >= 0 ? goldColor : expenseRed,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _Stat(label: '日均收入', value: '¥${data.avgDailyIncome.toStringAsFixed(0)}', color: incomeGreen),
            _Stat(label: '日均支出', value: '¥${data.avgDailyExpense.toStringAsFixed(0)}', color: expenseRed),
            _Stat(label: '周期支出', value: '¥${data.upcomingBillsTotal.toStringAsFixed(0)}', color: accentColor),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: TextStyle(color: context.themeHint, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> projections;
  final List<double>? simProjections;
  const _BarChart({required this.projections, this.simProjections});

  @override
  Widget build(BuildContext context) {
    final allValues = [...projections, if (simProjections != null) ...simProjections!];
    final maxVal = allValues.fold<double>(1, (m, v) => v > m ? v : m);
    final minVal = allValues.fold<double>(0, (m, v) => v < m ? v : m);
    final range = (maxVal - minVal).abs().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('📊', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('未来30天余额预测',
                style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          Text('基于平均收支和周期账单', style: TextStyle(color: context.themeHint, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(projections.length, (i) {
                final val = projections[i];
                final barH = ((val - minVal) / range * 100).clamp(4.0, 100.0);
                final isNeg = val < 0;
                final barColor = isNeg ? expenseRed : (val < maxVal * 0.3 ? accentColor : incomeGreen);

                Widget bar = Container(
                  width: double.infinity, height: barH,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                );

                if (simProjections != null) {
                  final simVal = simProjections![i];
                  final simH = ((simVal - minVal) / range * 100).clamp(4.0, 100.0);
                  final simColor = simVal < 0 ? expenseRed : incomeGreen;
                  bar = Stack(alignment: Alignment.bottomCenter, children: [
                    Container(width: double.infinity, height: barH,
                      decoration: BoxDecoration(color: barColor.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                    Container(width: double.infinity, height: simH,
                      decoration: BoxDecoration(color: simColor.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                  ]);
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(message: '第${i + 1}天\n¥${val.toStringAsFixed(0)}', child: bar),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('今天', style: TextStyle(fontSize: 10, color: context.themeHint)),
              Text('第15天', style: TextStyle(fontSize: 10, color: context.themeHint)),
              Text('第30天', style: TextStyle(fontSize: 10, color: context.themeHint)),
            ],
          ),
          if (simProjections != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Container(width: 10, height: 10, color: incomeGreen.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text('原始', style: TextStyle(fontSize: 11, color: context.themeSub)),
              const SizedBox(width: 12),
              Container(width: 10, height: 10, color: incomeGreen.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text('模拟后', style: TextStyle(fontSize: 11, color: context.themeSub)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _CashflowData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data.dailyDisposable;
    return Row(children: [
      Expanded(child: _StatCard(
        emoji: '🌟',
        label: '每日可花',
        value: '¥${d.toStringAsFixed(0)}',
        subtitle: d >= 0 ? '收支正向 ✨' : '入不敷出 😅',
        color: d >= 0 ? incomeGreen : expenseRed,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        emoji: data.minBalance < 0 ? '📉' : '📈',
        label: '30天最低余额',
        value: '¥${data.minBalance.toStringAsFixed(0)}',
        subtitle: data.minBalance < 0 ? '⚠ 预计亏空' : '状态健康 💪',
        color: data.minBalance < 0 ? expenseRed : incomeGreen,
      )),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value, subtitle;
  final Color color;
  const _StatCard({
    required this.emoji, required this.label,
    required this.value, required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: context.themeSub)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _CreditDebtCard extends StatelessWidget {
  final _CashflowData data;
  const _CreditDebtCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final util = data.creditUtilization;
    final color = util > 0.7 ? expenseRed : util > 0.4 ? accentColor : incomeGreen;
    final utilPct = (util * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        const Text('💳', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('信用卡负债', style: TextStyle(fontSize: 11, color: context.themeSub)),
          const SizedBox(height: 3),
          Text('¥${data.totalCreditDebt.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('使用率 $utilPct%',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _CashflowData data;
  const _AlertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.minBalance >= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: expenseRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: expenseRed.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Text('⚠️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('余额预警', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 3),
          Text(
            '未来30天预计最低余额 ¥${data.minBalance.toStringAsFixed(0)}，请注意收支平衡',
            style: TextStyle(color: context.themeSub, fontSize: 12),
          ),
        ])),
      ]),
    );
  }
}

class _SimulatorCard extends StatelessWidget {
  final TextEditingController controller;
  final double? simAmount;
  final ValueChanged<double?> onSimulate;
  final VoidCallback onClear;

  const _SimulatorCard({
    required this.controller, required this.simAmount,
    required this.onSimulate, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: accentColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🔬', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('大额消费模拟',
              style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 4),
        Text('输入金额，查看对30天余额的影响', style: TextStyle(color: context.themeHint, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: context.themeText),
              decoration: InputDecoration(
                hintText: '输入消费金额',
                hintStyle: TextStyle(color: context.themeHint),
                prefixText: '¥ ',
                prefixStyle: const TextStyle(color: goldColor),
                filled: true, fillColor: context.themeBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: goldColor)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [goldColor, accentColor]),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent, borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  final val = double.tryParse(controller.text);
                  if (val != null && val > 0) onSimulate(val);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text('模拟', style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ]),
        if (simAmount != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(child: Text(
              '一次性消费 ¥${simAmount!.toStringAsFixed(0)} 的影响已显示在图表中',
              style: TextStyle(fontSize: 11, color: context.themeSub),
            )),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: context.themeDivider, borderRadius: BorderRadius.circular(50)),
                child: Text('清除', style: TextStyle(fontSize: 11, color: context.themeSub)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _UpcomingBillsCard extends StatelessWidget {
  final RecurringProvider rp;
  const _UpcomingBillsCard({required this.rp});

  @override
  Widget build(BuildContext context) {
    final upcoming = rp.getUpcoming(30);
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final total = upcoming.fold(0.0, (sum, b) => sum + b.amount);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: accentColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text('即将到来的周期支出', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Text('共 ¥${total.toStringAsFixed(0)}', style: TextStyle(color: context.themeSub, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        ...upcoming.take(5).map((b) {
          final days = _daysUntil(b.nextDueDate);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(b.frequency == 'monthly' ? '🔄' : b.frequency == 'quarterly' ? '📆' : '⏰', style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(b.name, style: TextStyle(fontSize: 13, color: context.themeText))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('¥${b.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: accentColor)),
                Text(days == 0 ? '今天' : '$days天后', style: TextStyle(fontSize: 11, color: context.themeSub)),
              ]),
            ]),
          );
        }),
        if (upcoming.length > 5)
          Text('... 还有 ${upcoming.length - 5} 笔', style: TextStyle(fontSize: 11, color: context.themeHint)),
      ]),
    );
  }

  int _daysUntil(String? dateStr) {
    if (dateStr == null) return 999;
    return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
  }
}
