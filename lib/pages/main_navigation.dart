import 'package:flutter/material.dart';

import '../widgets/matcha_nav_bar.dart';
import 'dashboard/dashboard_page.dart';
import 'debts/debts_page.dart';
import 'history/history_page.dart';
import 'input/input_page.dart';
import 'portfolio/portfolio_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    InputPage(),
    PortfolioPage(),
    DebtsPage(),
    HistoryPage(),
  ];

  static const _navItems = [
    MatchaNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    MatchaNavItem(icon: Icons.add_circle_outline_rounded, selectedIcon: Icons.add_circle_rounded, label: 'Input'),
    MatchaNavItem(icon: Icons.pie_chart_outline_rounded, selectedIcon: Icons.pie_chart_rounded, label: 'Aset'),
    MatchaNavItem(icon: Icons.handshake_outlined, selectedIcon: Icons.handshake_rounded, label: 'Utang'),
    MatchaNavItem(icon: Icons.history_rounded, selectedIcon: Icons.history_rounded, label: 'Riwayat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: MatchaNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        items: _navItems,
      ),
    );
  }
}
