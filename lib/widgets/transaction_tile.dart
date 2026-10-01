import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'money_text.dart';

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
        return AppColors.gain;
      case HistoryTxKind.expense:
        return AppColors.loss;
      case HistoryTxKind.assetBuy:
        return AppColors.equity;
      case HistoryTxKind.assetSell:
        return AppColors.crypto;
      case HistoryTxKind.debtPayment:
        return AppColors.gold;
    }
  }

  bool get _isPositive =>
      item.kind == HistoryTxKind.income || item.kind == HistoryTxKind.assetSell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Nilai bertanda (+ untuk income/jual, - untuk expense/beli/bayar utang)
    // supaya MoneyText(signed:true) otomatis tampilkan prefix yang benar
    // sekaligus mengkonversi ke mata uang tampilan (IDR/USD) yang aktif.
    final signedAmount = _isPositive ? item.amount : -item.amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_color.withOpacity(0.18), _color.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 18, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  if (item.subtitle.isNotEmpty)
                    Text(item.subtitle,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(AppFormatters.date(item.date),
                      style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant.withOpacity(0.7))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  amountInIdr: signedAmount,
                  signed: true,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isPositive ? AppColors.gain : AppColors.loss,
                  ),
                ),
                if (item.realizedGainLoss != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('Realized: ', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                      MoneyText(
                        amountInIdr: item.realizedGainLoss!,
                        signed: true,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.realizedGainLoss! >= 0 ? AppColors.gain : AppColors.loss,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
