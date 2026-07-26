import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/budgets_provider.dart';
import '../../../shared/widgets/budget_card.dart';

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

    final int? year = await AppBottomSheet.show<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          // ── Fixed AppScreenHeader ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppScreenHeader(
              title: l10n.budgets,
              isScrolled: _scrollOffset > 15,
            ),
          ),
        ],
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
        // ── Top spacing for AppScreenHeader ─────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 54),
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
                  return BudgetCard(
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
                    l10n.today,
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
        height: 180,
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
}
