import 'package:flutter/foundation.dart';
import '../core/database.dart';
import '../models/recurring_bill.dart';
import '../models/transaction.dart';
import 'transaction_provider.dart';

class RecurringProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<RecurringBill> _bills = [];

  List<RecurringBill> get bills => List.unmodifiable(_bills);

  Future<void> init() async {
    await _load();
  }

  Future<void> _load() async {
    final rows = await _db.getRecurringBills();
    _bills = rows.map((r) => RecurringBill.fromMap(r)).toList();
    notifyListeners();
  }

  List<RecurringBill> getUpcoming(int daysAhead) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(Duration(days: daysAhead));
    return _bills.where((b) {
      if (!b.isActive || b.nextDueDate == null) return false;
      final due = DateTime.parse(b.nextDueDate!);
      return !due.isBefore(today) && !due.isAfter(cutoff);
    }).toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
  }

  Future<List<RecurringBill>> getUpcomingFromDb(int days) async {
    final rows = await _db.getUpcomingBills(days);
    return rows.map((r) => RecurringBill.fromMap(r)).toList();
  }

  Future<void> add(RecurringBill bill) async {
    await _db.insertRecurringBill(bill.toMap());
    await _load();
  }

  Future<void> update(RecurringBill bill) async {
    await _db.updateRecurringBill(bill.toMap());
    await _load();
  }

  Future<void> delete(int id) async {
    await _db.deleteRecurringBill(id);
    await _load();
  }

  Future<void> toggle(RecurringBill bill) async {
    await update(bill.copyWith(isActive: !bill.isActive));
  }

  /// Marks a bill as paid: creates an expense transaction and advances the due date.
  Future<void> markPaid(RecurringBill bill, TransactionProvider txp) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tx = Transaction(
      type: 'expense',
      amount: bill.amount,
      category: bill.category,
      account: bill.account ?? '现金',
      note: bill.note ?? bill.name,
      date: dateStr,
    );
    await txp.addTransaction(tx);
    final nextDate = bill.computeNextDueDate();
    await update(bill.copyWith(nextDueDate: nextDate));
  }
}
