import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper penyimpanan preferensi ringan (PIN hash, status lock aktif,
/// status onboarding sudah dilihat) lewat SharedPreferences.
///
/// PIN TIDAK PERNAH disimpan mentah — selalu di-hash (SHA-256 + salt
/// statis sederhana) sebelum disimpan, dan verifikasi dilakukan dengan
/// membandingkan hash, bukan membandingkan teks PIN langsung.
class SecurityService {
  SecurityService._();

  static const _keyPinHash = 'matchafin_pin_hash';
  static const _keyLockEnabled = 'matchafin_lock_enabled';
  static const _keyBiometricEnabled = 'matchafin_biometric_enabled';
  static const _keyOnboardingSeen = 'matchafin_onboarding_seen';

  // Salt statis sederhana — cukup untuk mencegah PIN kebaca polos di
  // storage, BUKAN pengganti keamanan kelas-enterprise (app ini tanpa
  // backend/akun, ancaman utamanya cuma "orang lain pegang HP ini").
  static const _salt = 'matchafin_salt_v1';

  /// Di-expose supaya bisa diuji tanpa SharedPreferences.
  static String hashPin(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinHash, hashPin(pin));
    await prefs.setBool(_keyLockEnabled, true);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPinHash);
    if (stored == null) return false;
    return stored == hashPin(pin);
  }

  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLockEnabled) ?? false;
  }

  static Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLockEnabled, false);
    await prefs.remove(_keyPinHash);
    await prefs.setBool(_keyBiometricEnabled, false);
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }
}
