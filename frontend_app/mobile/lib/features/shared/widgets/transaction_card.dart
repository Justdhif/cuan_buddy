import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
class TransactionCard extends ConsumerWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showTime = false,
    this.hideSavingsGoal = false,
  });

  final dynamic transaction;
  final VoidCallback? onTap;
  final bool showTime;
  final bool hideSavingsGoal;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tx = transaction as Map<String, dynamic>;
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

    final txCurrency =
        tx['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);
    final fmtOriginal = NumberFormat.currency(
        locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
    final dynamic category = tx['category'];
    final dynamic savingsGoal = tx['savingsGoal'];
    final emoji = (category is Map
            ? (category['emojiIcon'] as String? ?? category['emoji'] as String?)
            : null) ??
        (isIncome ? '💰' : '💸');

    final catName = category is Map ? category['name'] as String? : null;
    final title = tx['title'] as String? ??
        tx['note'] as String? ??
        catName ??
        l10n.transaction;

    final defaultTypeColor = isIncome ? AppColors.success : AppColors.danger;
    final catColor = category is Map
        ? AppColors.colorFromHex(category['colorCode'] as String?,
            fallback: defaultTypeColor)
        : defaultTypeColor;
    
    final iconShape = ref.watch(categoryIconShapeProvider);

    return InkWell(
      onTap: onTap ??
          () {
            context.push(
              '/transactions/form',
              extra: {
                'initialType': tx['type'] as String? ?? 'expense',
                'initialTransaction': tx,
              },
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                color: catColor,
                shape: iconShape == CategoryIconShape.circle
                    ? const CircleBorder()
                    : iconShape == CategoryIconShape.squircle
                        ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24))
                        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryLight
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          catName ?? l10n.transaction,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      if (!hideSavingsGoal && savingsGoal != null && savingsGoal is Map)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🎨 ${savingsGoal['name']}',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? "▲" : "▼"} ${txCurrency == currencyCode ? fmt.format(amount) : fmtOriginal.format(amount)}',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: isIncome ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (txCurrency != currencyCode)
                  Consumer(
                    builder: (context, ref, _) {
                      final convertedAsync =
                          ref.watch(convertedAmountProvider(ConversionParams(
                        amount: amount,
                        from: txCurrency,
                        to: currencyCode,
                      )));
                      return convertedAsync.when(
                        data: (converted) => Text(
                          '≈ ${isIncome ? '+' : '-'}${fmt.format(converted)}',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        loading: () => const SizedBox(
                            width: 20,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                if (showTime && tx['date'] != null)
                  Text(
                    _formatTime(tx['date'] as String),
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }
}
