import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../budget/budget_page.dart';
import '../cash/manage_accounts_page.dart';
import '../lock/pin_setup_page.dart';
import '../onboarding/onboarding_page.dart';
import '../savings/savings_goal_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [ThemeModeToggle(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionHeader(icon: Icons.account_balance_wallet_rounded, color: AppColors.matchaDarkest, title: 'Keuangan'),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.pie_chart_rounded,
              color: AppColors.gold,
              title: 'Anggaran Bulanan',
              subtitle: 'Set batas pengeluaran per kategori',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetPage())),
            ),
            _tile(
              context,
              icon: Icons.savings_rounded,
              color: AppColors.moneyMarket,
              title: 'Target Tabungan',
              subtitle: 'Dana darurat, liburan, dll',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalPage())),
            ),
            _tile(
              context,
              icon: Icons.credit_card_rounded,
              color: AppColors.crypto,
              title: 'Kelola Akun',
              subtitle: 'Tambah, ganti nama, atau hapus akun kas',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAccountsPage())),
            ),
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.lock_rounded, color: AppColors.loss, title: 'Keamanan'),
            const SizedBox(height: 12),
            SwitchListTile(
              value: security.lockEnabled,
              onChanged: (v) async {
                if (v) {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupPage()));
                } else {
                  await context.read<SecurityProvider>().disableLock();
                }
              },
              title: const Text('Kunci PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Minta PIN tiap kali membuka aplikasi', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.matchaDarkest,
              tileColor: scheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            if (security.lockEnabled) ...[
              const SizedBox(height: 10),
              _tile(
                context,
                icon: Icons.password_rounded,
                color: AppColors.matchaDarkest,
                title: 'Ganti PIN',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupPage())),
              ),
              if (security.biometricAvailable)
                SwitchListTile(
                  value: security.biometricEnabled,
                  onChanged: (v) => context.read<SecurityProvider>().setBiometricEnabled(v),
                  title: const Text('Biometric (Fingerprint/Face ID)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pakai sidik jari/wajah sebagai alternatif PIN', style: TextStyle(fontSize: 12)),
                  activeColor: AppColors.matchaDarkest,
                  tileColor: scheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Biometric tidak tersedia di device ini (atau belum di-setup di sisi native — lihat README).',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.info_outline_rounded, color: AppColors.cash, title: 'Lainnya'),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.school_outlined,
              color: AppColors.matchaMedium,
              title: 'Lihat Tutorial Lagi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OnboardingPage(onDone: () => Navigator.pop(context))),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('MatchaFin', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
