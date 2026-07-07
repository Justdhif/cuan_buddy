import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// State model for budgets response
class BudgetsState {
  final List<dynamic> budgets;
  final bool isLoading;
  final bool isInitialLoad;
  final String? error;
  final String selectedMonthYear; // YYYY-MM

  BudgetsState({
    this.budgets = const [],
    this.isLoading = false,
    this.isInitialLoad = true,
    this.error,
    String? selectedMonthYear,
  }) : selectedMonthYear = selectedMonthYear ??
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  BudgetsState copyWith({
    List<dynamic>? budgets,
    bool? isLoading,
    bool? isInitialLoad,
    String? error,
    String? selectedMonthYear,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: error,
      selectedMonthYear: selectedMonthYear ?? this.selectedMonthYear,
    );
  }
}

class BudgetsNotifier extends StateNotifier<BudgetsState> {
  BudgetsNotifier(this.ref) : super(BudgetsState()) {
    fetchBudgets();
  }

  final Ref ref;

  Future<void> fetchBudgets({String? monthYear}) async {
    final my = monthYear ?? state.selectedMonthYear;
    state = state.copyWith(isLoading: true, error: null, selectedMonthYear: my);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/budgets', queryParameters: {'monthYear': my});
      final data = response.data;
      if (data is List) {
        state = state.copyWith(budgets: data, isLoading: false, isInitialLoad: false);
      } else if (data is Map && data['data'] is List) {
        state = state.copyWith(budgets: data['data'], isLoading: false, isInitialLoad: false);
      } else {
        state = state.copyWith(budgets: [], isLoading: false, isInitialLoad: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false, isInitialLoad: false);
    }
  }

  void selectMonth(String monthYear) {
    fetchBudgets(monthYear: monthYear);
  }

  Future<void> createBudget({
    required String categoryId,
    String? walletId,
    required double limitAmount,
    required String monthYear,
    int periodCount = 1,
    int startDay = 1,
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/budgets', data: {
        'categoryId': categoryId,
        'walletId': walletId,
        'limitAmount': limitAmount,
        'monthYear': monthYear,
        'periodCount': periodCount,
        'startDay': startDay,
      });
      await fetchBudgets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBudget({
    required String id,
    required double limitAmount,
    String? walletId,
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/budgets/$id', data: {
        'limitAmount': limitAmount,
        'walletId': walletId,
      });
      await fetchBudgets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/budgets/$id');
      await fetchBudgets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final budgetsNotifierProvider =
    StateNotifierProvider<BudgetsNotifier, BudgetsState>((ref) {
  return BudgetsNotifier(ref);
});

/// Monthly spending summary for the selected month
final monthlyBudgetSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, double>, String>((ref, monthYear) async {
  final budgetsState = ref.watch(budgetsNotifierProvider);
  if (budgetsState.budgets.isEmpty) {
    return {'totalLimit': 0.0, 'totalSpent': 0.0, 'totalIncome': 0.0};
  }

  final currencyService = ref.watch(currencyServiceProvider);
  final profile = ref.watch(profileProvider);
  final baseCurrency =
      profile.valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;

  double totalLimit = 0;
  double totalSpent = 0;
  double totalIncome = 0;

  for (final b in budgetsState.budgets) {
    final rawL = b['limitAmount'];
    final limit = rawL is num
        ? rawL.toDouble()
        : double.tryParse(rawL?.toString() ?? '0') ?? 0;

    final rawS = b['spentAmount'];
    final spent = rawS is num
        ? rawS.toDouble()
        : double.tryParse(rawS?.toString() ?? '0') ?? 0;

    final rawI = b['incomeAmount'];
    final income = rawI is num
        ? rawI.toDouble()
        : double.tryParse(rawI?.toString() ?? '0') ?? 0;

    final bCurrency = b['currency'] as String? ?? AppConstants.defaultCurrency;

    if (bCurrency == baseCurrency) {
      totalLimit += limit;
      totalSpent += spent;
      totalIncome += income;
    } else {
      final convLimit = await currencyService.convert(limit, bCurrency, baseCurrency);
      final convSpent = await currencyService.convert(spent, bCurrency, baseCurrency);
      final convIncome = await currencyService.convert(income, bCurrency, baseCurrency);
      totalLimit += convLimit;
      totalSpent += convSpent;
      totalIncome += convIncome;
    }
  }

  return {
    'totalLimit': totalLimit,
    'totalSpent': totalSpent,
    'totalIncome': totalIncome,
  };
});

// Keep old provider alias for backward compatibility (used nowhere but just in case)
final convertedBudgetsSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, double>, String>((ref, filter) async {
  return ref.watch(monthlyBudgetSummaryProvider(
    ref.watch(budgetsNotifierProvider).selectedMonthYear,
  ).future);
});
