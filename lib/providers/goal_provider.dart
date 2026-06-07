import 'package:flutter/foundation.dart';
import '../core/database.dart';
import '../models/goal.dart';
import '../models/transaction.dart';

class GoalProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Goal> _goals = [];

  List<Goal> get goals => List.unmodifiable(_goals);

  Future<void> init() async {
    await _db.database;
    final rows = await _db.getGoals();
    _goals = rows.map<Goal>((r) => Goal.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    final id = await _db.insertGoal(goal.toMap());
    _goals.insert(0, goal.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.updateGoal(goal.toMap());
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) _goals[idx] = goal;
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<List<Goal>> getAllGoals() async {
    final rows = await _db.getGoals();
    return rows.map<Goal>((r) => Goal.fromMap(r)).toList();
  }

  double getProgress(int id) {
    final goal = _goals.firstWhere((g) => g.id == id);
    return goal.progress;
  }

  // Returns how much needs to be saved per month to hit the deadline.
  // Returns null if the goal has no deadline or is already complete.
  double? getMonthlySavingNeeded(int id) {
    final goal = _goals.firstWhere((g) => g.id == id);
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0 || goal.deadline == null) return null;

    final deadline = DateTime.parse(goal.deadline!);
    final now = DateTime.now();
    final months =
        (deadline.year - now.year) * 12 + (deadline.month - now.month);
    if (months <= 0) return remaining;

    return remaining / months;
  }

  Future<void> syncGoalWithTransaction(Transaction t) async {
    if (t.type != 'income') return;

    bool changed = false;
    for (int i = 0; i < _goals.length; i++) {
      final goal = _goals[i];
      if (goal.account == t.account && goal.progress < 1.0) {
        final updated = goal.copyWith(
          currentAmount: goal.currentAmount + t.amount,
        );
        await _db.updateGoal(updated.toMap());
        _goals[i] = updated;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
