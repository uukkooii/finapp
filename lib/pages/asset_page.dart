import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key});
  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AssetProvider>(context);
    final assets = ap.assets;
    final total = ap.totalAssets;
    final profit = ap.totalProfit;
    final breakdown = ap.typeBreakdown;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themeCard,
        title: const Text('🏦 资产管家', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: goldColor,
        foregroundColor: Colors.black,
        onPressed: () => _showAddDialog(context, ap),
        icon: const Icon(Icons.add),
        label: const Text('添加资产', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Total card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.themeHeader1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: goldColor.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            const Text('💰', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text('¥${_fmt(total)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: goldColor)),
            Text('总资产', style: TextStyle(color: context.themeSub, fontSize: 14)),
            if (profit != 0) ...[
              const SizedBox(height: 8),
              Text('${profit > 0 ? "📈" : "📉"} 总收益 ¥${_fmt(profit)}',
                  style: TextStyle(color: profit >= 0 ? incomeGreen : expenseRed, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        // Type breakdown
        if (breakdown.isNotEmpty) ...[
          Text('资产分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.themeText)),
          const SizedBox(height: 10),
          ...breakdown.entries.map((e) {
            final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: context.cardDecoration(),
                child: Row(children: [
                  Text(Asset.typeIcon(e.key), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: TextStyle(fontWeight: FontWeight.w600, color: context.themeText)),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? e.value / total : 0, minHeight: 4,
                        backgroundColor: context.themeDivider,
                        valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
                      ),
                    ),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('¥${_fmt(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
                    Text('$pct%', style: TextStyle(color: context.themeSub, fontSize: 11)),
                  ]),
                ]),
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        // Asset list
        Text('资产明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.themeText)),
        const SizedBox(height: 10),
        if (assets.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text('还没有资产，点右下角 + 添加吧 ✨', style: TextStyle(color: context.themeHint)),
          ))
        else
          ...assets.map((a) => _AssetTile(asset: a)),
        const SizedBox(height: 80),
      ]),
    );
  }

  void _showAddDialog(BuildContext context, AssetProvider ap, {Asset? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final costCtrl = TextEditingController(text: existing?.costBasis?.toString() ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var selectedType = existing?.type ?? '银行存款';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (stateCtx, setSheetState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(sheetCtx).brightness == Brightness.dark ? cardColor : lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(existing != null ? '编辑资产' : '添加资产', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(sheetCtx).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D2D2D))),
            const SizedBox(height: 16),
            // Type selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Asset.typeOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = Asset.typeOptions[i];
                  final sel = t == selectedType;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = t),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? goldColor.withValues(alpha: 0.22) : (Theme.of(sheetCtx).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? goldColor : Colors.white24, width: sel ? 1.5 : 0.5),
                      ),
                      child: Center(child: Text('${Asset.typeIcon(t)} $t', style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? goldColor : (Theme.of(sheetCtx).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666))))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildField(sheetCtx, _nameLabel(selectedType), nameCtrl, hint: _nameHint(selectedType)),
            const SizedBox(height: 10),
            _buildField(sheetCtx, _amountLabel(selectedType), amountCtrl, hint: _amountHint(selectedType), numeric: true),
            if (_showCost(selectedType)) ...[
              const SizedBox(height: 10),
              _buildField(sheetCtx, '成本 ¥（可选）', costCtrl, hint: '买入价，用于计算收益', numeric: true),
            ],
            const SizedBox(height: 10),
            _buildField(sheetCtx, '备注', noteCtrl, hint: '可选'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text);
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                      const SnackBar(content: Text('请输入资产名称'), backgroundColor: expenseRed),
                    );
                    return;
                  }
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                      const SnackBar(content: Text('请输入有效的金额'), backgroundColor: expenseRed),
                    );
                    return;
                  }
                  final cost = double.tryParse(costCtrl.text);
                  try {
                    if (existing != null) {
                      await ap.updateAsset(existing.copyWith(name: name, type: selectedType, amount: amount, costBasis: cost, note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()));
                    } else {
                      await ap.addAsset(Asset(name: name, type: selectedType, amount: amount, costBasis: cost, note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(), createdAt: ''));
                    }
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  } catch (e) {
                    if (sheetCtx.mounted) {
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        SnackBar(content: Text('保存失败：$e'), backgroundColor: expenseRed),
                      );
                    }
                  }
                },
                child: Text(existing != null ? '保存' : '添加', style: const TextStyle(fontSize: 16, color: Colors.black)),
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () { ap.deleteAsset(existing.id!); Navigator.pop(sheetCtx); },
                child: const Text('删除此资产', style: TextStyle(color: expenseRed)),
              ),
            ],
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ));
  }

  Widget _buildField(BuildContext ctx, String label, TextEditingController ctrl, {String? hint, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D2D2D), fontSize: 15),
      cursorColor: goldColor,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1B2E) : const Color(0xFFFAF8F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: goldColor, width: 1.5)),
      ),
    );
  }

  // ── 按资产类型返回不同的字段标签/提示 ──
  String _nameLabel(String type) {
    switch (type) {
      case '银行存款': return '银行名称';
      case '理财': return '产品名称';
      case '股票': return '股票名称';
      case '基金': return '基金名称';
      case '房产': return '房产名称';
      case '车辆': return '品牌型号';
      case '数字货币': return '币种名称';
      default: return '名称';
    }
  }
  String _nameHint(String type) {
    switch (type) {
      case '银行存款': return '工商银行储蓄卡';
      case '理财': return '招行月月宝 / 余额宝';
      case '股票': return '贵州茅台 600519';
      case '基金': return '易方达蓝筹精选';
      case '房产': return 'XX小区 X栋XXX';
      case '车辆': return '特斯拉 Model Y';
      case '黄金': return '实物金条 / 纸黄金';
      case '数字货币': return 'BTC / ETH';
      case '现金': return '钱包 / 储蓄罐';
      default: return '资产名称';
    }
  }
  String _amountLabel(String type) {
    switch (type) {
      case '银行存款': return '余额 ¥';
      case '理财': return '当前金额 ¥';
      case '股票': return '当前市值 ¥';
      case '基金': return '当前市值 ¥';
      case '房产': return '当前估值 ¥';
      case '车辆': return '当前估值 ¥';
      case '黄金': return '当前价值 ¥';
      case '数字货币': return '当前价值 ¥';
      default: return '金额 ¥';
    }
  }
  String _amountHint(String type) {
    switch (type) {
      case '银行存款': return '100,000';
      case '理财': return '50,000';
      case '股票': return '持仓市值';
      case '基金': return '持仓市值';
      case '房产': return '市场估值';
      case '车辆': return '二手估价';
      case '黄金': return '按克/盎司';
      case '数字货币': return '按当前币价';
      default: return '输入金额';
    }
  }
  /// 现金和"其他"不需要成本字段
  bool _showCost(String type) {
    return type != '现金' && type != '其他';
  }

  String _fmt(num n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(2)}万';
    return n.toStringAsFixed(0);
  }
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  const _AssetTile({required this.asset});

  @override
  Widget build(BuildContext context) {
    final profit = asset.profit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final ap = Provider.of<AssetProvider>(context, listen: false);
            final parent = context.findAncestorStateOfType<_AssetPageState>();
            parent!._showAddDialog(context, ap, existing: asset);
          },
          child: Row(children: [
            Text(asset.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asset.name, style: TextStyle(fontWeight: FontWeight.w600, color: context.themeText)),
              if (asset.note != null && asset.note!.isNotEmpty)
                Text(asset.note!, style: TextStyle(fontSize: 11, color: context.themeHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('¥${_fmt(asset.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
              if (profit != 0)
                Text('${profit >= 0 ? "+" : ""}¥${_fmt(profit)}', style: TextStyle(fontSize: 11, color: profit >= 0 ? incomeGreen : expenseRed)),
            ]),
          ]),
        ),
      ),
    );
  }

  String _fmt(num n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(2)}万';
    return n.toStringAsFixed(0);
  }
}
