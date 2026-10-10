import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_goal_model.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/savings_goal_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';

const _goalIcons = [
  Icons.savings_rounded,
  Icons.flight_takeoff_rounded,
  Icons.home_rounded,
  Icons.medical_services_rounded,
  Icons.school_rounded,
];

const _goalColors = [
  AppColors.matchaDarkest,
  AppColors.gold,
  AppColors.moneyMarket,
  AppColors.crypto,
  AppColors.loss,
];

class SavingsGoalPage extends StatelessWidget {
  const SavingsGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsGoalProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Target Tabungan', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Goal Baru'),
      ),
      body: SafeArea(
        child: provider.goals.isEmpty
            ? const EmptyState(
                icon: Icons.savings_outlined,
                title: 'Belum ada target tabungan',
                subtitle: 'Buat goal pertamamu, misal "Dana Darurat" atau "Liburan"',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: provider.goals.length,
                itemBuilder: (context, i) => GoalCard(goal: provider.goals[i]),
              ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, SavingsGoalProvider provider) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? targetDate;
    int styleIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Target Tabungan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Goal (misal: Dana Darurat)')),
                const SizedBox(height: 14),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Target Nominal (Rp)'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => targetDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Target Tanggal (opsional)'),
                    child: Text(targetDate != null ? AppFormatters.date(targetDate!) : '-'),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Warna & ikon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: List.generate(_goalColors.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => styleIndex = i),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: _goalColors[i],
                        child: Icon(styleIndex == i ? Icons.check : _goalIcons[i], size: 16, color: Colors.white),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final target = CurrencyInputHelper.unformatIdr(targetCtrl.text);
                if (nameCtrl.text.trim().isEmpty || target <= 0) return;
                provider.addGoal(
                  name: nameCtrl.text.trim(),
                  targetAmount: target,
                  targetDate: targetDate,
                  color: _goalColors[styleIndex],
                  icon: _goalIcons[styleIndex],
                );
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

/// Kartu satu goal — dipakai di halaman Target Tabungan dan ringkasan Dashboard.
class GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = goal.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(goal.icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    if (goal.targetDate != null)
                      Text('Target: ${AppFormatters.date(goal.targetDate!)}',
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (goal.isCompleted) const Icon(Icons.celebration_rounded, color: AppColors.gold, size: 20),
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: (v) {
                  if (v == 'contribute') _showContributeDialog(context, goal, isWithdraw: false);
                  if (v == 'withdraw') _showContributeDialog(context, goal, isWithdraw: true);
                  if (v == 'delete') _confirmDelete(context, goal);
                },
                itemBuilder: (context) => [
                  if (!goal.isCompleted) const PopupMenuItem(value: 'contribute', child: Text('Tambah Tabungan')),
                  if (goal.currentAmount > 0) const PopupMenuItem(value: 'withdraw', child: Text('Tarik Dana')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus Goal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressPercent / 100,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MoneyText(amountInIdr: goal.currentAmount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('target ', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  MoneyText(amountInIdr: goal.targetAmount, compact: true, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          if (goal.isCompleted) ...[
            const SizedBox(height: 8),
            const Text('🎉 Target tercapai!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gain)),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus "${goal.name}"?'),
        content: Text(
          goal.currentAmount > 0
              ? 'Goal ini punya dana tersimpan Rp${goal.currentAmount.toStringAsFixed(0)}. Menghapus goal TIDAK mengembalikan dana itu ke akun mana pun — tarik dulu lewat menu "Tarik Dana" kalau ingin dikembalikan.'
              : 'Goal ini akan dihapus.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () {
              context.read<SavingsGoalProvider>().deleteGoal(goal.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context, SavingsGoalModel goal, {required bool isWithdraw}) {
    final amountCtrl = TextEditingController();
    String? accountId;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final cashFlow = dialogContext.watch<CashFlowProvider>();
          accountId ??= cashFlow.accounts.isNotEmpty ? cashFlow.accounts.first.id : null;

          return AlertDialog(
            title: Text(isWithdraw ? 'Tarik Dana dari ${goal.name}' : 'Tambah Tabungan ke ${goal.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: accountId,
                  decoration: InputDecoration(labelText: isWithdraw ? 'Dikembalikan ke Akun' : 'Sumber Dana (Akun)'),
                  items: cashFlow.accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${AppFormatters.rupiah(a.balance)})', overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => accountId = v),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
              FilledButton(
                onPressed: () {
                  final amount = CurrencyInputHelper.unformatIdr(amountCtrl.text);
                  final goalProvider = dialogContext.read<SavingsGoalProvider>();
                  final err = isWithdraw
                      ? goalProvider.withdraw(goalId: goal.id, amount: amount, accountId: accountId, cashFlow: cashFlow)
                      : goalProvider.contribute(goalId: goal.id, amount: amount, accountId: accountId, cashFlow: cashFlow);
                  if (err != null) {
                    setState(() => error = err);
                    return;
                  }
                  Navigator.pop(dialogContext);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
