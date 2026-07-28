import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import 'auth_service.dart';

class SocketService {
  SocketService({required this.authService});

  final AuthService authService;
  io.Socket? _socket;
  bool _connected = false;

  final List<void Function()> _onConnectCallbacks = [];

  bool get isConnected => _connected;

  void onConnected(void Function() callback) {
    _onConnectCallbacks.add(callback);
    if (_connected) callback();
  }

  void removeOnConnected(void Function() callback) {
    _onConnectCallbacks.remove(callback);
  }

  void connect(String userId) {
    if (_connected && _socket != null) {

      for (final cb in List<void Function()>.from(_onConnectCallbacks)) {
        cb();
      }
      return;
    }

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

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _onConnectCallbacks.clear();
  }
}
