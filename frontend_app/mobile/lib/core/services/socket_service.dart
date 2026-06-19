import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import 'auth_service.dart';

/// Service that manages the Socket.IO connection with the backend.
/// The backend uses socket.io (@nestjs/websockets) and expects
/// the userId as a query param on connection: ?userId=xxx
class SocketService {
  SocketService({required this.authService});

  final AuthService authService;
  io.Socket? _socket;
  bool _connected = false;

  /// Callbacks invoked every time the socket successfully (re)connects.
  final List<void Function()> _onConnectCallbacks = [];

  bool get isConnected => _connected;

  /// Register a callback to be called when the socket connects (or reconnects).
  /// If the socket is already connected, the callback is invoked immediately.
  void onConnected(void Function() callback) {
    _onConnectCallbacks.add(callback);
    if (_connected) callback();
  }

  /// Remove a previously registered onConnected callback.
  void removeOnConnected(void Function() callback) {
    _onConnectCallbacks.remove(callback);
  }

  /// Call this once the user is authenticated.
  /// [userId] is obtained from the profile API response.
  void connect(String userId) {
    if (_connected && _socket != null) {
      // Already connected — fire callbacks immediately for late subscribers.
      for (final cb in List<void Function()>.from(_onConnectCallbacks)) {
        cb();
      }
      return;
    }

    // Strip /api prefix — socket.io connects at root
    final socketUrl = AppConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setQuery({'userId': userId})
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      // Fire all registered onConnect callbacks.
      for (final cb in List<void Function()>.from(_onConnectCallbacks)) {
        cb();
      }
    });

    _socket!.onDisconnect((_) {
      _connected = false;
    });

    _socket!.onConnectError((data) {
      _connected = false;
    });

    _socket!.on('reconnect', (_) {
      _connected = true;
      for (final cb in List<void Function()>.from(_onConnectCallbacks)) {
        cb();
      }
    });

    _socket!.connect();
  }

  /// Listen to a specific event from the server.
  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove listener for an event.
  void off(String event) {
    _socket?.off(event);
  }

  /// Disconnect and clean up.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _onConnectCallbacks.clear();
  }
}
