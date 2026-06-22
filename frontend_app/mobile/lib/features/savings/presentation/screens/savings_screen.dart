import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/services/currency_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/savings_provider.dart';
import '../widgets/add_savings_sheet.dart';
import '../widgets/top_up_sheet.dart';
import '../widgets/savings_gamification_widget.dart';
import '../../../profile/presentation/widgets/single_table_import_sheet.dart';
import '../../../profile/data/services/backup_worker.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String _statusFilter = 'All'; // 'All', 'In Progress', 'Completed'
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsNotifierProvider);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          child: Text(l10n.savingsGoals),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAddSavingsSheet(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'export') {
                ref.read(backupWorkerProvider).runBackupProcess(tables: ['savings_goals']);
              } else if (value == 'import') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const SingleTableImportSheet(tableName: 'savings_goals'),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.exportData),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.importData),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(savingsNotifierProvider.notifier).fetchGoals(),
        color: AppColors.primary,
        child: _buildBody(context, ref, savingsState, isDark, currencySymbol),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SavingsState state, bool isDark, String currencySymbol) {
    if (state.isLoading && state.goals.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && state.goals.isEmpty) {
      return AppErrorState(message: state.error!);
    }

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    // Calculate Completed Goals
    int completedGoals = 0;

    for (final g in state.goals) {
      final rawT = g['targetAmount'];
      final t = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      final rawC = g['currentAmount'];
      final c = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
      if (g['status'] == 'completed' || (t > 0 && c >= t)) {
        completedGoals++;
      }
    }

    // Filter goals
    final filteredGoals = state.goals.where((g) {
      if (_statusFilter == 'All') return true;
      final rawT = g['targetAmount'];
      final t = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      final rawC = g['currentAmount'];
      final c = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
      final isCompleted = g['status'] == 'completed' || (t > 0 && c >= t);
      
      if (_statusFilter == 'Completed') return isCompleted;
      if (_statusFilter == 'In Progress') return !isCompleted;
      return true;
    }).toList();

    final viewportHeight = MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 80;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      controller: _scrollController,
      slivers: [
        // Summary Header
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF6B58E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final summaryAsync = ref.watch(convertedSavingsSummaryProvider('All'));
                      return summaryAsync.when(
                        data: (summary) {
                          final totalSaved = summary['totalSaved'] ?? 0.0;
                          final totalTarget = summary['totalTarget'] ?? 0.0;
                          return Column(
                            children: [
                              Text(
                                l10n.totalSaved,
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmt.format(totalSaved),
                                style: AppTypography.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    l10n.goals,
                                    state.goals.length.toString(),
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                                  _buildSummaryItem(
                                    l10n.completed,
                                    completedGoals.toString(),
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                                  _buildSummaryItem(
                                    l10n.remaining,
                                    fmt.format(totalTarget > totalSaved ? totalTarget - totalSaved : 0),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                ),
              ),
            ),
        ),

        // Status Filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: ['All', 'In Progress', 'Completed'].map((status) {
                  final isSelected = _statusFilter == status;
                  final String translatedStatus = switch (status) {
                    'All' => l10n.all,
                    'In Progress' => l10n.inProgress,
                    'Completed' => l10n.completed,
                    _ => status,
                  };

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          translatedStatus,
                          textAlign: TextAlign.center,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            color: isSelected 
                                ? Colors.white 
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Goals List
        if (state.goals.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: AppEmptyState(
                emoji: '🎯',
                title: l10n.noSavingsGoals,
                subtitle: l10n.noSavingsGoalsSubtitle,
              ),
            ),
          )
        else if (filteredGoals.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: AppEmptyState(
                emoji: '🔍',
                title: l10n.noGoalsFilter(switch (_statusFilter) {
                  'All' => l10n.all,
                  'In Progress' => l10n.inProgress,
                  'Completed' => l10n.completed,
                  _ => _statusFilter,
                }),
                subtitle: l10n.tryChangingFilter,
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final goal = filteredGoals[index];
                  return _buildGoalCard(context, goal, currencySymbol);
                },
                childCount: filteredGoals.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ]
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal, String currencySymbol) {
    final l10n = AppLocalizations.of(context);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final name = goal['name'] as String? ?? l10n.unnamedGoal;
    final rawT = goal['targetAmount'];
    final targetAmount = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
    final rawC = goal['currentAmount'];
    final currentAmount = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
    final targetDateStr = goal['targetDate'] as String?;
    
    final percentage = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);
    final isCompleted = goal['status'] == 'completed' || safePercentage >= 1.0;

    final goalCurrency = goal['currency'] as String? ?? AppConstants.defaultCurrency;
    final goalCurrencySymbol = AppConstants.getCurrencySymbol(goalCurrency);

    final fmtOriginal = NumberFormat.currency(
      locale: 'en_US',
      symbol: goalCurrencySymbol,
      decimalDigits: 0,
    );

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    // Countdown Logic
    String? countdownText;
    Color? countdownColor;
    if (!isCompleted && targetDateStr != null) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diff = targetDate.difference(now).inDays;
        
        if (diff < 0) {
          countdownText = l10n.daysOverdue(diff.abs());
          countdownColor = AppColors.danger;
        } else if (diff == 0) {
          countdownText = l10n.dueToday;
          countdownColor = AppColors.warning;
        } else {
          countdownText = l10n.daysLeft(diff);
          countdownColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted 
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.completedBadge,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (countdownText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (countdownColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdownText,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: countdownColor ?? AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    showAddSavingsSheet(context, goal: goal);
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteGoal),
                        content: Text(l10n.deleteGoalConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.delete, style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(savingsNotifierProvider.notifier).deleteGoal(goal['id']);
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
                      children: [
                        const Icon(Icons.edit_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalCurrency == currencyCode ? fmt.format(currentAmount) : fmtOriginal.format(currentAmount),
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (goalCurrency != currencyCode)
                    Consumer(
                      builder: (context, ref, _) {
                        final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
                        if (goalCurrency == currencyCode) return const SizedBox.shrink();
                        
                        final convertedAsync = ref.watch(convertedAmountProvider(ConversionParams(
                          amount: currentAmount,
                          from: goalCurrency,
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
                    l10n.of_(goalCurrency == currencyCode ? fmt.format(targetAmount) : fmtOriginal.format(targetAmount)),
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (goalCurrency != currencyCode)
                    Consumer(
                      builder: (context, ref, _) {
                        final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
                        if (goalCurrency == currencyCode) return const SizedBox.shrink();
                        
                        final convertedAsync = ref.watch(convertedAmountProvider(ConversionParams(
                          amount: targetAmount,
                          from: goalCurrency,
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
          const SizedBox(height: 12),
          SavingsGamificationWidget(percentage: safePercentage),
          
          // Action Button
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showTopUpSheet(context, goal),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(l10n.updateFunds),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

