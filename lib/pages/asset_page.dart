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
      floatingActionButton: FloatingActionButton(
        backgroundColor: goldColor,
        onPressed: () => _showAddDialog(context, ap),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Total card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: context.themeHeroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
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
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.themeHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(existing != null ? '编辑资产' : '添加资产', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.themeText)),
            const SizedBox(height: 16),
            // Type selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Asset.typeOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final t = Asset.typeOptions[i];
                  final sel = t == selectedType;
                  return GestureDetector(
                    onTap: () => setState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: sel ? goldColor.withValues(alpha: 0.2) : context.themeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? goldColor : context.themeDivider),
                      ),
                      child: Center(child: Text('${Asset.typeIcon(t)} $t', style: TextStyle(fontSize: 12, color: sel ? goldColor : context.themeSub))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _field('名称', nameCtrl, hint: '工商银行储蓄卡'),
            const SizedBox(height: 10),
            _field('当前市值 ¥', amountCtrl, hint: '100000', numeric: true),
            const SizedBox(height: 10),
            _field('成本 ¥（可选）', costCtrl, hint: '用于计算收益', numeric: true),
            const SizedBox(height: 10),
            _field('备注', noteCtrl, hint: '可选'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: goldColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text);
                  if (name.isEmpty || amount == null) return;
                  final cost = double.tryParse(costCtrl.text);
                  if (existing != null) {
                    ap.updateAsset(existing.copyWith(name: name, type: selectedType, amount: amount, costBasis: cost, note: noteCtrl.text));
                  } else {
                    ap.addAsset(Asset(name: name, type: selectedType, amount: amount, costBasis: cost, note: noteCtrl.text, createdAt: ''));
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing != null ? '保存' : '添加', style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () { ap.deleteAsset(existing.id!); Navigator.pop(ctx); },
                child: Text('删除此资产', style: TextStyle(color: expenseRed)),
              ),
            ],
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: context.themeText),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: context.themeSub),
        filled: true, fillColor: context.themeBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
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
