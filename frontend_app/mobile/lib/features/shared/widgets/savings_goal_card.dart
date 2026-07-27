import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';

class SavingsGoalCard extends ConsumerWidget {
  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.isDark,
    required this.currencySymbol,
    this.onTap,
  });

  final dynamic goal;
  final bool isDark;
  final String currencySymbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final iconShape = ref.watch(categoryIconShapeProvider);

    final g = goal as Map<String, dynamic>;
    final name = g['name'] as String? ?? l10n.unnamedGoal;
    final emoji = g['emojiIcon'] as String? ?? g['emoji'] as String? ?? '🎯';
    final colorHex = g['colorCode'] as String? ?? '#6C63FF';
    final goalColor = AppColors.colorFromHex(colorHex, fallback: AppColors.primary);

    final rawT = g['targetAmount'];
    final targetAmount = rawT is num
        ? rawT.toDouble()
        : double.tryParse(rawT?.toString() ?? '0') ?? 0;
    final rawC = g['currentAmount'];
    final currentAmount = rawC is num
        ? rawC.toDouble()
        : double.tryParse(rawC?.toString() ?? '0') ?? 0;
    final targetDateStr = g['targetDate'] as String?;

    final percentage = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);
    final isCompleted = g['status'] == 'completed' || safePercentage >= 1.0;
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

    final currentFmt = CurrencyFormatter.formatAmount(currentAmount, symbol: currencySymbol);
    final targetFmt = CurrencyFormatter.formatAmount(targetAmount, symbol: currencySymbol);

    String? targetDateFormatted;
    if (targetDateStr != null) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        targetDateFormatted = DateFormat('dd MMM yyyy').format(targetDate);
      } catch (_) {}
    }

    String? dailySaveText;
    if (!isCompleted && targetDateStr != null && targetAmount > currentAmount) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diffDays = targetDate.difference(now).inDays;
        final perDayStr = l10n.perDayShort;

        if (diffDays > 0) {
          final dailyAmount = (targetAmount - currentAmount) / diffDays;
          final dailyFmt = CurrencyFormatter.formatAmount(dailyAmount, symbol: currencySymbol);
          dailySaveText = '$dailyFmt$perDayStr';
        } else if (diffDays == 0) {
          final dailyFmt = CurrencyFormatter.formatAmount(targetAmount - currentAmount, symbol: currencySymbol);
          dailySaveText = '$dailyFmt$perDayStr';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap ?? () => context.push('/savings/detail', extra: {'goal': g}),
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
            Row(
              children: [
                Hero(
                  tag: 'savings_icon_${g['id']}',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (g['isPin'] == true) ...[
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
                          if (g['wallet']?['name'] != null)
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
                                g['wallet']['name'] as String,
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
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      percentageText,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.languageCode == 'id' ? 'Tercapai' : 'Achieved',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (targetDateFormatted != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        targetDateFormatted,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: safePercentage,
                minHeight: 10,
                backgroundColor: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            if (dailySaveText != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.languageCode == 'id'
                            ? 'Perlu menabung $dailySaveText'
                            : 'Need to save $dailySaveText',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
