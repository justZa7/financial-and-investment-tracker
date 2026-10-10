import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/budget_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/display_currency_provider.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/savings_goal_provider.dart';
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
import '../budget/budget_page.dart';
import '../cash/cash_detail_page.dart';
import '../savings/savings_goal_page.dart';
import '../settings/settings_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cashFlow = context.watch<CashFlowProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final debt = context.watch<DebtProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final goalProvider = context.watch<SavingsGoalProvider>();
    final budgetProgress = budgetProvider.allProgress(cashFlow);
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.matchaDarkest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, size: 16, color: AppColors.latteFoam),
                ),
                const SizedBox(width: 8),
                const Text('MatchaFin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            actions: [
              const ThemeModeToggle(),
              const DisplayCurrencyToggle(),
              IconButton(
                tooltip: 'Pengaturan',
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                const SectionHeader(icon: Icons.pie_chart_rounded, color: AppColors.matchaDarkest, title: 'Aset Anda'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 124,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CashSummaryCard(
                        value: cashFlow.totalCashBalance,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CashDetailPage()),
                        ),
                      ),
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
                if (budgetProgress.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.pie_chart_outline_rounded,
                    color: AppColors.gold,
                    title: 'Anggaran Bulan Ini',
                    trailing: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetPage()),
                      ),
                      child: const Text('Lihat semua', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        children: budgetProgress.take(3).map((p) => _budgetRow(context, p, cashFlow)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (goalProvider.goals.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.savings_rounded,
                    color: AppColors.moneyMarket,
                    title: 'Target Tabungan',
                    trailing: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsGoalPage()),
                      ),
                      child: const Text('Lihat semua', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...goalProvider.goals.take(2).map((g) => GoalCard(goal: g)),
                  const SizedBox(height: 10),
                ],
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

  Widget _budgetRow(BuildContext context, BudgetProgress p, CashFlowProvider cashFlow) {
    final scheme = Theme.of(context).colorScheme;
    final color = p.isOverBudget ? AppColors.loss : (p.isNearLimit ? AppColors.gold : AppColors.gain);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cashFlow.categoryById(p.budget.categoryId).name,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
              ),
              Text('${p.percent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (p.percent / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
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
              _miniStat(
                context,
                'Kas & Bank',
                cashFlow.totalCashBalance,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CashDetailPage()),
                ),
              ),
              _miniStat(context, 'Aset Investasi', portfolio.totalMarketValue),
              _miniStat(context, 'Total Utang', debt.totalDebt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, double amountInIdr, {VoidCallback? onTap}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            if (onTap != null) ...[
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, size: 12, color: Colors.white60),
            ],
          ],
        ),
        const SizedBox(height: 3),
        MoneyText(
          amountInIdr: amountInIdr,
          compact: true,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: content),
    );
  }
}
