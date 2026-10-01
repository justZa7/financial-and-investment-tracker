import 'package:flutter/material.dart';

import '../models/asset_holding_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'asset_class_card.dart';
import 'money_text.dart';

class PortfolioItemTile extends StatelessWidget {
  final AssetHoldingModel holding;
  final VoidCallback? onUpdatePrice;

  const PortfolioItemTile({
    super.key,
    required this.holding,
    this.onUpdatePrice,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = assetClassColor(holding.assetClass);
    final gain = holding.unrealizedGainLoss;
    final isGain = gain >= 0;
    final gainColor = isGain ? AppColors.gain : AppColors.loss;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(assetClassIcon(holding.assetClass), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(holding.ticker,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              holding.assetClass.label,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        holding.name,
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onUpdatePrice,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_note_rounded, size: 18, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _metric(context, 'Qty', AppFormatters.decimal(holding.qty, fraction: 4)),
                _metric(context, 'Avg Price', null, amountInIdr: holding.avgBuyPrice),
                _metric(context, 'Harga Pasar', null, amountInIdr: holding.marketPrice),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gainColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Value', style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        MoneyText(
                          amountInIdr: holding.currentValue,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Unrealized G/L', style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(isGain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 12, color: gainColor),
                          MoneyText(
                            amountInIdr: gain,
                            signed: true,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: gainColor),
                          ),
                        ],
                      ),
                      Text(
                        '(${AppFormatters.percent(holding.unrealizedGainLossPercent)})',
                        style: TextStyle(fontSize: 10.5, color: gainColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (holding.realizedGainLoss != 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Realized G/L: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                  MoneyText(
                    amountInIdr: holding.realizedGainLoss,
                    signed: true,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: holding.realizedGainLoss >= 0 ? AppColors.gain : AppColors.loss,
                    ),
                  ),
                ],
              ),
            ],
            if (holding.assetClass == AssetClass.moneyMarket && holding.annualYieldPercent > 0) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.percent_rounded, size: 14, color: AppColors.moneyMarket),
                  const SizedBox(width: 6),
                  Text(
                    'Yield Tahunan: ${AppFormatters.decimal(holding.annualYieldPercent, fraction: 2)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.moneyMarket),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Estimasi Yield Gain: ', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  MoneyText(
                    amountInIdr: holding.estimatedYieldGain,
                    signed: true,
                    style: TextStyle(fontSize: 11, color: scheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                  if (holding.firstBuyDate != null)
                    Text(' (sejak ${AppFormatters.date(holding.firstBuyDate!)})',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String? value, {double? amountInIdr}) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          amountInIdr != null
              ? MoneyText(
                  amountInIdr: amountInIdr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
                )
              : Text(value ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
        ],
      ),
    );
  }
}
