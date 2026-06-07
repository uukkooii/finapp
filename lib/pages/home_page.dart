import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/asset_provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import 'add_transaction_page.dart';

String _categoryIcon(String categoryName) {
  for (final c in categories) {
    if (c['name'] == categoryName) return c['icon']!;
  }
  return '📌';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _autoPayChecked = false;

  void _showTransactionList(List<Transaction> transactions, String title, {Color? accent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TransactionListSheet(transactions: transactions, title: title, accent: accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final txp = Provider.of<TransactionProvider>(context);
    final bp = Provider.of<BudgetProvider>(context);
    final gp = Provider.of<GoalProvider>(context);
    final rp = Provider.of<RecurringProvider>(context);
    final cp = Provider.of<CreditProvider>(context);
    final ap = Provider.of<AssetProvider>(context);

    // 启动时自动处理已到期的自动记账账单（仅一次）
    if (!_autoPayChecked) {
      _autoPayChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rp.processAutoPay(txp);
      });
    }

    return RefreshIndicator(
      color: goldColor, backgroundColor: context.themeCard, displacement: 40,
      onRefresh: () async {
        await Future.wait([
          txp.init(),
          ap.reload(),
          bp.init(),
          gp.init(),
        ]);
        await rp.processAutoPay(txp);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SearchBar(txp: txp),
          const SizedBox(height: 14),
          _NetWorthCard(txp: txp, ap: ap, now: now, onTap: () async {
            final txns = await txp.getTransactionsByMonth(now.year, now.month);
            if (mounted) _showTransactionList(txns, '${now.month}月全部账单', accent: goldColor);
          }),
          const SizedBox(height: 14),
          _AssetSummaryCard(ap: ap),
          const SizedBox(height: 14),
          _GoalRingsRow(gp: gp),
          const SizedBox(height: 14),
          _MonthlySummary(txp: txp, now: now,
            onTapIncome: () async {
              final txns = await txp.getTransactionsByMonth(now.year, now.month);
              if (mounted) _showTransactionList(txns.where((t) => t.type == 'income').toList(), '${now.month}月收入明细', accent: incomeGreen);
            },
            onTapExpense: () async {
              final txns = await txp.getTransactionsByMonth(now.year, now.month);
              if (mounted) _showTransactionList(txns.where((t) => t.type == 'expense').toList(), '${now.month}月支出明细', accent: expenseRed);
            },
          ),
          const SizedBox(height: 14),
          _BudgetCard(bp: bp, txp: txp, now: now, onTap: () async {
            final txns = await txp.getTransactionsByMonth(now.year, now.month);
            if (mounted) _showTransactionList(txns.where((t) => t.type == 'expense').toList(), '${now.month}月预算支出', accent: goldColor);
          }),
          const SizedBox(height: 14),
          _UpcomingAlerts(gp: gp, rp: rp, cp: cp, now: now),
          const SizedBox(height: 14),
          _RecentTransactions(txp: txp),
        ]),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final TransactionProvider txp;
  final AssetProvider ap;
  final DateTime now;
  final VoidCallback? onTap;
  const _NetWorthCard({required this.txp, required this.ap, required this.now, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchAll(),
      builder: (ctx, snap) {
        final loading = !snap.hasData;
        final data = snap.data;
        final thisMonth = (data?[0] as Map<String, double>?) ?? {};
        final lastMonth = (data?[1] as Map<String, double>?) ?? {};
        final assetTotal = (data?[2] as double?) ?? 0;
        final monthlyNet = (thisMonth['totalIncome'] ?? 0) - (thisMonth['totalExpense'] ?? 0);
        final netWorth = monthlyNet + assetTotal;
        final lastMonthly = (lastMonth['totalIncome'] ?? 0) - (lastMonth['totalExpense'] ?? 0);
        final lastNet = lastMonthly + assetTotal;
        final pctChange = lastNet != 0 ? ((netWorth - lastNet) / lastNet.abs()) * 100 : 0.0;
        final isUp = pctChange >= 0;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
          opacity: loading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: context.themeHeader1,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: goldColor.withValues(alpha: 0.25)),
              boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: loading
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final s in [(80.0, 12.0), (160.0, 28.0), (100.0, 12.0)])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: s.$1, height: s.$2,
                          decoration: BoxDecoration(color: context.themeDivider, borderRadius: BorderRadius.circular(10)),
            ),
          ),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('💎', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('净资产', style: TextStyle(color: context.themeSub, fontSize: 14)),
                    ]),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: netWorth),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, v, __) => Text(
                        '¥${v.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold, color: goldColor, letterSpacing: -0.5),
            ),
          ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isUp ? incomeGreen : expenseRed).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(isUp ? '📈' : '📉', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? '+' : ''}${pctChange.toStringAsFixed(1)}% vs 上月',
                          style: TextStyle(
                              color: isUp ? incomeGreen : expenseRed,
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ]),
          ),
        ));
      },
    );
  }

  Future<List<dynamic>> _fetchAll() async {
    final thisMonth = await txp.getMonthlySummary(now.year, now.month);
    final lastDate = DateTime(now.year, now.month - 1);
    final lastMonth = await txp.getMonthlySummary(lastDate.year, lastDate.month);
    final assetTotal = ap.totalAssets;
    return [thisMonth, lastMonth, assetTotal];
  }
}

