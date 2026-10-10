import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/pin_pad.dart';

/// Halaman buat PIN baru (atau ganti PIN lama) — minta input 2x supaya
/// tidak salah ketik, konfirmasi harus sama persis.
class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _firstPin = '';
  String _input = '';
  bool _isConfirmStep = false;
  String? _error;

  void _onDigit(String digit) {
    if (_input.length >= 6) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == 6) _onComplete();
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onComplete() async {
    if (!_isConfirmStep) {
      setState(() {
        _firstPin = _input;
        _input = '';
        _isConfirmStep = true;
      });
      return;
    }

    if (_input != _firstPin) {
      setState(() {
        _error = 'PIN tidak cocok, coba lagi dari awal';
        _input = '';
        _firstPin = '';
        _isConfirmStep = false;
      });
      return;
    }

    await context.read<SecurityProvider>().setupPin(_input);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN berhasil diset'), behavior: SnackBarBehavior.floating),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.matchaBg,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Buat PIN')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.matchaDarkest),
            const SizedBox(height: 16),
            Text(
              _isConfirmStep ? 'Ulangi PIN yang sama' : 'Buat PIN 6 digit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.matchaDarkest),
            ),
            const SizedBox(height: 16),
            PinDots(filled: _input.length),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
            ],
            const Spacer(),
            PinNumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
