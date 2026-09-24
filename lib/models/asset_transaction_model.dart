import 'asset_holding_model.dart';

enum AssetTxType { buy, sell, dividend }

class AssetTransactionModel {
  final String id;
  final String assetId;
  final String ticker;
  final AssetClass assetClass;
  final AssetTxType type;
  final double qty;
  final double pricePerUnit;
  final double fee;
  final DateTime date;
  final double? realizedGainLoss; // hanya terisi untuk transaksi SELL

  AssetTransactionModel({
    required this.id,
    required this.assetId,
    required this.ticker,
    required this.assetClass,
    required this.type,
    required this.qty,
    required this.pricePerUnit,
    this.fee = 0,
    required this.date,
    this.realizedGainLoss,
  });

  double get grossTotal => qty * pricePerUnit;
}
