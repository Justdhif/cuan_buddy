import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

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

  /// Register socket listener immediately when the notifier is created
  /// so real-time updates work regardless of which screen is active.
  void _subscribeToSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.on('new_notification', (data) {
      // Prepend new notification to list for instant UI update,
      // then do a full refresh to sync with server.
      if (data is Map) {
        final newNotif = Map<String, dynamic>.from(data);
        final updated = [newNotif, ...state.notifications];
        state = state.copyWith(notifications: updated);
      }
      // Also do a full fetch to get server-formatted data
      fetchNotifications();
    });
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
    // Clean up socket listener when provider is disposed
    ref.read(socketServiceProvider).off('new_notification');
    super.dispose();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
