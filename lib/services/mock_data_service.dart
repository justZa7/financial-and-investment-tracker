import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/asset_holding_model.dart';
import '../models/category_model.dart';
import '../models/cash_transaction_model.dart';
import '../models/debt_model.dart';

const _uuid = Uuid();

/// Blueprint sederhana untuk transaksi Beli/Jual aset yang akan
/// di-"replay" oleh PortfolioProvider lewat method buyAsset()/sellAsset()
/// miliknya sendiri, supaya logika Weighted Average & Realized G/L
/// yang dipakai untuk data mock SAMA PERSIS dengan logika saat user
/// input transaksi baru dari UI.
class AssetTxSeed {
  final String ticker;
  final String name;
  final AssetClass assetClass;
  final bool isBuy;
  final double qty;
  final double price;
  final double fee;
  final DateTime date;

  AssetTxSeed({
    required this.ticker,
    required this.name,
    required this.assetClass,
    required this.isBuy,
    required this.qty,
    required this.price,
    this.fee = 0,
    required this.date,
  });
}

class MockDataService {
  MockDataService._();

  static final DateTime _now = DateTime.now();

  // ---------------------------------------------------------------------
  // AKUN
  // ---------------------------------------------------------------------
  /// Akun default dengan saldo Rp0 — bukan data dummy transaksi, hanya
  /// daftar akun awal yang wajar (Tunai, Bank, E-Wallet) supaya dropdown
  /// akun di form Input tidak kosong saat aplikasi pertama kali dibuka.
  /// User bebas menambah/mengubah saldo lewat transaksi yang mereka input.
  static List<AccountModel> defaultAccounts() => [
        AccountModel(id: _uuid.v4(), name: 'Tunai', type: AccountType.cash, balance: 0),
        AccountModel(id: _uuid.v4(), name: 'Bank', type: AccountType.bank, balance: 0),
        AccountModel(id: _uuid.v4(), name: 'E-Wallet', type: AccountType.eWallet, balance: 0),
      ];

  static List<AccountModel> accounts() => [
        AccountModel(id: _uuid.v4(), name: 'Tunai', type: AccountType.cash, balance: 850000),
        AccountModel(id: _uuid.v4(), name: 'BCA', type: AccountType.bank, balance: 18500000),
        AccountModel(id: _uuid.v4(), name: 'Jenius', type: AccountType.bank, balance: 4200000),
        AccountModel(id: _uuid.v4(), name: 'GoPay', type: AccountType.eWallet, balance: 650000),
      ];

