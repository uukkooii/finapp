import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../widgets/month_selector.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final txp = Provider.of<TransactionProvider>(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _monthSelector(),
        const SizedBox(height: 16),
        _lineCard(txp),
        const SizedBox(height: 16),
        _pieCard(txp),
        const SizedBox(height: 16),
        _barCard(txp),
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

  Widget _lineCard(TransactionProvider txp) {
    return FutureBuilder<Map<int, Map<String, double>>>(
      future: txp.getDailyTrend(_month.year, _month.month),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _card(child: const _EmptyData(label: '加载中...'));
        }
        if (snap.hasError || !snap.hasData) {
          return _card(child: const _EmptyData(label: '暂无数据'));
        }
        final data = snap.data!;
        final maxDays = data.length;
        if (maxDays == 0) {
          return _card(child: const _EmptyData(label: '本月暂无数据'));
        }
        final maxVal = data.values
            .map((m) => (m['income']! > m['expense']! ? m['income']! : m['expense']!))
            .fold(0.0, (a, b) => a > b ? a : b);

        final incomeSpots = data.entries
            .where((e) => e.value['income']! > 0)
            .map((e) => FlSpot(e.key.toDouble(), e.value['income']!))
            .toList();
        final expenseSpots = data.entries
            .where((e) => e.value['expense']! > 0)
            .map((e) => FlSpot(e.key.toDouble(), e.value['expense']!))
            .toList();

        if (incomeSpots.isEmpty && expenseSpots.isEmpty) {
          return _card(child: const _EmptyData(label: '本月暂无数据'));
        }

        return _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('📈', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('每日趋势', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _legendDot(incomeGreen, '收入'),
              const SizedBox(width: 16),
              _legendDot(expenseRed, '支出'),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: maxDays.toDouble(),
                  minY: 0,
                  maxY: maxVal > 0 ? maxVal * 1.15 : 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? _niceInterval(maxVal) : 50,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.themeDivider,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v >= 10000 ? '${(v / 10000).toStringAsFixed(1)}万' : v.toStringAsFixed(0),
                          style: TextStyle(fontSize: 9, color: context.themeHint),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxDays > 15 ? 3 : 1,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}日',
                          style: TextStyle(fontSize: 10, color: context.themeHint),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    if (incomeSpots.isNotEmpty)
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: incomeGreen,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: maxDays <= 15,
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(radius: 3, color: incomeGreen, strokeWidth: 0),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: incomeGreen.withValues(alpha: 0.08),
                        ),
                      ),
                    if (expenseSpots.isNotEmpty)
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: expenseRed,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: maxDays <= 15,
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(radius: 3, color: expenseRed, strokeWidth: 0),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: expenseRed.withValues(alpha: 0.08),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ]);
  }

  double _niceInterval(double maxVal) {
    if (maxVal <= 100) return 25;
    if (maxVal <= 500) return 100;
    if (maxVal <= 2000) return 500;
    if (maxVal <= 10000) return 2000;
    if (maxVal <= 50000) return 10000;
    return 20000;
  }

  Widget _pieCard(TransactionProvider txp) {
    return FutureBuilder<Map<String, double>>(
      future: txp.getCategoryBreakdown(_month.year, _month.month),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _card(child: const _EmptyData(label: '加载中...'));
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return _card(
              child: const _EmptyData(label: '本月暂无支出数据'));
        }
        final data = snap.data!;
        final total =
            data.values.fold(0.0, (a, b) => a + b);
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final colors = _chartColors();

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🍩 支出分类',
                      style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('共 ¥${total.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: context.themeSub,
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _InteractivePieChart(
                        entries: entries,
                        total: total,
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: List.generate(
                            entries.length > 6
                                ? 6
                                : entries.length, (i) {
                          String icon = '📌';
                          for (final c in categories) {
                            if (c['name'] ==
                                entries[i].key) {
                              icon = c['icon']!;
                              break;
                            }
                          }
                          final pct = total > 0
                              ? entries[i].value / total * 100
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors[
                                        i % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$icon ${entries[i].key}  ${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            context.themeText),
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((e) {
                final pct =
                    total > 0 ? e.value / total : 0.0;
                final idx = entries.indexOf(e);
                String icon = '📌';
                for (final c in categories) {
                  if (c['name'] == e.key) {
                    icon = c['icon']!;
                    break;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(icon,
                          style:
                              const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.key,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.themeText))),
                      Text(
                        '¥${e.value.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                colors[idx % colors.length],
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: context.themeDivider,
                          valueColor:
                              AlwaysStoppedAnimation(
                                  colors[
                                      idx % colors.length]),
                          minHeight: 4,
                          borderRadius:
                              BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _barCard(TransactionProvider txp) {
    return FutureBuilder<List<Map<String, double>>>(
      future: _getMonthlyData(txp),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _card(
              child: const _EmptyData(label: '加载中...'));
        }
        if (snap.hasError || !snap.hasData) {
          return _card(
              child: const _EmptyData(label: '暂无数据'));
        }
        final data = snap.data!;
        double maxY = 100;
        for (final d in data) {
          if ((d['income'] ?? 0) > maxY) {
            maxY = d['income']!;
          }
          if ((d['expense'] ?? 0) > maxY) {
            maxY = d['expense']!;
          }
        }

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📈 月度收支',
                  style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _legend(incomeGreen, '收入'),
                  const SizedBox(width: 16),
                  _legend(expenseRed, '支出'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxY * 1.25,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(
                              color: context.themeDivider,
                              strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox();
                            }
                            final d = DateTime(
                                _month.year,
                                _month.month - 5 + i);
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                      top: 4),
                              child: Text('${d.month}月',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          context.themeSub)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups:
                        List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: data[i]['income'] ?? 0,
                            color: incomeGreen,
                            width: 10,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: data[i]['expense'] ?? 0,
                            color: expenseRed,
                            width: 10,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF1A1A2E),
                        getTooltipItem: (group, groupIndex,
                            rod, rodIndex) {
                          final label =
                              rodIndex == 0 ? '收入' : '支出';
                          return BarTooltipItem(
                            '$label\n¥${rod.toY.toStringAsFixed(0)}',
                            TextStyle(
                                color: rod.color,
                                fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _monthlySummaryTable(data),
            ],
          ),
        );
      },
    );
  }

  Widget _monthlySummaryTable(List<Map<String, double>> data) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          children: [
            _tableCell('月份', isHeader: true),
            _tableCell('收入', isHeader: true, color: incomeGreen),
            _tableCell('支出', isHeader: true, color: expenseRed),
            _tableCell('结余', isHeader: true, color: goldColor),
          ],
        ),
        ...List.generate(data.length, (i) {
          final d = DateTime(_month.year, _month.month - 5 + i);
          final income = data[i]['income'] ?? 0;
          final expense = data[i]['expense'] ?? 0;
          final balance = income - expense;
          return TableRow(children: [
            _tableCell('${d.month}月'),
            _tableCell('+${income.toStringAsFixed(0)}',
                color: incomeGreen),
            _tableCell('-${expense.toStringAsFixed(0)}',
                color: expenseRed),
            _tableCell(
              (balance >= 0 ? '+' : '') +
                  balance.toStringAsFixed(0),
              color: balance >= 0 ? incomeGreen : expenseRed,
            ),
          ]);
        }),
      ],
    );
  }

  Widget _tableCell(String text,
      {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          color: color ??
              (isHeader ? context.themeSub : context.themeText),
          fontWeight: isHeader
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Future<List<Map<String, double>>> _getMonthlyData(
      TransactionProvider txp) async {
    final result = <Map<String, double>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(_month.year, _month.month - i);
      final s = await txp.getMonthlySummary(d.year, d.month);
      result.add({
        'income': s['totalIncome'] ?? 0,
        'expense': s['totalExpense'] ?? 0,
      });
    }
    return result;
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: context.themeText)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(),
      child: child,
    );
  }

  List<Color> _chartColors() => const [
        Color(0xFFFF8FAB),
        Color(0xFF7BE0AD),
        Color(0xFF74B9FF),
        Color(0xFFFFB347),
        Color(0xFFA29BFE),
        Color(0xFFFAB1A0),
        Color(0xFFFFD93D),
        Color(0xFF6BCB77),
        Color(0xFFF47373),
        Color(0xFF4CA1AF),
      ];
}

