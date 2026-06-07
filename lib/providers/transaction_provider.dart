import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../core/database.dart';
import '../models/transaction.dart';
import 'goal_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  GoalProvider? _goalProvider;

  void setGoalProvider(GoalProvider gp) {
    _goalProvider = gp;
  }

  Future<void> init() async {
    await _db.database;
  }

  Future<void> addTransaction(Transaction t) async {
    await _db.insertTransaction(t.toMap());
    if (t.type == 'income' && _goalProvider != null) {
      await _goalProvider!.syncGoalWithTransaction(t);
    }
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction t) async {
    await _db.updateTransaction(t.toMap());
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    notifyListeners();
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await _db.getTransactionsByMonth(monthStr);
    return rows.map<Transaction>((r) => Transaction.fromMap(r)).toList();
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in txns) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  Future<Map<String, double>> getCategoryBreakdown(int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
    final breakdown = <String, double>{};
    for (final t in txns) {
      if (t.type == 'expense') {
        breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
      }
    }
    return breakdown;
  }

  Future<List<Transaction>> getRecentTransactions(int limit) async {
    final Database db = await _db.database;
    final rows = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map<Transaction>((r) => Transaction.fromMap(r)).toList();
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    final Database db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'category LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
      limit: 20,
    );
    return rows.map<Transaction>((r) => Transaction.fromMap(r)).toList();
  }

  Future<String> exportAllCsv() async {
    final Database db = await _db.database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    final buf = StringBuffer('日期,类型,分类,金额,账户,备注\n');
    for (final r in rows) {
      final date = r['date'] ?? '';
      final type = r['type'] == 'income' ? '收入' : '支出';
      final cat = r['category'] ?? '';
      final amt = (r['amount'] as num?)?.toStringAsFixed(2) ?? '0';
      final acct = r['account'] ?? '';
      final note = (r['note'] as String?)?.replaceAll(',', '，') ?? '';
      buf.writeln('$date,$type,$cat,$amt,$acct,$note');
    }
    return buf.toString();
  }

  Future<String> exportCsvToFile() async {
    final csv = await exportAllCsv();
    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      final tmp = Directory('/tmp');
      final file = File('${tmp.path}/金库_导出_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv, flush: true);
      return file.path;
    }
    final file = File('${dir.path}/金库_导出_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv, flush: true);
    return file.path;
  }
}
