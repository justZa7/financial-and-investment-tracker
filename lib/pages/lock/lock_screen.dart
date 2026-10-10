import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/pin_pad.dart';

/// Ditampilkan sebelum masuk ke MainNavigation kalau lock aktif. Minta PIN
/// (atau biometric kalau diaktifkan). Tidak ada "lupa PIN" karena semua data
/// cuma di device ini — kalau PIN lupa, satu-satunya jalan adalah
/// uninstall/reinstall app.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _input = '';
  String? _error;
  bool _checking = false;

  Future<void> _onDigit(String digit) async {
    if (_input.length >= 6 || _checking) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == 6) await _verify();
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await context.read<SecurityProvider>().unlockWithPin(_input);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = 'PIN salah, coba lagi';
        _input = '';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: AppColors.matchaBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.matchaDarkest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.eco_rounded, size: 38, color: AppColors.latteFoam),
            ),
            const SizedBox(height: 16),
            const Text('MatchaFin Terkunci', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.matchaDarkest)),
            const SizedBox(height: 4),
            const Text('Masukkan PIN untuk melanjutkan', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6350))),
            const SizedBox(height: 20),
            PinDots(filled: _input.length),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
            ],
            const Spacer(),
            if (security.biometricEnabled && security.biometricAvailable) ...[
              IconButton(
                iconSize: 36,
                onPressed: () => context.read<SecurityProvider>().unlockWithBiometric(),
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.matchaDarkest),
              ),
              const SizedBox(height: 4),
            ],
            PinNumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
