import 'package:flutter/foundation.dart';
import '../core/database.dart';
import '../models/asset.dart';

class AssetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Asset> _assets = [];

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
    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    final rows = await _db.getAssets();
    _assets = rows.map((r) => Asset.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addAsset(Asset asset) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final map = asset.toMap();
    map['created_at'] = now;
    map['updated_at'] = now;
    final id = await _db.insertAsset(map);
    _assets.add(asset.copyWith(id: id, createdAt: now, updatedAt: now));
    notifyListeners();
  }

  Future<void> updateAsset(Asset asset) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final map = asset.toMap();
    map['updated_at'] = now;
    await _db.updateAsset(map);
    final idx = _assets.indexWhere((a) => a.id == asset.id);
    if (idx != -1) _assets[idx] = asset.copyWith(updatedAt: now);
    notifyListeners();
  }

  Future<void> deleteAsset(int id) async {
    await _db.deleteAsset(id);
    _assets.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