class _GoalRingsRow extends StatelessWidget {
  final GoalProvider gp;
  const _GoalRingsRow({required this.gp});

  @override
  Widget build(BuildContext context) {
    final goals = gp.goals.take(3).toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: lavenderColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🎯', style: TextStyle(fontSize: 16)),
          SizedBox(width: 6),
          Text('目标进度', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: goals.map((g) => _GoalRing(goal: g)).toList(),
        ),
      ]),
    );
  }
}

class _GoalRing extends StatelessWidget {
  final Goal goal;
  const _GoalRing({required this.goal});

  Color _hexToColor(String hex) {
    try { return Color(int.parse('FF$hex', radix: 16)); } catch (_) { return goldColor; }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final ringColor = _hexToColor(goal.color ?? 'FF8FAB');

    return Column(mainAxisSize: MainAxisSize.min, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.elasticOut,
        builder: (_, v, __) => SizedBox(
          width: 78, height: 78,
          child: CustomPaint(
            painter: _GoalRingPainter(v, ringColor, context.themeDivider),
            child: Center(child: Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 26))),
          ),
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 78,
        child: Text(goal.name, textAlign: TextAlign.center, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.themeText)),
      ),
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: ringColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
        child: Text('${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: ringColor, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  const _GoalRingPainter(this.progress, this.color, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    canvas.drawCircle(center, radius, Paint()
      ..color = bgColor ..strokeWidth = 7 ..style = PaintingStyle.stroke);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false,
        Paint()
          ..strokeWidth = 7 ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: -math.pi / 2 + 2 * math.pi * progress.clamp(0.0, 1.0),
            colors: [color.withValues(alpha: 0.6), color],
            tileMode: TileMode.clamp,
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) => old.progress != progress || old.color != color || old.bgColor != bgColor;
}

