/// Konfigurasi global aplikasi.
///
/// Set [useMockData] = false untuk demo/presentasi ke dosen dengan kondisi
/// KOSONG (empty state) — dosen bisa input transaksi, investasi, dan
/// utang/piutang sendiri dari nol.
///
/// Set [useMockData] = true untuk keperluan development/testing cepat,
/// di mana semua chart & list langsung terisi data contoh.
///
/// Catatan: Akun (Tunai, BCA, dst) & Kategori (Gaji, Makan, dst) TETAP
/// disediakan meski useMockData = false, karena keduanya adalah data
/// struktural (master data) yang dibutuhkan dropdown di form Input —
/// bukan "transaksi dummy". Saldo akun akan dimulai dari Rp 0.
class AppConfig {
  AppConfig._();

  static const bool useMockData = false;
}
