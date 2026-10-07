import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/asset_holding_model.dart';
import 'exchange_rate_service.dart';

/// Hasil fetch harga otomatis untuk satu ticker (dipakai saat bulk-refresh
/// di halaman Portfolio).
class FetchPriceResult {
  final String ticker;
  final double? price;
  final String? error;

  FetchPriceResult({required this.ticker, this.price, this.error});

  bool get success => price != null;
}

/// Kuotasi harga lengkap untuk SATU aset — harga terkini + histori ringkas
/// untuk sparkline chart (kalau API-nya menyediakan). Dipakai untuk preview
/// live saat user mengetik ticker di form Input, dan untuk auto-update
/// setelah transaksi Beli/Jual disimpan.
class AssetQuote {
  final double price;
  /// Titik harga historis (kronologis, lama -> baru), basis IDR. Bisa
  /// kosong kalau API untuk kelas aset tsb tidak menyediakan histori
  /// (misal Emas) — UI harus menangani list kosong dengan baik.
  final List<double> history;

  AssetQuote({required this.price, this.history = const []});

  /// Perubahan dari titik pertama ke terakhir di [history], dalam %.
  /// Null kalau histori tidak cukup untuk dihitung.
  double? get changePercent {
    if (history.length < 2 || history.first == 0) return null;
    return ((history.last - history.first) / history.first) * 100;
  }
}

/// Service untuk mengambil harga pasar terkini (+ histori ringkas) dari API
/// publik — dipakai di 2 tempat: (1) tombol ☁️/pull-to-refresh di halaman
/// Portfolio (lewat [fetchAll], bulk, banyak holding sekaligus), dan
/// (2) live-preview saat mengetik ticker di form Input serta auto-update
/// setelah Beli/Jual disimpan (lewat [fetchQuote], satu ticker).
///
/// STATUS DUKUNGAN PER KELAS ASET:
/// - **Crypto**  : CoinGecko `market_chart` (gratis, tanpa API key) — kasih
///   harga terkini SEKALIGUS histori 7 hari untuk sparkline.
/// - **Equity**  : Yahoo Finance `chart` endpoint (gratis, unofficial) —
///   kasih harga terkini + histori harian ringkas. Ticker tanpa titik
///   otomatis dianggap saham IDX (+".JK").
/// - **Gold**    : gold-api.com (gratis, tanpa API key) — HANYA harga spot
///   terkini, TIDAK ada histori/chart dari API ini. Estimasi dari harga
///   spot emas dunia (USD/troy-ounce → IDR/gram), BUKAN harga resmi Antam.
/// - **Reksadana/Money Market**: SENGAJA tidak didukung — NAB harian tidak
///   tersedia lewat API publik gratis. [fetchQuote] mengembalikan null.
///
/// ⚠️ Endpoint Yahoo Finance & gold-api.com TIDAK RESMI didokumentasikan
/// penyedianya — cukup andal untuk demo, bisa berubah sewaktu-waktu tanpa
/// pemberitahuan. Untuk produksi, pertimbangkan API resmi berbayar.
class MarketDataService {
  MarketDataService._();

  // static const Map<String, String> _coingeckoIds = {
  //   'BTC': 'bitcoin',
  //   'ETH': 'ethereum',
  //   'BNB': 'binancecoin',
  //   'SOL': 'solana',
  //   'USDT': 'tether',
  //   'USDC': 'usd-coin',
  //   'XRP': 'ripple',
  //   'ADA': 'cardano',
  //   'DOGE': 'dogecoin',
  //   'AVAX': 'avalanche-2',
  //   'DOT': 'polkadot',
  // };

static Map<String, String> _coingeckoIds = {};
static bool _coinListLoaded = false;

static Future<void> _loadCoinGeckoIds() async {
  if (_coinListLoaded) return;

  final uri = Uri.parse(
    'https://api.coingecko.com/api/v3/coins/list',
  );

  final res = await http.get(uri).timeout(
    const Duration(seconds: 10),
  );

  if (res.statusCode != 200) {
    throw Exception(
      'Gagal mengambil daftar coin CoinGecko: ${res.statusCode}',
    );
  }

  final data = jsonDecode(res.body) as List<dynamic>;

  _coingeckoIds = {
    for (final coin in data)
      (coin['symbol'] as String).toUpperCase(): coin['id'] as String,
  };

  _coinListLoaded = true;
}

