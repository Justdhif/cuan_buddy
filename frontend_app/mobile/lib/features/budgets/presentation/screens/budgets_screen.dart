import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/budgets_provider.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final String _statusFilter =
      'All'; // 'All', 'On Track', 'Warning', 'Exceeded'
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
    final budgetsState = ref.watch(budgetsNotifierProvider);
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
          child: Text(l10n.budgets),
        ),

      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(budgetsNotifierProvider.notifier).fetchBudgets(),
        color: AppColors.primary,
        child: _buildBody(context, ref, budgetsState, isDark, currencySymbol),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => context.push('/budgets/form'),
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

  Widget _buildBody(BuildContext context, WidgetRef ref, BudgetsState state,
      bool isDark, String currencySymbol) {
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
      final limit = rawL is num
          ? rawL.toDouble()
          : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      final rollover = rawR is num
          ? rawR.toDouble()
          : double.tryParse(rawR?.toString() ?? '0') ?? 0;
      final totalLimit = limit + rollover;
      final rawS = b['spentAmount'];
      final spent = rawS is num
          ? rawS.toDouble()
          : double.tryParse(rawS?.toString() ?? '0') ?? 0;
      final p = totalLimit > 0 ? spent / totalLimit : 0.0;

      if (_statusFilter == 'Exceeded') return p >= 1.0;
      if (_statusFilter == 'Warning') return p > 0.7 && p < 1.0;
      if (_statusFilter == 'On Track') return p <= 0.7;
      return true;
    }).toList();

    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        80;

    return CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      controller: _scrollController,
      slivers: [
        // Summary Header Card
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
                      ref.watch(convertedBudgetsSummaryProvider('All'));
                  return summaryAsync.when(
                    data: (summary) {
                      final totalLimit = summary['totalLimit'] ?? 0.0;
                      final totalSpent = summary['totalSpent'] ?? 0.0;
                      final percentage =
                          totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
                      final safePercentage = percentage.clamp(0.0, 1.0);

                      Color progressColor;
                      if (percentage >= 1.0) {
                        progressColor = AppColors.danger;
                      } else if (percentage >= 0.8) {
                        progressColor = AppColors.warning;
                      } else if (percentage >= 0.5) {
                        progressColor = const Color(0xFFEAB308);
                      } else {
                        progressColor = AppColors.success;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.budgetSummary,
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Total Spent
                              Expanded(
                                child: _buildSummaryMetric(
                                  icon: Icons.account_balance_wallet_rounded,
                                  iconColor: AppColors.danger,
                                  label: l10n.totalSpent,
                                  valueWidget: Text(
                                    fmt.format(totalSpent),
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
                                          color: progressColor,
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
                                          backgroundColor: progressColor.withValues(alpha: 0.15),
                                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                              Container(width: 1, height: 60, color: isDark ? AppColors.borderDark : AppColors.borderLight, margin: const EdgeInsets.symmetric(horizontal: 6)),
                              // 3. Total Budget
                              Expanded(
                                child: _buildSummaryMetric(
                                  icon: Icons.track_changes_rounded,
                                  iconColor: AppColors.primary,
                                  label: l10n.totalBudget,
                                  valueWidget: Text(
                                    fmt.format(totalLimit),
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  );
                },
              ),
            ),
          ),
        ),

        // Budgets List
        if (state.budgets.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: AppEmptyState(
                emoji: '📊',
                title: l10n.noBudgetsSet,
                subtitle: l10n.noBudgetsSetSubtitle,
              ),
            ),
          )
        else if (filteredBudgets.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
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
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard(
      {required this.budget,
      required this.isDark,
      required this.currencySymbol});
  final dynamic budget;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final localeCode = Localizations.localeOf(context).languageCode;

    final tx = budget as Map<String, dynamic>;
    final rawL = tx['limitAmount'];
    final limitAmount = rawL is num
        ? rawL.toDouble()
        : double.tryParse(rawL?.toString() ?? '0') ?? 0;
    final rawS = tx['spentAmount'];
    final spentAmount = rawS is num
        ? rawS.toDouble()
        : double.tryParse(rawS?.toString() ?? '0') ?? 0;
    final rawR = tx['rolloverAmount'];
    final rolloverAmount = rawR is num
        ? rawR.toDouble()
        : double.tryParse(rawR?.toString() ?? '0') ?? 0;
    final totalLimitAmount = limitAmount + rolloverAmount;

    final categoryName = tx['category']?['name'] as String? ??
        tx['categoryName'] as String? ??
        l10n.budget;
    final monthYear = tx['monthYear'] as String? ?? '';

    final percentage =
        totalLimitAmount > 0 ? (spentAmount / totalLimitAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);

    final txCurrency =
        tx['currency'] as String? ?? AppConstants.defaultCurrency;
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

    // Parse monthYear (YYYY-MM) to find startDate and endDate
    final parts = monthYear.split('-');
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? DateTime.now().year;
      final month = int.tryParse(parts[1]) ?? DateTime.now().month;
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month + 1, 0); // last day of month
    } else {
      startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
      endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    }

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    double todayProgressFraction = 0.0;
    if (today.isBefore(startDate)) {
      todayProgressFraction = 0.0;
    } else if (today.isAfter(endDate)) {
      todayProgressFraction = 1.0;
    } else {
      final totalDays = endDate.difference(startDate).inDays + 1;
      final elapsedDays = today.difference(startDate).inDays;
      todayProgressFraction = elapsedDays / totalDays;
    }

    final remainingDays =
        endDate.isAfter(today) ? endDate.difference(today).inDays + 1 : 0;
    final remaining = totalLimitAmount - spentAmount;
    final dailyAllowance =
        remainingDays > 0 && remaining > 0 ? remaining / remainingDays : 0.0;

    final remainingFormatted = txCurrency == currencyCode
        ? fmt.format(remaining.abs())
        : fmtOriginal.format(remaining.abs());
    final totalLimitFormatted = txCurrency == currencyCode
        ? fmt.format(totalLimitAmount)
        : fmtOriginal.format(totalLimitAmount);

    final String subtitle;
    if (remaining >= 0) {
      subtitle = localeCode == 'id'
          ? '$remainingFormatted tersisa dari $totalLimitFormatted'
          : '$remainingFormatted remaining of $totalLimitFormatted';
    } else {
      subtitle = localeCode == 'id'
          ? '$remainingFormatted terlampaui dari $totalLimitFormatted'
          : '$remainingFormatted exceeded of $totalLimitFormatted';
    }

    // Color theme from database
    final catHex =
        tx['category']?['colorCode'] as String? ?? tx['colorCode'] as String?;
    final baseColor =
        AppColors.colorFromHex(catHex, fallback: AppColors.primary);
    final topGradientColor = baseColor;
    final bottomGradientColor =
        Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor;

    // Define dynamic colors based on consumption percentage
    Color progressBarColor;
    if (percentage >= 1.0) {
      progressBarColor = AppColors.danger;
    } else if (percentage >= 0.8) {
      progressBarColor = AppColors.warning;
    } else if (percentage >= 0.5) {
      progressBarColor = const Color(0xFFEAB308);
    } else {
      progressBarColor = AppColors.success;
    }

    final catEmoji = tx['category']?['emojiIcon'] as String? ??
        tx['category']?['emoji'] as String? ??
        tx['emoji'] as String? ??
        tx['emojiIcon'] as String? ??
        '📦';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: spentAmount > totalLimitAmount
              ? AppColors.danger.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: spentAmount > totalLimitAmount ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── Top Section: Gradient ───────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/budgets/form', extra: {'budget': tx}),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [topGradientColor, bottomGradientColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      catEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Bottom Section: Solid ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: isDark ? const Color(0xFF161F28) : const Color(0xFFF8F9FA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar & Dates Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 20,
                      margin: const EdgeInsets.only(bottom: 6),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d MMM', localeCode).format(startDate),
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final todayPosition =
                              maxWidth * todayProgressFraction;
                          const todayLabelWidth = 50.0;

                          return SizedBox(
                            height: 52,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Progress Bar Background & Active Fill
                                Positioned(
                                  bottom: 6,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      children: [
                                        FractionallySizedBox(
                                          widthFactor: safePercentage,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: progressBarColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: safePercentage > 0.15
                                                ? Text(
                                                    '${(safePercentage * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Proportional "Hari ini" Indicator
                                if (todayProgressFraction > 0.0 &&
                                    todayProgressFraction < 1.0)
                                  Positioned(
                                    left: todayPosition - (todayLabelWidth / 2),
                                    top: 0,
                                    child: SizedBox(
                                      width: todayLabelWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              localeCode == 'id'
                                                  ? 'Hari ini'
                                                  : 'Today',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            width: 1.5,
                                            height: 34,
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 20,
                      margin: const EdgeInsets.only(bottom: 6),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d MMM', localeCode).format(endDate),
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Daily Allowance Info
                Builder(
                  builder: (context) {
                    final String infoText;
                    if (remaining >= 0) {
                      if (remainingDays > 0) {
                        final allowanceFormatted = fmt.format(dailyAllowance);
                        infoText = localeCode == 'id'
                            ? 'Anda bisa membelanjakan $allowanceFormatted/hari untuk $remainingDays hari ke depan'
                            : 'You can spend $allowanceFormatted/day for $remainingDays more days';
                      } else {
                        infoText = localeCode == 'id'
                            ? 'Periode anggaran telah berakhir'
                            : 'Budget period has ended';
                      }
                    } else {
                      final limitExceededFormatted =
                          fmt.format(remaining.abs());
                      infoText = localeCode == 'id'
                          ? 'Anggaran telah terlampaui sebesar $limitExceededFormatted'
                          : 'Budget exceeded by $limitExceededFormatted';
                    }

                    return Text(
                      infoText,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
