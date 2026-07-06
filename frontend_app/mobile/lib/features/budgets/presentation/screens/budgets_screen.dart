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

  int _selectedYear = DateTime.now().year;
  late int _selectedMonthIndex;

  List<DateTime> get _months {
    return List.generate(12, (i) => DateTime(_selectedYear, i + 1));
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonthIndex = now.month - 1; // 0-based for Jan-Dec

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
    // Each month tab is 90px wide, with 8px padding on each side
    const itemWidth = 90.0;
    const horizontalPadding = 8.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = horizontalPadding + (_selectedMonthIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    // Safety check in case scroll controller isn't attached yet
    if (!_monthScrollController.hasClients) return;
    
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
    return '$_selectedYear-${(_selectedMonthIndex + 1).toString().padLeft(2, '0')}';
  }

  void _onMonthTap(int index) {
    setState(() => _selectedMonthIndex = index);
    _scrollToSelectedMonth();
    _updateProviderMonth();
  }

  void _updateProviderMonth() {
    ref.read(budgetsNotifierProvider.notifier).selectMonth(_selectedMonthYear);
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedYear = now.year;
      _selectedMonthIndex = now.month - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthScrollController.hasClients) {
        _scrollToSelectedMonth(animate: true);
      }
    });
    _updateProviderMonth();
  }

  Future<void> _pickYear() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    final years = List.generate(15, (i) => currentYear - 5 + i);

    // Pre-scroll to selected year
    final initialScrollIndex = years.indexOf(_selectedYear).clamp(0, years.length - 1);
    final scrollController = ScrollController(
      initialScrollOffset: initialScrollIndex * 56.0,
    );

    final int? year = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Text(
                    l10n.selectYear,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Year list
            SizedBox(
              height: 300,
              child: ListView.builder(
                controller: scrollController,
                itemCount: years.length,
                itemExtent: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final y = years[index];
                  final isSelected = y == _selectedYear;
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, y),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$y',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : AppColors.textPrimaryLight),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );

    scrollController.dispose();

    if (year != null && year != _selectedYear) {
      setState(() => _selectedYear = year);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedMonth(animate: false);
      });
      _updateProviderMonth();
    }
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

  // ── Month Scroller ──────────────────────────────────────────────────────
  Widget _buildMonthScroller(bool isDark, NumberFormat fmt) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final months = _months;
    final now = DateTime.now();
    final isTodaySelected = _selectedYear == now.year && _selectedMonthIndex == now.month - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Year selector & Today button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _pickYear,
                child: Row(
                  children: [
                    Text(
                      '$_selectedYear',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded, 
                      size: 24,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: isTodaySelected ? null : _goToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: Border.all(
                      color: isTodaySelected 
                          ? (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.borderLight.withValues(alpha: 0.4))
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    localeCode == 'id' ? 'Hari Ini' : 'Today',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isTodaySelected
                          ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.4)
                          : (isDark ? Colors.white : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Month tab row
        SizedBox(
          height: 52,
          child: ListView.builder(
            controller: _monthScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = index == _selectedMonthIndex;
              final monthName = DateFormat('MMMM', localeCode).format(month);

              return GestureDetector(
                onTap: () => _onMonthTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
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
                          monthName,
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

        const SizedBox(height: 12),
      ],
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
