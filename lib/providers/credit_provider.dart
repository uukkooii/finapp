import 'package:flutter/foundation.dart';
import '../core/database.dart';
import '../models/credit_card.dart';

class CreditProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<CreditCard> _cards = [];

  List<CreditCard> get cards => List.unmodifiable(_cards);

  Future<void> init() async {
    await _load();
  }

  Future<void> _load() async {
    final rows = await _db.getCreditCards();
    _cards = rows.map((r) => CreditCard.fromMap(r)).toList();
    notifyListeners();
  }

  double get totalDebt =>
      _cards.fold(0, (sum, c) => sum + c.currentBalance);

  double get totalLimit =>
      _cards.fold(0, (sum, c) => sum + c.creditLimit);

  double get overallUtilization =>
      totalLimit > 0 ? (totalDebt / totalLimit).clamp(0.0, 1.0) : 0.0;

  List<CreditCard> getUpcomingPayments(int daysAhead) {
    final now = DateTime.now();
    return _cards.where((c) {
      final days = c.daysUntilPayment(now);
      return days >= 0 && days <= daysAhead;
    }).toList()
      ..sort((a, b) =>
          a.daysUntilPayment(now).compareTo(b.daysUntilPayment(now)));
  }

  Future<void> add(CreditCard card) async {
    await _db.insertCreditCard(card.toMap());
    await _load();
  }

  Future<void> update(CreditCard card) async {
    await _db.updateCreditCard(card.toMap());
    await _load();
  }

  Future<void> delete(int id) async {
    await _db.deleteCreditCard(id);
    await _load();
  }
}
