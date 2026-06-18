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

  bool get isConnected => _connected;

  /// Call this once the user is authenticated.
  /// [userId] is obtained from the profile API response.
  void connect(String userId) {
    if (_connected && _socket != null) return;

    // Strip /api prefix — socket.io connects at root
    final socketUrl = AppConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
    });

    _socket!.onDisconnect((_) {
      _connected = false;
    });

    _socket!.onConnectError((data) {
      _connected = false;
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
  }
}