/// 独立 StatefulWidget 隔离饼图触摸状态 — 点击不触发全页重建
class _InteractivePieChart extends StatefulWidget {
  final List<MapEntry<String, double>> entries;
  final double total;
  final List<Color> colors;
  const _InteractivePieChart({
    required this.entries,
    required this.total,
    required this.colors,
  });

  @override
  State<_InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<_InteractivePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  response.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: List.generate(widget.entries.length, (i) {
          final pct = widget.total > 0
              ? widget.entries[i].value / widget.total
              : 0.0;
          final isTouched = _touchedIndex == i;
          return PieChartSectionData(
            color: widget.colors[i % widget.colors.length],
            value: widget.entries[i].value,
            title: isTouched
                ? '${widget.entries[i].key}\n${(pct * 100).toStringAsFixed(0)}%'
                : pct > 0.05
                    ? '${(pct * 100).toStringAsFixed(0)}%'
                    : '',
            radius: isTouched ? 95 : 75,
            titleStyle: TextStyle(
                fontSize: isTouched ? 12 : 11,
                color: context.themeText,
                fontWeight: FontWeight.bold),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 28,
      ),
    );
  }
}

class _EmptyData extends StatelessWidget {
  final String label;
  const _EmptyData({required this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: context.themeHint, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
