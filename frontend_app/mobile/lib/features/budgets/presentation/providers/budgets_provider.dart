import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// State model for budgets response
class BudgetsState {
  final List<dynamic> budgets;
  final bool isLoading;
  final String? error;

  BudgetsState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetsState copyWith({
    List<dynamic>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BudgetsNotifier extends StateNotifier<BudgetsState> {
  BudgetsNotifier(this.ref) : super(BudgetsState()) {
    fetchBudgets();
  }

  final Ref ref;

  Future<void> fetchBudgets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/budgets');
      final data = response.data;
      if (data is List) {
        state = state.copyWith(budgets: data, isLoading: false);
      } else if (data is Map && data['data'] is List) {
        state = state.copyWith(budgets: data['data'], isLoading: false);
      } else {
        state = state.copyWith(budgets: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createBudget({
    required String categoryId,
    required double limitAmount,
    required String monthYear,
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/budgets', data: {
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'monthYear': monthYear,
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
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/budgets/$id', data: {
        'limitAmount': limitAmount,
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

final convertedBudgetsSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, filter) async {
  final budgetsState = ref.watch(budgetsNotifierProvider);
  if (budgetsState.budgets.isEmpty)
    return {'totalLimit': 0.0, 'totalSpent': 0.0};

  final currencyService = ref.watch(currencyServiceProvider);
  final profile = ref.watch(profileProvider);
  final baseCurrency = profile.valueOrNull?['currency'] as String? ??
      AppConstants.defaultCurrency;

  double totalLimit = 0;
  double totalSpent = 0;

  for (final b in budgetsState.budgets) {
    final rawL = b['limitAmount'];
    final rawR = b['rolloverAmount'];
    final limit = rawL is num
        ? rawL.toDouble()
        : double.tryParse(rawL?.toString() ?? '0') ?? 0;
    final rollover = rawR is num
        ? rawR.toDouble()
        : double.tryParse(rawR?.toString() ?? '0') ?? 0;
    final tL = limit + rollover;

    final rawS = b['spentAmount'];
    final spent = rawS is num
        ? rawS.toDouble()
        : double.tryParse(rawS?.toString() ?? '0') ?? 0;

    if (filter != 'All') {
      final p = tL > 0 ? spent / tL : 0.0;
      if (filter == 'Exceeded' && p < 1.0) continue;
      if (filter == 'Warning' && (p <= 0.7 || p >= 1.0)) continue;
      if (filter == 'On Track' && p > 0.7) continue;
    }

    final bCurrency = b['currency'] as String? ?? AppConstants.defaultCurrency;

    if (bCurrency == baseCurrency) {
      totalLimit += tL;
      totalSpent += spent;
    } else {
      final convLimit =
          await currencyService.convert(tL, bCurrency, baseCurrency);
      final convSpent =
          await currencyService.convert(spent, bCurrency, baseCurrency);
      totalLimit += convLimit;
      totalSpent += convSpent;
    }
  }

  return {'totalLimit': totalLimit, 'totalSpent': totalSpent};
});
