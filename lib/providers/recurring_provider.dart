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

  /// 自动记账：处理所有已到期且开启自动记账的账单
  /// 返回自动处理的数量
  Future<int> processAutoPay(TransactionProvider txp) async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int count = 0;

    for (final bill in _bills) {
      if (!bill.isActive || !bill.autoPay || bill.nextDueDate == null) continue;
      if (bill.nextDueDate!.compareTo(today) > 0) continue; // not due yet

      final tx = Transaction(
        type: 'expense',
        amount: bill.amount,
        category: bill.category,
        account: bill.account ?? '现金',
        note: bill.note ?? bill.name,
        date: today,
      );
      await txp.addTransaction(tx);

      final nextDate = bill.computeNextDueDate();
      // Batch 推进到期日，不逐个通知
      final updated = bill.copyWith(nextDueDate: nextDate);
      await _db.updateRecurringBill(updated.toMap());
      count++;
    }

    if (count > 0) await _load();
    return count;
  }

  /// Toggle autoPay
  Future<void> toggleAutoPay(RecurringBill bill) async {
    await update(bill.copyWith(autoPay: !bill.autoPay));
  }
}
