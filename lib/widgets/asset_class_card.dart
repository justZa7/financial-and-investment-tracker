import 'package:flutter/material.dart';
import '../models/asset_holding_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

Color assetClassColor(AssetClass cls) {
  switch (cls) {
    case AssetClass.equity:
      return AppColors.equity;
    case AssetClass.gold:
      return AppColors.gold;
    case AssetClass.crypto:
      return AppColors.crypto;
    case AssetClass.moneyMarket:
      return AppColors.moneyMarket;
  }
}

IconData assetClassIcon(AssetClass cls) {
  switch (cls) {
    case AssetClass.equity:
      return Icons.show_chart;
    case AssetClass.gold:
      return Icons.circle;
    case AssetClass.crypto:
      return Icons.currency_bitcoin;
    case AssetClass.moneyMarket:
      return Icons.savings_outlined;
  }
}

class AssetClassCard extends StatelessWidget {
  final AssetClass assetClass;
  final double value;

  const AssetClassCard({
    super.key,
    required this.assetClass,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = assetClassColor(assetClass);
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(assetClassIcon(assetClass), size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            assetClass.label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            AppFormatters.rupiahCompact(value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class CashSummaryCard extends StatelessWidget {
  final double value;
  const CashSummaryCard({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.cash.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                size: 16, color: AppColors.cash),
          ),
          const SizedBox(height: 10),
          Text('Cash', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(
            AppFormatters.rupiahCompact(value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
