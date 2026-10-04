import '../models/asset_holding_model.dart';
import '../utils/formatters.dart';

/// Validasi input transaksi Beli/Jual aset per kelas aset. Dipanggil dari
/// validator field Qty di form Input (sehingga error muncul inline, SEBELUM
/// form bisa di-submit) dan dari pengecekan ulang saat tombol Simpan
/// ditekan — kalau salah satu gagal, `PortfolioProvider.buyAsset()` /
/// `sellAsset()` TIDAK PERNAH dipanggil, jadi data yang salah tidak pernah
/// masuk ke portfolio.
class AssetValidationService {
  AssetValidationService._();

  /// 1 lot saham di Bursa Efek Indonesia (IDX) = 100 lembar. Saham hanya
  /// bisa diperdagangkan dalam kelipatan ini.
  static const int equityLotSize = 100;

  /// Minimal pembelian emas (gram) — mencegah input seperti 0 atau nilai
  /// recehan yang tidak masuk akal secara praktik jual-beli emas.
  static const double minGoldGrams = 0.01;

  /// Minimal nominal pembelian Reksadana Pasar Uang (Rp), meniru minimum
  /// setoran awal yang lazim di platform sekuritas Indonesia.
  static const double minMoneyMarketAmount = 10000;

  /// Validasi Qty saja (tidak butuh harga). Dipakai sebagai validator field
  /// Qty di form — jalan setiap kali form di-submit lewat `FormState.validate()`.
  /// Null = valid, String = pesan error yang ditampilkan di bawah field.
  static String? validateQty({
    required AssetClass assetClass,
    required double? qty,
  }) {
    if (qty == null) return 'Qty harus berupa angka yang valid';
    if (qty <= 0) return 'Qty harus lebih besar dari 0';

    switch (assetClass) {
      case AssetClass.equity:
        if (qty != qty.roundToDouble()) {
          return 'Jumlah lembar saham harus bilangan bulat (tanpa desimal)';
        }
        if (qty % equityLotSize != 0) {
          return 'Saham dibeli per lot (1 lot = $equityLotSize lembar). '
              'Masukkan kelipatan $equityLotSize, misal: 100, 200, 500.';
        }
        return null;

      case AssetClass.gold:
        if (qty < minGoldGrams) {
          return 'Minimal pembelian emas ${AppFormatters.decimal(minGoldGrams, fraction: 2)} gram';
        }
        return null;

      case AssetClass.crypto:
        // Crypto boleh pecahan sekecil apapun (misal 0.00000001 BTC) —
        // qty > 0 saja sudah cukup, sudah dicek di atas.
        return null;

      case AssetClass.moneyMarket:
        // Qty di sini = jumlah unit/nominal reksadana; validasi nominal
        // minimum butuh harga juga, dicek terpisah lewat
        // [validateMinPurchaseAmount] karena harga belum tentu diisi saat
        // field Qty sedang divalidasi sendirian.
        return null;
    }
  }

  /// Validasi tambahan yang butuh harga sekaligus (nominal total transaksi)
  /// — dipanggil terpisah saat tombol Simpan ditekan, setelah Qty & Harga
  /// keduanya terisi.
  static String? validateMinPurchaseAmount({
    required AssetClass assetClass,
    required double qty,
    required double pricePerUnit,
  }) {
    if (assetClass == AssetClass.moneyMarket) {
      final total = qty * pricePerUnit;
      if (total < minMoneyMarketAmount) {
        return 'Minimal pembelian Reksadana adalah ${AppFormatters.rupiah(minMoneyMarketAmount)} '
            '(saat ini: ${AppFormatters.rupiah(total)})';
      }
    }
    return null;
  }

  /// Teks bantuan singkat yang ditampilkan di bawah field Qty supaya user
  /// tahu aturannya SEBELUM salah input, bukan cuma setelah kena error.
  static String? hintFor(AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.equity:
        return 'Wajib kelipatan 1 lot = $equityLotSize lembar (contoh: 100, 200, 500)';
      case AssetClass.gold:
        return 'Minimal ${AppFormatters.decimal(minGoldGrams, fraction: 2)} gram';
      case AssetClass.crypto:
        return 'Boleh pecahan desimal, contoh: 0.015';
      case AssetClass.moneyMarket:
        return 'Minimal total pembelian ${AppFormatters.rupiah(minMoneyMarketAmount)}';
    }
  }
}
