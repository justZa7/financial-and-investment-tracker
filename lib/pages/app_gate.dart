import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/security_provider.dart';
import '../services/security_service.dart';
import '../utils/app_theme.dart';
import 'lock/lock_screen.dart';
import 'main_navigation.dart';
import 'onboarding/onboarding_page.dart';

/// Widget akar yang menentukan layar pertama yang dilihat user:
/// Onboarding (kalau belum pernah lihat) -> Lock Screen (kalau PIN aktif)
/// -> MainNavigation. Urutan ini dicek sekali tiap app start.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _onboardingChecked = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final seen = await SecurityService.hasSeenOnboarding();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !seen;
      _onboardingChecked = true;
    });
    if (!_showOnboarding) {
      context.read<SecurityProvider>().initialize();
    }
  }

  Future<void> _onOnboardingDone() async {
    await SecurityService.markOnboardingSeen();
    if (!mounted) return;
    setState(() => _showOnboarding = false);
    context.read<SecurityProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingChecked) return const _Splash();
    if (_showOnboarding) return OnboardingPage(onDone: _onOnboardingDone);

    final security = context.watch<SecurityProvider>();
    switch (security.status) {
      case AppLockStatus.loading:
        return const _Splash();
      case AppLockStatus.locked:
        return const LockScreen();
      case AppLockStatus.unlocked:
        return const MainNavigation();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.matchaBg,
      body: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.matchaDarkest, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.eco_rounded, color: AppColors.latteFoam, size: 32),
        ),
      ),
    );
  }
}
