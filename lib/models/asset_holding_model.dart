enum AssetClass { equity, gold, crypto, moneyMarket }

extension AssetClassLabel on AssetClass {
  String get label {
    switch (this) {
      case AssetClass.equity:
        return 'Saham';
      case AssetClass.gold:
        return 'Emas';
      case AssetClass.crypto:
        return 'Crypto';
      case AssetClass.moneyMarket:
        return 'Reksadana';
    }
  }
}

/// Merepresentasikan satu posisi/holding aset (misal: BBCA, BTC, Emas Antam)
/// Menggunakan metode Weighted Average Cost Basis untuk avgBuyPrice.
class AssetHoldingModel {
  final String id;
  final String ticker;
  final String name;
  final AssetClass assetClass;
  double qty;
  double avgBuyPrice;
  double marketPrice;
  double realizedGainLoss; // akumulasi profit/loss dari penjualan sebelumnya

  /// Khusus relevan untuk [AssetClass.moneyMarket]: yield/bunga tahunan (%)
  /// yang dijanjikan produk reksadana pasar uang tsb (misal 5.5% per tahun).
  /// Diisi manual saat input transaksi Beli.
  double annualYieldPercent;

  /// Tanggal pembelian pertama, dipakai untuk menghitung lama holding period
  /// saat mengestimasi yield gain.
  DateTime? firstBuyDate;

  AssetHoldingModel({
    required this.id,
    required this.ticker,
    required this.name,
    required this.assetClass,
    this.qty = 0,
    this.avgBuyPrice = 0,
    this.marketPrice = 0,
    this.realizedGainLoss = 0,
    this.annualYieldPercent = 0,
    this.firstBuyDate,
  });

  double get currentValue => qty * marketPrice;
  double get costBasis => qty * avgBuyPrice;
  double get unrealizedGainLoss => (marketPrice - avgBuyPrice) * qty;
  double get unrealizedGainLossPercent =>
      avgBuyPrice == 0 ? 0 : ((marketPrice - avgBuyPrice) / avgBuyPrice) * 100;

  /// Estimasi yield gain (dari bunga/yield tahunan, BUKAN dari kenaikan
  /// harga/NAB) sejak tanggal beli pertama. Simple interest, bukan
  /// compounding, karena tujuannya cuma estimasi kasar untuk ditampilkan
  /// di UI (bukan hasil resmi dari manajer investasi).
  ///
  /// Rumus: Cost Basis * (Yield Tahunan / 100) * (Hari Dipegang / 365)
  double get estimatedYieldGain {
    if (annualYieldPercent <= 0 || firstBuyDate == null) return 0;
    final daysHeld = DateTime.now().difference(firstBuyDate!).inDays;
    if (daysHeld <= 0) return 0;
    return costBasis * (annualYieldPercent / 100) * (daysHeld / 365);
  }
}
