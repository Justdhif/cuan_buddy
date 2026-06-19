import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService(Dio());
});

class CurrencyService {
  final Dio _dio;
  static const String _ratesKeyPrefix = 'exchange_rates_';
  static const String _lastFetchKeyPrefix = 'exchange_rates_date_';

  CurrencyService(this._dio);

  Future<Map<String, dynamic>?> getRates(String baseCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_ratesKeyPrefix$baseCurrency';
    final dateKey = '$_lastFetchKeyPrefix$baseCurrency';

    final lastFetch = prefs.getString(dateKey);
    final cachedRates = prefs.getString(cacheKey);

    // If we have cached rates and they are less than 24 hours old, use them
    if (lastFetch != null && cachedRates != null) {
      final fetchDate = DateTime.parse(lastFetch);
      if (DateTime.now().difference(fetchDate).inHours < 24) {
        return jsonDecode(cachedRates);
      }
    }

    // Otherwise, fetch from API
    try {
      final response = await _dio.get('https://open.er-api.com/v6/latest/$baseCurrency');
      if (response.statusCode == 200 && response.data['result'] == 'success') {
        final rates = response.data['rates'] as Map<String, dynamic>;
        
        // Cache the result
        await prefs.setString(cacheKey, jsonEncode(rates));
        await prefs.setString(dateKey, DateTime.now().toIso8601String());
        
        return rates;
      }
    } catch (e) {
      // If network fails, return cached rates if available
      if (cachedRates != null) {
        return jsonDecode(cachedRates);
      }
    }
    return null;
  }

  Future<double> convert(double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;

    // We fetch rates based on the `fromCurrency`
    final rates = await getRates(fromCurrency);
    if (rates != null && rates.containsKey(toCurrency)) {
      final rate = (rates[toCurrency] as num).toDouble();
      return amount * rate;
    }
    
    // If exact base fails, try reverse
    final reverseRates = await getRates(toCurrency);
    if (reverseRates != null && reverseRates.containsKey(fromCurrency)) {
      final reverseRate = (reverseRates[fromCurrency] as num).toDouble();
      return amount / reverseRate;
    }

    // If both fail, return original amount as fallback
    return amount;
  }
}

class ConversionParams {
  final double amount;
  final String from;
  final String to;

  const ConversionParams({
    required this.amount,
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversionParams &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => amount.hashCode ^ from.hashCode ^ to.hashCode;
}

final convertedAmountProvider = FutureProvider.family<double, ConversionParams>((ref, params) async {
  final service = ref.watch(currencyServiceProvider);
  return await service.convert(params.amount, params.from, params.to);
});
