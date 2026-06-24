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

  Future<void> _showMonthYearPicker(BuildContext context, TransactionFilterState state, bool isDark) async {
    final localeCode = ref.read(languageProvider);
    final String title = localeCode == 'id' ? 'Pilih Bulan & Tahun' : 'Select Month & Year';
    
    int tempYear = state.currentMonth.year;
    
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                width: 300,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year selector row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() {
                              tempYear--;
                            });
                          },
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                        Text(
                          '$tempYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              tempYear++;
                            });
                          },
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Month Grid (3 columns, 4 rows)
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthIndex = index + 1;
                          final isSelected = state.currentMonth.month == monthIndex && state.currentMonth.year == tempYear;
                          
                          final dummyDate = DateTime(tempYear, monthIndex, 1);
                          final monthLabel = DateFormat('MMMM', localeCode).format(dummyDate);

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop(DateTime(tempYear, monthIndex, 1));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppColors.primaryGradient : null,
                                color: isSelected 
                                    ? null 
                                    : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );

    if (pickedDate != null) {
      ref.read(transactionFilterProvider.notifier).updateMonth(pickedDate);
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          _buildHeader(context, filterState, isDark),
          const SizedBox(height: 12),
          _buildCashflowSummary(context, totalIncome, totalExpense, isDark),
          const Divider(height: 16),
          _buildLegend(context, filterState, isDark),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TransactionFilterState state, bool isDark) {
    final localeCode = ref.watch(languageProvider);
    final monthFormat = DateFormat('MMMM yyyy', localeCode);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            if (state.isExpanded) {
              ref.read(transactionFilterProvider.notifier).updateMonth(
                DateTime(state.currentMonth.year, state.currentMonth.month - 1, 1),
              );
            } else {
              ref.read(transactionFilterProvider.notifier).updateWeek(-7);
            }
          },
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
        TextButton(
          onPressed: () => _showMonthYearPicker(context, state, isDark),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            monthFormat.format(state.currentMonth),
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            if (state.isExpanded) {
              ref.read(transactionFilterProvider.notifier).updateMonth(
                DateTime(state.currentMonth.year, state.currentMonth.month + 1, 1),
              );
            } else {
              ref.read(transactionFilterProvider.notifier).updateWeek(7);
            }
          },
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
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

  Widget _buildLegend(BuildContext context, TransactionFilterState state, bool isDark) {
    final l10n = AppLocalizations.of(context);
    
    // Left Component: Today button (icon-only)
    final todayButton = InkWell(
      onTap: () {
        ref.read(transactionFilterProvider.notifier).selectDate(DateTime.now());
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
          Icons.today_rounded,
          size: 20,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
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
          state.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
