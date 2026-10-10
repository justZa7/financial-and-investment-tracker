import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../services/security_service.dart';

enum AppLockStatus { loading, locked, unlocked }

/// Mengatur status kunci aplikasi (PIN + biometric). [status] dicek sekali
/// saat app start (lewat [initialize]) — kalau lock aktif, app menampilkan
/// LockScreen sampai [unlockWithPin]/[unlockWithBiometric] berhasil.
class SecurityProvider extends ChangeNotifier {
  AppLockStatus status = AppLockStatus.loading;
  bool lockEnabled = false;
  bool biometricEnabled = false;
  bool biometricAvailable = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> initialize() async {
    lockEnabled = await SecurityService.isLockEnabled();
    biometricEnabled = await SecurityService.isBiometricEnabled();

    try {
      biometricAvailable = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      // Platform belum di-setup (lihat README "Setup Native untuk Biometric")
      // -> anggap biometric tidak tersedia, jangan sampai app crash.
      debugPrint('[SecurityProvider] local_auth tidak tersedia: $e');
      biometricAvailable = false;
    }

    status = lockEnabled ? AppLockStatus.locked : AppLockStatus.unlocked;
    notifyListeners();

    if (status == AppLockStatus.locked && biometricEnabled && biometricAvailable) {
      unawaited(unlockWithBiometric());
    }
  }

  Future<bool> setupPin(String pin) async {
    await SecurityService.savePin(pin);
    lockEnabled = true;
    notifyListeners();
    return true;
  }

  Future<void> disableLock() async {
    await SecurityService.disableLock();
    lockEnabled = false;
    biometricEnabled = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await SecurityService.setBiometricEnabled(enabled);
    biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await SecurityService.verifyPin(pin);
    if (ok) {
      status = AppLockStatus.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> unlockWithBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Buka kunci MatchaFin',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) {
        status = AppLockStatus.unlocked;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('[SecurityProvider] autentikasi biometric gagal: $e');
      return false;
    }
  }
}
