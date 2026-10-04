import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account_model.dart';
import '../../providers/cashflow_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../../widgets/theme_mode_toggle.dart';

Color accountTypeColor(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return AppColors.gold;
    case AccountType.bank:
      return AppColors.matchaDarkest;
    case AccountType.eWallet:
      return AppColors.moneyMarket;
  }
}

IconData accountTypeIcon(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return Icons.payments_outlined;
    case AccountType.bank:
      return Icons.account_balance_outlined;
    case AccountType.eWallet:
      return Icons.smartphone_outlined;
  }
}

class CashDetailPage extends StatelessWidget {
  const CashDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashFlowProvider>();
    final scheme = Theme.of(context).colorScheme;

    final typeBalances = {
      for (final t in AccountType.values) t: provider.balanceByType(t),
    };

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Detail Kas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          ThemeModeToggle(),
          DisplayCurrencyToggle(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _totalCard(context, provider.totalCashBalance),
            const SizedBox(height: 24),
            const SectionHeader(
              icon: Icons.donut_large_rounded,
              color: AppColors.matchaDarkest,
              title: 'Alokasi per Tipe',
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _typeAllocation(context, typeBalances),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              icon: Icons.list_alt_rounded,
              color: AppColors.moneyMarket,
              title: 'Rincian per Akun',
            ),
            const SizedBox(height: 14),
            for (final type in AccountType.values) ...[
              _typeGroup(context, provider, type, typeBalances[type] ?? 0),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalCard(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.matchaDarkest, AppColors.matchaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.matchaDarkest.withAlpha(25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Total Saldo Kas', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            amountInIdr: total,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _typeAllocation(BuildContext context, Map<AccountType, double> typeBalances) {
    final scheme = Theme.of(context).colorScheme;
    final total = typeBalances.values.fold(0.0, (a, b) => a + b);
    final entries = typeBalances.entries.where((e) => e.value > 0).toList();

    if (total <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('Belum ada saldo kas', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: entries.map((e) {
                final color = accountTypeColor(e.key);
                final pct = e.value / total * 100;
                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 38,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final pct = e.value / total * 100;
              final color = accountTypeColor(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.key.label, style: TextStyle(fontSize: 12.5, color: scheme.onSurface)),
                    ),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _typeGroup(BuildContext context, CashFlowProvider provider, AccountType type, double subtotal) {
    final scheme = Theme.of(context).colorScheme;
    final color = accountTypeColor(type);
    final accounts = provider.accountsByType(type);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.matchaDarkest.withAlpha(5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withAlpha(12), shape: BoxShape.circle),
                child: Icon(accountTypeIcon(type), size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(type.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface)),
              ),
              MoneyText(
                amountInIdr: subtotal,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface),
              ),
            ],
          ),
          if (accounts.isEmpty) ...[
            const SizedBox(height: 10),
            EmptyState(icon: accountTypeIcon(type), title: 'Belum ada akun ${type.label.toLowerCase()}'),
          ] else ...[
            const Divider(height: 24),
            ...accounts.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 5, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.name, style: TextStyle(fontSize: 12.5, color: scheme.onSurface)),
                      ),
                      MoneyText(
                        amountInIdr: a.balance,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
