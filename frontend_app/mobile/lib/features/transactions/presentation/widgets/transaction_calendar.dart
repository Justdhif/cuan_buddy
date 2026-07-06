import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/transaction_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'package:marquee/marquee.dart';

class TransactionCalendar extends ConsumerStatefulWidget {
  const TransactionCalendar({super.key});

  @override
  ConsumerState<TransactionCalendar> createState() =>
      _TransactionCalendarState();
}

class _TransactionCalendarState extends ConsumerState<TransactionCalendar> {
  /// Opens a month-only grid picker as a bottom sheet.
  Future<void> _showMonthPicker(
      BuildContext context, TransactionFilterState state, bool isDark) async {
    final localeCode = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context);
    final String title = l10n.selectMonth;

    final int? pickedMonth = await showModalBottomSheet<int>(
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
                    title,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Month grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (_, index) {
                  final monthIndex = index + 1;
                  final isSelected = state.currentMonth.month == monthIndex;
                  final dummyDate = DateTime(state.currentMonth.year, monthIndex, 1);
                  final monthLabel = DateFormat('MMMM', localeCode).format(dummyDate);
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(monthIndex),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? AppColors.borderDark.withValues(alpha: 0.3)
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        monthLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : AppColors.textPrimaryLight),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );

    if (pickedMonth != null) {
      ref.read(transactionFilterProvider.notifier).updateMonth(
            DateTime(state.currentMonth.year, pickedMonth, 1),
          );
    }
  }

  /// Opens a year-only scroll picker as a bottom sheet.
  Future<void> _showYearPicker(
      BuildContext context, TransactionFilterState state, bool isDark) async {
    final localeCode = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context);
    final String title = l10n.selectYear;
    final int currentYear = DateTime.now().year;
    final int startYear = currentYear - 10;
    final int endYear = currentYear + 5;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);
    final int initialIndex = (state.currentMonth.year - startYear).clamp(0, years.length - 1);
    final ScrollController yearScrollCtrl = ScrollController(
      initialScrollOffset: initialIndex * 56.0,
    );

    final int? pickedYear = await showModalBottomSheet<int>(
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
                    title,
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
                controller: yearScrollCtrl,
                itemCount: years.length,
                itemExtent: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (_, index) {
                  final year = years[index];
                  final isSelected = state.currentMonth.year == year;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(year),
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
                        '$year',
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

    yearScrollCtrl.dispose();

    if (pickedYear != null) {
      ref.read(transactionFilterProvider.notifier).updateMonth(
            DateTime(pickedYear, state.currentMonth.month, 1),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(transactionFilterProvider);
    final summaryAsync = ref.watch(calendarSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monthlySummaryAsync = ref.watch(monthlySummaryProvider);
    final double totalIncome =
        monthlySummaryAsync.valueOrNull?['totalIncome'] ?? 0.0;
    final double totalExpense =
        monthlySummaryAsync.valueOrNull?['totalExpense'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          _buildHeader(context, filterState, isDark),
          const SizedBox(height: 12),
          _buildLegend(context, filterState, isDark),
          const SizedBox(height: 12),
          _buildDaysOfWeek(isDark),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: summaryAsync.when(
              data: (summaryData) =>
                  _buildGrid(context, filterState, summaryData, isDark),
              loading: () => _buildGrid(
                  context, filterState, summaryAsync.value ?? [], isDark),
              error: (e, _) => const SizedBox(
                  height: 80,
                  child: Center(child: Text('Failed to load calendar'))),
            ),
          ),
          const SizedBox(height: 16),
          _buildCashflowSummary(context, totalIncome, totalExpense, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, TransactionFilterState state, bool isDark) {
    final localeCode = ref.watch(languageProvider);
    final monthName = DateFormat('MMMM', localeCode).format(state.currentMonth);
    final yearName = DateFormat('yyyy').format(state.currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left chevron
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            if (state.isExpanded) {
              ref.read(transactionFilterProvider.notifier).updateMonth(
                    DateTime(state.currentMonth.year,
                        state.currentMonth.month - 1, 1),
                  );
            } else {
              ref.read(transactionFilterProvider.notifier).updateWeek(-7);
            }
          },
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),

        // Center: tappable month text + tappable year text
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showMonthPicker(context, state, isDark),
              child: Text(
                monthName,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showYearPicker(context, state, isDark),
              child: Text(
                yearName,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),

        // Right chevron
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            if (state.isExpanded) {
              ref.read(transactionFilterProvider.notifier).updateMonth(
                    DateTime(state.currentMonth.year,
                        state.currentMonth.month + 1, 1),
                  );
            } else {
              ref.read(transactionFilterProvider.notifier).updateWeek(7);
            }
          },
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
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
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(BuildContext context, TransactionFilterState state,
      List<dynamic> summaryData, bool isDark) {
    final List<DateTime> days = [];

    if (state.isExpanded) {
      final firstDayOfMonth =
          DateTime(state.currentMonth.year, state.currentMonth.month, 1);
      final lastDayOfMonth =
          DateTime(state.currentMonth.year, state.currentMonth.month + 1, 0);

      int firstWeekday = firstDayOfMonth.weekday;
      if (firstWeekday == 7) firstWeekday = 0; // Make Sunday 0

      for (int i = firstWeekday - 1; i >= 0; i--) {
        days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
      }
      for (int i = 0; i < lastDayOfMonth.day; i++) {
        days.add(
            DateTime(state.currentMonth.year, state.currentMonth.month, i + 1));
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
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
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
                  : (isToday && isCurrentMonth
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isCurrentMonth || !state.isExpanded
                        ? (isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black))
                        : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)
                            .withValues(alpha: 0.5),
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  Widget _buildLegend(
      BuildContext context, TransactionFilterState state, bool isDark) {
    final l10n = AppLocalizations.of(context);

    // Determine if today is already the selected date
    final now = DateTime.now();
    final isTodaySelected = state.selectedDate.year == now.year &&
        state.selectedDate.month == now.month &&
        state.selectedDate.day == now.day;

    // Left Component: Today button (icon-only, disabled when today is selected)
    final todayButton = InkWell(
      onTap: isTodaySelected
          ? null
          : () {
              ref
                  .read(transactionFilterProvider.notifier)
                  .selectDate(DateTime.now());
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(
            color: isTodaySelected
                ? (isDark
                    ? AppColors.borderDark.withValues(alpha: 0.3)
                    : AppColors.borderLight.withValues(alpha: 0.4))
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.today_rounded,
          size: 20,
          color: isTodaySelected
              ? (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)
                  .withValues(alpha: 0.4)
              : (isDark ? Colors.white : AppColors.textPrimaryLight),
        ),
      ),
    );

    // Center Component: Legend labels
    final legendLabels = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(l10n.incomeType,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                )),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(l10n.expenseType,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                )),
          ],
        ),
      ],
    );

    // Right Component: Expand/Collapse button
    final toggleButton = InkWell(
      onTap: () {
        ref.read(transactionFilterProvider.notifier).toggleExpand();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          state.isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        todayButton,
        legendLabels,
        toggleButton,
      ],
    );
  }

  Widget _buildCashflowSummary(BuildContext context, double totalIncome,
      double totalExpense, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    final double netTotal = totalIncome - totalExpense;
    final Color netColor = netTotal >= 0 ? AppColors.success : AppColors.danger;

    Widget buildSummaryItem({
      required IconData icon,
      required Color iconColor,
      required Color iconBgColor,
      required String title,
      required String amount,
      required Color amountColor,
    }) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)
                          .withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final amountStyle = TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      
                      final textPainter = TextPainter(
                        text: TextSpan(text: amount, style: amountStyle),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout(minWidth: 0, maxWidth: double.infinity);

                      if (textPainter.size.width > constraints.maxWidth) {
                        return SizedBox(
                          height: textPainter.size.height,
                          width: constraints.maxWidth,
                          child: Marquee(
                            text: amount,
                            style: amountStyle,
                            scrollAxis: Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            blankSpace: 20.0,
                            velocity: 30.0,
                            pauseAfterRound: const Duration(seconds: 1),
                            accelerationDuration: const Duration(milliseconds: 500),
                            accelerationCurve: Curves.linear,
                            decelerationDuration: const Duration(milliseconds: 500),
                            decelerationCurve: Curves.easeOut,
                          ),
                        );
                      } else {
                        return Text(
                          amount,
                          style: amountStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          buildSummaryItem(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.success,
            iconBgColor: AppColors.success.withValues(alpha: 0.1),
            title: l10n.incomeType,
            amount: fmt.format(totalIncome),
            amountColor: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          Container(
            height: 24,
            width: 1,
            color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                .withValues(alpha: 0.5),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          buildSummaryItem(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.danger,
            iconBgColor: AppColors.danger.withValues(alpha: 0.1),
            title: l10n.expenseType,
            amount: fmt.format(totalExpense),
            amountColor: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          Container(
            height: 24,
            width: 1,
            color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                .withValues(alpha: 0.5),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          buildSummaryItem(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            title: l10n.net,
            amount: fmt.format(netTotal),
            amountColor: netColor,
          ),
        ],
      ),
    );
  }
}
