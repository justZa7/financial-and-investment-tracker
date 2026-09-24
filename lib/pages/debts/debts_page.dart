import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/debt_item_card.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Utang & Piutang',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _headerCards(provider),
          ),
          const SizedBox(height: 12),
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Piutang Anda', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.rupiah(provider.totalReceivable),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Utang Anda', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.rupiah(provider.totalDebt),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _debtList(DebtProvider provider, List<DebtModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('Belum ada data', style: TextStyle(color: Colors.grey.shade500)),
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
            Text('Sisa: ${AppFormatters.rupiah(debt.remaining)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nominal Pembayaran (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.replaceAll(',', ''));
              if (amount != null && amount > 0) {
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
