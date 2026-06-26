import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/currency_service.dart';

class AnalyticsState {
  final Map<String, dynamic> summary;
  final List<dynamic> spendingByCategory;
  final List<dynamic> monthlyTrend;
  final Map<String, dynamic> financialHealth;
  final bool isLoading;
  final String? error;

  AnalyticsState({
    this.summary = const {},
    this.spendingByCategory = const [],
    this.monthlyTrend = const [],
    this.financialHealth = const {},
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    Map<String, dynamic>? summary,
    List<dynamic>? spendingByCategory,
    List<dynamic>? monthlyTrend,
    Map<String, dynamic>? financialHealth,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      summary: summary ?? this.summary,
      spendingByCategory: spendingByCategory ?? this.spendingByCategory,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      financialHealth: financialHealth ?? this.financialHealth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this.ref) : super(AnalyticsState()) {
    fetchAllAnalytics();
  }

  final Ref ref;

  Future<void> fetchAllAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currencyService = ref.read(currencyServiceProvider);

      // We need to get the user's base currency to convert transactions properly
      String baseCurrency = 'IDR'; // fallback
      try {
        final profileRes = await dio.get('/profiles/me');
        if (profileRes.data != null && profileRes.data['currency'] != null) {
          baseCurrency = profileRes.data['currency'];
        }
      } catch (_) {}

      // Fetch all transactions to calculate the accurate converted summary
      final txRes =
          await dio.get('/transactions', queryParameters: {'limit': 10000});
      final txData = txRes.data;
      List txList = [];
      if (txData is List) {
        txList = txData;
      } else if (txData is Map && txData['data'] is List) {
        txList = txData['data'];
      }

      double totalIncome = 0;
      double totalExpense = 0;

      for (var tx in txList) {
        final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
        final type = tx['type'];
        final txCurrency = tx['currency'] ?? baseCurrency;

        final convertedAmount =
            await currencyService.convert(amount, txCurrency, baseCurrency);

        if (type == 'income') totalIncome += convertedAmount;
        if (type == 'expense') totalExpense += convertedAmount;
      }

      final balance = totalIncome - totalExpense;
      final customSummary = {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': balance,
      };

      final spendingRes = await dio.get('/analytics/spending-category');
      final trendRes = await dio.get('/analytics/monthly-trend');
      final healthRes = await dio.get('/analytics/financial-health');

      state = state.copyWith(
        summary: customSummary,
        spendingByCategory:
            spendingRes.data is List ? spendingRes.data as List : [],
        monthlyTrend: trendRes.data is List ? trendRes.data as List : [],
        financialHealth:
            healthRes.data is Map ? healthRes.data as Map<String, dynamic> : {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final analyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});