  static const double _gramsPerTroyOunce = 31.1034768;

  // ---------------------------------------------------------------------
  // SATU TICKER — dipakai live-preview di form Input & auto-update pasca-save
  // ---------------------------------------------------------------------

  /// Null kalau kelas aset tidak didukung (Money Market), ticker kosong,
  /// atau fetch gagal karena sebab apapun. Dipakai untuk live-preview di
  /// form Input, di mana detail pesan error kurang penting (UI cukup
  /// tampilkan "tidak ditemukan, isi manual") — untuk diagnostik error
  /// yang lebih rinci (dipakai bulk-refresh Portfolio), lihat [fetchAll].
  static Future<AssetQuote?> fetchQuote(String ticker, AssetClass assetClass) async {
    if (ticker.trim().isEmpty || assetClass == AssetClass.moneyMarket) return null;
    try {
      return await _dispatch(ticker, assetClass);
    } catch (e) {
      debugPrint('[MarketDataService] fetchQuote($ticker) gagal: $e');
      return null;
    }
  }

  static Future<AssetQuote?> _dispatch(String ticker, AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.crypto:
        return _fetchCryptoQuote(ticker);
      case AssetClass.equity:
        return _fetchEquityQuote(ticker);
      case AssetClass.gold:
        return _fetchGoldQuote();
      case AssetClass.moneyMarket:
        return Future.value(null);
    }
  }

  // static Future<AssetQuote?> _fetchCryptoQuote(String ticker) async {
  //   final id = _coingeckoIds[ticker.trim().toUpperCase()];
  //   if (id == null) return null;

  //   final uri = Uri.parse('https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=idr&days=7');
  //   final res = await http.get(uri).timeout(const Duration(seconds: 10));
  //   if (res.statusCode != 200) return null;

  //   final data = jsonDecode(res.body) as Map<String, dynamic>;
  //   final rawPrices = (data['prices'] as List?) ?? [];
  //   if (rawPrices.isEmpty) return null;

  //   final allPoints = rawPrices
  //       .map((p) => (p as List)[1] as num)
  //       .map((n) => n.toDouble())
  //       .toList();

  //   // Downsample supaya chart tetap ringan & halus (CoinGecko bisa kasih
  //   // ratusan titik untuk rentang 7 hari).
  //   final history = _downsample(allPoints, 24);
  //   return AssetQuote(price: allPoints.last, history: history);
  // }

  static Future<AssetQuote?> _fetchCryptoQuote(String ticker) async {
  await _loadCoinGeckoIds();

  final symbol = ticker.trim().toUpperCase();
  final id = _coingeckoIds[symbol];

  if (id == null) return null;

  final uri = Uri.parse(
    'https://api.coingecko.com/api/v3/coins/$id/market_chart'
    '?vs_currency=idr&days=7',
  );

  final res = await http.get(uri).timeout(
    const Duration(seconds: 10),
  );

  if (res.statusCode != 200) return null;

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final rawPrices = (data['prices'] as List?) ?? [];

  if (rawPrices.isEmpty) return null;

  final allPoints = rawPrices
      .map((p) => (p as List)[1] as num)
      .map((n) => n.toDouble())
      .toList();

  final history = _downsample(allPoints, 24);

  return AssetQuote(
    price: allPoints.last,
    history: history,
  );
}

  static String _toYahooSymbol(String ticker) {
    final t = ticker.trim().toUpperCase();
    if (t.contains('.')) return t;
    return '$t.JK';
  }

  static Future<AssetQuote?> _fetchEquityQuote(String ticker) async {
    final symbol = _toYahooSymbol(ticker);
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=1mo&interval=1d');
    final res = await http.get(
      uri,
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; FinanceTrackerApp/1.0)'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final resultList = data['chart']?['result'] as List?;
    if (resultList == null || resultList.isEmpty) return null;
    final result = resultList.first as Map<String, dynamic>;

    final price = (result['meta']?['regularMarketPrice'] as num?)?.toDouble();
    if (price == null) return null;

    final closes = (result['indicators']?['quote'] as List?)?.isNotEmpty == true
        ? (result['indicators']['quote'][0]['close'] as List?)
        : null;

    final history = (closes ?? [])
        .where((c) => c != null)
        .map((c) => (c as num).toDouble())
        .toList();

    return AssetQuote(price: price, history: _downsample(history, 24));
  }

  static Future<AssetQuote?> _fetchGoldQuote() async {
    final uri = Uri.parse('https://api.gold-api.com/price/XAU');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final pricePerOunceUsd = (data['price'] as num?)?.toDouble();
    if (pricePerOunceUsd == null) return null;

    final usdToIdr = await ExchangeRateService.fetchUsdToIdrRate();
    final pricePerGramIdr = (pricePerOunceUsd / _gramsPerTroyOunce) * usdToIdr;

    // gold-api.com tidak menyediakan histori -> history kosong, UI akan
    // menampilkan state "grafik belum tersedia" tanpa chart.
    return AssetQuote(price: pricePerGramIdr, history: const []);
  }

  static List<double> _downsample(List<double> points, int maxPoints) {
    if (points.length <= maxPoints) return points;
    final step = points.length / maxPoints;
    return List.generate(maxPoints, (i) => points[(i * step).floor()]);
  }

  // ---------------------------------------------------------------------
  // BULK — dipakai tombol ☁️ / pull-to-refresh di halaman Portfolio
  // ---------------------------------------------------------------------
  static Future<List<FetchPriceResult>> fetchAll(List<AssetHoldingModel> holdings) async {
    final results = <FetchPriceResult>[];

    final fetchable = holdings.where((h) => h.assetClass != AssetClass.moneyMarket).toList();
    final futures = fetchable.map((h) async {
      try {
        final quote = await _dispatch(h.ticker, h.assetClass);
        if (quote != null) {
          return FetchPriceResult(ticker: h.ticker, price: quote.price);
        }
        final reason = switch (h.assetClass) {
          AssetClass.equity =>
            'Simbol "${h.ticker}" tidak ditemukan di Yahoo Finance. Cek penulisan ticker.',
          AssetClass.crypto =>
            'Ticker "${h.ticker}" belum ada di mapping CoinGecko (MarketDataService._coingeckoIds).',
          AssetClass.gold => 'Response API harga emas tidak sesuai format yang diharapkan.',
          AssetClass.moneyMarket => '-',
        };
        return FetchPriceResult(ticker: h.ticker, error: reason);
      } catch (e) {
        // Pesan error ASLI (bukan digeneralisir) supaya gampang di-debug —
        // misal kalau release build gagal fetch tapi debug jalan normal,
        // exception sebenarnya (SocketException, HandshakeException,
        // TimeoutException, dll) akan kelihatan di sini.
        debugPrint('[MarketDataService] fetch ${h.ticker} (${h.assetClass}) gagal: $e');
        return FetchPriceResult(ticker: h.ticker, error: 'Gagal terhubung ke API: $e');
      }
    });
    results.addAll(await Future.wait(futures));

    for (final h in holdings.where((h) => h.assetClass == AssetClass.moneyMarket)) {
      results.add(FetchPriceResult(
        ticker: h.ticker,
        error: 'Reksadana Pasar Uang tidak difetch otomatis (NAB harian tidak tersedia lewat '
            'API publik). Silakan gunakan "Update Harga Manual".',
      ));
    }

    return results;
  }
}
