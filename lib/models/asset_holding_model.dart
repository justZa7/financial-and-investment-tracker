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

  AssetHoldingModel({
    required this.id,
    required this.ticker,
    required this.name,
    required this.assetClass,
    this.qty = 0,
    this.avgBuyPrice = 0,
    this.marketPrice = 0,
    this.realizedGainLoss = 0,
  });

  double get currentValue => qty * marketPrice;
  double get costBasis => qty * avgBuyPrice;
  double get unrealizedGainLoss => (marketPrice - avgBuyPrice) * qty;
  double get unrealizedGainLossPercent =>
      avgBuyPrice == 0 ? 0 : ((marketPrice - avgBuyPrice) / avgBuyPrice) * 100;
}
