import 'package:intl/intl.dart';

import 'formatters.dart';
import 'input_currency.dart';

/// Helper format angka uang: basis PENYIMPANAN selalu IDR, tapi bisa
/// diformat/ditampilkan sesuai [InputCurrency] pilihan user (IDR atau USD).
/// Dipakai bareng DisplayCurrencyProvider + MoneyText supaya "seluruh
/// portofolio" bisa di-toggle tampilannya ke USD, mirip aplikasi trading.
class MoneyFormatter {
  MoneyFormatter._();

  static final NumberFormat _usdFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  static final NumberFormat _usdCompactFormat =
      NumberFormat.compactCurrency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  /// Konversi nilai IDR -> mata uang tampilan (kalau USD, dibagi kurs).
  static double convert(double idrAmount, InputCurrency currency, double usdRate) {
    if (currency == InputCurrency.idr || usdRate <= 0) return idrAmount;
    return idrAmount / usdRate;
  }

  /// Format nilai yang SUDAH dikonversi (dipakai internal chart dsb, di
  /// mana konversi & format dipisah supaya scaling chart tetap benar).
  static String formatValue(double alreadyConvertedValue, InputCurrency currency, {bool compact = false}) {
    if (currency == InputCurrency.idr) {
      return compact
          ? AppFormatters.rupiahCompact(alreadyConvertedValue)
          : AppFormatters.rupiah(alreadyConvertedValue);
    }
    return compact ? _usdCompactFormat.format(alreadyConvertedValue) : _usdFormat.format(alreadyConvertedValue);
  }

  /// Konversi + format sekaligus dari nilai basis IDR.
  static String format(double idrAmount, InputCurrency currency, double usdRate, {bool compact = false}) {
    return formatValue(convert(idrAmount, currency, usdRate), currency, compact: compact);
  }

  /// Sama seperti [format], tapi dengan prefix +/- sesuai tanda nilainya.
  static String formatSigned(double idrAmount, InputCurrency currency, double usdRate, {bool compact = false}) {
    final converted = convert(idrAmount, currency, usdRate);
    final formatted = formatValue(converted.abs(), currency, compact: compact);
    return converted >= 0 ? '+$formatted' : '-$formatted';
  }
}