  // ---------------------------------------------------------------------
  // KATEGORI
  // ---------------------------------------------------------------------
  static List<CategoryModel> categories() => [
        CategoryModel(id: _uuid.v4(), name: 'Gaji', flow: CategoryFlow.income, icon: Icons.payments_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Bonus', flow: CategoryFlow.income, icon: Icons.card_giftcard_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Freelance', flow: CategoryFlow.income, icon: Icons.laptop_mac_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Lainnya (Income)', flow: CategoryFlow.income, icon: Icons.more_horiz),
        CategoryModel(id: _uuid.v4(), name: 'Makan & Minum', flow: CategoryFlow.expense, icon: Icons.restaurant_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Transportasi', flow: CategoryFlow.expense, icon: Icons.directions_car_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Tagihan & Utilitas', flow: CategoryFlow.expense, icon: Icons.receipt_long_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Belanja', flow: CategoryFlow.expense, icon: Icons.shopping_bag_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Hiburan', flow: CategoryFlow.expense, icon: Icons.movie_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Kesehatan', flow: CategoryFlow.expense, icon: Icons.local_hospital_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Pendidikan', flow: CategoryFlow.expense, icon: Icons.school_outlined),
        CategoryModel(id: _uuid.v4(), name: 'Lainnya (Expense)', flow: CategoryFlow.expense, icon: Icons.more_horiz),
      ];

  // ---------------------------------------------------------------------
  // TRANSAKSI KAS (6 bulan terakhir, agar line chart & rata2 terisi)
  // ---------------------------------------------------------------------
  static List<CashTransactionModel> cashTransactions({
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
  }) {
    final bank = accounts.firstWhere((a) => a.name == 'BCA').id;
    final cash = accounts.firstWhere((a) => a.name == 'Tunai').id;
    final ewallet = accounts.firstWhere((a) => a.name == 'GoPay').id;

    String cat(String name) => categories.firstWhere((c) => c.name == name).id;

    final list = <CashTransactionModel>[];

    for (int m = 5; m >= 0; m--) {
      final monthDate = DateTime(_now.year, _now.month - m, 1);

      // Pemasukan rutin: Gaji tiap tanggal 1
      list.add(CashTransactionModel(
        id: _uuid.v4(),
        type: CashFlowType.income,
        accountId: bank,
        categoryId: cat('Gaji'),
        amount: 12000000 + (m.isEven ? 500000 : 0),
        date: DateTime(monthDate.year, monthDate.month, 1),
        description: 'Gaji bulanan',
      ));

      if (m % 2 == 0) {
        list.add(CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.income,
          accountId: bank,
          categoryId: cat('Freelance'),
          amount: 1500000,
          date: DateTime(monthDate.year, monthDate.month, 15),
          description: 'Proyek freelance',
        ));
      }

      // Pengeluaran rutin
      list.addAll([
        CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.expense,
          accountId: bank,
          categoryId: cat('Tagihan & Utilitas'),
          amount: 950000,
          date: DateTime(monthDate.year, monthDate.month, 5),
          description: 'Listrik, air, internet',
        ),
        CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.expense,
          accountId: cash,
          categoryId: cat('Makan & Minum'),
          amount: 2200000 + (m * 30000),
          date: DateTime(monthDate.year, monthDate.month, 10),
          description: 'Makan harian',
        ),
        CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.expense,
          accountId: ewallet,
          categoryId: cat('Transportasi'),
          amount: 650000,
          date: DateTime(monthDate.year, monthDate.month, 12),
          description: 'Ojek online & bensin',
        ),
        CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.expense,
          accountId: bank,
          categoryId: cat('Belanja'),
          amount: 800000 + (m.isOdd ? 400000 : 0),
          date: DateTime(monthDate.year, monthDate.month, 18),
          description: 'Kebutuhan bulanan',
        ),
        CashTransactionModel(
          id: _uuid.v4(),
          type: CashFlowType.expense,
          accountId: ewallet,
          categoryId: cat('Hiburan'),
          amount: 350000,
          date: DateTime(monthDate.year, monthDate.month, 22),
          description: 'Nonton & langganan streaming',
        ),
      ]);
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------------------------------------------------------------------
  // TRANSAKSI ASET (di-replay oleh PortfolioProvider)
  // ---------------------------------------------------------------------
  static List<AssetTxSeed> assetTransactionSeeds() {
    DateTime d(int monthsAgo, int day) =>
        DateTime(_now.year, _now.month - monthsAgo, day);

    return [
      // BBCA - Saham
      AssetTxSeed(ticker: 'BBCA', name: 'Bank Central Asia Tbk', assetClass: AssetClass.equity, isBuy: true, qty: 100, price: 9200, fee: 15000, date: d(5, 3)),
      AssetTxSeed(ticker: 'BBCA', name: 'Bank Central Asia Tbk', assetClass: AssetClass.equity, isBuy: true, qty: 100, price: 9450, fee: 15000, date: d(3, 10)),
      AssetTxSeed(ticker: 'BBCA', name: 'Bank Central Asia Tbk', assetClass: AssetClass.equity, isBuy: false, qty: 50, price: 9800, fee: 10000, date: d(1, 5)),

      // BBRI - Saham
      AssetTxSeed(ticker: 'BBRI', name: 'Bank Rakyat Indonesia Tbk', assetClass: AssetClass.equity, isBuy: true, qty: 500, price: 4300, fee: 12000, date: d(4, 8)),
      AssetTxSeed(ticker: 'BBRI', name: 'Bank Rakyat Indonesia Tbk', assetClass: AssetClass.equity, isBuy: true, qty: 300, price: 4150, fee: 10000, date: d(2, 14)),

      // ANTM - Saham
      AssetTxSeed(ticker: 'ANTM', name: 'Aneka Tambang Tbk', assetClass: AssetClass.equity, isBuy: true, qty: 400, price: 1450, fee: 8000, date: d(3, 20)),

      // Emas
      AssetTxSeed(ticker: 'XAU', name: 'Emas Antam (gram)', assetClass: AssetClass.gold, isBuy: true, qty: 10, price: 1120000, fee: 0, date: d(5, 15)),
      AssetTxSeed(ticker: 'XAU', name: 'Emas Antam (gram)', assetClass: AssetClass.gold, isBuy: true, qty: 5, price: 1180000, fee: 0, date: d(2, 2)),

      // Crypto BTC
      AssetTxSeed(ticker: 'BTC', name: 'Bitcoin', assetClass: AssetClass.crypto, isBuy: true, qty: 0.02, price: 620000000, fee: 25000, date: d(4, 1)),
      AssetTxSeed(ticker: 'BTC', name: 'Bitcoin', assetClass: AssetClass.crypto, isBuy: true, qty: 0.015, price: 700000000, fee: 25000, date: d(1, 18)),
      AssetTxSeed(ticker: 'BTC', name: 'Bitcoin', assetClass: AssetClass.crypto, isBuy: false, qty: 0.01, price: 950000000, fee: 20000, date: d(0, 3)),

      // Crypto ETH
      AssetTxSeed(ticker: 'ETH', name: 'Ethereum', assetClass: AssetClass.crypto, isBuy: true, qty: 0.5, price: 32000000, fee: 15000, date: d(3, 6)),

      // Reksadana
      AssetTxSeed(ticker: 'RDPU-01', name: 'RD Pasar Uang Mandiri', assetClass: AssetClass.moneyMarket, isBuy: true, qty: 5000000, price: 1, fee: 0, date: d(5, 1)),
      AssetTxSeed(ticker: 'RDPU-01', name: 'RD Pasar Uang Mandiri', assetClass: AssetClass.moneyMarket, isBuy: true, qty: 2000000, price: 1.01, fee: 0, date: d(2, 1)),
    ];
  }

  /// Harga pasar terkini untuk masing-masing ticker (dipakai setelah replay,
  /// mensimulasikan hasil "Update Harga Pasar").
  static Map<String, double> latestMarketPrices() => {
        'BBCA': 10100,
        'BBRI': 4450,
        'ANTM': 1610,
        'XAU': 1250000,
        'BTC': 1050000000,
        'ETH': 35500000,
        'RDPU-01': 1.032,
      };

  // ---------------------------------------------------------------------
  // UTANG / PIUTANG
  // ---------------------------------------------------------------------
  static List<DebtModel> debts() {
    DateTime d(int daysFromNow) => _now.add(Duration(days: daysFromNow));

    final debt1 = DebtModel(
      id: _uuid.v4(),
      type: DebtType.debt,
      counterpartyName: 'Kredivo (Cicilan Laptop)',
      principal: 9000000,
      remaining: 4500000,
      dueDate: d(4),
      note: 'Cicilan 6x, sudah jalan 3x',
      status: DebtStatus.partial,
      payments: [
        DebtPaymentModel(id: _uuid.v4(), amount: 1500000, date: _now.subtract(const Duration(days: 60))),
        DebtPaymentModel(id: _uuid.v4(), amount: 1500000, date: _now.subtract(const Duration(days: 30))),
        DebtPaymentModel(id: _uuid.v4(), amount: 1500000, date: _now.subtract(const Duration(days: 2))),
      ],
    );

    final debt2 = DebtModel(
      id: _uuid.v4(),
      type: DebtType.debt,
      counterpartyName: 'Budi (Teman Kantor)',
      principal: 1000000,
      remaining: 1000000,
      dueDate: d(20),
      note: 'Pinjam untuk keperluan mendadak',
      status: DebtStatus.unpaid,
    );

    final receivable1 = DebtModel(
      id: _uuid.v4(),
      type: DebtType.receivable,
      counterpartyName: 'Siti (Adik)',
      principal: 2000000,
      remaining: 800000,
      dueDate: d(2),
      note: 'Bantu bayar kuliah',
      status: DebtStatus.partial,
      payments: [
        DebtPaymentModel(id: _uuid.v4(), amount: 1200000, date: _now.subtract(const Duration(days: 15))),
      ],
    );

    final receivable2 = DebtModel(
      id: _uuid.v4(),
      type: DebtType.receivable,
      counterpartyName: 'Rina (Rekan Bisnis)',
      principal: 5000000,
      remaining: 5000000,
      dueDate: d(-3),
      note: 'Modal usaha bersama, sudah lewat jatuh tempo',
      status: DebtStatus.unpaid,
    );

    final receivable3 = DebtModel(
      id: _uuid.v4(),
      type: DebtType.receivable,
      counterpartyName: 'Dedi (Tetangga)',
      principal: 500000,
      remaining: 0,
      dueDate: _now.subtract(const Duration(days: 10)),
      note: 'Pinjam untuk beli galon & sembako',
      status: DebtStatus.paid,
      payments: [
        DebtPaymentModel(id: _uuid.v4(), amount: 500000, date: _now.subtract(const Duration(days: 12))),
      ],
    );

    return [debt1, debt2, receivable1, receivable2, receivable3];
  }
}
