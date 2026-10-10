import 'package:flutter/material.dart';

import '../models/debt_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'money_text.dart';

class DebtItemCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onPay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(DebtPaymentModel payment)? onEditPayment;
  final void Function(DebtPaymentModel payment)? onDeletePayment;

  const DebtItemCard({
    super.key,
    required this.debt,
    required this.onPay,
    this.onEdit,
    this.onDelete,
    this.onEditPayment,
    this.onDeletePayment,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPaid = debt.status == DebtStatus.paid;
    final progress = debt.principal == 0
        ? 0.0
        : (1 - (debt.remaining / debt.principal)).clamp(0.0, 1.0).toDouble();
    final accent = debt.type == DebtType.debt ? AppColors.loss : AppColors.gain;

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
                  backgroundColor: accent.withOpacity(0.12),
                  child: Icon(
                    debt.type == DebtType.debt ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.counterpartyName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface)),
                      Text(
                        'Jatuh tempo: ${AppFormatters.date(debt.dueDate)}',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.gain.withOpacity(0.12)
                        : (debt.isOverdue ? AppColors.loss.withOpacity(0.12) : AppColors.gold.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    debt.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppColors.gain : (debt.isOverdue ? AppColors.loss : AppColors.gold),
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            if (debt.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(debt.note, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sisa Pinjaman', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      MoneyText(
                        amountInIdr: debt.remaining,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
                if (!isPaid)
                  FilledButton.tonal(
                    onPressed: onPay,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Bayar Cicilan', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            if (debt.payments.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Riwayat pembayaran (${debt.payments.length})',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                  children: debt.payments.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(AppFormatters.date(p.date), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                          ),
                          MoneyText(amountInIdr: p.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          if (onEditPayment != null)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              onPressed: () => onEditPayment!(p),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          if (onDeletePayment != null)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              onPressed: () => onDeletePayment!(p),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.loss),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
