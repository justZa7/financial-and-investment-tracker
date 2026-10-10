import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/budget_model.dart';
import 'cashflow_provider.dart';

const _uuid = Uuid();

/// Status progress satu budget, dihitung on-the-fly dari pengeluaran bulan
/// berjalan (bukan disimpan statis) — selalu akurat walau transaksi baru
/// masuk kapan saja.
class BudgetProgress {
  final BudgetModel budget;
  final double spent;

  BudgetProgress({required this.budget, required this.spent});

  double get percent => budget.monthlyLimit <= 0 ? 0.0 : (spent / budget.monthlyLimit * 100);
  double get remaining => (budget.monthlyLimit - spent).clamp(0.0, double.infinity).toDouble();
  bool get isOverBudget => spent > budget.monthlyLimit;
  bool get isNearLimit => !isOverBudget && percent >= 80;
}

/// Anggaran bulanan per kategori. BUKAN penyimpan angka "sudah terpakai"
/// sendiri — angka itu selalu dihitung ulang dari CashFlowProvider supaya
/// satu sumber kebenaran (single source of truth) untuk data pengeluaran.
class BudgetProvider extends ChangeNotifier {
  final List<BudgetModel> _budgets = [];

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  bool hasBudgetFor(String categoryId) => _budgets.any((b) => b.categoryId == categoryId);

  BudgetModel? budgetForCategory(String categoryId) {
    for (final b in _budgets) {
      if (b.categoryId == categoryId) return b;
    }
    return null;
  }

  String setBudget({required String categoryId, required double monthlyLimit}) {
    final existing = budgetForCategory(categoryId);
    if (existing != null) {
      existing.monthlyLimit = monthlyLimit;
      notifyListeners();
      return existing.id;
    }
    final budget = BudgetModel(id: _uuid.v4(), categoryId: categoryId, monthlyLimit: monthlyLimit);
    _budgets.add(budget);
    notifyListeners();
    return budget.id;
  }

  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
  }

  List<BudgetProgress> allProgress(CashFlowProvider cashFlow) {
    return _budgets
        .map((b) => BudgetProgress(budget: b, spent: cashFlow.expenseThisMonthForCategory(b.categoryId)))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  double totalMonthlyLimit() => _budgets.fold(0.0, (s, b) => s + b.monthlyLimit);

  double totalSpent(CashFlowProvider cashFlow) =>
      _budgets.fold(0.0, (s, b) => s + cashFlow.expenseThisMonthForCategory(b.categoryId));
}
