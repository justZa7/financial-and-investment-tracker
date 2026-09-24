import 'package:flutter/material.dart';

import '../models/asset_holding_model.dart';
import '../utils/formatters.dart';
import 'asset_class_card.dart';

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
    final color = assetClassColor(holding.assetClass);
    final gain = holding.unrealizedGainLoss;
    final gainColor = gain >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(assetClassIcon(holding.assetClass), color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(holding.ticker,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${holding.name} · ${holding.assetClass.label}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onUpdatePrice,
                  icon: const Icon(Icons.edit_note, size: 20),
                  tooltip: 'Update Harga Pasar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _metric('Qty', AppFormatters.decimal(holding.qty, fraction: 4)),
                _metric('Avg Price', AppFormatters.rupiah(holding.avgBuyPrice)),
                _metric('Harga Pasar', AppFormatters.rupiah(holding.marketPrice)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metric('Current Value', AppFormatters.rupiah(holding.currentValue)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unrealized G/L',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatters.rupiahSigned(gain)} (${AppFormatters.percent(holding.unrealizedGainLossPercent)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: gainColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (holding.realizedGainLoss != 0) ...[
              const SizedBox(height: 8),
              Text(
                'Realized G/L: ${AppFormatters.rupiahSigned(holding.realizedGainLoss)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: holding.realizedGainLoss >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
