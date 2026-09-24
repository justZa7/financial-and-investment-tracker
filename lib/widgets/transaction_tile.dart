import 'package:flutter/material.dart';

import '../utils/formatters.dart';

enum HistoryTxKind { income, expense, assetBuy, assetSell, debtPayment }

class HistoryItem {
  final HistoryTxKind kind;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final double? realizedGainLoss;

  HistoryItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.realizedGainLoss,
  });
}

class TransactionTile extends StatelessWidget {
  final HistoryItem item;

  const TransactionTile({super.key, required this.item});

  IconData get _icon {
    switch (item.kind) {
      case HistoryTxKind.income:
        return Icons.south_west_rounded;
      case HistoryTxKind.expense:
        return Icons.north_east_rounded;
      case HistoryTxKind.assetBuy:
        return Icons.add_shopping_cart_outlined;
      case HistoryTxKind.assetSell:
        return Icons.sell_outlined;
      case HistoryTxKind.debtPayment:
        return Icons.payments_outlined;
    }
  }

  Color get _color {
    switch (item.kind) {
      case HistoryTxKind.income:
        return Colors.green.shade600;
      case HistoryTxKind.expense:
        return Colors.red.shade600;
      case HistoryTxKind.assetBuy:
        return Colors.blue.shade600;
      case HistoryTxKind.assetSell:
        return Colors.purple.shade600;
      case HistoryTxKind.debtPayment:
        return Colors.orange.shade700;
    }
  }

  bool get _isPositive =>
      item.kind == HistoryTxKind.income || item.kind == HistoryTxKind.assetSell;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _color.withOpacity(0.12),
              child: Icon(_icon, size: 18, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(AppFormatters.date(item.date),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_isPositive ? '+' : '-'}${AppFormatters.rupiah(item.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (item.realizedGainLoss != null)
                  Text(
                    'Realized: ${AppFormatters.rupiahSigned(item.realizedGainLoss!)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: item.realizedGainLoss! >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
