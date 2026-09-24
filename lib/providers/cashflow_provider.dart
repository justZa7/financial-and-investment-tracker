import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/cash_transaction_model.dart';
import '../services/mock_data_service.dart';

const _uuid = Uuid();

class CashFlowProvider extends ChangeNotifier {
  final List<AccountModel> _accounts = [];
  final List<CategoryModel> _categories = [];
  final List<CashTransactionModel> _transactions = [];

  CashFlowProvider() {
    // Kategori & akun dasar tetap disiapkan (bukan "data dummy transaksi",
    // tapi daftar pilihan wajib supaya dropdown di form Input tidak kosong).
    // Tidak ada satupun transaksi kas yang di-seed -> mulai dari nol.
    _categories.addAll(MockDataService.categories());
    _accounts.addAll(MockDataService.defaultAccounts());
  }

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<CashTransactionModel> get transactions =>
      List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));

  List<CategoryModel> categoriesFor(CashFlowType type) => _categories
      .where((c) =>
          (type == CashFlowType.income && c.flow == CategoryFlow.income) ||
          (type == CashFlowType.expense && c.flow == CategoryFlow.expense))
      .toList();

  AccountModel accountById(String id) =>
      _accounts.firstWhere((a) => a.id == id, orElse: () => _accounts.first);

  CategoryModel categoryById(String id) => _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => _categories.first,
      );

  double get totalCashBalance =>
      _accounts.fold(0.0, (sum, a) => sum + a.balance);

  // -------------------------------------------------------------------
  // AGGREGATE HELPERS
  // -------------------------------------------------------------------
  double _sumInMonth(CashFlowType type, DateTime month) {
    return _transactions
        .where((t) =>
            t.type == type &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalIncomeThisMonth => _sumInMonth(CashFlowType.income, DateTime.now());
  double get totalExpenseThisMonth => _sumInMonth(CashFlowType.expense, DateTime.now());

  /// Rata-rata pemasukan per bulan (dari histori yang tersedia)
  double get averageMonthlyIncome => _averageMonthly(CashFlowType.income);
  double get averageMonthlyExpense => _averageMonthly(CashFlowType.expense);

  double _averageMonthly(CashFlowType type) {
    final months = _monthsWithData();
    if (months.isEmpty) return 0;
    final total = _transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
    return total / months.length;
  }

  Set<String> _monthsWithData() {
    return _transactions.map((t) => '${t.date.year}-${t.date.month}').toSet();
  }

  /// Data untuk line chart: 6 bulan terakhir -> {income, expense}
  List<MonthlyFlow> monthlyTrend({int months = 6}) {
    final now = DateTime.now();
    final result = <MonthlyFlow>[];
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      result.add(MonthlyFlow(
        month: month,
        income: _sumInMonth(CashFlowType.income, month),
        expense: _sumInMonth(CashFlowType.expense, month),
      ));
    }
    return result;
  }

  // -------------------------------------------------------------------
  // MUTATIONS
  // -------------------------------------------------------------------
  void addTransaction({
    required CashFlowType type,
    required String accountId,
    required String categoryId,
    required double amount,
    required DateTime date,
    String description = '',
  }) {
    final tx = CashTransactionModel(
      id: _uuid.v4(),
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      date: date,
      description: description,
    );
    _transactions.add(tx);

    final account = accountById(accountId);
    account.balance +=
        type == CashFlowType.income ? amount : -amount;

    notifyListeners();
  }
}

class MonthlyFlow {
  final DateTime month;
  final double income;
  final double expense;

  MonthlyFlow({required this.month, required this.income, required this.expense});
}
