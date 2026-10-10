import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/savings_goal_model.dart';
import 'cashflow_provider.dart';

const _uuid = Uuid();

class SavingsGoalProvider extends ChangeNotifier {
  final List<SavingsGoalModel> _goals = [];

  List<SavingsGoalModel> get goals => List.unmodifiable(_goals);

  SavingsGoalModel? goalById(String id) {
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  double get totalSaved => _goals.fold(0.0, (s, g) => s + g.currentAmount);
  double get totalTarget => _goals.fold(0.0, (s, g) => s + g.targetAmount);

  String addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    IconData icon = Icons.savings_rounded,
    Color color = const Color(0xFF5C7A45),
  }) {
    final goal = SavingsGoalModel(
      id: _uuid.v4(),
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      icon: icon,
      color: color,
    );
    _goals.add(goal);
    notifyListeners();
    return goal.id;
  }

  void deleteGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
  }

  /// Setor dana ke goal — kalau [accountId] & [cashFlow] diisi, saldo akun
  /// itu BENERAN berkurang (uangnya nyata dipindah). Null = sukses.
  String? contribute({
    required String goalId,
    required double amount,
    String? accountId,
    CashFlowProvider? cashFlow,
    DateTime? date,
  }) {
    final goal = goalById(goalId);
    if (goal == null) return 'Goal tidak ditemukan';
    if (amount <= 0) return 'Nominal harus lebih besar dari 0';

    if (accountId != null && cashFlow != null) {
      final balance = cashFlow.balanceOf(accountId);
      if (balance < amount) {
        return 'Saldo akun tidak cukup (tersedia Rp${balance.toStringAsFixed(0)})';
      }
      cashFlow.adjustAccountBalance(accountId, -amount);
    }

    goal.currentAmount += amount;
    goal.contributions.add(SavingsContributionModel(
      id: _uuid.v4(),
      amount: amount,
      date: date ?? DateTime.now(),
      accountId: accountId,
    ));
    notifyListeners();
    return null;
  }

  /// Tarik dana dari goal kembali ke akun kas (kalau [accountId] diisi).
  String? withdraw({
    required String goalId,
    required double amount,
    String? accountId,
    CashFlowProvider? cashFlow,
    DateTime? date,
  }) {
    final goal = goalById(goalId);
    if (goal == null) return 'Goal tidak ditemukan';
    if (amount <= 0) return 'Nominal harus lebih besar dari 0';
    if (amount > goal.currentAmount) return 'Nominal melebihi dana yang tersimpan di goal ini';

    if (accountId != null && cashFlow != null) {
      cashFlow.adjustAccountBalance(accountId, amount);
    }

    goal.currentAmount -= amount;
    goal.contributions.add(SavingsContributionModel(
      id: _uuid.v4(),
      amount: -amount,
      date: date ?? DateTime.now(),
      accountId: accountId,
    ));
    notifyListeners();
    return null;
  }
}
