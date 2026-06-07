import 'package:flutter/material.dart';
import 'statistics_page.dart';
import 'cashflow_page.dart';
import '../core/constants.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: '📊 统计'),
              Tab(text: '📈 现金流'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              StatisticsPage(),
              CashflowPage(),
            ],
          ),
        ),
      ],
    );
  }
}
