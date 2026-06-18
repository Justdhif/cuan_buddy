import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

final analyticsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/analytics/summary');
  return response.data as Map<String, dynamic>;
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
