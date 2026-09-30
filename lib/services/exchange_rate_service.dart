import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Mengambil kurs USD -> IDR dari API publik gratis (open.er-api.com,
/// tanpa perlu API key). Kalau fetch gagal (tidak ada koneksi, dsb),
/// pakai [fallbackRate] terakhir yang berhasil didapat/di-cache.
class ExchangeRateService {
  ExchangeRateService._();

  /// Nilai default sebelum fetch pertama berhasil / kalau fetch gagal total.
  static double _cachedRate = 16300;

  /// Pesan error asli dari percobaan fetch terakhir (null kalau sukses).
  /// Berguna untuk debugging: beda dengan "tidak konek internet" yang
  /// digeneralisir, ini nunjukkin exception SEBENARNYA (timeout, host
  /// tidak ditemukan, certificate error, dsb).
  static String? lastError;

  static double get fallbackRate => _cachedRate;

  static Future<double> fetchUsdToIdrRate() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rate = (data['rates']?['IDR'] as num?)?.toDouble();
        if (rate != null && rate > 0) {
          _cachedRate = rate;
          lastError = null;
        } else {
          lastError = 'Response API tidak berisi field rates.IDR yang valid';
        }
      } else {
        lastError = 'HTTP ${res.statusCode} dari open.er-api.com';
      }
    } catch (e) {
      lastError = e.toString();
      // Print ke console (kelihatan di `flutter run --release` / logcat)
      // supaya gampang di-debug tanpa perlu breakpoint.
      debugPrint('[ExchangeRateService] fetch gagal: $e');
    }
    return _cachedRate;
  }
}
