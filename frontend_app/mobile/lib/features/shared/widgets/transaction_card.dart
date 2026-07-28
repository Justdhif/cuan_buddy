import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
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

    final formattedTime = (showTime && tx['date'] != null) ? _formatTime(tx['date'] as String) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final room = tx['room'];
    final roomName = room is Map ? room['name'] as String? : null;
    final roomEmoji = room is Map ? (room['emojiIcon'] as String? ?? '👥') : '👥';
    final roomColorCode = room is Map ? room['colorCode'] as String? : null;
    final roomColor = AppColors.colorFromHex(roomColorCode, fallback: const Color(0xFF8B5CF6));

    final hasBadges = catName != null ||
        walletName != null ||
        (!hideSavingsGoal && savingsGoal != null && savingsGoal is Map) ||
        tx['roomId'] != null ||
        roomName != null ||
        (tx['user'] != null && tx['user']['profile'] != null);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 14),

                Expanded(
                  child: GestureDetector(
                    onTap: onTitleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (formattedTime != null && formattedTime.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            formattedTime,
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: onAmountTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
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
                    ],
                  ),
                ),
              ],
            ),

            if (hasBadges) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                    children: [
                      _buildBadge(
                        text: catName ?? l10n.transaction,
                        textColor: catColor,
                        bgColor: catColor.withValues(alpha: 0.15),
                        fontWeight: FontWeight.w600,
                      ),
                      if (walletName != null) ...[
                        const SizedBox(width: 6),
                        _buildBadge(
                          text: '$walletEmoji $walletName',
                          textColor: walletColor,
                          bgColor: walletColor.withValues(alpha: 0.12),
                        ),
                      ],
                      if (!hideSavingsGoal && savingsGoal != null && savingsGoal is Map) ...[
                        const SizedBox(width: 6),
                        _buildBadge(
                          text: '$savingsEmoji ${savingsGoal['name']}',
                          textColor: savingsColor,
                          bgColor: savingsColor.withValues(alpha: 0.12),
                        ),
                      ],
                      if (tx['roomId'] != null || roomName != null) ...[
                        const SizedBox(width: 6),
                        _buildBadge(
                          text: roomName != null ? '$roomEmoji $roomName' : '👥 Room',
                          textColor: roomColor,
                          bgColor: roomColor.withValues(alpha: 0.15),
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                      if (tx['user'] != null && tx['user']['profile'] != null) ...[
                        const SizedBox(width: 6),
                        _buildMemberBadge(
                          name: (tx['user']['profile']['fullName'] ??
                              tx['user']['profile']['username'] ??
                              'User').toString(),
                          avatarUrl: tx['user']['profile']['avatar'] as String?,
                          email: tx['user']['email'] as String?,
                          color: AppColors.secondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color textColor,
    required Color bgColor,
    double maxWidth = 135.0,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: fontWeight,
          fontSize: 10.5,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildMemberBadge({
    required String name,
    required String? avatarUrl,
    required String? email,
    required Color color,
    double maxWidth = 135.0,
  }) {
    final initial = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : (email != null && email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'U');

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 6,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            backgroundColor: color,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.secondaryDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ],
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
