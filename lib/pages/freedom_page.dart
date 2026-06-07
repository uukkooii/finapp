import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../providers/goal_provider.dart';
import '../providers/transaction_provider.dart';

class FreedomPage extends StatefulWidget {
  const FreedomPage({super.key});

  @override
  State<FreedomPage> createState() => _FreedomPageState();
}

class _FreedomPageState extends State<FreedomPage> {
  final _monthlyExpenseCtrl = TextEditingController(text: '3000');
  final _netAssetsCtrl = TextEditingController(text: '0');
  final _annualRateCtrl = TextEditingController(text: '7');
  final _monthlySavingsCtrl = TextEditingController(text: '2000');

  bool _calculated = false;
  double _requiredPrincipal = 0;
  double _netAssets = 0;
  double _gap = 0;
  double _progress = 0;
  double _yearsNeeded = 0;
  double _monthlyNeeded = 0;

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedValues();
    _addListeners();
    await _loadNetAssets();
    if (mounted) _autoCalculate();
  }

  Future<void> _loadSavedValues() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final monthlyExpense = prefs.getString('freedom_monthly_expense');
    final netAssets = prefs.getString('freedom_net_assets');
    final annualRate = prefs.getString('freedom_annual_rate');
    final monthlySavings = prefs.getString('freedom_monthly_savings');
    if (monthlyExpense != null) _monthlyExpenseCtrl.text = monthlyExpense;
    if (netAssets != null) _netAssetsCtrl.text = netAssets;
    if (annualRate != null) _annualRateCtrl.text = annualRate;
    if (monthlySavings != null) _monthlySavingsCtrl.text = monthlySavings;
  }

  void _addListeners() {
    _monthlyExpenseCtrl.addListener(
        () => _prefs?.setString('freedom_monthly_expense', _monthlyExpenseCtrl.text));
    _netAssetsCtrl.addListener(
        () => _prefs?.setString('freedom_net_assets', _netAssetsCtrl.text));
    _annualRateCtrl.addListener(
        () => _prefs?.setString('freedom_annual_rate', _annualRateCtrl.text));
    _monthlySavingsCtrl.addListener(
        () => _prefs?.setString('freedom_monthly_savings', _monthlySavingsCtrl.text));
  }

  void _autoCalculate() {
    if (_monthlyExpenseCtrl.text.isNotEmpty &&
        _netAssetsCtrl.text.isNotEmpty &&
        _annualRateCtrl.text.isNotEmpty &&
        _monthlySavingsCtrl.text.isNotEmpty) {
      _calculate();
    }
  }

  Future<void> _loadNetAssets() async {
    if (!mounted) return;
    // Only auto-populate from goals if the user hasn't saved a custom value yet.
    final savedValue = _prefs?.getString('freedom_net_assets');
    if (savedValue != null && savedValue.isNotEmpty && savedValue != '0') return;
    final goals = await context.read<GoalProvider>().getAllGoals();
    final total = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    if (total > 0 && mounted) {
      _netAssetsCtrl.text = total.toStringAsFixed(0);
    }
  }

  void _calculate() {
    final monthlyExpense = double.tryParse(_monthlyExpenseCtrl.text) ?? 0;
    final netAssets = double.tryParse(_netAssetsCtrl.text) ?? 0;
    final annualRate = (double.tryParse(_annualRateCtrl.text) ?? 7) / 100;
    final monthlySavings = double.tryParse(_monthlySavingsCtrl.text) ?? 0;

    if (monthlyExpense <= 0) return;

    final required = monthlyExpense * 12 * 25;
    final gap = (required - netAssets).clamp(0.0, double.infinity);
    final progress = (netAssets / required).clamp(0.0, 1.0);

    double years = 0;
    double monthlyNeeded = 0;

    if (gap > 0 && annualRate > 0) {
      final monthlyRate = annualRate / 12;
      // FV of annuity formula rearranged: N = log(1 + gap*r/(ms)) / log(1+r)
      // where r = annualRate, ms = monthlySavings*12
      if (monthlySavings > 0) {
        final annualSavings = monthlySavings * 12;
        final numerator = log(1 + (gap * annualRate) / annualSavings);
        final denominator = log(1 + annualRate);
        years = numerator / denominator;
      }

      // Monthly savings needed to close the gap in `years` years
      if (years > 0) {
        final totalMonths = years * 12;
        monthlyNeeded =
            gap * monthlyRate / (pow(1 + monthlyRate, totalMonths) - 1);
      }
    }

    setState(() {
      _requiredPrincipal = required;
      _netAssets = netAssets;
      _gap = gap;
      _progress = progress;
      _yearsNeeded = years;
      _monthlyNeeded = monthlyNeeded;
      _calculated = true;
    });
  }

  @override
  void dispose() {
    _monthlyExpenseCtrl.dispose();
    _netAssetsCtrl.dispose();
    _annualRateCtrl.dispose();
    _monthlySavingsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = getDailyQuote();
    return Scaffold(
      backgroundColor: context.themeBg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🚀 财务自由计算器',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _InputCard(
                    monthlyExpenseCtrl: _monthlyExpenseCtrl,
                    netAssetsCtrl: _netAssetsCtrl,
                    annualRateCtrl: _annualRateCtrl,
                    monthlySavingsCtrl: _monthlySavingsCtrl,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '✨ 开始计算',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_calculated) ...[
                    const SizedBox(height: 20),
                    _ResultCard(
                      requiredPrincipal: _requiredPrincipal,
                      netAssets: _netAssets,
                      gap: _gap,
                      progress: _progress,
                      yearsNeeded: _yearsNeeded,
                      monthlyNeeded: _monthlyNeeded,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _ExportButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _QuoteBar(quote: quote),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController monthlyExpenseCtrl;
  final TextEditingController netAssetsCtrl;
  final TextEditingController annualRateCtrl;
  final TextEditingController monthlySavingsCtrl;

  const _InputCard({
    required this.monthlyExpenseCtrl,
    required this.netAssetsCtrl,
    required this.annualRateCtrl,
    required this.monthlySavingsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(),
      child: Column(
        children: [
          _Field(
            label: '月支出 (元)',
            controller: monthlyExpenseCtrl,
            hint: '3000',
          ),
          const SizedBox(height: 12),
          _Field(
            label: '当前净资产 (元)',
            controller: netAssetsCtrl,
            hint: '0',
          ),
          const SizedBox(height: 12),
          _Field(
            label: '预期年化收益率 (%)',
            controller: annualRateCtrl,
            hint: '7',
          ),
          const SizedBox(height: 12),
          _Field(
            label: '每月可存金额 (元)',
            controller: monthlySavingsCtrl,
            hint: '2000',
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: context.themeText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.themeSub),
        hintText: hint,
        hintStyle: TextStyle(color: context.themeHint),
        filled: true,
        fillColor: context.themeBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: goldColor),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final double requiredPrincipal;
  final double netAssets;
  final double gap;
  final double progress;
  final double yearsNeeded;
  final double monthlyNeeded;

  const _ResultCard({
    required this.requiredPrincipal,
    required this.netAssets,
    required this.gap,
    required this.progress,
    required this.yearsNeeded,
    required this.monthlyNeeded,
  });

  String _fmt(double v) {
    if (v >= 10000) {
      return '${(v / 10000).toStringAsFixed(2)}万';
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(glowColor: goldColor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: '目标本金', value: _fmt(requiredPrincipal)),
              _Stat(label: '当前净资产', value: _fmt(netAssets)),
              _Stat(label: '缺口', value: _fmt(gap)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    backgroundColor: context.themeDivider,
                    valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: goldColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '已完成',
                      style: TextStyle(color: context.themeSub, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (yearsNeeded > 0) ...[
            _InfoRow(
              label: '预计还需年限',
              value: '${yearsNeeded.toStringAsFixed(1)} 年',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: '每月应存金额',
              value: '¥${monthlyNeeded.toStringAsFixed(0)}',
            ),
          ] else
            const Text(
              '🎉 恭喜！您已达到财务自由目标！',
              style: TextStyle(color: incomeGreen, fontSize: 16),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: goldColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: context.themeSub, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.themeSub, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: context.themeText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(glowColor: incomeGreen),
      child: Column(
        children: [
          Row(children: [
            const Text('📤', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('数据导出', style: TextStyle(color: context.themeText, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('导出全部交易记录为 CSV 文件', style: TextStyle(color: context.themeSub, fontSize: 11)),
                    ]),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [mintColor, incomeGreen]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () async {
                    try {
                      final tp = context.read<TransactionProvider>();
                      final path = await tp.exportCsvToFile();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ 已导出到: $path', style: TextStyle(color: context.themeText)),
                            backgroundColor: incomeGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 导出失败: $e', style: TextStyle(color: context.themeText)),
                            backgroundColor: expenseRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('导出 CSV', style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _QuoteBar extends StatelessWidget {
  final Map<String, String> quote;

  const _QuoteBar({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: context.themeCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '"${quote['text']}"',
            style: TextStyle(
              color: context.themeText,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '— ${quote['author']}',
            style: const TextStyle(color: goldColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
