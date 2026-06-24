import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/savings_provider.dart';
import '../widgets/add_savings_sheet.dart';
import '../../../profile/presentation/widgets/single_table_import_sheet.dart';
import '../../../profile/data/services/backup_worker.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
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
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
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

      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(savingsNotifierProvider.notifier).fetchGoals(),
        color: AppColors.primary,
        child: _buildBody(context, ref, savingsState, isDark, currencySymbol),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => showAddSavingsSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SavingsState state,
      bool isDark, String currencySymbol) {
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



    // Use all goals, no filter
    final filteredGoals = state.goals;

    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        80;

    return CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      controller: _scrollController,
      slivers: [
        // Summary Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final summaryAsync =
                      ref.watch(convertedSavingsSummaryProvider('All'));
                  return summaryAsync.when(
                    data: (summary) {
                      final totalSaved = summary['totalSaved'] ?? 0.0;
                      final totalTarget = summary['totalTarget'] ?? 0.0;
                      final percentage = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;
                      final safePercentage = percentage.clamp(0.0, 1.0);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.savingSummary,
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Total Saldo
                              Expanded(
                                child: _buildSummaryMetric(
                                  icon: Icons.account_balance_wallet_rounded,
                                  iconColor: AppColors.success,
                                  label: l10n.totalSaved,
                                  valueWidget: Text(
                                    fmt.format(totalSaved),
                                    style: AppTypography.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                              Container(width: 1, height: 60, color: isDark ? AppColors.borderDark : AppColors.borderLight, margin: const EdgeInsets.symmetric(horizontal: 6)),
                              // 2. Progress Total
                              Expanded(
                                child: _buildSummaryMetric(
                                  icon: Icons.pie_chart_rounded,
                                  iconColor: const Color(0xFF9b51e0),
                                  label: l10n.progressTotal,
                                  valueWidget: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${(safePercentage * 100).toInt()}%',
                                        style: AppTypography.textTheme.titleSmall?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: safePercentage,
                                          minHeight: 4,
                                          backgroundColor: AppColors.success.withValues(alpha: 0.15),
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                              Container(width: 1, height: 60, color: isDark ? AppColors.borderDark : AppColors.borderLight, margin: const EdgeInsets.symmetric(horizontal: 6)),
                              // 3. Total Target
                              Expanded(
                                child: _buildSummaryMetric(
                                  icon: Icons.track_changes_rounded,
                                  iconColor: AppColors.primary,
                                  label: l10n.totalTarget,
                                  valueWidget: Text(
                                    fmt.format(totalTarget),
                                    style: AppTypography.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                        child:
                            CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  );
                },
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

  Widget _buildSummaryMetric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget valueWidget,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        valueWidget,
      ],
    );
  }

  Widget _buildGoalCard(
      BuildContext context, Map<String, dynamic> goal, String currencySymbol) {
    final l10n = AppLocalizations.of(context);
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = goal['name'] as String? ?? l10n.unnamedGoal;
    final emoji = goal['emojiIcon'] as String? ?? '🎯';
    final colorHex = goal['colorCode'] as String? ?? '#6C63FF';
    final goalColor = AppColors.colorFromHex(colorHex, fallback: AppColors.primary);

    final rawT = goal['targetAmount'];
    final targetAmount = rawT is num
        ? rawT.toDouble()
        : double.tryParse(rawT?.toString() ?? '0') ?? 0;
    final rawC = goal['currentAmount'];
    final currentAmount = rawC is num
        ? rawC.toDouble()
        : double.tryParse(rawC?.toString() ?? '0') ?? 0;
    final targetDateStr = goal['targetDate'] as String?;

    final percentage = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);
    final isCompleted = goal['status'] == 'completed' || safePercentage >= 1.0;
    final percentageText = '${(safePercentage * 100).toInt()}%';

    Color progressColor;
    if (safePercentage >= 1.0) {
      progressColor = AppColors.success;
    } else if (safePercentage >= 0.7) {
      progressColor = AppColors.primary;
    } else if (safePercentage >= 0.4) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = AppColors.danger;
    }

    final goalCurrency =
        goal['currency'] as String? ?? AppConstants.defaultCurrency;
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

    // Target date formatted
    String? targetDateFormatted;
    if (targetDateStr != null) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        targetDateFormatted = DateFormat('dd MMM yyyy').format(targetDate);
      } catch (_) {}
    }

    final String currentFmt = goalCurrency == currencyCode
        ? fmt.format(currentAmount)
        : fmtOriginal.format(currentAmount);
    final String targetFmt = goalCurrency == currencyCode
        ? fmt.format(targetAmount)
        : fmtOriginal.format(targetAmount);

    String? dailySaveText;
    if (!isCompleted && targetDateStr != null && targetAmount > currentAmount) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diffDays = targetDate.difference(now).inDays;
        
        final isId = Localizations.localeOf(context).languageCode == 'id';
        final perDayStr = isId ? '/hari' : '/day';

        if (diffDays > 0) {
          final dailyAmount = (targetAmount - currentAmount) / diffDays;
          final String dailyFmt = goalCurrency == currencyCode
              ? fmt.format(dailyAmount)
              : fmtOriginal.format(dailyAmount);
          dailySaveText = '$dailyFmt$perDayStr';
        } else if (diffDays == 0) {
          final String dailyFmt = goalCurrency == currencyCode
              ? fmt.format(targetAmount - currentAmount)
              : fmtOriginal.format(targetAmount - currentAmount);
          dailySaveText = '$dailyFmt$perDayStr';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        // Could navigate to detail screen in future
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.4)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Icon + Title/Amount + Menu ────────────────────────
            Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: goalColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentFmt / $targetFmt',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // More menu
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      size: 18,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: Text(l10n.delete,
                                    style: const TextStyle(
                                        color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref
                                .read(savingsNotifierProvider.notifier)
                                .deleteGoal(goal['id']);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to delete: $e')));
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
                            const Icon(Icons.edit_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Text(l10n.delete,
                                style: const TextStyle(
                                    color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Progress bar ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: safePercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: safePercentage > 0.15
                          ? Text(
                              percentageText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            // ── Target date & Daily Save ────────────────────────────────────
            if (targetDateFormatted != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target: $targetDateFormatted',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  if (dailySaveText != null)
                    Text(
                      dailySaveText,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

