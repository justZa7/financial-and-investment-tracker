import 'package:flutter/material.dart';

import '../models/debt_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'money_text.dart';

class DebtAlertCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback? onTap;

  const DebtAlertCard({super.key, required this.debt, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = debt.isOverdue;
    final color = overdue ? AppColors.loss : AppColors.gold;
    final typeLabel = debt.type == DebtType.debt ? 'Utang ke' : 'Piutang dari';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overdue ? Icons.warning_amber_rounded : Icons.schedule,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$typeLabel ${debt.counterpartyName}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MoneyText(
              amountInIdr: debt.remaining,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.daysUntil(debt.dueDate),
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
