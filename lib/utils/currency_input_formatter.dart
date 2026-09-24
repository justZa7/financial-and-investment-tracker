import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '', // Tanpa simbol 'Rp ' agar murni angka saja
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus karakter non-digit agar hanya memproses angka
    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }

    final double value = double.parse(cleanText);
    final String formattedText = _formatter.format(value).trim();

    return TextEditingValue(
      text: formattedText,
      // Menjaga kursor tetap berada di paling akhir teks
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}