import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/socket_service.dart';

// ─── Core Services ────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope overrides');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

// ─── Network ──────────────────────────────────────────────────────────────────
final dioClientProvider = Provider<DioClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return DioClient(authService: authService, prefs: prefs);
});

// ─── Socket.IO (Real-time) ────────────────────────────────────────────────────
final socketServiceProvider = Provider<SocketService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final socket = SocketService(authService: authService);
  ref.onDispose(socket.disconnect);
  return socket;
});
