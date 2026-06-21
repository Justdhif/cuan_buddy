import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final budgetTransactionsProvider = FutureProvider.family<List<dynamic>, String>((ref, categoryId) async {
  final dio = ref.watch(dioClientProvider).dio;
  
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final response = await dio.get('/transactions', queryParameters: {
    'categoryId': categoryId,
    'startDate': start.toUtc().toIso8601String(),
    'endDate': end.toUtc().toIso8601String(),
    'limit': 200,
  });

  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});

class BudgetDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> budget;
  
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final category = budget['category'] as Map<String, dynamic>? ?? {};
    final categoryName = category['name'] as String? ?? 'Unknown Category';
    final categoryEmoji = category['icon'] as String? ?? '💰';
    final categoryId = category['id'] as String? ?? '';
    
    final spentAmount = (budget['spentAmount'] as num?)?.toDouble() ?? 0.0;
    final limitAmount = (budget['limitAmount'] as num?)?.toDouble() ?? 0.0;
    final rolloverAmount = (budget['rolloverAmount'] as num?)?.toDouble() ?? 0.0;
    final totalLimitAmount = limitAmount + rolloverAmount;
    
    final safePercentage = totalLimitAmount > 0 ? (spentAmount / totalLimitAmount).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor = AppColors.success;
    if (safePercentage >= 1.0) {
      progressColor = AppColors.danger;
    } else if (safePercentage > 0.8) {
      progressColor = AppColors.warning;
    }

    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(categoryEmoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (rolloverAmount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${fmt.format(rolloverAmount)} Rollover',
                                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fmt.format(spentAmount),
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.of_(fmt.format(totalLimitAmount)),
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: safePercentage,
                        backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Transactions this month',
                style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          Consumer(
            builder: (context, ref, _) {
              if (categoryId.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
              final txAsync = ref.watch(budgetTransactionsProvider(categoryId));
              
              return txAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No transactions found for this category.',
                            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index];
                        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                        final dateStr = tx['date'] as String?;
                        final date = dateStr != null ? DateTime.tryParse(dateStr) : DateTime.now();
                        final note = tx['note'] as String? ?? '';
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_downward_rounded, color: AppColors.danger, size: 20),
                            ),
                          ),
                          title: Text(
                            note.isNotEmpty ? note : categoryName,
                            style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(date ?? DateTime.now()),
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          trailing: Text(
                            fmt.format(amount),
                            style: AppTypography.textTheme.bodyLarge?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error: $e', style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