class _MonthlySummary extends StatelessWidget {
  final TransactionProvider txp;
  final DateTime now;
  final VoidCallback? onTapIncome;
  final VoidCallback? onTapExpense;
  const _MonthlySummary({required this.txp, required this.now, this.onTapIncome, this.onTapExpense});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: txp.getMonthlySummary(now.year, now.month),
      builder: (ctx, snap) {
        final income = snap.data?['totalIncome'] ?? 0.0;
        final expense = snap.data?['totalExpense'] ?? 0.0;
        final balance = snap.data?['balance'] ?? 0.0;

        Widget item(String label, double amount, Color color, {VoidCallback? onTap}) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(children: [
              Text(label, style: TextStyle(fontSize: 11, color: color)),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: amount),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, __) => Text('¥${v.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ),
            ]),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('${now.month}月概览',
                  style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              item('收入 💚', income, incomeGreen, onTap: onTapIncome),
              Container(width: 1, height: 44, color: context.themeHint),
              item('支出 🔴', expense, expenseRed, onTap: onTapExpense),
              Container(width: 1, height: 44, color: context.themeHint),
              item('结余 ✨', balance, goldColor),
            ]),
          ]),
        );
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetProvider bp;
  final TransactionProvider txp;
  final DateTime now;
  final VoidCallback? onTap;
  const _BudgetCard({required this.bp, required this.txp, required this.now, this.onTap});

  @override
  Widget build(BuildContext context) {
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day + 1;

    return FutureBuilder<List>(
      future: Future.wait([
        bp.getTotalBudget(monthStr),
        txp.getMonthlySummary(now.year, now.month),
      ]),
      builder: (ctx, snap) {
        final totalBudget = snap.data != null ? snap.data![0] as double : 0.0;
        final expense = snap.data != null
            ? (snap.data![1] as Map<String, double>)['totalExpense'] ?? 0.0
            : 0.0;
        final progress = totalBudget > 0 ? (expense / totalBudget).clamp(0.0, 1.0) : 0.0;
        final isOver = totalBudget > 0 && expense > totalBudget;
        final remaining = totalBudget - expense;
        final dailySuggestion = totalBudget > 0 && !isOver && remainingDays > 0
            ? remaining / remainingDays : null;
        final emoji = isOver ? '😅' : progress > 0.8 ? '😬' : progress > 0.5 ? '😊' : '🥳';

        return GestureDetector(
          onTap: onTap,
          child: Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(glowColor: isOver ? expenseRed : incomeGreen),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [
                Text('💰', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('本月预算', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              Text(
                totalBudget > 0
                    ? '¥${expense.toStringAsFixed(0)} / ¥${totalBudget.toStringAsFixed(0)}'
                    : '未设置',
                style: TextStyle(fontSize: 12, color: isOver ? expenseRed : context.themeSub),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress, minHeight: 10,
                backgroundColor: context.themeHint,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? expenseRed : incomeGreen,
            ),
            ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (totalBudget > 0)
                Text(
                  isOver
                      ? '超出 ¥${(expense - totalBudget).toStringAsFixed(0)}'
                      : '还剩 ¥${remaining.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: isOver ? expenseRed : incomeGreen),
                )
              else
                const SizedBox.shrink(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: context.themeDivider, borderRadius: BorderRadius.circular(16)),
                child: Text('还剩 $remainingDays 天 $emoji',
                    style: TextStyle(fontSize: 11, color: context.themeSub)),
              ),
            ]),
            ...(dailySuggestion != null
                ? [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16)),
                      child: Text('✨ 每日建议消费 ¥${dailySuggestion.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: goldColor)),
                    ),
                  ]
                : []),
          ]),
        ));
      },
    );
  }
}

class _UpcomingAlerts extends StatelessWidget {
  final GoalProvider gp;
  final RecurringProvider rp;
  final CreditProvider cp;
  final DateTime now;
  const _UpcomingAlerts({required this.gp, required this.rp, required this.cp, required this.now});

