import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset_holding_model.dart';

class MarketService {
  /// Mengambil harga Crypto dari CoinGecko (Gratis & tanpa API key)
  /// Asumsi `symbol` diisi ID CoinGecko seperti: 'bitcoin', 'ethereum', 'solana', 'cardano'
  static Future<double?> fetchCryptoPriceIDR(String coinId) async {
    try {
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=${coinId.toLowerCase()}&vs_currencies=idr',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey(coinId.toLowerCase())) {
          return (data[coinId.toLowerCase()]['idr'] as num).toDouble();
        }
      }
    } catch (e) {
      print('Error fetching crypto ($coinId):$e');
    }
    return null;
  }

  /// Mengambil harga Saham / ETF / Reksadana dari Yahoo Finance
  /// Untuk saham Indonesia (IHSG), tambahkan suffix `.JK` (contoh: `BBCA.JK`, `TLKM.JK`)
  static Future<double?> fetchStockPriceIDR(String symbol) async {
    try {
      final formattedTicker = symbol.contains('.') ? symbol : '$symbol.JK';
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$formattedTicker',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final price = result[0]['meta']['regularMarketPrice'];
          return (price as num).toDouble();
        }
      }
    } catch (e) {
      print('Error fetching stock ($symbol):$e');
    }
    return null;
  }
}