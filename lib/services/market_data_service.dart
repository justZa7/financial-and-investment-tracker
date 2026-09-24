import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/asset_holding_model.dart';

/// Hasil fetch harga otomatis untuk satu ticker.
class FetchPriceResult {
  final String ticker;
  final double? price; // null kalau gagal / tidak didukung
  final String? error;

  FetchPriceResult({required this.ticker, this.price, this.error});

  bool get success => price != null;
}

/// Service untuk mengambil harga pasar terkini dari API publik, dipanggil
/// dari tombol "Fetch Harga dari API" di halaman Portfolio.
///
/// STATUS DUKUNGAN PER KELAS ASET (penting dibaca sebelum demo):
/// - **Crypto**  : didukung penuh lewat CoinGecko (gratis, tanpa API key).
/// - **Equity**  : didukung lewat Yahoo Finance (endpoint publik/unofficial
///   `query1.finance.yahoo.com`, gratis, tanpa API key). Ticker tanpa suffix
///   otomatis dianggap saham IDX dan ditambah ".JK" (contoh: BBCA -> BBCA.JK).
///   ⚠️ Endpoint ini TIDAK RESMI didokumentasikan Yahoo — bisa saja berubah
///   format/di-rate-limit sewaktu-waktu tanpa pemberitahuan. Untuk kebutuhan
///   produksi/skala besar, pertimbangkan API berbayar resmi (IEX Cloud,
///   Alpha Vantage, dsb).
/// - **Gold**    : BELUM didukung otomatis. Perlu API harga emas berbayar
///   (metals-api.com, goldapi.io, dsb). Lengkapi [_fetchGoldBatch].
/// - **Reksadana/Money Market**: BELUM didukung otomatis — NAB per produk
///   umumnya hanya tersedia lewat API masing-masing platform sekuritas /
///   manajer investasi, tidak ada API publik terstandarisasi.
///
/// Untuk kelas aset yang belum didukung, [fetchAll] tetap mengembalikan
/// [FetchPriceResult] dengan `error` terisi supaya UI bisa menampilkan
/// alasannya ke user, alih-alih diam-diam gagal.
class MarketDataService {
  MarketDataService._();

  /// Mapping ticker umum -> id CoinGecko. Tambahkan sendiri kalau perlu
  /// ticker crypto lain (lihat daftar id di https://api.coingecko.com/api/v3/coins/list).
  static const Map<String, String> _coingeckoIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'BNB': 'binancecoin',
    'SOL': 'solana',
    'USDT': 'tether',
    'USDC': 'usd-coin',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'AVAX': 'avalanche-2',
    'DOT': 'polkadot',
  };

  static Future<List<FetchPriceResult>> fetchAll(List<AssetHoldingModel> holdings) async {
    final results = <FetchPriceResult>[];

    final cryptoHoldings = holdings.where((h) => h.assetClass == AssetClass.crypto).toList();
    if (cryptoHoldings.isNotEmpty) {
      results.addAll(await _fetchCryptoBatch(cryptoHoldings.map((h) => h.ticker).toList()));
    }

    final equityHoldings = holdings.where((h) => h.assetClass == AssetClass.equity).toList();
    if (equityHoldings.isNotEmpty) {
      results.addAll(await _fetchEquityBatch(equityHoldings.map((h) => h.ticker).toList()));
    }

    for (final h in holdings.where(
        (h) => h.assetClass != AssetClass.crypto && h.assetClass != AssetClass.equity)) {
      results.add(FetchPriceResult(
        ticker: h.ticker,
        error: 'Update otomatis untuk ${h.assetClass.label} belum didukung (perlu API berbayar). '
            'Gunakan "Update Harga Manual".',
      ));
    }

    return results;
  }

  // ---------------------------------------------------------------------
  // CRYPTO — CoinGecko
  // ---------------------------------------------------------------------
  static Future<List<FetchPriceResult>> _fetchCryptoBatch(List<String> tickers) async {
    final uniqueTickers = tickers.toSet().toList();
    final ids = uniqueTickers
        .map((t) => _coingeckoIds[t.toUpperCase()])
        .whereType<String>()
        .toSet()
        .join(',');

    if (ids.isEmpty) {
      return uniqueTickers
          .map((t) => FetchPriceResult(
                ticker: t,
                error: 'Ticker "$t" belum ada di mapping CoinGecko. Tambahkan di MarketDataService._coingeckoIds.',
              ))
          .toList();
    }

    try {
      final uri = Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=idr');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return uniqueTickers
            .map((t) => FetchPriceResult(ticker: t, error: 'Gagal fetch (HTTP ${res.statusCode})'))
            .toList();
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      return uniqueTickers.map((t) {
        final id = _coingeckoIds[t.toUpperCase()];
        final price = id != null ? (data[id]?['idr'] as num?)?.toDouble() : null;
        if (price == null) {
          return FetchPriceResult(ticker: t, error: 'Data harga tidak ditemukan untuk $t');
        }
        return FetchPriceResult(ticker: t, price: price);
      }).toList();
    } catch (_) {
      return uniqueTickers
          .map((t) => FetchPriceResult(ticker: t, error: 'Gagal terhubung ke API (cek koneksi internet)'))
          .toList();
    }
  }

  // ---------------------------------------------------------------------
  // EQUITY — Yahoo Finance (unofficial, gratis, tanpa API key)
  // ---------------------------------------------------------------------

  /// Ubah ticker lokal ("BBCA") jadi simbol Yahoo Finance ("BBCA.JK").
  /// Kalau ticker sudah mengandung titik (misal user isi manual "AAPL"
  /// untuk saham AS tanpa suffix, atau sudah pakai suffix lain seperti
  /// ".JK"/".L"/dst), dipakai apa adanya tanpa ditambah ".JK".
  static String _toYahooSymbol(String ticker) {
    final t = ticker.trim().toUpperCase();
    if (t.contains('.')) return t;
    return '$t.JK'; // default: asumsikan saham IDX (Bursa Efek Indonesia)
  }

  static Future<List<FetchPriceResult>> _fetchEquityBatch(List<String> tickers) async {
    final uniqueTickers = tickers.toSet().toList();
    // Fetch paralel per simbol (endpoint chart Yahoo hanya menerima 1 simbol/request).
    final futures = uniqueTickers.map(_fetchSingleEquity);
    return Future.wait(futures);
  }

  static Future<FetchPriceResult> _fetchSingleEquity(String ticker) async {
    final symbol = _toYahooSymbol(ticker);
    try {
      final uri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol');
      final res = await http.get(
        uri,
        // Beberapa deployment Yahoo menolak request tanpa User-Agent browser.
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; FinanceTrackerApp/1.0)'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return FetchPriceResult(
          ticker: ticker,
          error: 'Gagal fetch $symbol dari Yahoo Finance (HTTP ${res.statusCode})',
        );
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final resultList = data['chart']?['result'] as List?;
      final result = (resultList != null && resultList.isNotEmpty)
          ? resultList.first as Map<String, dynamic>
          : null;

      final price = (result?['meta']?['regularMarketPrice'] as num?)?.toDouble();

      if (price == null) {
        return FetchPriceResult(
          ticker: ticker,
          error: 'Simbol "$symbol" tidak ditemukan di Yahoo Finance. '
              'Cek penulisan ticker (untuk saham IDX pastikan tanpa suffix, contoh: BBCA).',
        );
      }

      return FetchPriceResult(ticker: ticker, price: price);
    } catch (_) {
      return FetchPriceResult(
        ticker: ticker,
        error: 'Gagal terhubung ke Yahoo Finance untuk $symbol (cek koneksi internet)',
      );
    }
  }
}
