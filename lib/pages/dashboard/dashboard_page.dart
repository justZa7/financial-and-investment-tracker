import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/display_currency_provider.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/calculation_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/allocation_pie_chart.dart';
import '../../widgets/asset_class_card.dart';
import '../../widgets/debt_alert_card.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/money_text.dart';
import '../../widgets/performance_line_chart.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../models/asset_holding_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cashFlow = context.watch<CashFlowProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final debt = context.watch<DebtProvider>();
    final displayCurrency = context.watch<DisplayCurrencyProvider>().currency;
    final usdRate = context.watch<ExchangeRateProvider>().rate;

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
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: const [
              ThemeModeToggle(),
              DisplayCurrencyToggle(),
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
                        color: AppColors.gain,
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
                        color: AppColors.matchaDarkest,
                        valuePositive: portfolio.annualReturnPercent >= 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // List Aset per kelas
                SectionHeader(icon: Icons.pie_chart_rounded, color: AppColors.matchaDarkest, title: 'Aset Anda'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 124,
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
                const SizedBox(height: 24),

                // Rata-rata income/expense
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Rata-rata Pemasukan',
                        valueWidget: MoneyText(amountInIdr: cashFlow.averageMonthlyIncome, compact: true),
                        subtitle: 'per bulan',
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.gain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'Rata-rata Pengeluaran',
                        valueWidget: MoneyText(amountInIdr: cashFlow.averageMonthlyExpense, compact: true),
                        subtitle: 'per bulan',
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.loss,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pie chart alokasi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          icon: Icons.donut_large_rounded,
                          color: AppColors.crypto,
                          title: 'Alokasi Antar Aset',
                        ),
                        const SizedBox(height: 16),
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          icon: Icons.show_chart_rounded,
                          color: AppColors.matchaDarkest,
                          title: 'Grafik Performance',
                        ),
                        const SizedBox(height: 12),
                        PerformanceLineChart(
                          labels: trendLabels,
                          portfolioValues: portfolioTrend,
                          incomeValues: monthlyTrend.map((m) => m.income).toList(),
                          expenseValues: monthlyTrend.map((m) => m.expense).toList(),
                          currency: displayCurrency,
                          usdRate: usdRate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick alert utang/piutang
                if (debt.dueSoonAlerts.isNotEmpty) ...[
                  const SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.gold,
                    title: 'Peringatan Jatuh Tempo',
                  ),
                  const SizedBox(height: 12),
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
          colors: [AppColors.matchaDarkest, AppColors.matchaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.matchaDarkest.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Total Net Worth', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            amountInIdr: netWorth,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _miniStat('Kas & Bank', cashFlow.totalCashBalance),
              _miniStat('Aset Investasi', portfolio.totalMarketValue),
              _miniStat('Total Utang', debt.totalDebt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amountInIdr) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 3),
          MoneyText(
            amountInIdr: amountInIdr,
            compact: true,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
