import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

import '../../../../core/services/currency_service.dart';

final analyticsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final currencyService = ref.watch(currencyServiceProvider);
  
  // We need to get the user's base currency to convert transactions properly
  String baseCurrency = 'IDR'; // fallback
  try {
    final profileRes = await dio.get('/profiles/me');
    if (profileRes.data != null && profileRes.data['currency'] != null) {
      baseCurrency = profileRes.data['currency'];
    }
  } catch (_) {}

  // Fetch all transactions to calculate the accurate converted summary
  final txRes = await dio.get('/transactions', queryParameters: {'limit': 10000});
  final txData = txRes.data;
  List txList = [];
  if (txData is List) txList = txData;
  else if (txData is Map && txData['data'] is List) txList = txData['data'];

  double totalIncome = 0;
  double totalExpense = 0;

  for (var tx in txList) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['type'];
    final txCurrency = tx['currency'] ?? baseCurrency;

    final convertedAmount = await currencyService.convert(amount, txCurrency, baseCurrency);

    if (type == 'income') totalIncome += convertedAmount;
    if (type == 'expense') totalExpense += convertedAmount;
  }

  final balance = totalIncome - totalExpense;
  return {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'balance': balance,
  };
});

final financialHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/analytics/financial-health');
  return response.data as Map<String, dynamic>;
});

final recentTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/transactions', queryParameters: {'limit': 5});
  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});
