import 'package:flutter/material.dart';
import '../models/asset_holding_model.dart';
import '../utils/app_theme.dart';
import 'money_text.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
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
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          MoneyText(
            amountInIdr: value,
            compact: true,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class CashSummaryCard extends StatelessWidget {
  final double value;
  final VoidCallback? onTap;
  const CashSummaryCard({super.key, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
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
            child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.cash),
          ),
          const SizedBox(height: 10),
          Text('Cash', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          MoneyText(
            amountInIdr: value,
            compact: true,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface),
          ),
        ],
      ),
      ),
    );
  }
}
