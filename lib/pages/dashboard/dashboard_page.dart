import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/calculation_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/allocation_pie_chart.dart';
import '../../widgets/asset_class_card.dart';
import '../../widgets/debt_alert_card.dart';
import '../../widgets/performance_line_chart.dart';
import '../../widgets/summary_card.dart';
import '../../models/asset_holding_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cashFlow = context.watch<CashFlowProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final debt = context.watch<DebtProvider>();

    final netWorth = CalculationService.netWorth(
      totalCash: cashFlow.totalCashBalance,
      totalAssetValue: portfolio.totalMarketValue,
      totalDebt: debt.totalDebt,
    );

    final savingsRate = CalculationService.savingsRate(
      totalIncome: cashFlow.totalIncomeThisMonth,
      totalExpense: cashFlow.totalExpenseThisMonth,
    );

    final monthlyTrend = cashFlow.monthlyTrend();
    final portfolioTrend = portfolio.portfolioValueTrend(points: monthlyTrend.length);
    final trendLabels = monthlyTrend
        .map((m) => DateFormat('MMM', 'id_ID').format(m.month))
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<PortfolioProvider>().autoUpdatePrices();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                Consumer<PortfolioProvider>(
                  builder: (context, portfolio, _) {
                    if (portfolio.isUpdatingPrices) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                        ),
                      );
                    }
                    return IconButton(
                      tooltip: 'Update Harga Otomatis',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => portfolio.autoUpdatePrices(),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _netWorthCard(context, netWorth, cashFlow, portfolio, debt),
                  const SizedBox(height: 16),

                  // Savings Rate & Annual Return
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Savings Rate',
                          value: '${savingsRate.toStringAsFixed(1)}%',
                          subtitle: 'Bulan ini',
                          icon: Icons.savings_outlined,
                          color: Colors.teal,
                          valuePositive: savingsRate >= 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Annual Return',
                          value: AppFormatters.percent(portfolio.annualReturnPercent),
                          subtitle: 'Seluruh portofolio',
                          icon: Icons.trending_up_rounded,
                          color: Colors.indigo,
                          valuePositive: portfolio.annualReturnPercent >= 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // List Aset per kelas
                  Text('Aset Anda', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 128,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CashSummaryCard(value: cashFlow.totalCashBalance),
                        const SizedBox(width: 10),
                        for (final cls in AssetClass.values)
                          if (portfolio.valueByClass(cls) > 0) ...[
                            AssetClassCard(assetClass: cls, value: portfolio.valueByClass(cls)),
                            const SizedBox(width: 10),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rata-rata income/expense
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Rata-rata Pemasukan',
                          value: AppFormatters.rupiahCompact(cashFlow.averageMonthlyIncome),
                          subtitle: 'per bulan',
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Rata-rata Pengeluaran',
                          value: AppFormatters.rupiahCompact(cashFlow.averageMonthlyExpense),
                          subtitle: 'per bulan',
                          icon: Icons.arrow_upward_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pie chart alokasi
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alokasi Antar Aset',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          AllocationPieChart(
                            allocation: portfolio.allocation,
                            cashValue: cashFlow.totalCashBalance,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Line chart performance
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grafik Performance',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          PerformanceLineChart(
                            labels: trendLabels,
                            portfolioValues: portfolioTrend,
                            incomeValues: monthlyTrend.map((m) => m.income).toList(),
                            expenseValues: monthlyTrend.map((m) => m.expense).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick alert utang/piutang
                  if (debt.dueSoonAlerts.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Peringatan Jatuh Tempo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: debt.dueSoonAlerts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => DebtAlertCard(debt: debt.dueSoonAlerts[i]),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _netWorthCard(
    BuildContext context,
    double netWorth,
    CashFlowProvider cashFlow,
    PortfolioProvider portfolio,
    DebtProvider debt,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6FED), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Net Worth', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            AppFormatters.rupiah(netWorth),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Kas & Bank', AppFormatters.rupiahCompact(cashFlow.totalCashBalance)),
              _miniStat('Aset Investasi', AppFormatters.rupiahCompact(portfolio.totalMarketValue)),
              _miniStat('Total Utang', AppFormatters.rupiahCompact(debt.totalDebt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
