import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
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
}
