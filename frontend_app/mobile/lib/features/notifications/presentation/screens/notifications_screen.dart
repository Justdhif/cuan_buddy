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
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../../../shared/presentation/providers/shared_provider.dart';

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
        icon: Icons.notifications_none_rounded,
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

    IconData tileIcon = Icons.notifications_rounded;

    if (title == 'TRANSACTION_RECORDED') {
      title = l10n.newTransactionRecorded;
      tileIcon = Icons.account_balance_wallet_rounded;
      try {
        final payload = jsonDecode(message);
        final type = payload['type'];
        final amount = payload['amount'] is num
            ? (payload['amount'] as num).toDouble()
            : double.parse(payload['amount'].toString());
        final currency = payload['currency'] as String;
        final typeStr = type == 'income'
            ? l10n.incomeNotification
            : l10n.expenseNotification;
        final txCurrencySymbol = AppConstants.getCurrencySymbol(currency);
        final fmt = NumberFormat.currency(
            locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
        final amountStr = fmt.format(amount);
        message = l10n.transactionRecordedSuccess(typeStr, amountStr);

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
      tileIcon = Icons.pie_chart_rounded;
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
          title = l10n.newBudgetCreated;
          final limit = payload['limitAmount'] is num
              ? (payload['limitAmount'] as num).toDouble()
              : double.parse(payload['limitAmount'].toString());
          message = l10n.budgetSetTo(monthYear, formatWithConversion(limit));
        } else if (title == 'BUDGET_EXCEEDED') {
          title = l10n.budgetExceededNotification;
          final limit = payload['limitAmount'] is num
              ? (payload['limitAmount'] as num).toDouble()
              : double.parse(payload['limitAmount'].toString());
          final spent = payload['totalSpent'] is num
              ? (payload['totalSpent'] as num).toDouble()
              : double.parse(payload['totalSpent'].toString());
          message = l10n.budgetExceededWarning(monthYear, categoryName ?? 'kategori', formatWithConversion(limit), formatWithConversion(spent));
        } else if (title == 'BUDGET_WARNING') {
          title = l10n.budgetWarningNotification;
          final ratio = payload['ratio'] is num
              ? (payload['ratio'] as num).toDouble()
              : double.parse(payload['ratio'].toString());
          message = l10n.budgetWarningDetail((ratio * 100).round(), monthYear, categoryName ?? 'kategori');
        } else if (title == 'BUDGET_PREDICTION_WARNING') {
          title = l10n.budgetPredictionWarning;
          final predicted = payload['predicted'] is num
              ? (payload['predicted'] as num).toDouble()
              : double.parse(payload['predicted'].toString());
          message = l10n.budgetPredictionWarningDetail(monthYear, categoryName ?? 'kategori', formatWithConversion(predicted));
        }
      } catch (_) {
        if (title == 'BUDGET_CREATED') {
          title = l10n.newBudgetCreated;
        } else if (title == 'BUDGET_EXCEEDED') {
          title = l10n.budgetExceededNotification;
        } else if (title == 'BUDGET_WARNING') {
          title = l10n.budgetWarningNotification;
        } else if (title == 'BUDGET_PREDICTION_WARNING') {
          title = l10n.budgetPredictionWarning;
        }
      }
    } else if (title == 'FRIEND_REQUEST') {
      title = l10n.languageCode == 'id' ? 'Permintaan Pertemanan' : 'Friend Request';
      tileIcon = Icons.person_add_rounded;
      try {
        final payload = jsonDecode(message);
        final senderName = payload['senderName'] ?? payload['senderEmail'] ?? 'Seseorang';
        message = l10n.languageCode == 'id'
            ? '$senderName ingin berteman dengan Anda'
            : '$senderName wants to be friends with you';
      } catch (_) {}
    } else if (title == 'FRIEND_REQUEST_ACCEPTED') {
      title = l10n.languageCode == 'id' ? 'Pertemanan Diterima' : 'Friend Request Accepted';
      tileIcon = Icons.people_rounded;
      try {
        final payload = jsonDecode(message);
        final receiverName = payload['receiverName'] ?? payload['receiverEmail'] ?? 'Seseorang';
        message = l10n.languageCode == 'id'
            ? '$receiverName menerima permintaan pertemanan Anda'
            : '$receiverName accepted your friend request';
      } catch (_) {}
    } else if (title == 'FRIEND_REQUEST_DECLINED') {
      title = l10n.languageCode == 'id' ? 'Pertemanan Ditolak' : 'Friend Request Declined';
      tileIcon = Icons.person_remove_rounded;
      try {
        final payload = jsonDecode(message);
        final receiverName = payload['receiverName'] ?? payload['receiverEmail'] ?? 'Seseorang';
        message = l10n.languageCode == 'id'
            ? '$receiverName menolak permintaan pertemanan Anda'
            : '$receiverName declined your friend request';
      } catch (_) {}
    } else if (title == 'ROOM_INVITATION') {
      title = l10n.languageCode == 'id' ? 'Undangan Ruang' : 'Room Invitation';
      tileIcon = Icons.meeting_room_rounded;
      try {
        final payload = jsonDecode(message);
        final inviterName = payload['inviterName'] ?? 'Seseorang';
        final roomName = payload['roomName'] ?? 'Ruang';
        message = l10n.languageCode == 'id'
            ? '$inviterName mengundang Anda ke ruang $roomName'
            : '$inviterName invited you to room $roomName';
      } catch (_) {}
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
                tileIcon,
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
                  if (notif['title'] == 'FRIEND_REQUEST' && !isRead) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            try {
                              final payload = jsonDecode(notif['message']);
                              final friendshipId = payload['friendshipId'];
                              final error = await ref.read(sharedNotifierProvider.notifier).respondFriendRequest(friendshipId, 'accept');
                              if (context.mounted) {
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error), backgroundColor: AppColors.danger),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.languageCode == 'id' ? 'Berhasil menerima pertemanan' : 'Friend request accepted'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  ref.read(notificationsNotifierProvider.notifier).markAsRead(notif['id']);
                                  ref.read(notificationsNotifierProvider.notifier).fetchNotifications();
                                }
                              }
                            } catch (_) {}
                          },
                          child: Text(l10n.accept, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: Size.zero,
                            side: BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            try {
                              final payload = jsonDecode(notif['message']);
                              final friendshipId = payload['friendshipId'];
                              final error = await ref.read(sharedNotifierProvider.notifier).respondFriendRequest(friendshipId, 'decline');
                              if (context.mounted) {
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error), backgroundColor: AppColors.danger),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.languageCode == 'id' ? 'Berhasil menolak pertemanan' : 'Friend request declined'),
                                      backgroundColor: AppColors.textSecondaryDark,
                                    ),
                                  );
                                  ref.read(notificationsNotifierProvider.notifier).markAsRead(notif['id']);
                                  ref.read(notificationsNotifierProvider.notifier).fetchNotifications();
                                }
                              }
                            } catch (_) {}
                          },
                          child: Text(l10n.decline, style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
