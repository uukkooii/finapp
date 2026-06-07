import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database.dart';
import '../models/budget.dart';
import 'transaction_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final TransactionProvider _transactionProvider;

  BudgetProvider(this._transactionProvider);

  Future<void> init() async {
    await _db.database;
  }

  Future<void> setBudget(String month, String category, double amount) async {
    await _db.upsertBudget({
      'month': month,
      'category': category,
      'amount': amount,
    });
    notifyListeners();
  }

  Future<Budget?> getBudget(String month, String category) async {
    final Database db = await _db.database;
    final rows = await db.query(
      'budgets',
      where: 'month = ? AND category = ?',
      whereArgs: [month, category],
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<List<Budget>> getAllBudgets(String month) async {
    final rows = await _db.getBudgetsByMonth(month);
    return rows.map<Budget>((r) => Budget.fromMap(r)).toList();
  }

  Future<void> deleteBudget(String month, String category) async {
    final Database db = await _db.database;
    await db.delete(
      'budgets',
      where: 'month = ? AND category = ?',
      whereArgs: [month, category],
    );
    notifyListeners();
  }

  Future<double> getTotalBudget(String month) async {
    final budgets = await getAllBudgets(month);
    // If explicit 总计 budget exists, use it
    for (final b in budgets) {
      if (b.category == '总计') return b.amount;
    }
    // Otherwise sum all category budgets (excluding 总计)
    double total = 0.0;
    for (final b in budgets) {
      total += b.amount;
    }
    return total;
  }

  Future<double> getSpentAmount(String month, String category) async {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final breakdown = await _transactionProvider.getCategoryBreakdown(year, m);
    return breakdown[category] ?? 0.0;
  }

  Future<double> getProgress(String month, String category) async {
    final budget = await getBudget(month, category);
    if (budget == null || budget.amount == 0) return 0.0;
    final spent = await getSpentAmount(month, category);
    return spent / budget.amount;
  }

  Future<bool> isOverBudget(String month, String category) async {
    final progress = await getProgress(month, category);
    return progress > 1.0;
  }
}
