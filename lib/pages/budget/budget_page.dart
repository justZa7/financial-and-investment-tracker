import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cash_transaction_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final cashFlow = context.watch<CashFlowProvider>();
    final scheme = Theme.of(context).colorScheme;
    final progressList = budgetProvider.allProgress(cashFlow);

    final totalLimit = budgetProvider.totalMonthlyLimit();
    final totalSpent = budgetProvider.totalSpent(cashFlow);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Anggaran Bulanan', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSetBudgetDialog(context, budgetProvider, cashFlow),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set Anggaran'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (totalLimit > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.matchaDarkest, AppColors.matchaDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Anggaran Bulan Ini', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(amountInIdr: totalSpent, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Text('/ ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              MoneyText(amountInIdr: totalLimit, compact: true, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble(),
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: totalSpent > totalLimit ? const Color(0xFFFFB4A1) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (progressList.isEmpty)
              const EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Belum ada anggaran',
                subtitle: 'Tap "Set Anggaran" untuk mulai set batas pengeluaran per kategori',
              )
            else
              ...progressList.map((p) => _BudgetCard(
                    progress: p,
                    categoryName: cashFlow.categoryById(p.budget.categoryId).name,
                    onEdit: () => _showSetBudgetDialog(context, budgetProvider, cashFlow, existing: p.budget.categoryId),
                    onDelete: () => budgetProvider.deleteBudget(p.budget.id),
                  )),
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, BudgetProvider budgetProvider, CashFlowProvider cashFlow, {String? existing}) {
    final expenseCategories = cashFlow.categoriesFor(CashFlowType.expense);
    String? categoryId = existing ?? (expenseCategories.isNotEmpty ? expenseCategories.first.id : null);
    final existingLimit = existing != null ? budgetProvider.budgetForCategory(existing)?.monthlyLimit : null;
    final limitCtrl = TextEditingController(text: existingLimit?.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing != null ? 'Edit Anggaran' : 'Set Anggaran Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: expenseCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: existing != null ? null : (v) => setState(() => categoryId = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Batas Bulanan (Rp)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final limit = CurrencyInputHelper.unformatIdr(limitCtrl.text);
                if (categoryId == null || limit <= 0) return;
                budgetProvider.setBudget(categoryId: categoryId!, monthlyLimit: limit);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetProgress progress;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({required this.progress, required this.categoryName, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.isOverBudget
        ? AppColors.loss
        : progress.isNearLimit
            ? AppColors.gold
            : AppColors.gain;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Text('${progress.percent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress.percent / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MoneyText(amountInIdr: progress.spent, compact: true, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  Text(' terpakai', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
              Row(
                children: [
                  Text('limit ', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  MoneyText(amountInIdr: progress.budget.monthlyLimit, compact: true, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          if (progress.isOverBudget) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.loss),
                SizedBox(width: 4),
                Text('Melebihi anggaran!', style: TextStyle(fontSize: 11, color: AppColors.loss, fontWeight: FontWeight.w600)),
              ],
            ),
          ] else if (progress.isNearLimit) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: AppColors.gold),
                SizedBox(width: 4),
                Text('Hampir mencapai batas', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