  String _formatDue(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.month}月${d.day}日';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _alertRow(BuildContext context, {required String emoji, required String label,
      required String amount, required String badge, required Color amountColor, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: context.themeText))),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor)),
        const SizedBox(width: 8),
        Text(badge, style: TextStyle(fontSize: 11, color: badgeColor ?? context.themeHint)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingGoals = gp.goals.where((g) {
      if (g.deadline == null) return false;
      final diff = DateTime.parse(g.deadline!).difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).toList();
    final upcomingBills = rp.getUpcoming(7);
    final upcomingPayments = cp.getUpcomingPayments(7);
    final hasAlerts = upcomingGoals.isNotEmpty || upcomingBills.isNotEmpty || upcomingPayments.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: hasAlerts ? accentColor : incomeGreen),
      child: !hasAlerts
          ? Row(children: [
              const Text('💪', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('太棒了！', style: TextStyle(color: context.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('继续保持良好的储蓄习惯 ✨', style: TextStyle(color: context.themeSub, fontSize: 12)),
              ])),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Text('⏰', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('即将到期', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              ...upcomingBills.map((b) => _alertRow(context,
                emoji: '🔄', label: b.name,
                amount: '¥${b.amount.toStringAsFixed(0)}',
                badge: b.nextDueDate != null ? _formatDue(b.nextDueDate!) : '',
                amountColor: accentColor,
              )),
              ...upcomingPayments.map((c) {
                final days = c.daysUntilPayment(now);
                return _alertRow(context,
                  emoji: '💳', label: '${c.name} 还款',
                  amount: '¥${c.currentBalance.toStringAsFixed(0)}',
                  badge: days == 0 ? '今天' : '$days天后',
                  amountColor: expenseRed,
                  badgeColor: days <= 3 ? expenseRed : null,
                );
              }),
              ...upcomingGoals.map((g) {
                final days = DateTime.parse(g.deadline!).difference(now).inDays;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Text(g.icon ?? '🎯', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name, style: TextStyle(fontSize: 13, color: context.themeText)),
                      Text('还差 ¥${(g.targetAmount - g.currentAmount).toStringAsFixed(0)} · 剩 $days 天',
                          style: TextStyle(fontSize: 11, color: context.themeHint)),
                    ])),
                    Text('${(g.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, color: goldColor)),
                  ]),
                );
              }),
            ]),
    );
  }
}

class _AssetSummaryCard extends StatelessWidget {
  final AssetProvider ap;
  const _AssetSummaryCard({required this.ap});

  @override
  Widget build(BuildContext context) {
    final total = ap.totalAssets;
    if (total <= 0) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/assets'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(glowColor: lavenderColor),
          child: Row(children: [
            const Text('🏦', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text('添加你的资产', style: TextStyle(color: context.themeText, fontWeight: FontWeight.w600))),
            Text('管理 →', style: TextStyle(color: context.themeSub, fontSize: 13)),
          ]),
        ),
      );
    }
    final profit = ap.totalProfit;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/assets'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: context.cardDecoration(glowColor: incomeGreen),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🏦', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            const Text('资产管家', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('查看 →', style: TextStyle(color: context.themeSub, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Text('¥${_fmt(v)}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.themeText, letterSpacing: -0.5)),
          ),
          if (profit != 0) ...[
            const SizedBox(height: 4),
            Text('${profit > 0 ? "📈" : "📉"} 总收益 ${profit > 0 ? "+" : ""}¥${_fmt(profit)}',
                style: TextStyle(fontSize: 12, color: profit >= 0 ? incomeGreen : expenseRed)),
          ],
        ]),
      ),
    );
  }

  String _fmt(num n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(2)}万';
    return n.toStringAsFixed(0);
  }
}

class _RecentTransactions extends StatefulWidget {
  final TransactionProvider txp;
  const _RecentTransactions({required this.txp});

  @override
  State<_RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<_RecentTransactions> {
  Future<List<Transaction>>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.txp.getRecentTransactions(5);
  }

  @override
  void didUpdateWidget(_RecentTransactions old) {
    super.didUpdateWidget(old);
    _future = widget.txp.getRecentTransactions(5);
  }

  String _relativeDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '$diff天前';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: _future,
      builder: (ctx, snap) {
        final txns = snap.data ?? [];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('📝', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('最近记录', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            if (txns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Column(children: [
                  const Text('🧾', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('还没有记录哦～', style: TextStyle(color: context.themeHint, fontSize: 13)),
                  Text('点击 + 开始记账吧！', style: TextStyle(color: context.themeHint, fontSize: 11)),
                ])),
              )
            else
              ...txns.map((t) => _SwipableRow(
                transaction: t,
                relDate: _relativeDate(t.date),
                onDelete: () async {
                  await widget.txp.deleteTransaction(t.id!);
                  setState(() { _future = widget.txp.getRecentTransactions(5); });
                },
              )),
          ]),
        );
      },
    );
  }
}

