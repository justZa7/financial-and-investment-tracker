import 'package:flutter/material.dart';

import '../models/debt_model.dart';
import '../utils/formatters.dart';

class DebtItemCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onPay;

  const DebtItemCard({super.key, required this.debt, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.status == DebtStatus.paid;
    final progress = debt.principal == 0
        ? 0.0
        : (1 - (debt.remaining / debt.principal)).clamp(0.0, 1.0);
    final accent = debt.type == DebtType.debt ? Colors.red.shade600 : Colors.green.shade600;

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
                    debt.type == DebtType.debt
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Jatuh tempo: ${AppFormatters.date(debt.dueDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withOpacity(0.12)
                        : (debt.isOverdue ? Colors.red.withOpacity(0.12) : Colors.orange.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    debt.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? Colors.green.shade700
                          : (debt.isOverdue ? Colors.red.shade700 : Colors.orange.shade800),
                    ),
                  ),
                ),
              ],
            ),
            if (debt.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(debt.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
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
                      Text('Sisa Pinjaman', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(
                        AppFormatters.rupiah(debt.remaining),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          ],
        ),
      ),
    );
  }
}
