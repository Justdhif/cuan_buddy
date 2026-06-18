import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

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
      
      final summaryRes = await dio.get('/analytics/summary');
      final spendingRes = await dio.get('/analytics/spending-category');
      final trendRes = await dio.get('/analytics/monthly-trend');
      final healthRes = await dio.get('/analytics/financial-health');

      state = state.copyWith(
        summary: summaryRes.data is Map ? summaryRes.data as Map<String, dynamic> : {},
        spendingByCategory: spendingRes.data is List ? spendingRes.data as List : [],
        monthlyTrend: trendRes.data is List ? trendRes.data as List : [],
        financialHealth: healthRes.data is Map ? healthRes.data as Map<String, dynamic> : {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final analyticsNotifierProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});
