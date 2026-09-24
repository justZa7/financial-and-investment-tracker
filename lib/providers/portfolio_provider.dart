import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_holding_model.dart';
import '../models/asset_transaction_model.dart';
import '../services/calculation_service.dart';
import '../services/market_data_service.dart';

const _uuid = Uuid();

class PortfolioProvider extends ChangeNotifier {
  final Map<String, AssetHoldingModel> _holdings = {}; // key: ticker
  final List<AssetTransactionModel> _transactions = [];

  // Tidak ada data yang di-seed -> portofolio mulai kosong.
  // User membangun holding-nya sendiri lewat buyAsset()/sellAsset()
  // dari form Input (Tab Investasi).

  List<AssetHoldingModel> get holdings =>
      List.unmodifiable(_holdings.values.where((h) => h.qty > 0.0000001 || h.realizedGainLoss != 0));

  List<AssetHoldingModel> get activeHoldings =>
      List.unmodifiable(_holdings.values.where((h) => h.qty > 0.0000001));

  List<AssetTransactionModel> get transactions =>
      List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));

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
  /// secara proporsional dari cost basis kumulatif -> nilai pasar saat ini,
  /// supaya grafik tetap representatif untuk kebutuhan demo/presentasi.
  List<double> portfolioValueTrend({int points = 6}) {
    if (activeHoldings.isEmpty) return List.filled(points, 0);
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
    final existing = _holdings[key];

    if (existing == null) {
      _holdings[key] = AssetHoldingModel(
        id: _uuid.v4(),
        ticker: key,
        name: name,
        assetClass: assetClass,
        qty: qty,
        avgBuyPrice: pricePerUnit,
        marketPrice: pricePerUnit,
        annualYieldPercent: annualYieldPercent,
        firstBuyDate: date,
      );
    } else {
      final newAvg = CalculationService.weightedAveragePrice(
        existingQty: existing.qty,
        existingAvgPrice: existing.avgBuyPrice,
        buyQty: qty,
        buyPrice: pricePerUnit,
      );
      existing.qty += qty;
      existing.avgBuyPrice = newAvg;
      // Update yield tahunan kalau user isi nilai baru (misal manajer investasi
      // mengubah rate yield produknya), pertahankan firstBuyDate paling awal.
      if (annualYieldPercent > 0) {
        existing.annualYieldPercent = annualYieldPercent;
      }
      existing.firstBuyDate ??= date;
      if (date.isBefore(existing.firstBuyDate!)) {
        existing.firstBuyDate = date;
      }
    }

    _transactions.add(AssetTransactionModel(
      id: _uuid.v4(),
      assetId: _holdings[key]!.id,
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
  /// untuk detail dukungan per kelas aset). Hasil sukses langsung diterapkan
  /// ke holding via updateMarketPrice(); hasil gagal dikembalikan apa adanya
  /// supaya UI bisa menampilkan alasannya ke user.
  Future<List<FetchPriceResult>> fetchMarketPricesFromApi() async {
    final results = await MarketDataService.fetchAll(activeHoldings);
    for (final r in results) {
      if (r.success) {
        updateMarketPrice(r.ticker, r.price!);
      }
    }
    return results;
  }
}
