import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../widgets/debt_item_card.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';
import '../../widgets/theme_mode_toggle.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Utang & Piutang',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const ThemeModeToggle(),
                const DisplayCurrencyToggle(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _headerCards(provider),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Piutang Saya'),
              Tab(text: 'Utang Saya'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _debtList(provider, provider.receivables),
                _debtList(provider, provider.debts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCards(DebtProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _headerCard(
            label: 'Total Piutang Anda',
            amountInIdr: provider.totalReceivable,
            icon: Icons.arrow_downward_rounded,
            colors: const [AppColors.matchaDark, AppColors.matchaDarkest],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _headerCard(
            label: 'Total Utang Anda',
            amountInIdr: provider.totalDebt,
            icon: Icons.arrow_upward_rounded,
            colors: const [AppColors.loss, Color(0xFF9A3F26)],
          ),
        ),
      ],
    );
  }

  Widget _headerCard({
    required String label,
    required double amountInIdr,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            amountInIdr: amountInIdr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _debtList(DebtProvider provider, List<DebtModel> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'Belum ada data',
        subtitle: 'Tambahkan lewat tab Input > Utang/Piutang',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final d = items[i];
        return DebtItemCard(
          debt: d,
          onPay: () => _showPayDialog(context, provider, d),
          onEdit: () => _showEditDebtDialog(context, provider, d),
          onDelete: () => _confirmDeleteDebt(context, provider, d),
          onEditPayment: (p) => _showEditPaymentDialog(context, provider, d, p),
          onDeletePayment: (p) => _confirmDeletePayment(context, provider, d, p),
        );
      },
    );
  }

  void _showPayDialog(BuildContext context, DebtProvider provider, DebtModel debt) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bayar Cicilan - ${debt.counterpartyName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Sisa: ', style: TextStyle(fontWeight: FontWeight.w600)),
                MoneyText(amountInIdr: debt.remaining, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nominal Pembayaran (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final amount = CurrencyInputHelper.unformatIdr(ctrl.text);
              if (amount > 0) {
                provider.payInstallment(debtId: debt.id, amount: amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pembayaran berhasil dicatat'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // EDIT & HAPUS
  // -------------------------------------------------------------------
  void _showEditDebtDialog(BuildContext context, DebtProvider provider, DebtModel debt) {
    final nameCtrl = TextEditingController(text: debt.counterpartyName);
    final amountCtrl = TextEditingController(text: debt.principal.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: debt.note);
    DateTime dueDate = debt.dueDate;
    final canEditPrincipal = debt.payments.isEmpty;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Utang/Piutang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pihak Kedua')),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  enabled: canEditPrincipal,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Nominal Awal (Rp)',
                    helperText: canEditPrincipal ? null : 'Tidak bisa diubah karena sudah ada cicilan dibayar',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: dueDate,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Jatuh Tempo'),
                    child: Text(AppFormatters.date(dueDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setState(() => error = 'Nama tidak boleh kosong');
                  return;
                }
                final principal = canEditPrincipal
                    ? CurrencyInputHelper.unformatIdr(amountCtrl.text)
                    : debt.principal;
                final err = provider.updateDebt(
                  debtId: debt.id,
                  counterpartyName: nameCtrl.text.trim(),
                  principal: principal,
                  dueDate: dueDate,
                  note: noteCtrl.text,
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDebt(BuildContext context, DebtProvider provider, DebtModel debt) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus "${debt.counterpartyName}"?'),
        content: Text(
          debt.payments.isEmpty
              ? 'Data ini akan dihapus permanen.'
              : 'Data ini beserta ${debt.payments.length} riwayat pembayarannya akan dihapus permanen.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () {
              provider.deleteDebt(debt.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, DebtProvider provider, DebtModel debt, DebtPaymentModel payment) {
    final ctrl = TextEditingController(text: payment.amount.toStringAsFixed(0));
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Nominal Pembayaran (Rp)'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final err = provider.updatePayment(
                  debtId: debt.id,
                  paymentId: payment.id,
                  amount: CurrencyInputHelper.unformatIdr(ctrl.text),
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, DebtProvider provider, DebtModel debt, DebtPaymentModel payment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pembayaran ini?'),
        content: const Text('Sisa pinjaman & status akan dihitung ulang otomatis.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () {
              provider.deletePayment(debtId: debt.id, paymentId: payment.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
