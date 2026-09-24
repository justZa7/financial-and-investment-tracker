import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'pages/main_navigation.dart';
import 'providers/cashflow_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/portfolio_provider.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const FinanceTrackerApp());
}

/// Aplikasi langsung masuk ke Dashboard/Home — TANPA Login/Authentication.
class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CashFlowProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
      ],
      child: MaterialApp(
        title: 'Personal Finance & Investment Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainNavigation(),
      ),
    );
  }
}
