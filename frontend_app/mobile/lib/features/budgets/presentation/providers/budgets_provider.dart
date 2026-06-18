import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

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
}

final budgetsNotifierProvider = StateNotifierProvider<BudgetsNotifier, BudgetsState>((ref) {
  return BudgetsNotifier(ref);
});
