import 'package:flutter/foundation.dart';

import '../utils/input_currency.dart';

/// Menyimpan preferensi mata uang TAMPILAN untuk SELURUH aplikasi — mirip
/// aplikasi trading, di mana portofolio bisa dilihat dalam IDR atau USD.
///
/// Ini BEDA dengan mata uang INPUT per-field di form (CurrencyAmountField):
/// semua data tetap DISIMPAN dalam IDR di provider lain (CashFlowProvider,
/// PortfolioProvider, DebtProvider) — provider ini cuma mengatur bagaimana
/// angka itu DITAMPILKAN di layar, lewat widget MoneyText.
class DisplayCurrencyProvider extends ChangeNotifier {
  InputCurrency _currency = InputCurrency.idr;

  InputCurrency get currency => _currency;
  bool get isUsd => _currency == InputCurrency.usd;

  void toggle() {
    _currency = _currency == InputCurrency.idr ? InputCurrency.usd : InputCurrency.idr;
    notifyListeners();
  }

  void setCurrency(InputCurrency c) {
    if (_currency == c) return;
    _currency = c;
    notifyListeners();
  }
}
