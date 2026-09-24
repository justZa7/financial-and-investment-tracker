/// Mata uang yang bisa dipilih user saat mengisi nominal di form Input.
/// Nilai yang DISIMPAN ke model/provider selalu dalam IDR (Rupiah) —
/// kalau user pilih USD, nilainya dikonversi ke IDR pakai kurs terkini
/// sebelum disimpan, supaya semua kalkulasi (Net Worth, dsb) tetap 1 basis.
enum InputCurrency { idr, usd }

extension InputCurrencyX on InputCurrency {
  String get label => this == InputCurrency.idr ? 'IDR' : 'USD';
  String get symbol => this == InputCurrency.idr ? 'Rp' : '\$';
}
