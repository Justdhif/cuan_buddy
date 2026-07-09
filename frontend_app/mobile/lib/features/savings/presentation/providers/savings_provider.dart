import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/providers/widget_preferences_provider.dart';
import '../../../../core/services/widget_service.dart';

class SavingsState {
  final List<dynamic> goals;
  final bool isLoading;
  final bool isInitialLoad;
  final String? error;

  SavingsState({
    this.goals = const [],
    this.isLoading = false,
    this.isInitialLoad = true,
    this.error,
  });

  SavingsState copyWith({
    List<dynamic>? goals,
    bool? isLoading,
    bool? isInitialLoad,
    String? error,
  }) {
    return SavingsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: error,
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier(this.ref) : super(SavingsState()) {
    fetchGoals();
  }

  final Ref ref;

  void _updateWidgetIfSelected() {
    try {
      final selectedGoalId = ref.read(selectedSavingsWidgetIdProvider);
      if (selectedGoalId != null) {
        final goal = state.goals.firstWhere((g) => g['id'] == selectedGoalId);
        final rawT = goal['targetAmount'];
        final rawS = goal['savedAmount'];
        final target = rawT is num
            ? rawT.toDouble()
            : double.tryParse(rawT?.toString() ?? '0') ?? 0;
        final saved = rawS is num
            ? rawS.toDouble()
            : double.tryParse(rawS?.toString() ?? '0') ?? 0;
        final profile = ref.read(profileProvider).valueOrNull;
        final currency = profile?['currency'] as String? ?? AppConstants.defaultCurrency;
        final emoji = goal['icon'] as String? ?? '🎯';
        final name = goal['name'] as String? ?? 'Savings Goal';

        WidgetService.updateSavingsWidgetData(
          emoji: emoji,
          name: name,
          savedAmount: saved,
          targetAmount: target,
          currency: currency,
        );
      }
    } catch (e) {
      // Goal not found or error parsing
    }
  }

  Future<void> fetchGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/goals');
      final data = response.data;
      if (data is List) {
        state = state.copyWith(goals: data, isLoading: false, isInitialLoad: false);
      } else if (data is Map && data['data'] is List) {
        state = state.copyWith(goals: data['data'], isLoading: false, isInitialLoad: false);
      } else {
        state = state.copyWith(goals: [], isLoading: false, isInitialLoad: false);
      }
      _updateWidgetIfSelected();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false, isInitialLoad: false);
    }
  }

  Future<void> createGoal({
    required String name,
    String? walletId,
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
      if (walletId != null) data['walletId'] = walletId;
      if (currentAmount != null) data['currentAmount'] = currentAmount;
      if (targetDate != null) data['targetDate'] = targetDate;

      await dio.post('/goals', data: data);
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBalance(String id, double newAmount) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/goals/$id', data: {
        'currentAmount': newAmount,
      });
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/goals/$id', data: data);
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/goals/$id');
      await fetchGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final savingsNotifierProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier(ref);
});

final convertedSavingsSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, filter) async {
  final savingsState = ref.watch(savingsNotifierProvider);
  if (savingsState.goals.isEmpty) {
    return {'totalTarget': 0.0, 'totalSaved': 0.0};
  }

  final currencyService = ref.watch(currencyServiceProvider);
  final profile = ref.watch(profileProvider);
  final baseCurrency = profile.valueOrNull?['currency'] as String? ??
      AppConstants.defaultCurrency;

  double totalTarget = 0;
  double totalSaved = 0;

  for (final goal in savingsState.goals) {
    if (filter == 'In Progress' && goal['status'] == 'completed') continue;
    if (filter == 'Completed' && goal['status'] != 'completed') continue;

    final gCurrency =
        goal['currency'] as String? ?? AppConstants.defaultCurrency;
    final rawT = goal['targetAmount'];
    final target = rawT is num
        ? rawT.toDouble()
        : double.tryParse(rawT?.toString() ?? '0') ?? 0;
    final rawC = goal['currentAmount'];
    final current = rawC is num
        ? rawC.toDouble()
        : double.tryParse(rawC?.toString() ?? '0') ?? 0;

    if (gCurrency == baseCurrency) {
      totalTarget += target;
      totalSaved += current;
    } else {
      final convTarget =
          await currencyService.convert(target, gCurrency, baseCurrency);
      final convSaved =
          await currencyService.convert(current, gCurrency, baseCurrency);
      totalTarget += convTarget;
      totalSaved += convSaved;
    }
  }

  return {'totalTarget': totalTarget, 'totalSaved': totalSaved};
});
