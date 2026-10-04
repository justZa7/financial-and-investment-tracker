import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/currency_input_formatter.dart';
import '../utils/formatters.dart';
import '../utils/input_currency.dart';

/// Field nominal dengan toggle mata uang IDR/USD.
/// Nilai akhir yang diekspos lewat [amountInIdr] SELALU dalam Rupiah
/// (dikonversi otomatis pakai [exchangeRate] kalau user pilih USD),
/// supaya semua data yang disimpan ke provider tetap satu basis mata uang.
class CurrencyAmountField extends StatefulWidget {
  final String label;
  final String hint;
  final double exchangeRate;
  final String? Function(String?)? validator;
  /// Dipanggil tiap kali nilai (basis IDR) berubah — dipakai parent widget
  /// yang perlu tahu nilai terkini secara live, misal untuk menghitung
  /// ringkasan "Total Pembelian" yang update sambil user mengetik.
  final ValueChanged<double>? onAmountChanged;

  const CurrencyAmountField({
    super.key,
    required this.label,
    required this.exchangeRate,
    this.hint = '',
    this.validator,
    this.onAmountChanged,
  });

  @override
  State<CurrencyAmountField> createState() => CurrencyAmountFieldState();
}

class CurrencyAmountFieldState extends State<CurrencyAmountField> {
  InputCurrency currency = InputCurrency.idr;
  final TextEditingController controller = TextEditingController();

  /// Nilai nominal, sudah dikonversi ke IDR kalau currency == usd.
  double get amountInIdr {
    if (currency == InputCurrency.idr) {
      return CurrencyInputHelper.unformatIdr(controller.text);
    }
    final usd = CurrencyInputHelper.unformatUsd(controller.text);
    return usd * widget.exchangeRate;
  }

  void clear() => controller.clear();

  /// Isi field ini secara programatik dengan nilai dalam IDR (dipaksa ke
  /// mode currency IDR dulu kalau sebelumnya di USD) — dipakai tombol
  /// "Gunakan harga ini" dari hasil fetch harga pasar live.
  void setAmountInIdr(double value) {
    setState(() {
      currency = InputCurrency.idr;
      controller.text = NumberFormat.decimalPattern('id_ID').format(value.round());
    });
    widget.onAmountChanged?.call(amountInIdr);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            SegmentedButton<InputCurrency>(
              segments: const [
                ButtonSegment(value: InputCurrency.idr, label: Text('IDR', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: InputCurrency.usd, label: Text('USD', style: TextStyle(fontSize: 11))),
              ],
              selected: {currency},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
              ),
              onSelectionChanged: (s) => setState(() {
                currency = s.first;
                controller.clear();
                widget.onAmountChanged?.call(amountInIdr);
              }),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            currency == InputCurrency.idr
                ? ThousandsSeparatorInputFormatter()
                : UsdInputFormatter(),
          ],
          decoration: InputDecoration(
            prefixText: currency == InputCurrency.idr ? 'Rp ' : '\$ ',
            hintText: widget.hint,
          ),
          validator: widget.validator,
          onChanged: (_) => setState(() {
            widget.onAmountChanged?.call(amountInIdr);
          }),
        ),
        if (currency == InputCurrency.usd && controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '≈ ${AppFormatters.rupiah(amountInIdr)}  (kurs 1 USD = ${AppFormatters.rupiah(widget.exchangeRate)})',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
