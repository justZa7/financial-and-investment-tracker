import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/display_currency_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../utils/money_formatter.dart';

/// Text yang otomatis memformat nilai uang (basis IDR) sesuai preferensi
/// mata uang tampilan global (IDR/USD dari DisplayCurrencyProvider).
///
/// Cukup ganti `Text(AppFormatters.rupiah(x))` jadi
/// `MoneyText(amountInIdr: x)` di widget mana pun — otomatis ikut ter-update
/// saat user toggle mata uang tampilan, tanpa perlu ubah widget induknya.
class MoneyText extends StatelessWidget {
  final double amountInIdr;
  final bool compact;
  final bool signed;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MoneyText({
    super.key,
    required this.amountInIdr,
    this.compact = false,
    this.signed = false,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<DisplayCurrencyProvider>().currency;
    final rate = context.watch<ExchangeRateProvider>().rate;

    final text = signed
        ? MoneyFormatter.formatSigned(amountInIdr, currency, rate, compact: compact)
        : MoneyFormatter.format(amountInIdr, currency, rate, compact: compact);

    return Text(text, style: style, maxLines: maxLines, overflow: overflow);
  }
}
