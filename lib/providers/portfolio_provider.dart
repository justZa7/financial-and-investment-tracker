import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_holding_model.dart';
import '../models/asset_transaction_model.dart';
import '../services/calculation_service.dart';
import '../services/market_data_service.dart';

const _uuid = Uuid();

/// Hasil simulasi replay transaksi satu ticker — dipakai untuk VALIDASI
/// sebelum commit perubahan dari edit/hapus transaksi.
typedef _ReplayResult = ({
  double qty,
  double avgPrice,
  double realized,
  DateTime? firstBuy,
  List<AssetTransactionModel> updatedTxs,
});

class PortfolioProvider extends ChangeNotifier {
  final Map<String, AssetHoldingModel> _holdings = {}; // key: ticker
  final List<AssetTransactionModel> _transactions = [];

  // Tidak ada data yang di-seed -> portofolio mulai kosong.

  List<AssetHoldingModel> get holdings =>
      List.unmodifiable(_holdings.values.where((h) => h.qty > 0.0000001 || h.realizedGainLoss != 0));

  List<AssetHoldingModel> get activeHoldings =>
      List.unmodifiable(_holdings.values.where((h) => h.qty > 0.0000001));

  List<AssetTransactionModel> get transactions =>
      List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));

  AssetTransactionModel? transactionById(String id) {
    for (final t in _transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  AssetHoldingModel? holdingByTicker(String ticker) => _holdings[ticker.toUpperCase()];

  // -------------------------------------------------------------------
  // AGGREGATES
  // -------------------------------------------------------------------
  double get totalMarketValue =>
      activeHoldings.fold(0.0, (sum, h) => sum + h.currentValue);

  double get totalCostBasis =>
      activeHoldings.fold(0.0, (sum, h) => sum + h.costBasis);

  double get totalUnrealizedGainLoss =>
      activeHoldings.fold(0.0, (sum, h) => sum + h.unrealizedGainLoss);

  double get totalRealizedGainLoss =>
      _holdings.values.fold(0.0, (sum, h) => sum + h.realizedGainLoss);

  double get totalGainLoss => totalUnrealizedGainLoss + totalRealizedGainLoss;

  /// Total estimasi yield gain dari seluruh holding Reksadana Pasar Uang
  double get totalYieldGain =>
      activeHoldings.fold(0.0, (sum, h) => sum + h.estimatedYieldGain);

  /// Annual Return (%) portofolio keseluruhan
  double get annualReturnPercent => CalculationService.annualReturnPercent(
        totalGain: totalGainLoss,
        totalCostBasis: totalCostBasis,
      );

  double valueByClass(AssetClass cls) => activeHoldings
      .where((h) => h.assetClass == cls)
      .fold(0.0, (sum, h) => sum + h.currentValue);

  Map<AssetClass, double> get allocation {
    final map = <AssetClass, double>{};
    for (final cls in AssetClass.values) {
      final v = valueByClass(cls);
      if (v > 0) map[cls] = v;
    }
    return map;
  }

  /// Trend nilai portofolio beberapa titik terakhir untuk line chart.
  /// Karena tidak ada historis harga pasar sungguhan, nilai diinterpolasi
  /// dari cost basis -> nilai pasar saat ini (representatif untuk demo).
  List<double> portfolioValueTrend({int points = 6}) {
    if (activeHoldings.isEmpty) return List.filled(points, 0.0);
    final currentValue = totalMarketValue;
    final startValue = totalCostBasis * 0.9;
    return List.generate(points, (i) {
      final t = points == 1 ? 1.0 : i / (points - 1);
      return startValue + (currentValue - startValue) * t;
    });
  }

  // -------------------------------------------------------------------
  // MUTATIONS - Algoritma Akuntansi Investasi
  // -------------------------------------------------------------------

  /// BUY: Weighted Average Cost Basis
  void buyAsset({
    required String ticker,
    required String name,
    required AssetClass assetClass,
    required double qty,
    required double pricePerUnit,
    double fee = 0,
    required DateTime date,
    double annualYieldPercent = 0,
  }) {
    final key = ticker.toUpperCase();
    final isNew = !_holdings.containsKey(key);
    final holding = _holdings.putIfAbsent(
      key,
      () => AssetHoldingModel(id: _uuid.v4(), ticker: key, name: name, assetClass: assetClass),
    );

    holding.avgBuyPrice = CalculationService.weightedAveragePrice(
      existingQty: holding.qty,
      existingAvgPrice: holding.avgBuyPrice,
      buyQty: qty,
      buyPrice: pricePerUnit,
    );
    holding.qty += qty;
    if (isNew) holding.marketPrice = pricePerUnit;
    if (annualYieldPercent > 0) holding.annualYieldPercent = annualYieldPercent;
    holding.firstBuyDate ??= date;
    if (date.isBefore(holding.firstBuyDate!)) holding.firstBuyDate = date;

    _transactions.add(AssetTransactionModel(
      id: _uuid.v4(),
      assetId: holding.id,
      ticker: key,
      assetClass: assetClass,
      type: AssetTxType.buy,
      qty: qty,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
    ));

    notifyListeners();
  }

  /// SELL: berbasis Average Cost Basis (avg cost dipertahankan, qty berkurang)
  /// Realized G/L = (SellPrice - AvgPrice) * SellQty - Fee
  String? sellAsset({
    required String ticker,
    required double qty,
    required double pricePerUnit,
    double fee = 0,
    required DateTime date,
  }) {
    final key = ticker.toUpperCase();
    final holding = _holdings[key];

    if (holding == null || holding.qty < qty) {
      return 'Qty melebihi jumlah aset yang dimiliki';
    }

    final realized = CalculationService.realizedGainLoss(
      sellPrice: pricePerUnit,
      avgPrice: holding.avgBuyPrice,
      sellQty: qty,
      fee: fee,
    );

    holding.qty -= qty;
    holding.realizedGainLoss += realized;

    _transactions.add(AssetTransactionModel(
      id: _uuid.v4(),
      assetId: holding.id,
      ticker: key,
      assetClass: holding.assetClass,
      type: AssetTxType.sell,
      qty: qty,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      realizedGainLoss: realized,
    ));

    notifyListeners();
    return null; // sukses
  }

  // -------------------------------------------------------------------
  // EDIT & HAPUS TRANSAKSI — pendekatan REPLAY
  // -------------------------------------------------------------------
  // Mengubah/menghapus satu transaksi lama bisa mempengaruhi avg price &
  // realized gain SEMUA transaksi setelahnya untuk ticker yang sama (avg
  // price bersifat kumulatif). Supaya hasilnya benar APAPUN transaksi yang
  // diedit/dihapus (bukan cuma yang terakhir), seluruh transaksi ticker itu
  // disimulasikan ULANG dari nol, urut tanggal, di [_simulateTicker] —
  // divalidasi dulu (cegah oversell) SEBELUM di-commit lewat
  // [_commitSimulation].
  // -------------------------------------------------------------------

  /// Simulasi di variabel sementara, TIDAK menyentuh state asli. Null kalau
  /// urutan transaksi tidak valid (ada SELL yang qty-nya melebihi stok).
  _ReplayResult? _simulateTicker(List<AssetTransactionModel> txsForTicker) {
    final sorted = [...txsForTicker]..sort((a, b) => a.date.compareTo(b.date));
    double qty = 0, avgPrice = 0, realized = 0;
    DateTime? firstBuy;
    final updated = <AssetTransactionModel>[];

    for (final tx in sorted) {
      if (tx.type == AssetTxType.buy) {
        avgPrice = CalculationService.weightedAveragePrice(
          existingQty: qty,
          existingAvgPrice: avgPrice,
          buyQty: tx.qty,
          buyPrice: tx.pricePerUnit,
        );
        qty += tx.qty;
        if (firstBuy == null || tx.date.isBefore(firstBuy)) firstBuy = tx.date;
        updated.add(tx);
      } else {
        if (qty < tx.qty - 0.0000001) return null; // oversell -> invalid
        final r = CalculationService.realizedGainLoss(
          sellPrice: tx.pricePerUnit,
          avgPrice: avgPrice,
          sellQty: tx.qty,
          fee: tx.fee,
        );
        qty -= tx.qty;
        realized += r;
        updated.add(AssetTransactionModel(
          id: tx.id,
          assetId: tx.assetId,
          ticker: tx.ticker,
          assetClass: tx.assetClass,
          type: tx.type,
          qty: tx.qty,
          pricePerUnit: tx.pricePerUnit,
          fee: tx.fee,
          date: tx.date,
          realizedGainLoss: r,
        ));
      }
    }

    return (qty: qty, avgPrice: avgPrice, realized: realized, firstBuy: firstBuy, updatedTxs: updated);
  }

  /// Terapkan hasil [_simulateTicker] ke state asli: tulis ulang record
  /// transaksi SELL (realizedGainLoss-nya mungkin berubah) & update holding.
  /// `annualYieldPercent`/`marketPrice` SENGAJA tidak disentuh — keduanya
  /// independen dari histori transaksi, jadi otomatis tetap terjaga.
  void _commitSimulation(String key, _ReplayResult result) {
    for (final updatedTx in result.updatedTxs) {
      final idx = _transactions.indexWhere((t) => t.id == updatedTx.id);
      if (idx != -1) _transactions[idx] = updatedTx;
    }

    // Holding baru dihapus kalau SUDAH TIDAK ADA transaksi tersisa untuk
    // ticker ini. Kalau transaksinya masih ada tapi qty=0 & realized=0
    // (misal beli lalu jual di harga yang sama), holding tetap disimpan
    // (tersembunyi dari getter `holdings`/`activeHoldings`) supaya kalau
    // transaksinya diedit lagi dan qty jadi > 0, state-nya tetap konsisten.
    if (result.updatedTxs.isEmpty) {
      _holdings.remove(key);
      return;
    }

    final holding = _holdings[key];
    if (holding != null) {
      holding.qty = result.qty;
      holding.avgBuyPrice = result.avgPrice;
      holding.realizedGainLoss = result.realized;
      holding.firstBuyDate = result.firstBuy;
    }
  }

  /// Edit satu transaksi Beli/Jual (qty/harga/fee/tanggal). Null = sukses,
  /// String = pesan error (perubahan bikin transaksi jual jadi oversell —
  /// perubahan DIBATALKAN, state tidak berubah sama sekali).
  String? updateAssetTransaction({
    required String transactionId,
    required double qty,
    required double pricePerUnit,
    double fee = 0,
    required DateTime date,
  }) {
    final old = transactionById(transactionId);
    if (old == null) return 'Transaksi tidak ditemukan';

    final candidate = AssetTransactionModel(
      id: old.id,
      assetId: old.assetId,
      ticker: old.ticker,
      assetClass: old.assetClass,
      type: old.type,
      qty: qty,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      realizedGainLoss: old.realizedGainLoss,
    );

    final others = _transactions.where((t) => t.ticker == old.ticker && t.id != transactionId).toList();
    final result = _simulateTicker([...others, candidate]);
    if (result == null) {
      return 'Perubahan ini membuat jumlah jual melebihi stok yang dimiliki pada tanggal tersebut. '
          'Coba kurangi qty jual lain dulu, atau edit transaksi beli yang terkait.';
    }

    // Transaksi yang diedit sendiri harus ikut diganti di daftar utama
    // (kalau BUY, tidak ada di updatedTxs hasil perubahan nilai lainnya).
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    _transactions[index] = candidate;
    _commitSimulation(old.ticker, result);
    notifyListeners();
    return null;
  }

  /// Hapus satu transaksi Beli/Jual. False kalau transaksi tidak ditemukan
  /// atau penghapusannya bikin urutan transaksi tidak valid.
  bool deleteAssetTransaction(String transactionId) {
    final removed = transactionById(transactionId);
    if (removed == null) return false;

    final remaining = _transactions.where((t) => t.ticker == removed.ticker && t.id != transactionId).toList();
    final result = _simulateTicker(remaining);
    if (result == null) return false;

    _transactions.removeWhere((t) => t.id == transactionId);
    _commitSimulation(removed.ticker, result);
    notifyListeners();
    return true;
  }

  /// Update harga pasar manual -> memicu re-render nilai portofolio & chart
  void updateMarketPrice(String ticker, double newPrice) {
    final key = ticker.toUpperCase();
    final holding = _holdings[key];
    if (holding != null) {
      holding.marketPrice = newPrice;
      notifyListeners();
    }
  }

  /// Fetch harga pasar semua aset dari API publik (lihat MarketDataService
  /// untuk detail dukungan per kelas aset).
  Future<List<FetchPriceResult>> fetchMarketPricesFromApi() async {
    final results = await MarketDataService.fetchAll(activeHoldings);
    for (final r in results) {
      if (r.success) {
        updateMarketPrice(r.ticker, r.price!);
      }
    }
    return results;
  }

  /// Fetch & terapkan harga pasar untuk SATU ticker saja — dipakai otomatis
  /// setelah transaksi Beli/Jual disimpan dari form Input.
  Future<void> fetchSinglePrice(String ticker, AssetClass assetClass) async {
    final quote = await MarketDataService.fetchQuote(ticker, assetClass);
    if (quote != null) {
      updateMarketPrice(ticker, quote.price);
    }
  }
}
