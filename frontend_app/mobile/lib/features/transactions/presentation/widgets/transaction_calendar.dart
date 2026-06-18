import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/transaction_provider.dart';

class TransactionCalendar extends ConsumerWidget {
  const TransactionCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(transactionFilterProvider);
    final summaryAsync = ref.watch(calendarSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, ref, filterState, isDark),
          const SizedBox(height: 16),
          _buildDaysOfWeek(isDark),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: summaryAsync.when(
              data: (summaryData) => _buildGrid(context, ref, filterState, summaryData, isDark),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const SizedBox(height: 80, child: Center(child: Text('Failed to load calendar'))),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ref.read(transactionFilterProvider.notifier).toggleExpand();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, TransactionFilterState state, bool isDark) {
    final monthFormat = DateFormat('MMMM yyyy');
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
            ),
            Text(
              monthFormat.format(state.currentMonth),
              style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            ),
          ],
        ),
        const Spacer(),
        _buildLegend(isDark),
      ],
    );
  }

  Widget _buildDaysOfWeek(bool isDark) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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
      BuildContext context, WidgetRef ref, TransactionFilterState state, List<dynamic> summaryData, bool isDark) {
    
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
      final remainingDays = 42 - days.length; // Max 6 weeks
      for (int i = 0; i < remainingDays; i++) {
        days.add(lastDayOfMonth.add(Duration(days: i + 1)));
      }
    } else {
      // 1-week view anchored around selectedDate
      final anchorDate = state.selectedDate;
      int weekday = anchorDate.weekday;
      if (weekday == 7) weekday = 0; // Make Sunday 0

      final startOfWeek = anchorDate.subtract(Duration(days: weekday));
      for (int i = 0; i < 7; i++) {
        days.add(startOfWeek.add(Duration(days: i)));
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

  Widget _buildLegend(bool isDark) {
    return Row(
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
            Text('Income', style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
            )),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('Expense', style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
            )),
          ],
        ),
      ],
    );
  }
}
