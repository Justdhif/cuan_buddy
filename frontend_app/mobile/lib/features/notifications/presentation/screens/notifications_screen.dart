import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../providers/notifications_provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (notifState.notifications
              .any((n) => !(n['isRead'] as bool? ?? false)))
            TextButton(
              onPressed: () {
                // Mark all as read
                for (final n in notifState.notifications) {
                  final id = n['id'] as String?;
                  final isRead = n['isRead'] as bool? ?? false;
                  if (id != null && !isRead) {
                    ref
                        .read(notificationsNotifierProvider.notifier)
                        .markAsRead(id);
                  }
                }
              },
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationsNotifierProvider.notifier)
            .fetchNotifications(),
        color: AppColors.primary,
        child: _buildBody(context, ref, notifState, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      NotificationsState state, bool isDark) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && state.notifications.isEmpty) {
      return AppErrorState(message: state.error!);
    }
    if (state.notifications.isEmpty) {
      return AppEmptyState(
        emoji: '🔔',
        title: l10n.noNotifications,
        subtitle: l10n.noNotificationsSubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final notif = state.notifications[index];
        return _NotificationTile(
          notif: notif,
          onTap: () {
            final id = notif['id'] as String?;
            final isRead = notif['isRead'] as bool? ?? false;
            if (id != null && !isRead) {
              ref.read(notificationsNotifierProvider.notifier).markAsRead(id);
            }
          },
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notif, required this.onTap});
  final dynamic notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = notif['isRead'] as bool? ?? false;
    String title = notif['title'] as String? ?? l10n.notification;
    String message = notif['message'] as String? ?? '';
    final createdAt = notif['createdAtFormatted'] as String? ?? '';

    if (title == 'TRANSACTION_RECORDED') {
      final isId = ref.watch(languageProvider) == 'id';
      title = isId ? 'Transaksi Baru Tercatat' : 'New Transaction Recorded';
      try {
        final payload = jsonDecode(message);
        final type = payload['type'];
        final amount = payload['amount'] is num
            ? (payload['amount'] as num).toDouble()
            : double.parse(payload['amount'].toString());
        final currency = payload['currency'] as String;
        final typeStr = type == 'income'
            ? (isId ? 'pemasukan' : 'income')
            : (isId ? 'pengeluaran' : 'expense');
        final txCurrencySymbol = AppConstants.getCurrencySymbol(currency);
        final fmt = NumberFormat.currency(
            locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
        final amountStr = fmt.format(amount);
        message = isId
            ? 'Anda telah berhasil mencatat $typeStr sebesar $amountStr.'
            : 'You have successfully recorded a $typeStr of $amountStr.';

        final defaultCurrency =
            ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
                AppConstants.defaultCurrency;
        if (currency != defaultCurrency) {
          final convertedAsync = ref.watch(convertedAmountProvider(
              ConversionParams(
                  amount: amount, from: currency, to: defaultCurrency)));
          final defCurrencySymbol =
              AppConstants.getCurrencySymbol(defaultCurrency);
          final defFmt = NumberFormat.currency(
              locale: 'en_US', symbol: defCurrencySymbol, decimalDigits: 0);
          final convertedText = convertedAsync.maybeWhen(
            data: (converted) => ' (≈ ${defFmt.format(converted)})',
            orElse: () => '',
          );
          message += convertedText;
        }
      } catch (_) {}
    } else if (title == 'BUDGET_EXCEEDED' ||
        title == 'BUDGET_WARNING' ||
        title == 'BUDGET_PREDICTION_WARNING' ||
        title == 'BUDGET_CREATED') {
      final isId = ref.watch(languageProvider) == 'id';

      try {
        final payload = jsonDecode(message);
        final monthYear = payload['monthYear'] as String;
        final categoryName = payload['categoryName'] as String?;
        final currency =
            payload['currency'] as String? ?? AppConstants.defaultCurrency;
        final txCurrencySymbol = AppConstants.getCurrencySymbol(currency);
        final fmt = NumberFormat.currency(
            locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
        final defaultCurrency =
            ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
                AppConstants.defaultCurrency;
        final defCurrencySymbol =
            AppConstants.getCurrencySymbol(defaultCurrency);
        final defFmt = NumberFormat.currency(
            locale: 'en_US', symbol: defCurrencySymbol, decimalDigits: 0);

        String formatWithConversion(double amount) {
          String str = fmt.format(amount);
          if (currency != defaultCurrency) {
            final convertedAsync = ref.watch(convertedAmountProvider(
                ConversionParams(
                    amount: amount, from: currency, to: defaultCurrency)));
            final convertedText = convertedAsync.maybeWhen(
              data: (converted) => ' (≈ ${defFmt.format(converted)})',
              orElse: () => '',
            );
            str += convertedText;
          }
          return str;
        }

        if (title == 'BUDGET_CREATED') {
          title = isId ? 'Anggaran Baru Dibuat' : 'New Budget Created';
          final limit = payload['limitAmount'] is num
              ? (payload['limitAmount'] as num).toDouble()
              : double.parse(payload['limitAmount'].toString());
          message = isId
              ? 'Anggaran untuk bulan $monthYear telah diatur sebesar ${formatWithConversion(limit)}.'
              : 'Budget for $monthYear has been set to ${formatWithConversion(limit)}.';
        } else if (title == 'BUDGET_EXCEEDED') {
          title = isId ? 'Batas Anggaran Terlampaui' : 'Budget Exceeded';
          final limit = payload['limitAmount'] is num
              ? (payload['limitAmount'] as num).toDouble()
              : double.parse(payload['limitAmount'].toString());
          final spent = payload['totalSpent'] is num
              ? (payload['totalSpent'] as num).toDouble()
              : double.parse(payload['totalSpent'].toString());
          message = isId
              ? 'Anda telah melampaui batas anggaran $monthYear untuk $categoryName! Batas: ${formatWithConversion(limit)}, Terpakai: ${formatWithConversion(spent)}'
              : 'You have exceeded your $monthYear budget for $categoryName! Limit: ${formatWithConversion(limit)}, Spent: ${formatWithConversion(spent)}';
        } else if (title == 'BUDGET_WARNING') {
          title = isId ? 'Peringatan Anggaran' : 'Budget Warning';
          final ratio = payload['ratio'] is num
              ? (payload['ratio'] as num).toDouble()
              : double.parse(payload['ratio'].toString());
          message = isId
              ? 'Hati-hati! Anda telah menggunakan ${(ratio * 100).round()}% dari anggaran $monthYear untuk $categoryName.'
              : 'Watch out! You have spent ${(ratio * 100).round()}% of your $monthYear budget for $categoryName.';
        } else if (title == 'BUDGET_PREDICTION_WARNING') {
          title = isId
              ? 'Peringatan Prediksi Anggaran'
              : 'Budget Prediction Warning';
          final predicted = payload['predicted'] is num
              ? (payload['predicted'] as num).toDouble()
              : double.parse(payload['predicted'].toString());
          message = isId
              ? 'Berdasarkan pengeluaran Anda, Anda diprediksi akan melampaui anggaran $monthYear untuk $categoryName. Estimasi pengeluaran: ${formatWithConversion(predicted)}'
              : 'Based on your spending, you are projected to exceed your $monthYear budget for $categoryName. Estimated spend: ${formatWithConversion(predicted)}';
        }
      } catch (_) {
        if (title == 'BUDGET_CREATED') {
          title = isId ? 'Anggaran Baru Dibuat' : 'New Budget Created';
        } else if (title == 'BUDGET_EXCEEDED') {
          title = isId ? 'Batas Anggaran Terlampaui' : 'Budget Exceeded';
        } else if (title == 'BUDGET_WARNING') {
          title = isId ? 'Peringatan Anggaran' : 'Budget Warning';
        } else if (title == 'BUDGET_PREDICTION_WARNING') {
          title = isId
              ? 'Peringatan Prediksi Anggaran'
              : 'Budget Prediction Warning';
        }
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot indicator for unread
            Container(
              margin: const EdgeInsets.only(top: 6, right: 12),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : AppColors.primary,
              ),
            ),
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? (isDark ? AppColors.surfaceDark : const Color(0xFFF0EFF8))
                    : AppColors.primary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: isRead
                    ? (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
