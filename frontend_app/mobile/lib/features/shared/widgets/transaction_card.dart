import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
class TransactionCard extends ConsumerWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onIconTap,
    this.onTitleTap,
    this.onAmountTap,
    this.showTime = true,
    this.hideSavingsGoal = false,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  final dynamic transaction;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;
  final VoidCallback? onTitleTap;
  final VoidCallback? onAmountTap;
  final bool showTime;
  final bool hideSavingsGoal;
  final EdgeInsetsGeometry contentPadding;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tx = transaction as Map<String, dynamic>;
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

    final dynamic category = tx['category'];
    final dynamic savingsGoal = tx['savingsGoal'];
    final dynamic wallet = tx['wallet'];
    final txCurrency = (wallet is Map ? wallet['currency'] as String? : null) ??
        tx['currency'] as String? ??
        AppConstants.defaultCurrency;
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);
    final walletPrecision = (wallet is Map
        ? (wallet['decimalPrecision'] as num?)?.toInt()
        : null) ?? 2;
    final emoji = (category is Map
            ? (category['emojiIcon'] as String? ?? category['emoji'] as String?)
            : null) ??
        (isIncome ? '💰' : '💸');

    final catName = category is Map ? category['name'] as String? : null;
    final title = tx['title'] as String? ??
        tx['note'] as String? ??
        catName ??
        l10n.transaction;

    final defaultCatColor = AppColors.primary;
    final catColor = category is Map
        ? AppColors.colorFromHex(category['colorCode'] as String?,
            fallback: defaultCatColor)
        : defaultCatColor;
        
    final walletName = wallet is Map ? wallet['name'] as String? : null;
    final walletEmoji = wallet is Map ? wallet['emojiIcon'] as String? ?? '💼' : '💼';
    final walletColor = wallet is Map ? AppColors.colorFromHex(wallet['colorCode'] as String?, fallback: AppColors.primary) : AppColors.primary;
    
    final savingsEmoji = savingsGoal is Map ? savingsGoal['emojiIcon'] as String? ?? '🎯' : '🎯';
    final savingsColor = savingsGoal is Map ? AppColors.colorFromHex(savingsGoal['colorCode'] as String?, fallback: AppColors.success) : AppColors.success;
    
    final iconShape = ref.watch(categoryIconShapeProvider);

    final baseAmountRaw = tx['baseAmount'];
    final baseAmount = baseAmountRaw is num
        ? baseAmountRaw.toDouble()
        : double.tryParse(baseAmountRaw?.toString() ?? '0') ?? amount;

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
        padding: contentPadding,
        child: Row(
          children: [
            GestureDetector(
              onTap: onIconTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: ShapeDecoration(
                  color: catColor,
                  shape: iconShape.toShapeBorder(48),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: onTitleTap,
                behavior: HitTestBehavior.opaque,
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
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          catName ?? l10n.transaction,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (walletName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: walletColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$walletEmoji $walletName',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: walletColor,
                            ),
                          ),
                        ),
                      if (!hideSavingsGoal && savingsGoal != null && savingsGoal is Map)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: savingsColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$savingsEmoji ${savingsGoal['name']}',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: savingsColor,
                            ),
                          ),
                        ),
                      if (tx['roomId'] != null && tx['user'] != null && tx['user']['profile'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundImage: (tx['user']['profile']['avatar'] != null && (tx['user']['profile']['avatar'] as String).isNotEmpty)
                                    ? NetworkImage(tx['user']['profile']['avatar'])
                                    : null,
                                backgroundColor: AppColors.secondary,
                                child: (tx['user']['profile']['avatar'] == null || (tx['user']['profile']['avatar'] as String).isEmpty)
                                    ? Text(
                                        (tx['user']['profile']['fullName'] ?? tx['user']['email']).toString().substring(0, 1).toUpperCase(),
                                        style: const TextStyle(fontSize: 4, color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tx['user']['profile']['fullName'] ?? tx['user']['profile']['username'] ?? 'User',
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: AppColors.secondaryDark,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAmountTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                txCurrency == currencyCode
                    ? Text(
                        '${isIncome ? "▲" : "▼"} ${CurrencyFormatter.formatAmount(amount, symbol: currencySymbol, decimalPrecision: walletPrecision)}',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: isIncome ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Consumer(
                        builder: (context, ref, _) {
                          final convertedAsync =
                              ref.watch(convertedAmountProvider(ConversionParams(
                            amount: amount,
                            from: txCurrency,
                            to: currencyCode,
                          )));
                          return convertedAsync.when(
                            data: (converted) => Text(
                              '${isIncome ? "▲" : "▼"} ${CurrencyFormatter.formatAmount(converted, symbol: currencySymbol, decimalPrecision: walletPrecision)}',
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                color: isIncome ? AppColors.success : AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const SizedBox(
                                width: 24,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => Text(
                              '${isIncome ? "▲" : "▼"} ${CurrencyFormatter.formatAmount(baseAmount, symbol: currencySymbol, decimalPrecision: walletPrecision)}',
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                color: isIncome ? AppColors.success : AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                if (txCurrency != currencyCode)
                  Text(
                    '≈ ${isIncome ? '+' : '-'}${CurrencyFormatter.formatAmount(amount, symbol: txCurrencySymbol, decimalPrecision: walletPrecision)}',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
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
