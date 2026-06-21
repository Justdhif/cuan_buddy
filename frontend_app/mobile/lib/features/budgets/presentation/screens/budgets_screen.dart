import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/sticky_header_delegate.dart';
import '../../../../core/services/currency_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/budgets_provider.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String _statusFilter = 'All'; // 'All', 'On Track', 'Warning', 'Exceeded'
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 200 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsNotifierProvider);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l10n.budgets),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAddBudgetSheet(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetsNotifierProvider.notifier).fetchBudgets(),
        color: AppColors.primary,
        child: _buildBody(context, ref, budgetsState, isDark, currencySymbol),
      ),
      floatingActionButton: _showScrollToTop 
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BudgetsState state, bool isDark, String currencySymbol) {
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

    // Filter logic
    final filteredBudgets = state.budgets.where((b) {
      if (_statusFilter == 'All') return true;
      final rawL = b['limitAmount'];
      final rawR = b['rolloverAmount'];
      final limit = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      final rollover = rawR is num ? rawR.toDouble() : double.tryParse(rawR?.toString() ?? '0') ?? 0;
      final totalLimit = limit + rollover;
      final rawS = b['spentAmount'];
      final spent = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
      final p = totalLimit > 0 ? spent / totalLimit : 0.0;
      
      if (_statusFilter == 'Exceeded') return p >= 1.0;
      if (_statusFilter == 'Warning') return p > 0.7 && p < 1.0;
      if (_statusFilter == 'On Track') return p <= 0.7;
      return true;
    }).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      controller: _scrollController,
      slivers: [
        // Summary Header Card
        SliverToBoxAdapter(
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
                          child: Consumer(
                            builder: (context, ref, child) {
                              final summaryAsync = ref.watch(convertedBudgetsSummaryProvider('All'));
                              return summaryAsync.when(
                                data: (summary) {
                                  final totalLimit = summary['totalLimit'] ?? 0.0;
                                  final totalSpent = summary['totalSpent'] ?? 0.0;
                                  final percentage = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
                                  final safePercentage = percentage.clamp(0.0, 1.0);
                                  
                                  Color progressColor = AppColors.success;
                                  if (safePercentage >= 1.0) {
                                    progressColor = AppColors.danger;
                                  } else if (safePercentage > 0.7) {
                                    progressColor = AppColors.warning;
                                  }

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: 1.0,
                                        strokeWidth: 8,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? AppColors.surfaceDark : const Color(0xFFF0EFF8),
                                        ),
                                      ),
                                      CircularProgressIndicator(
                                        value: safePercentage,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                      ),
                                      Center(
                                        child: Text(
                                          '${(safePercentage * 100).toStringAsFixed(0)}%',
                                          style: AppTypography.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: progressColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const Icon(Icons.error, color: AppColors.danger),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Texts
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final summaryAsync = ref.watch(convertedBudgetsSummaryProvider('All'));
                              return summaryAsync.when(
                                data: (summary) {
                                  final totalLimit = summary['totalLimit'] ?? 0.0;
                                  final totalSpent = summary['totalSpent'] ?? 0.0;
                                  final percentage = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
                                  
                                  Color summaryColor = AppColors.success;
                                  if (percentage >= 1.0) {
                                    summaryColor = AppColors.danger;
                                  } else if (percentage > 0.7) {
                                    summaryColor = AppColors.warning;
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.totalBudget,
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
                                        l10n.spent(fmt.format(totalSpent)),
                                        style: AppTypography.textTheme.labelMedium?.copyWith(
                                          color: summaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const SizedBox(),
                                error: (_, __) => const SizedBox(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

        // Status Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: ['All', 'On Track', 'Warning', 'Exceeded'].asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final isSelected = _statusFilter == status;
                Color statusColor = AppColors.primary;
                if (status == 'On Track') statusColor = AppColors.success;
                if (status == 'Warning') statusColor = AppColors.warning;
                if (status == 'Exceeded') statusColor = AppColors.danger;

                final String translatedStatus = switch (status) {
                  'All' => l10n.all,
                  'On Track' => l10n.onTrack,
                  'Warning' => l10n.warning,
                  'Exceeded' => l10n.exceeded,
                  _ => status,
                };
                
                final String emoji = switch (status) {
                  'All' => '📁',
                  'On Track' => '✅',
                  'Warning' => '⚠️',
                  'Exceeded' => '❌',
                  _ => '📁',
                };

                return Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () {
                      if (!isSelected) setState(() => _statusFilter = status);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? statusColor.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : const Color(0xFFF3F0FF)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? statusColor : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            translatedStatus,
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              color: isSelected ? statusColor : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Budgets List
        if (state.budgets.isEmpty)
          SliverFillRemaining(
            child: AppEmptyState(
              emoji: '📊',
              title: l10n.noBudgetsSet,
              subtitle: l10n.noBudgetsSetSubtitle,
            ),
          )
        else if (filteredBudgets.isEmpty)
          SliverFillRemaining(
            child: AppEmptyState(
              emoji: '🔍',
              title: l10n.noBudgetsFilter(switch (_statusFilter) {
                'All' => l10n.all,
                'On Track' => l10n.onTrack,
                'Warning' => l10n.warning,
                'Exceeded' => l10n.exceeded,
                _ => _statusFilter,
              }),
              subtitle: l10n.tryChangingFilter,
            ),
          )
        else ...[
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
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.shrink(),
          ),
        ]
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.budget, required this.isDark, required this.currencySymbol});
  final dynamic budget;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final tx = budget as Map<String, dynamic>;
    final rawL = tx['limitAmount'];
    final limitAmount = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
    final rawS = tx['spentAmount'];
    final spentAmount = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
    final rawR = tx['rolloverAmount'];
    final rolloverAmount = rawR is num ? rawR.toDouble() : double.tryParse(rawR?.toString() ?? '0') ?? 0;
    final totalLimitAmount = limitAmount + rolloverAmount;
    final isRecurring = tx['isRecurring'] == true;
    
    final categoryName = tx['category']?['name'] as String? ?? tx['categoryName'] as String? ?? l10n.budget;
    final categoryEmoji = tx['category']?['emojiIcon'] as String? ?? tx['category']?['emoji'] as String? ?? tx['categoryEmoji'] as String? ?? '📦';
    final monthYear = tx['monthYear'] as String? ?? '';

    final percentage = totalLimitAmount > 0 ? (spentAmount / totalLimitAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);

    Color progressColor = AppColors.success;
    if (safePercentage >= 1.0) {
      progressColor = AppColors.danger;
    } else if (safePercentage > 0.7) {
      progressColor = AppColors.warning;
    }

    final txCurrency = tx['currency'] as String? ?? AppConstants.defaultCurrency;
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);

    final fmtOriginal = NumberFormat.currency(
      locale: 'en_US',
      symbol: txCurrencySymbol,
      decimalDigits: 0,
    );
    
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () => context.push('/budgets/detail', extra: tx),
      child: Container(
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
              if (safePercentage <= 0.5) const Text(' 🏆', style: TextStyle(fontSize: 16)),
              if (safePercentage > 0.8 && safePercentage < 1.0) const Text(' 🔥', style: TextStyle(fontSize: 16)),
              if (safePercentage >= 1.0) const Text(' 🚨', style: TextStyle(fontSize: 16)),
              if (isRecurring) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.repeat_rounded, size: 14, color: AppColors.primary),
                ),
              ],
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    showAddBudgetSheet(context, budget: tx);
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Budget?'),
                        content: const Text('Are you sure you want to delete this budget?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(budgetsNotifierProvider.notifier).deleteBudget(tx['id']);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_rounded, size: 20, color: AppColors.danger),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rolloverAmount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${fmt.format(rolloverAmount)} Rollover',
                style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txCurrency == currencyCode ? fmt.format(spentAmount) : fmtOriginal.format(spentAmount),
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (txCurrency != AppConstants.defaultCurrency)
                    Consumer(
                      builder: (context, ref, _) {
                        final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
                        if (txCurrency == currencyCode) return const SizedBox.shrink();
                        
                        final convertedAsync = ref.watch(convertedAmountProvider(ConversionParams(
                          amount: spentAmount,
                          from: txCurrency,
                          to: currencyCode,
                        )));
                        return convertedAsync.when(
                          data: (converted) => Text(
                            '≈ ${fmt.format(converted)}',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          loading: () => const SizedBox(width: 20, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const SizedBox(),
                        );
                      },
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.of_(txCurrency == currencyCode ? fmt.format(totalLimitAmount) : fmtOriginal.format(totalLimitAmount)),
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (txCurrency != AppConstants.defaultCurrency)
                    Consumer(
                      builder: (context, ref, _) {
                        final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
                        if (txCurrency == currencyCode) return const SizedBox.shrink();
                        
                        final convertedAsync = ref.watch(convertedAmountProvider(ConversionParams(
                          amount: totalLimitAmount,
                          from: txCurrency,
                          to: currencyCode,
                        )));
                        return convertedAsync.when(
                          data: (converted) => Text(
                            '≈ ${fmt.format(converted)}',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          loading: () => const SizedBox(width: 20, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const SizedBox(),
                        );
                      },
                    ),
                ],
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
                  l10n.budgetExceeded,
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
    ));
  }
}

