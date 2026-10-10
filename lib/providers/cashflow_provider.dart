import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/cash_transaction_model.dart';
import '../models/transfer_model.dart';
import '../services/mock_data_service.dart';

const _uuid = Uuid();

class CashFlowProvider extends ChangeNotifier {
  final List<AccountModel> _accounts = [];
  final List<CategoryModel> _categories = [];
  final List<CashTransactionModel> _transactions = [];
  final List<TransferModel> _transfers = [];

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
  List<TransferModel> get transfers =>
      List.unmodifiable(_transfers..sort((a, b) => b.date.compareTo(a.date)));

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

  CashTransactionModel? transactionById(String id) {
    for (final t in _transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  double get totalCashBalance =>
      _accounts.fold(0.0, (sum, a) => sum + a.balance);

  /// Total saldo untuk satu tipe akun (Tunai/Bank/E-Wallet) — dipakai
  /// halaman Detail Kas untuk breakdown per tipe.
  double balanceByType(AccountType type) => _accounts
      .where((a) => a.type == type)
      .fold(0.0, (sum, a) => sum + a.balance);

  List<AccountModel> accountsByType(AccountType type) =>
      _accounts.where((a) => a.type == type).toList();

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

  /// Total pengeluaran bulan berjalan untuk SATU kategori — dipakai fitur
  /// Budget untuk menghitung progress "terpakai / limit".
  double expenseThisMonthForCategory(String categoryId) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == CashFlowType.expense &&
            t.categoryId == categoryId &&
            t.date.year == now.year &&
            t.date.month == now.month)
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
  // MUTATIONS — Transaksi Kas (Pemasukan/Pengeluaran)
  // -------------------------------------------------------------------
  String addTransaction({
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
    accountById(accountId).balance += type == CashFlowType.income ? amount : -amount;
    notifyListeners();
    return tx.id;
  }

  /// Edit transaksi kas yang sudah ada. Efek saldo transaksi LAMA dibalik
  /// dulu dari akun lamanya, baru efek transaksi BARU diterapkan ke akun
  /// barunya — supaya saldo selalu konsisten walau akun/jenis/nominal
  /// diganti sekaligus.
  bool updateTransaction({
    required String id,
    required CashFlowType type,
    required String accountId,
    required String categoryId,
    required double amount,
    required DateTime date,
    String description = '',
  }) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    final old = _transactions[index];
    accountById(old.accountId).balance -= old.type == CashFlowType.income ? old.amount : -old.amount;

    _transactions[index] = CashTransactionModel(
      id: id,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      date: date,
      description: description,
    );
    accountById(accountId).balance += type == CashFlowType.income ? amount : -amount;

    notifyListeners();
    return true;
  }

  bool deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    final tx = _transactions[index];
    accountById(tx.accountId).balance -= tx.type == CashFlowType.income ? tx.amount : -tx.amount;
    _transactions.removeAt(index);

    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------------
  // MUTATIONS — Transfer Antar Akun Sendiri
  // -------------------------------------------------------------------
  /// Null = sukses, String = pesan error (saldo kurang / akun sama).
  String? addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String note = '',
  }) {
    if (fromAccountId == toAccountId) return 'Akun asal dan tujuan tidak boleh sama';
    if (amount <= 0) return 'Nominal transfer harus lebih besar dari 0';
    final fromBalance = balanceOf(fromAccountId);
    if (fromBalance < amount) {
      return 'Saldo tidak cukup (tersedia Rp${fromBalance.toStringAsFixed(0)})';
    }

    _transfers.add(TransferModel(
      id: _uuid.v4(),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
    ));
    accountById(fromAccountId).balance -= amount;
    accountById(toAccountId).balance += amount;
    notifyListeners();
    return null;
  }

  bool deleteTransfer(String id) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    final transfer = _transfers[index];
    // Balikkan efeknya: kembalikan ke akun asal, tarik lagi dari akun tujuan.
    accountById(transfer.fromAccountId).balance += transfer.amount;
    accountById(transfer.toAccountId).balance -= transfer.amount;
    _transfers.removeAt(index);

    notifyListeners();
    return true;
  }

  /// Saldo akun saat ini (dipakai UI untuk menampilkan "Saldo tersedia").
  double balanceOf(String accountId) => accountById(accountId).balance;

  /// Ubah saldo akun TANPA mencatat entri transaksi kas formal — dipakai
  /// saat beli/jual aset "Dari Kas"/"Masuk ke Kas" dan kontribusi Savings
  /// Goal, karena pergerakan dananya sudah tercatat di modul masing-masing.
  /// [delta] positif = menambah saldo, negatif = mengurangi saldo.
  void adjustAccountBalance(String accountId, double delta) {
    final account = accountById(accountId);
    account.balance += delta;
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // MUTATIONS — Kelola Akun
  // -------------------------------------------------------------------
  String addAccount({required String name, required AccountType type, double balance = 0}) {
    final account = AccountModel(id: _uuid.v4(), name: name, type: type, balance: balance);
    _accounts.add(account);
    notifyListeners();
    return account.id;
  }

  void renameAccount(String accountId, String newName) {
    accountById(accountId).name = newName;
    notifyListeners();
  }

  /// Hapus akun. Diizinkan walau saldo belum nol (UI memberi peringatan
  /// dulu) — transaksi lama yang mereferensi akun ini tidak dihapus,
  /// `accountById()` fallback ke akun pertama (graceful, tidak crash).
  /// Tidak boleh menghapus akun TERAKHIR supaya form Input tetap punya
  /// minimal satu pilihan akun. Mengembalikan false kalau ditolak.
  bool deleteAccount(String accountId) {
    if (_accounts.length <= 1) return false;
    _accounts.removeWhere((a) => a.id == accountId);
    notifyListeners();
    return true;
  }
}

class MonthlyFlow {
  final DateTime month;
  final double income;
  final double expense;

  MonthlyFlow({required this.month, required this.income, required this.expense});
}
