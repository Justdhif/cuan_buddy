import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';
class TransactionFilterState {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final bool isExpanded;
  final String? type;
  final String? categoryId;

  TransactionFilterState({
    required this.currentMonth,
    required this.selectedDate,
    this.isExpanded = false,
    this.type,
    this.categoryId,
  });

  TransactionFilterState copyWith({
    DateTime? currentMonth,
    DateTime? selectedDate,
    bool? isExpanded,
    String? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategoryId = false,
  }) {
    return TransactionFilterState(
      currentMonth: currentMonth ?? this.currentMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      isExpanded: isExpanded ?? this.isExpanded,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier()
      : super(TransactionFilterState(
          currentMonth: DateTime.now(),
          selectedDate: DateTime.now(),
          isExpanded: false,
        ));

  void toggleExpand() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void updateMonth(DateTime month) {
    state = state.copyWith(
      currentMonth: month,
      selectedDate: month,
    );
  }

  void updateWeek(int offsetDays) {
    final newDate = state.selectedDate.add(Duration(days: offsetDays));
    state = state.copyWith(
      selectedDate: newDate,
      currentMonth: DateTime(newDate.year, newDate.month, 1),
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      currentMonth: DateTime(date.year, date.month, 1),
    );
  }

  void setType(String? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
        categoryId: categoryId, clearCategoryId: categoryId == null);
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
        (ref) {
  return TransactionFilterNotifier();
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/categories', queryParameters: {'limit': 50});
  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});

final calendarSummaryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final filter = ref.watch(transactionFilterProvider);
  final dio = ref.watch(dioClientProvider).dio;

  final response =
      await dio.get('/transactions/calendar-summary', queryParameters: {
    'month': filter.currentMonth.month,
    'year': filter.currentMonth.year,
  });

  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});

final allTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final filter = ref.watch(transactionFilterProvider);
  final dio = ref.watch(dioClientProvider).dio;

  final query = <String, dynamic>{
    'limit': 100, // Fetch up to 100 for the day
  };

  // Always filter by selectedDate
  final start = DateTime(filter.selectedDate.year, filter.selectedDate.month,
      filter.selectedDate.day);
  final end = DateTime(filter.selectedDate.year, filter.selectedDate.month,
      filter.selectedDate.day, 23, 59, 59);
  query['startDate'] = start.toUtc().toIso8601String();
  query['endDate'] = end.toUtc().toIso8601String();

  if (filter.type != null) {
    query['type'] = filter.type;
  }
  if (filter.categoryId != null) {
    query['categoryId'] = filter.categoryId;
  }

  final response = await dio.get('/transactions', queryParameters: query);
  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});

final monthlySummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final filter = ref.watch(transactionFilterProvider);
  final dio = ref.watch(dioClientProvider).dio;
  final currencyCode =
      ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
          'IDR';
  final currencyService = ref.watch(currencyServiceProvider);

  final startOfMonth =
      DateTime(filter.currentMonth.year, filter.currentMonth.month, 1);
  final endOfMonth = DateTime(
      filter.currentMonth.year, filter.currentMonth.month + 1, 0, 23, 59, 59);

  final query = <String, dynamic>{
    'limit': 1000,
    'startDate': startOfMonth.toUtc().toIso8601String(),
    'endDate': endOfMonth.toUtc().toIso8601String(),
  };

  if (filter.categoryId != null) {
    query['categoryId'] = filter.categoryId;
  }

  final response = await dio.get('/transactions', queryParameters: query);
  final data = response.data;
  List txList = [];
  if (data is List) {
    txList = data;
  } else if (data is Map && data['data'] is List) {
    txList = data['data'];
  }

  double totalIncome = 0;
  double totalExpense = 0;
  for (var tx in txList) {
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
    final wallet = tx['wallet'];
    final txCurrency = (wallet is Map ? wallet['currency'] as String? : null) ??
        tx['currency'] as String? ??
        'IDR';
    double converted = amount;
    if (txCurrency != currencyCode) {
      converted = await currencyService.convert(amount, txCurrency, currencyCode);
    }

    if (isIncome) {
      totalIncome += converted;
    } else {
      totalExpense += converted;
    }
  }

  return {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
  };
});

final transactionListBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final currencyCode =
      ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? 'IDR';
  final currencyService = ref.watch(currencyServiceProvider);

  double totalIncome = 0;
  double totalExpense = 0;

  for (var tx in transactions) {
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

    final wallet = tx['wallet'];
    final txCurrency = (wallet is Map ? wallet['currency'] as String? : null) ??
        tx['currency'] as String? ??
        'IDR';
    double converted = amount;
    if (txCurrency != currencyCode) {
      converted = await currencyService.convert(amount, txCurrency, currencyCode);
    }

    if (isIncome) {
      totalIncome += converted;
    } else {
      totalExpense += converted;
    }
  }

  return totalIncome - totalExpense;
});
