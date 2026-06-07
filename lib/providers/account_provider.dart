import 'package:flutter/foundation.dart';
import '../core/database.dart';

class AccountProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<String> _accounts = [];

  List<String> get accounts => List.unmodifiable(_accounts);

  Future<void> init() async {
    await _db.seedDefaultAccounts();
    await _load();
  }

  Future<void> _load() async {
    final rows = await _db.getAccounts();
    _accounts = rows.map((r) => r['name'] as String).toList();
    notifyListeners();
  }

  Future<void> add(String name) async {
    await _db.insertAccount({'name': name, 'type': 'default', 'balance': 0.0});
    await _load();
  }

  Future<void> rename(String oldName, String newName) async {
    final rows = await _db.getAccounts();
    for (final r in rows) {
      if (r['name'] == oldName) {
        r['name'] = newName;
        await _db.updateAccount(r);
        break;
      }
    }
    await _load();
  }

  Future<void> delete(String name) async {
    final rows = await _db.getAccounts();
    for (final r in rows) {
      if (r['name'] == name) {
        await _db.deleteAccount(r['id'] as int);
        break;
      }
    }
    await _load();
  }
}
