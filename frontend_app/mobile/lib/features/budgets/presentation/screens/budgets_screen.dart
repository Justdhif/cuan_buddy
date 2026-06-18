import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/sticky_header_delegate.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/budgets_provider.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String _statusFilter = 'All'; // 'All', 'On Track', 'Warning', 'Exceeded'

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsNotifierProvider);
    final currencyCode = ref.watch(profileProvider).value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAddBudgetSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetsNotifierProvider.notifier).fetchBudgets(),
        color: AppColors.primary,
        child: _buildBody(context, budgetsState, isDark, currencySymbol),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BudgetsState state, bool isDark, String currencySymbol) {
    if (state.isLoading && state.budgets.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && state.budgets.isEmpty) {
      return AppErrorState(message: state.error!);
    }

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    // Calculate Summary
    double totalLimit = 0;
    double totalSpent = 0;

    for (final b in state.budgets) {
      final rawL = b['limitAmount'];
      totalLimit += rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      final rawS = b['spentAmount'];
      totalSpent += rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
    }
    
    final totalPercentage = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
    final safeTotalPercentage = totalPercentage.clamp(0.0, 1.0);
    
    Color summaryColor = AppColors.success;
    if (safeTotalPercentage >= 1.0) {
      summaryColor = AppColors.danger;
    } else if (safeTotalPercentage > 0.7) {
      summaryColor = AppColors.warning;
    }

    // Filter logic
    final filteredBudgets = state.budgets.where((b) {
      if (_statusFilter == 'All') return true;
      final rawL = b['limitAmount'];
      final limit = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      final rawS = b['spentAmount'];
      final spent = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
      final p = limit > 0 ? spent / limit : 0.0;
      
      if (_statusFilter == 'Exceeded') return p >= 1.0;
      if (_statusFilter == 'Warning') return p > 0.7 && p < 1.0;
      if (_statusFilter == 'On Track') return p <= 0.7;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Summary Header Card
        if (state.budgets.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              minHeight: 140, // Match typical card height
              maxHeight: 140,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Circular Progress
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: safeTotalPercentage),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(summaryColor),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${(safeTotalPercentage * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: summaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Budget',
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmt.format(totalLimit),
                                style: AppTypography.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Spent: ${fmt.format(totalSpent)}',
                                style: AppTypography.textTheme.labelMedium?.copyWith(
                                  color: summaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Status Filter Chips
        if (state.budgets.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: ['All', 'On Track', 'Warning', 'Exceeded'].map((status) {
                  final isSelected = _statusFilter == status;
                  Color? statusColor;
                  if (status == 'On Track') statusColor = AppColors.success;
                  if (status == 'Warning') statusColor = AppColors.warning;
                  if (status == 'Exceeded') statusColor = AppColors.danger;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = status);
                      },
                      selectedColor: (statusColor ?? AppColors.primary).withValues(alpha: isDark ? 0.3 : 0.1),
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? (statusColor ?? AppColors.primary)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      side: BorderSide(
                        color: isSelected 
                            ? (statusColor ?? AppColors.primary)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Budgets List
        if (state.budgets.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              emoji: '📊',
              title: 'No Budgets Set',
              subtitle: 'Tap + to set your first monthly spending limit.',
            ),
          )
        else if (filteredBudgets.isEmpty)
          SliverFillRemaining(
            child: AppEmptyState(
              emoji: '🔍',
              title: 'No $_statusFilter Budgets',
              subtitle: 'Try changing the filter.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _BudgetCard(
                    budget: filteredBudgets[index],
                    isDark: isDark,
                    currencySymbol: currencySymbol,
                  );
                },
                childCount: filteredBudgets.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.isDark, required this.currencySymbol});
  final dynamic budget;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final tx = budget as Map<String, dynamic>;
    final rawL = tx['limitAmount'];
    final limitAmount = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
    final rawS = tx['spentAmount'];
    final spentAmount = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
    final categoryName = tx['category']?['name'] as String? ?? tx['categoryName'] as String? ?? 'Budget';
    final categoryEmoji = tx['category']?['emoji'] as String? ?? tx['categoryEmoji'] as String? ?? '📦';
    final monthYear = tx['monthYear'] as String? ?? '';

    final percentage = limitAmount > 0 ? (spentAmount / limitAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);

    Color progressColor = AppColors.success;
    if (safePercentage >= 1.0) {
      progressColor = AppColors.danger;
    } else if (safePercentage > 0.7) {
      progressColor = AppColors.warning;
    }

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: safePercentage >= 1.0
              ? AppColors.danger.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: safePercentage >= 1.0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(categoryEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : const Color(0xFFF0EFF8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthYear,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmt.format(spentAmount),
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'of ${fmt.format(limitAmount)}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            // Animated Progress Bar
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: safePercentage),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
          ),
          if (safePercentage >= 1.0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  'Budget exceeded!',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
