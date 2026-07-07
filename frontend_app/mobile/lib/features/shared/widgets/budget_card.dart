import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
class BudgetCard extends ConsumerWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.isDark,
    required this.currencySymbol,
  });

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
    final iconShape = ref.watch(categoryIconShapeProvider);

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

    final String actionText;
    if (remaining >= 0) {
      actionText = l10n.remainingOf;
    } else {
      actionText = l10n.exceededOf;
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
        ? l10n.periodMonths(periodCount, startDay)
        : l10n.periodDate(startDay);

    return Container(
      height: 204,
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
                    decoration: ShapeDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: iconShape == CategoryIconShape.circle
                          ? const CircleBorder()
                          : iconShape == CategoryIconShape.squircle
                              ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24))
                              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            // Wallet badge
                            if (tx['wallet']?['name'] != null)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tx['wallet']['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: remainingFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: actionText,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: totalLimitFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
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
          Expanded(
            child: Container(
              width: double.infinity,
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
                                              l10n.today,
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
                        infoText = l10n.dailyAllowance(allowanceFormatted, remainingDays);
                      } else {
                        infoText = l10n.budgetPeriodEnded;
                      }
                    } else {
                      final limitExceededFormatted =
                          fmt.format(remaining.abs());
                      infoText = l10n.budgetExceededBy(limitExceededFormatted);
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
        ),
        ],
      ),
    );
  }
}
