import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/asset_holding_model.dart';
import 'exchange_rate_service.dart';

/// Hasil fetch harga otomatis untuk satu ticker.
class FetchPriceResult {
  final String ticker;
  final double? price; // null kalau gagal / tidak didukung
  final String? error;

  FetchPriceResult({required this.ticker, this.price, this.error});

  bool get success => price != null;
}

/// Service untuk mengambil harga pasar terkini dari API publik, dipanggil
/// dari tombol "Fetch Harga dari API" / pull-to-refresh di halaman Portfolio.
///
/// STATUS DUKUNGAN PER KELAS ASET (penting dibaca sebelum demo):
/// - **Crypto**  : didukung penuh lewat CoinGecko (gratis, tanpa API key).
/// - **Equity**  : didukung lewat Yahoo Finance (endpoint publik/unofficial
///   `query1.finance.yahoo.com`, gratis, tanpa API key). Ticker tanpa titik
///   otomatis dianggap saham IDX dan ditambah ".JK" (contoh: BBCA -> BBCA.JK).
/// - **Gold**    : didukung lewat gold-api.com (gratis, tanpa API key) untuk
///   harga emas spot dunia (USD/troy ounce), dikonversi ke IDR/gram pakai
///   kurs dari ExchangeRateService. ⚠️ Ini harga SPOT emas dunia, BUKAN
///   harga resmi Antam/toko emas lokal (yang biasanya ada premium/margin
///   tambahan) — anggap sebagai estimasi acuan, bukan harga jual-beli pasti.
/// - **Reksadana/Money Market**: SENGAJA tidak difetch otomatis — NAB per
///   produk reksadana pasar uang hanya tersedia lewat API masing-masing
///   platform sekuritas/manajer investasi (tidak ada API publik gratis
///   yang terstandarisasi). Selalu pakai "Update Harga Manual" untuk ini.
///
/// ⚠️ Catatan umum: endpoint Yahoo Finance & gold-api.com di atas TIDAK
/// RESMI didokumentasikan oleh penyedianya — dipakai luas oleh komunitas
/// developer, cukup andal untuk demo/skala kecil, tapi bisa berubah format
/// atau di-*rate-limit* sewaktu-waktu tanpa pemberitahuan resmi. Untuk
/// kebutuhan produksi/skala besar, pertimbangkan API berbayar resmi.
///
/// Untuk kelas aset yang sengaja tidak difetch (Reksadana), [fetchAll]
/// tetap mengembalikan [FetchPriceResult] dengan `error` terisi supaya UI
/// bisa menampilkan alasannya ke user, alih-alih diam-diam gagal.
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

  /// 1 troy ounce = 31.1034768 gram — dipakai konversi harga emas dunia
  /// (per ounce) ke satuan yang dipakai app ini (per gram).
  static const double _gramsPerTroyOunce = 31.1034768;

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

    final goldHoldings = holdings.where((h) => h.assetClass == AssetClass.gold).toList();
    if (goldHoldings.isNotEmpty) {
      results.addAll(await _fetchGoldBatch(goldHoldings.map((h) => h.ticker).toList()));
    }

    for (final h in holdings.where((h) => h.assetClass == AssetClass.moneyMarket)) {
      results.add(FetchPriceResult(
        ticker: h.ticker,
        error: 'Reksadana Pasar Uang tidak difetch otomatis (NAB harian tidak tersedia lewat '
            'API publik). Silakan gunakan "Update Harga Manual".',
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
    } catch (e) {
      debugPrint('[MarketDataService] fetch crypto gagal: $e');
      return uniqueTickers
          .map((t) => FetchPriceResult(ticker: t, error: 'Gagal terhubung ke API: $e'))
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
    } catch (e) {
      debugPrint('[MarketDataService] fetch equity $symbol gagal: $e');
      return FetchPriceResult(
        ticker: ticker,
        error: 'Gagal terhubung ke Yahoo Finance untuk $symbol: $e',
      );
    }
  }

  // ---------------------------------------------------------------------
  // GOLD — gold-api.com (unofficial, gratis, tanpa API key)
  // ---------------------------------------------------------------------
  static Future<List<FetchPriceResult>> _fetchGoldBatch(List<String> tickers) async {
    final uniqueTickers = tickers.toSet().toList();
    try {
      final uri = Uri.parse('https://api.gold-api.com/price/XAU');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return uniqueTickers
            .map((t) => FetchPriceResult(ticker: t, error: 'Gagal fetch harga emas (HTTP ${res.statusCode})'))
            .toList();
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final pricePerOunceUsd = (data['price'] as num?)?.toDouble();

      if (pricePerOunceUsd == null) {
        return uniqueTickers
            .map((t) => FetchPriceResult(ticker: t, error: 'Response API harga emas tidak sesuai format yang diharapkan'))
            .toList();
      }

      // Konversi: USD/troy-ounce -> USD/gram -> IDR/gram (pakai kurs terkini).
      final usdToIdr = await ExchangeRateService.fetchUsdToIdrRate();
      final pricePerGramIdr = (pricePerOunceUsd / _gramsPerTroyOunce) * usdToIdr;

      return uniqueTickers.map((t) => FetchPriceResult(ticker: t, price: pricePerGramIdr)).toList();
    } catch (e) {
      debugPrint('[MarketDataService] fetch gold gagal: $e');
      return uniqueTickers
          .map((t) => FetchPriceResult(ticker: t, error: 'Gagal terhubung ke API harga emas: $e'))
          .toList();
    }
  }
}
