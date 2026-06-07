import 'package:flutter/material.dart';
import 'budget_page.dart';
import 'recurring_page.dart';
import 'credit_page.dart';
import '../core/constants.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: context.themeCard,
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(50),
                ),
                dividerColor: Colors.transparent,
                labelColor: goldColor,
                unselectedLabelColor: context.themeHint,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: '💰 预算'),
                  Tab(text: '🔄 周期'),
                  Tab(text: '💳 信用'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  BudgetPage(),
                  RecurringPage(),
                  CreditPage(),
                ],
              ),
            ),
          ],
        ),
        // Floating add button — only on 周期/信用 tabs
        Positioned(
          bottom: 24,
          right: 20,
          child: AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) {
              if (_tabCtrl.index == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  if (_tabCtrl.index == 1) {
                    RecurringPage.showAddSheet(context);
                  } else if (_tabCtrl.index == 2) {
                    CreditPage.showAddSheet(context);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [goldColor, accentColor]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: goldColor.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
