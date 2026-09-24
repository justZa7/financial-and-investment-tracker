import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter yang otomatis menambahkan titik pemisah ribuan
/// (format Indonesia) saat user mengetik nominal IDR di TextField.
/// Contoh: user ketik "150000" -> tampil otomatis jadi "150.000".
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final trimmed = digitsOnly.length > 15 ? digitsOnly.substring(0, 15) : digitsOnly;
    final number = int.parse(trimmed);
    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// TextInputFormatter untuk nominal USD: koma sebagai pemisah ribuan,
/// titik sebagai pemisah desimal (maks. 2 digit desimal/sen).
/// Contoh: user ketik "1234.5" -> tampil otomatis jadi "1,234.5".
class UsdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Hanya izinkan satu titik desimal.
    final firstDot = text.indexOf('.');
    if (firstDot != -1) {
      text = text.substring(0, firstDot + 1) +
          text.substring(firstDot + 1).replaceAll('.', '');
    }

    String integerPart;
    String decimalPart = '';
    if (firstDot == -1) {
      integerPart = text;
    } else {
      integerPart = text.substring(0, firstDot);
      decimalPart = text.substring(firstDot); // termasuk titiknya
      if (decimalPart.length > 3) decimalPart = decimalPart.substring(0, 3); // maks 2 digit desimal
    }

    if (integerPart.isEmpty && decimalPart.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final intVal = integerPart.isEmpty ? 0 : int.tryParse(integerPart) ?? 0;
    final formattedInt = NumberFormat.decimalPattern('en_US').format(intVal);
    final newText = '$formattedInt$decimalPart';

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CurrencyInputHelper {
  CurrencyInputHelper._();

  /// "150.000" -> 150000.0
  static double unformatIdr(String formattedText) {
    return double.tryParse(formattedText.replaceAll('.', '')) ?? 0;
  }

  /// "1,234.5" -> 1234.5
  static double unformatUsd(String formattedText) {
    return double.tryParse(formattedText.replaceAll(',', '')) ?? 0;
  }
}
