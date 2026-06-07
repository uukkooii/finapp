import 'package:flutter/foundation.dart';
import '../core/database.dart';
import '../models/asset.dart';

class AssetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Asset> _assets = [];
  bool _loaded = false;

  List<Asset> get assets => List.unmodifiable(_assets);

  double get totalAssets => _assets.fold(0, (sum, a) => sum + a.amount);

  double get totalProfit => _assets.fold(0, (sum, a) => sum + a.profit);

  Map<String, double> get typeBreakdown {
    final map = <String, double>{};
    for (final a in _assets) {
      map[a.type] = (map[a.type] ?? 0) + a.amount;
    }
    return map;
  }

  Future<void> init() async {
    if (_loaded) return;
    await _loadAssets();
    _loaded = true;
  }

  /// 强制重新加载（供首页返回时调用）
  Future<void> reload() async {
    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final rows = await _db.getAssets();
      _assets = rows.map((r) {
        try {
          return Asset.fromMap(r);
        } catch (e) {
          debugPrint('[AssetProvider] fromMap error: $e row=$r');
          rethrow;
        }
      }).toList();
      debugPrint('[AssetProvider] Loaded ${_assets.length} assets, total=¥$totalAssets');
      notifyListeners();
    } catch (e) {
      debugPrint('[AssetProvider] _loadAssets failed: $e');
      _assets = [];
      notifyListeners();
    }
  }

  Future<void> addAsset(Asset asset) async {
    try {
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final map = asset.toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      final id = await _db.insertAsset(map);
      _assets.insert(0, asset.copyWith(id: id, createdAt: now, updatedAt: now));
      debugPrint('[AssetProvider] Added asset id=$id name=${asset.name} amount=${asset.amount} total now=¥$totalAssets');
      notifyListeners();
    } catch (e) {
      debugPrint('[AssetProvider] addAsset failed: $e');
      rethrow;
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final map = asset.toMap();
      map['updated_at'] = now;
      await _db.updateAsset(map);
      final idx = _assets.indexWhere((a) => a.id == asset.id);
      if (idx != -1) _assets[idx] = asset.copyWith(updatedAt: now);
      notifyListeners();
    } catch (e) {
      debugPrint('[AssetProvider] updateAsset failed: $e');
    }
  }

  Future<void> deleteAsset(int id) async {
    try {
      await _db.deleteAsset(id);
      _assets.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[AssetProvider] deleteAsset failed: $e');
    }
  }
}
