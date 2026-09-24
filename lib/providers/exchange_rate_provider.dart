import 'package:flutter/foundation.dart';

import '../services/exchange_rate_service.dart';

class ExchangeRateProvider extends ChangeNotifier {
  double _rate = ExchangeRateService.fallbackRate;
  bool _isLoading = false;
  DateTime? _updatedAt;

  double get rate => _rate;
  bool get isLoading => _isLoading;
  DateTime? get updatedAt => _updatedAt;

  ExchangeRateProvider() {
    refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    _rate = await ExchangeRateService.fetchUsdToIdrRate();
    _updatedAt = DateTime.now();

    _isLoading = false;
    notifyListeners();
  }
}