class _SwipableRow extends StatelessWidget {
  final Transaction transaction;
  final String relDate;
  final VoidCallback onDelete;
  const _SwipableRow({required this.transaction, required this.relDate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == 'income';
    final icon = _categoryIcon(t.category);

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
            color: expenseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
        child: const Text('🗑️', style: TextStyle(fontSize: 22)),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => AddTransactionPage.show(context, edit: transaction),
        child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: (isIncome ? incomeGreen : expenseRed).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(relDate, style: TextStyle(fontSize: 11, color: context.themeHint)),
          ])),
          Text(
            '${isIncome ? '+' : '-'}¥${t.amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isIncome ? incomeGreen : expenseRed),
          ),
        ]),
      ),
      ),  // GestureDetector
    );
  }
}

class _SearchBar extends StatefulWidget {
  final TransactionProvider txp;
  const _SearchBar({required this.txp});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();
  List<Transaction> _results = [];
  bool _showResults = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search(String q) {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _showResults = false; });
      return;
    }
    widget.txp.searchTransactions(q).then((list) {
      if (mounted) setState(() { _results = list; _showResults = true; });
    });
  }

  String _fmt(String d) {
    try { final p = DateTime.parse(d); return '${p.month}/${p.day}'; } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(color: context.themeCard, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: _ctrl, onChanged: _search,
          style: TextStyle(color: context.themeText, fontSize: 14),
          decoration: InputDecoration(
            hintText: '🔍 搜索交易...', hintStyle: TextStyle(color: context.themeHint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: context.themeHint, size: 20),
            suffixIcon: GestureDetector(
              onTap: () {
                _ctrl.clear();
                _search('');
              },
              child: Icon(Icons.close, color: context.themeHint, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      if (_showResults && _results.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: context.themeCard, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: _results.take(5).map((t) {
              final isInc = t.type == 'income';
              String icon = _categoryIcon(t.category);
              return ListTile(
                dense: true, leading: Text(icon, style: const TextStyle(fontSize: 22)),
                title: Text(t.category, style: TextStyle(fontSize: 13, color: context.themeText)),
                subtitle: Text(_fmt(t.date), style: TextStyle(fontSize: 11, color: context.themeHint)),
                trailing: Text('${isInc ? '+' : '-'}¥${t.amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isInc ? incomeGreen : expenseRed)),
                onTap: () => AddTransactionPage.show(context, edit: t),
              );
            }).toList(),
          ),
        ),
      ],
    ]);
  }
}

class _TransactionListSheet extends StatelessWidget {
  final List<Transaction> transactions;
  final String title;
  final Color? accent;

  const _TransactionListSheet({
    required this.transactions,
    required this.title,
    this.accent,
  });

  String _fmt(n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final income = transactions.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: context.themeHint, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: accent ?? goldColor))),
            if (income > 0)
              Padding(padding: const EdgeInsets.only(right: 12), child: Text('收 ¥${_fmt(income)}', style: const TextStyle(fontSize: 12, color: incomeGreen))),
            if (expense > 0)
              Text('支 ¥${_fmt(expense)}', style: const TextStyle(fontSize: 12, color: expenseRed)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: transactions.isEmpty
                ? Center(child: Text('暂无记录 📭', style: TextStyle(color: context.themeHint)))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: transactions.length,
                    itemBuilder: (_, i) {
                      final t = transactions[i];
                      final isInc = t.type == 'income';
                      final icon = _categoryIcon(t.category);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: GestureDetector(
                          onTap: () => AddTransactionPage.show(context, edit: t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: (isInc ? incomeGreen : expenseRed).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.themeText)),
                                if (t.note != null && t.note!.isNotEmpty)
                                  Text(t.note!, style: TextStyle(fontSize: 11, color: context.themeHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${isInc ? '+' : '-'}¥${t.amount.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isInc ? incomeGreen : expenseRed)),
                                Text(t.date, style: TextStyle(fontSize: 10, color: context.themeHint)),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
