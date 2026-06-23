import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/transaction_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class TransactionCalendar extends ConsumerStatefulWidget {
  const TransactionCalendar({super.key});

  @override
  ConsumerState<TransactionCalendar> createState() => _TransactionCalendarState();
}

class _TransactionCalendarState extends ConsumerState<TransactionCalendar> {
  late final ScrollController _scrollController;
  final List<GlobalKey> _monthKeys = List.generate(12, (index) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveMonth(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveMonth({bool animate = true}) {
    final filterState = ref.read(transactionFilterProvider);
    final activeMonthIndex = filterState.currentMonth.month - 1;
    final context = _monthKeys[activeMonthIndex].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5, // Center the active month in the viewport
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: animate ? Curves.easeInOut : Curves.linear,
      );
    }
  }

  Future<void> _selectYear(BuildContext context, TransactionFilterState state, bool isDark) async {
    final int currentYear = state.currentMonth.year;
    final localeCode = ref.read(languageProvider);
    final title = localeCode == 'id' ? 'Pilih Tahun' : 'Select Year';
    
    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Text(
            title,
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          content: SizedBox(
            width: 280,
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 21, // 2020 to 2040
              itemBuilder: (context, index) {
                final year = 2020 + index;
                final isSelected = year == currentYear;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(year);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedYear != null) {
      final newMonth = DateTime(selectedYear, state.currentMonth.month, 1);
      ref.read(transactionFilterProvider.notifier).updateMonth(newMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(transactionFilterProvider);
    final summaryAsync = ref.watch(calendarSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monthlySummaryAsync = ref.watch(monthlySummaryProvider);
    final double totalIncome = monthlySummaryAsync.valueOrNull?['totalIncome'] ?? 0.0;
    final double totalExpense = monthlySummaryAsync.valueOrNull?['totalExpense'] ?? 0.0;

    // Listen to changes in filterState to trigger auto-scroll
    ref.listen<TransactionFilterState>(
      transactionFilterProvider,
      (previous, next) {
        if (previous?.currentMonth.month != next.currentMonth.month ||
            previous?.currentMonth.year != next.currentMonth.year) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToActiveMonth();
          });
        }
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      child: Column(
        children: [
          _buildHeader(context, filterState, isDark),
          const SizedBox(height: 12),
          _buildCashflowSummary(context, totalIncome, totalExpense, isDark),
          const Divider(height: 16),
          _buildLegend(context, isDark),
          const SizedBox(height: 12),
          _buildDaysOfWeek(isDark),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: summaryAsync.when(
              data: (summaryData) => _buildGrid(context, filterState, summaryData, isDark),
              loading: () => _buildGrid(context, filterState, summaryAsync.value ?? [], isDark),
              error: (e, _) => const SizedBox(height: 80, child: Center(child: Text('Failed to load calendar'))),
            ),
          ),
          if (filterState.selectedDate.year != DateTime.now().year ||
              filterState.selectedDate.month != DateTime.now().month ||
              filterState.selectedDate.day != DateTime.now().day)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final localeCode = ref.watch(languageProvider);
                      final todayLabel = localeCode == 'id' ? 'Hari ini' : 'Today';
                      return GestureDetector(
                        onTap: () {
                           final today = DateTime.now();
                           ref.read(transactionFilterProvider.notifier).selectDate(today);
                        },
                        child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: AppColors.primary.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Text(
                             todayLabel,
                             style: AppTypography.textTheme.labelSmall?.copyWith(
                               color: AppColors.primary,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
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

  Widget _buildHeader(BuildContext context, TransactionFilterState state, bool isDark) {
    final localeCode = ref.watch(languageProvider);

    // 1. Left Component: Year Selector Button
    final yearButton = InkWell(
      onTap: () => _selectYear(context, state, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.calendar_today_rounded,
          size: 18,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );

    // 2. Center Component: Horizontal Scrollable Month List
    final monthListView = SizedBox(
      height: 40,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(12, (index) {
            final monthIndex = index + 1;
            final monthDate = DateTime(state.currentMonth.year, monthIndex, 1);
            final isSelected = state.currentMonth.month == monthIndex;
            final label = DateFormat('MMMM yyyy', localeCode).format(monthDate);

            return Padding(
              key: _monthKeys[index],
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == 11 ? 0 : 4,
              ),
              child: InkWell(
                onTap: () {
                  ref.read(transactionFilterProvider.notifier).updateMonth(monthDate);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : (isDark ? AppColors.surfaceDark : Colors.white),
                    border: isSelected
                        ? null
                        : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );

    // 3. Right Component: Expand/Collapse Button
    final toggleButton = InkWell(
      onTap: () {
        ref.read(transactionFilterProvider.notifier).toggleExpand();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          state.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          size: 24,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );

    return Row(
      children: [
        yearButton,
        const SizedBox(width: 8),
        Expanded(child: monthListView),
        const SizedBox(width: 8),
        toggleButton,
      ],
    );
  }

  Widget _buildDaysOfWeek(bool isDark) {
    final localeCode = ref.watch(languageProvider);
    final days = localeCode == 'id'
        ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(
      BuildContext context, TransactionFilterState state, List<dynamic> summaryData, bool isDark) {
    
    final List<DateTime> days = [];

    if (state.isExpanded) {
      final firstDayOfMonth = DateTime(state.currentMonth.year, state.currentMonth.month, 1);
      final lastDayOfMonth = DateTime(state.currentMonth.year, state.currentMonth.month + 1, 0);
      
      int firstWeekday = firstDayOfMonth.weekday;
      if (firstWeekday == 7) firstWeekday = 0; // Make Sunday 0

      for (int i = firstWeekday - 1; i >= 0; i--) {
        days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
      }
      for (int i = 0; i < lastDayOfMonth.day; i++) {
        days.add(DateTime(state.currentMonth.year, state.currentMonth.month, i + 1));
      }
      
      const totalGridDays = 35; // Exactly 5 weeks
      final remainingDays = totalGridDays - days.length;
      if (remainingDays > 0) {
        for (int i = 0; i < remainingDays; i++) {
          days.add(lastDayOfMonth.add(Duration(days: i + 1)));
        }
      } else if (days.length > totalGridDays) {
        days.removeRange(totalGridDays, days.length);
      }
    } else {
      final DateTime selected = state.selectedDate;
      int diffToSunday = selected.weekday == 7 ? 0 : selected.weekday;
      final DateTime sunday = selected.subtract(Duration(days: diffToSunday));
      for (int i = 0; i < 7; i++) {
        days.add(sunday.add(Duration(days: i)));
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final date = days[index];
        final isCurrentMonth = date.month == state.currentMonth.month;
        final isSelected = state.selectedDate.year == date.year &&
                           state.selectedDate.month == date.month &&
                           state.selectedDate.day == date.day;
        final isToday = DateTime.now().year == date.year &&
                        DateTime.now().month == date.month &&
                        DateTime.now().day == date.day;

        final monthStr = date.month.toString().padLeft(2, '0');
        final dayStr = date.day.toString().padLeft(2, '0');
        final dateString = '${date.year}-$monthStr-$dayStr';

        int incomeCount = 0;
        int expenseCount = 0;

        for (var item in summaryData) {
          if (item['date'] == dateString) {
            if (item['type'] == 'income') {
              incomeCount = (item['count'] as num).toInt();
            } else if (item['type'] == 'expense') {
              expenseCount = (item['count'] as num).toInt();
            }
          }
        }

        return GestureDetector(
          onTap: () {
            if (!isSelected) {
              ref.read(transactionFilterProvider.notifier).selectDate(date);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isToday && isCurrentMonth ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isCurrentMonth || !state.isExpanded
                        ? (isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black))
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.5),
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (incomeCount > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (expenseCount > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(l10n.incomeType, style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
            )),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(l10n.expenseType, style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCashflowSummary(BuildContext context, double totalIncome, double totalExpense, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.expenseType,
                  style: TextStyle(
                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '▼ ${fmt.format(totalExpense)}',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            width: 1,
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.incomeType,
                  style: TextStyle(
                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '▲ ${fmt.format(totalIncome)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
