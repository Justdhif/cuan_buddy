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

          final isId = ref.read(languageProvider) == 'id';
          final defaultCurrency = ref.read(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;

          Future<String> formatWithConversion(double amount, String currency) async {
            final txCurrencySymbol = AppConstants.getCurrencySymbol(currency);
            final fmt = NumberFormat.currency(locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
            String str = fmt.format(amount);
            if (currency != defaultCurrency) {
              try {
                final converted = await ref.read(convertedAmountProvider(ConversionParams(amount: amount, from: currency, to: defaultCurrency)).future);
                final defCurrencySymbol = AppConstants.getCurrencySymbol(defaultCurrency);
                final defFmt = NumberFormat.currency(locale: 'en_US', symbol: defCurrencySymbol, decimalDigits: 0);
                final convertedStr = defFmt.format(converted);
                str += ' (≈ $convertedStr)';
              } catch (_) {}
            }
            return str;
          }

          if (title == 'TRANSACTION_RECORDED') {
            title = isId ? 'Transaksi Baru Tercatat' : 'New Transaction Recorded';
            try {
              final payload = jsonDecode(message);
              final type = payload['type'];
              final amount = payload['amount'] is num ? (payload['amount'] as num).toDouble() : double.parse(payload['amount'].toString());
              final currency = payload['currency'] as String;
              
              final typeStr = type == 'income' ? (isId ? 'pemasukan' : 'income') : (isId ? 'pengeluaran' : 'expense');
              final amountStr = await formatWithConversion(amount, currency);
              message = isId 
                  ? 'Anda telah berhasil mencatat $typeStr sebesar $amountStr.'
                  : 'You have successfully recorded a $typeStr of $amountStr.';
            } catch (_) {}
          } else if (title == 'BUDGET_CREATED') {
            title = isId ? 'Anggaran Baru Dibuat' : 'New Budget Created';
            try {
              final payload = jsonDecode(message);
              final monthYear = payload['monthYear'];
              final limit = payload['limitAmount'] is num ? (payload['limitAmount'] as num).toDouble() : double.parse(payload['limitAmount'].toString());
              final currency = payload['currency'] as String;
              
              final limitStr = await formatWithConversion(limit, currency);
              message = isId 
                  ? 'Anggaran untuk bulan $monthYear telah diatur sebesar $limitStr.'
                  : 'Budget for $monthYear has been set to $limitStr.';
            } catch (_) {}
          } else if (title == 'BUDGET_EXCEEDED') {
            title = isId ? 'Batas Anggaran Terlampaui' : 'Budget Exceeded';
            try {
              final payload = jsonDecode(message);
              final monthYear = payload['monthYear'];
              final categoryName = payload['categoryName'] ?? 'kategori';
              final limit = payload['limitAmount'] is num ? (payload['limitAmount'] as num).toDouble() : double.parse(payload['limitAmount'].toString());
              final spent = payload['totalSpent'] is num ? (payload['totalSpent'] as num).toDouble() : double.parse(payload['totalSpent'].toString());
              final currency = payload['currency'] as String;
              
              final limitStr = await formatWithConversion(limit, currency);
              final spentStr = await formatWithConversion(spent, currency);
              message = isId 
                  ? 'Anda telah melampaui batas anggaran $monthYear untuk $categoryName! Batas: $limitStr, Terpakai: $spentStr'
                  : 'You have exceeded your $monthYear budget for $categoryName! Limit: $limitStr, Spent: $spentStr';
            } catch (_) {}
          } else if (title == 'BUDGET_WARNING') {
            title = isId ? 'Peringatan Anggaran' : 'Budget Warning';
            try {
              final payload = jsonDecode(message);
              final monthYear = payload['monthYear'];
              final categoryName = payload['categoryName'] ?? 'kategori';
              final ratio = payload['ratio'] is num ? (payload['ratio'] as num).toDouble() : double.parse(payload['ratio'].toString());
              message = isId 
                  ? 'Hati-hati! Anda telah menggunakan ${(ratio * 100).round()}% dari anggaran $monthYear untuk $categoryName.'
                  : 'Watch out! You have spent ${(ratio * 100).round()}% of your $monthYear budget for $categoryName.';
            } catch (_) {}
          } else if (title == 'BUDGET_PREDICTION_WARNING') {
            title = isId ? 'Peringatan Prediksi Anggaran' : 'Budget Prediction Warning';
            try {
              final payload = jsonDecode(message);
              final monthYear = payload['monthYear'];
              final categoryName = payload['categoryName'] ?? 'kategori';
              final predicted = payload['predicted'] is num ? (payload['predicted'] as num).toDouble() : double.parse(payload['predicted'].toString());
              final currency = payload['currency'] as String;
              
              final predictedStr = await formatWithConversion(predicted, currency);
              message = isId 
                  ? 'Berdasarkan pengeluaran Anda, Anda diprediksi akan melampaui anggaran $monthYear untuk $categoryName. Estimasi pengeluaran: $predictedStr'
                  : 'Based on your spending, you are projected to exceed your $monthYear budget for $categoryName. Estimated spend: $predictedStr';
            } catch (_) {}
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

