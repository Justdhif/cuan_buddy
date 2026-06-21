import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

class SavingsState {
  final List<dynamic> goals;
  final bool isLoading;
  final String? error;

  SavingsState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsState copyWith({
    List<dynamic>? goals,
    bool? isLoading,
    String? error,
  }) {
    return SavingsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier(this.ref) : super(SavingsState()) {
    fetchGoals();
  }

  final Ref ref;

  Future<void> fetchGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/goals');
      final data = response.data;
      if (data is List) {
        state = state.copyWith(goals: data, isLoading: false);
      } else if (data is Map && data['data'] is List) {
        state = state.copyWith(goals: data['data'], isLoading: false);
      } else {
        state = state.copyWith(goals: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    double? currentAmount,
    String? targetDate,
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final data = <String, dynamic>{
        'name': name,
        'targetAmount': targetAmount,
      };
      if (currentAmount != null) data['currentAmount'] = currentAmount;
      if (targetDate != null) data['targetDate'] = targetDate;

      await dio.post('/goals', data: data);
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBalance(String slug, double newAmount) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/goals/$slug', data: {
        'currentAmount': newAmount,
      });
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
  Future<void> updateGoal(String slug, Map<String, dynamic> data) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/goals/$slug', data: data);
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteGoal(String slug) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/goals/$slug');
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final savingsNotifierProvider = StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier(ref);
});
