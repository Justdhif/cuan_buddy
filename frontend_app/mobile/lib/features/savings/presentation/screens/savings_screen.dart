import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/savings_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(savingsNotifierProvider.notifier).fetchGoals(),
            color: AppColors.primary,
            child: _buildBody(context, ref, savingsState, isDark, currencySymbol),
          ),
          // ── Fixed AppScreenHeader ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppScreenHeader(
              title: l10n.savingsGoals,
              isScrolled: _scrollOffset > 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SavingsState state,
      bool isDark, String currencySymbol) {
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
        // ── Top spacing for AppScreenHeader ─────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 54),
        ),
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
                    loading: () => SummaryCardSkeleton(isDark: isDark),
                    error: (_, __) => const SizedBox(),
                  );
                },
              ),
            ),
          ),
        ),

        // Goals List
        if (state.isInitialLoad)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SkeletonCard(height: 160),
                childCount: 3,
              ),
            ),
          )
        else if (state.error != null && state.goals.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: AppErrorState(message: state.error!),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == filteredGoals.length) {
                    return _buildAddCard(
                      context,
                      onTap: () => context.push('/savings/form'),
                      title: l10n.addSavingsGoal,
                      isDark: isDark,
                    );
                  }
                  final goal = filteredGoals[index];
                  return _buildGoalCard(context, goal, currencySymbol);
                },
                childCount: filteredGoals.length + 1,
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

  Widget _buildAddCard(BuildContext context, {required VoidCallback onTap, required String title, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
      BuildContext context, Map<String, dynamic> goal, String currencySymbol) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconShape = ref.watch(categoryIconShapeProvider);

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

    final String currentFmt = fmt.format(currentAmount);
    final String targetFmt = fmt.format(targetAmount);

    String? dailySaveText;
    if (!isCompleted && targetDateStr != null && targetAmount > currentAmount) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diffDays = targetDate.difference(now).inDays;
        
        final perDayStr = l10n.perDayShort;

        if (diffDays > 0) {
          final dailyAmount = (targetAmount - currentAmount) / diffDays;
          final String dailyFmt = fmt.format(dailyAmount);
          dailySaveText = '$dailyFmt$perDayStr';
        } else if (diffDays == 0) {
          final String dailyFmt = fmt.format(targetAmount - currentAmount);
          dailySaveText = '$dailyFmt$perDayStr';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => context.push('/savings/detail', extra: {'goal': goal}),
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
                 Hero(
                  tag: 'savings_icon_${goal['id']}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: ShapeDecoration(
                        color: goalColor,
                        shape: iconShape.toShapeBorder(52),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
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
                          if (goal['isPin'] == true) ...[
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
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
                          if (goal['wallet']?['name'] != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              child: Text(
                                goal['wallet']['name'] as String,
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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
