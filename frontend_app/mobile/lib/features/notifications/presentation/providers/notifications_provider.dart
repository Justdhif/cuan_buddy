import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/notification_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';

class NotificationsState {
  final List<dynamic> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<dynamic>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this.ref) : super(NotificationsState()) {
    fetchNotifications();
    _subscribeToSocket();
  }

  final Ref ref;

  /// Register socket listener so real-time updates work regardless of
  /// which screen is active.  We defer actual `.on()` registration until
  /// the socket has established a connection to avoid missing events.
  void _subscribeToSocket() {
    final socket = ref.read(socketServiceProvider);

    void registerListener() {
      // Remove any stale listener first to prevent duplicates on reconnect.
      socket.off('new_notification');

      socket.on('new_notification', (data) async {
        // 1. Update local state optimistically for instant UI refresh.
        if (data is Map) {
          final newNotif = Map<String, dynamic>.from(data);
          final updated = [newNotif, ...state.notifications];
          state = state.copyWith(notifications: updated);

          // 2. Push a local notification so the user sees it even when
          //    the app is in the background / notification shade is open.
          String title = newNotif['title'] as String? ?? 'CuanBuddy';
          String message = newNotif['message'] as String? ??
              newNotif['body'] as String? ??
              'You have a new notification';

          if (title == 'TRANSACTION_RECORDED') {
            final isId = ref.read(languageProvider) == 'id';
            title = isId ? 'Transaksi Baru Tercatat' : 'New Transaction Recorded';
            final defaultCurrency = ref.read(profileProvider).value?['currency'] as String? ?? AppConstants.defaultCurrency;
            
            try {
              final payload = jsonDecode(message);
              final type = payload['type'];
              final amount = payload['amount'] is num ? (payload['amount'] as num).toDouble() : double.parse(payload['amount'].toString());
              final currency = payload['currency'] as String;
              
              final typeStr = type == 'income' ? (isId ? 'pemasukan' : 'income') : (isId ? 'pengeluaran' : 'expense');
              final txCurrencySymbol = AppConstants.getCurrencySymbol(currency);
              final fmt = NumberFormat.currency(locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
              final amountStr = fmt.format(amount);
              
              String finalMessage = isId 
                  ? 'Anda telah berhasil mencatat $typeStr sebesar $amountStr.'
                  : 'You have successfully recorded a $typeStr of $amountStr.';
                  
              if (currency != defaultCurrency) {
                try {
                  final converted = await ref.read(convertedAmountProvider(ConversionParams(amount: amount, from: currency, to: defaultCurrency)).future);
                  final defCurrencySymbol = AppConstants.getCurrencySymbol(defaultCurrency);
                  final defFmt = NumberFormat.currency(locale: 'en_US', symbol: defCurrencySymbol, decimalDigits: 0);
                  final convertedStr = defFmt.format(converted);
                  finalMessage += ' (≈ $convertedStr)';
                } catch (_) {}
              }
              
              message = finalMessage;
            } catch (_) {
              // fallback
            }
          }

          NotificationService().showSocketNotification(
            id: Random().nextInt(100000),
            title: title,
            body: message,
          );
        }

        // 3. Also do a full fetch to sync with server-formatted data.
        fetchNotifications();
      });
    }

    // Register immediately if socket is already connected; otherwise wait.
    socket.onConnected(registerListener);
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/notifications');
      final data = response.data;
      if (data is List) {
        state = state.copyWith(notifications: data, isLoading: false);
      } else if (data is Map && data['data'] is List) {
        state = state.copyWith(notifications: data['data'], isLoading: false);
      } else {
        state = state.copyWith(notifications: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/notifications/$id/read');

      // Update local state optimistically
      final updated = state.notifications.map((n) {
        if (n['id'] == id) {
          return {...(n as Map), 'isRead': true};
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      // Ignore or show error
    }
  }

  @override
  void dispose() {
    // Clean up socket listener and onConnect callback when provider is disposed
    final socket = ref.read(socketServiceProvider);
    socket.off('new_notification');
    super.dispose();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
