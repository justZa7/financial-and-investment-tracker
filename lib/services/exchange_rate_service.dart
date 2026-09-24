import 'dart:convert';
import 'package:http/http.dart' as http;

/// Mengambil kurs USD -> IDR dari API publik gratis (open.er-api.com,
/// tanpa perlu API key). Kalau fetch gagal (tidak ada koneksi, dsb),
/// pakai [fallbackRate] terakhir yang berhasil didapat/di-cache.
class ExchangeRateService {
  ExchangeRateService._();

  /// Nilai default sebelum fetch pertama berhasil / kalau fetch gagal total.
  static double _cachedRate = 16300;

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
        }
      }
    } catch (_) {
      // Tidak ada koneksi / API down -> diamkan, pakai _cachedRate terakhir.
    }
    return _cachedRate;
  }
}
