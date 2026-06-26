import 'dart:ui' show lerpDouble;
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
  final ScrollController _scrollController = ScrollController();
  final ScrollController _monthScrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Generate months: Jan last year → Dec next year (36 months)
  late final List<DateTime> _months;
  late int _selectedMonthIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    final now = DateTime.now();
    final startMonth = DateTime(now.year - 1, 1);
    _months = List.generate(36, (i) => DateTime(startMonth.year, startMonth.month + i));

    // Find current month index
    _selectedMonthIndex = _months.indexWhere(
      (m) => m.year == now.year && m.month == now.month,
    );
    if (_selectedMonthIndex < 0) _selectedMonthIndex = 12; // fallback

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _monthScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedMonth({bool animate = true}) {
    // Each month tab is approximately 72px wide
    const itemWidth = 72.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (_selectedMonthIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    final clampedOffset = offset.clamp(0.0, _monthScrollController.position.maxScrollExtent);
    if (animate) {
      _monthScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _monthScrollController.jumpTo(clampedOffset);
    }
  }

  String get _selectedMonthYear {
    final m = _months[_selectedMonthIndex];
    return '${m.year}-${m.month.toString().padLeft(2, '0')}';
  }

  void _onMonthTap(int index) {
    setState(() => _selectedMonthIndex = index);
    _scrollToSelectedMonth();
    final my = '${_months[index].year}-${_months[index].month.toString().padLeft(2, '0')}';
    ref.read(budgetsNotifierProvider.notifier).selectMonth(my);
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(budgetsNotifierProvider.notifier).fetchBudgets(),
            color: AppColors.primary,
            child: _buildBody(context, ref, budgetsState, isDark, currencySymbol),
          ),
          // ── Pinned AppBar Background (appears on scroll) ─────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(builder: (context) {
              final t = (_scrollOffset / 60).clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Container(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              );
            }),
          ),
          // ── Floating animated title (moves from hero to AppBar) ──────────────
          _buildFloatingTitle(context, l10n, isDark),
        ],
      ),
    );
  }

  /// Floating title that physically moves from hero position to AppBar as user scrolls.
  Widget _buildFloatingTitle(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final statusBarH = MediaQuery.of(context).padding.top;
    const appBarH = kToolbarHeight;
    final heroTitleY = statusBarH + 12.0 + 8.0 + 14.0;
    final appBarTitleY = statusBarH + appBarH / 2.0 - 13.0;
    final travelDist = heroTitleY - appBarTitleY;

    final t = (_scrollOffset / travelDist.abs()).clamp(0.0, 1.0);
    var currentY = lerpDouble(heroTitleY, appBarTitleY, t)!;

    if (_scrollOffset < 0) {
      currentY -= _scrollOffset;
    }

    final heroSize = AppTypography.textTheme.headlineMedium?.fontSize ?? 28.0;
    final appBarSize = AppTypography.textTheme.titleLarge?.fontSize ?? 22.0;
    final currentSize = lerpDouble(heroSize, appBarSize, t)!;

    return Positioned(
      top: currentY,
      left: 24.0,
      right: 120.0,
      child: IgnorePointer(
        child: Text(
          l10n.budgets,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: currentSize,
            fontWeight: FontWeight.bold,
            fontFamily: AppTypography.textTheme.headlineMedium?.fontFamily,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BudgetsState state,
      bool isDark, String currencySymbol) {
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    final filteredBudgets = state.budgets;

    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        80;

    return CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      controller: _scrollController,
      slivers: [
        // ── Hero content ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _BudgetHeroHeader(isDark: isDark),
        ),

        // ── Month Scroller ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildMonthScroller(isDark, fmt),
        ),

        // ── Budget List ────────────────────────────────────────────────
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
        else if (state.error != null && state.budgets.isEmpty)
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: AppErrorState(message: state.error!),
            ),
          )
        else if (state.budgets.isEmpty)
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
                title: 'Tidak ada budget',
                subtitle: 'Belum ada budget untuk bulan ini.',
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == filteredBudgets.length) {
                    return _buildAddCard(
                      context,
                      onTap: () => context.push('/budgets/form'),
                      title: l10n.setBudget,
                      isDark: isDark,
                    );
                  }
                  return _BudgetCard(
                    budget: filteredBudgets[index],
                    isDark: isDark,
                    currencySymbol: currencySymbol,
                  );
                },
                childCount: filteredBudgets.length + 1,
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

  // ── Month Scroller + Summary Pill ───────────────────────────────────────
  Widget _buildMonthScroller(bool isDark, NumberFormat fmt) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        // Month tab row
        SizedBox(
          height: 52,
          child: ListView.builder(
            controller: _monthScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _months.length,
            itemBuilder: (context, index) {
              final month = _months[index];
              final isSelected = index == _selectedMonthIndex;
              final now = DateTime.now();
              final isToday = month.year == now.year && month.month == now.month;
              final monthName = DateFormat('MMM', localeCode).format(month);

              return GestureDetector(
                onTap: () => _onMonthTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Month label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: AppTypography.textTheme.bodyMedium?.fontFamily,
                          fontSize: isSelected ? 15 : 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          isToday && !isSelected ? monthName : monthName,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Active indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isSelected ? 24 : 0,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Summary Pill Card (▼ spent | ▲ income | = balance)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer(
            builder: (context, ref, _) {
              final summaryAsync =
                  ref.watch(monthlyBudgetSummaryProvider(_selectedMonthYear));
              return summaryAsync.when(
                loading: () => _buildSummaryPillSkeleton(isDark),
                error: (_, __) => const SizedBox(),
                data: (summary) {
                  final spent = summary['totalSpent'] ?? 0.0;
                  final income = summary['totalIncome'] ?? 0.0;
                  final balance = income - spent;
                  return _buildSummaryPill(
                    isDark: isDark,
                    spent: spent,
                    income: income,
                    balance: balance,
                    fmt: fmt,
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSummaryPill({
    required bool isDark,
    required double spent,
    required double income,
    required double balance,
    required NumberFormat fmt,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2333) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Spent
          _PillItem(
            prefix: '▼',
            prefixColor: const Color(0xFFEF4444),
            value: fmt.format(spent),
            isDark: isDark,
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          // Income
          _PillItem(
            prefix: '▲',
            prefixColor: const Color(0xFF22C55E),
            value: fmt.format(income),
            isDark: isDark,
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          // Balance
          _PillItem(
            prefix: '=',
            prefixColor: Colors.white.withValues(alpha: 0.7),
            value: fmt.format(balance.abs()),
            isDark: isDark,
            valueColor: balance < 0
                ? const Color(0xFFEF4444)
                : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPillSkeleton(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2333) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
        )),
      ),
    );
  }

  Widget _buildAddCard(BuildContext context,
      {required VoidCallback onTap,
      required String title,
      required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
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
              child: const Icon(
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
}

// ── Pill Item ──────────────────────────────────────────────────────────────────
class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.prefix,
    required this.prefixColor,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  final String prefix;
  final Color prefixColor;
  final String value;
  final bool isDark;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          prefix,
          style: TextStyle(
            color: prefixColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: AppTypography.textTheme.bodyMedium?.fontFamily,
          ),
        ),
      ],
    );
  }
}

// ── Budget Card ────────────────────────────────────────────────────────────────
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

    final categoryName = tx['category']?['name'] as String? ??
        tx['categoryName'] as String? ??
        l10n.budget;
    final monthYear = tx['monthYear'] as String? ?? '';
    final periodCount = (tx['periodCount'] as num?)?.toInt() ?? 1;
    final startDay = (tx['startDay'] as num?)?.toInt() ?? 1;

    final percentage =
        limitAmount > 0 ? (spentAmount / limitAmount) : 0.0;
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

    // Parse period start/end dates
    DateTime startDate;
    DateTime endDate;
    if (tx['periodStartDate'] != null) {
      startDate = DateTime.parse(tx['periodStartDate']);
      endDate = DateTime.parse(tx['periodEndDate']);
    } else {
      final parts = monthYear.split('-');
      if (parts.length >= 2) {
        final year = int.tryParse(parts[0]) ?? DateTime.now().year;
        final month = int.tryParse(parts[1]) ?? DateTime.now().month;
        startDate = DateTime(year, month, startDay);
        endDate = DateTime(year, month + periodCount, startDay)
            .subtract(const Duration(days: 1));
      } else {
        startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
      }
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
    final remaining = limitAmount - spentAmount;
    final dailyAllowance =
        remainingDays > 0 && remaining > 0 ? remaining / remainingDays : 0.0;

    final remainingFormatted = txCurrency == currencyCode
        ? fmt.format(remaining.abs())
        : fmtOriginal.format(remaining.abs());
    final totalLimitFormatted = txCurrency == currencyCode
        ? fmt.format(limitAmount)
        : fmtOriginal.format(limitAmount);

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

    // Period badge label
    final periodLabel = periodCount > 1
        ? '$periodCount bulan (tgl $startDay)'
        : 'tgl $startDay';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: spentAmount > limitAmount
              ? AppColors.danger.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: spentAmount > limitAmount ? 1.5 : 1,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                categoryName,
                                style: AppTypography.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            // Period badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                periodLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color:
                isDark ? const Color(0xFF161F28) : const Color(0xFFF8F9FA),
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
                                // Progress Bar
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
                                      borderRadius:
                                          BorderRadius.circular(10),
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

                                // Today indicator
                                if (todayProgressFraction > 0.0 &&
                                    todayProgressFraction < 1.0)
                                  Positioned(
                                    left: todayPosition -
                                        (todayLabelWidth / 2),
                                    top: 0,
                                    child: SizedBox(
                                      width: todayLabelWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1),
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
                        final allowanceFormatted =
                            fmt.format(dailyAllowance);
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

// ── Hero Header Widget ────────────────────────────────────────────────────────
class _BudgetHeroHeader extends StatelessWidget {
  const _BudgetHeroHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: 0,
                    child: Text(
                      l10n.budgets,
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.budgetsSubtitle,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Center main – pie chart
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.pie_chart_rounded,
                          color: Colors.purple, size: 26),
                    ),
                  ),
                  // Top-right – bar chart
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bar_chart_rounded,
                          color: Colors.blue, size: 16),
                    ),
                  ),
                  // Bottom-left – trending up
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_up_rounded,
                          color: Colors.green, size: 15),
                    ),
                  ),
                  // Top-left – receipt
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.orange, size: 13),
                    ),
                  ),
                  // Bottom-right – target/track
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.track_changes_rounded,
                          color: Colors.red, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
