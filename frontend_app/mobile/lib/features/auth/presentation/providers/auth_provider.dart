import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

export 'auth_state.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dioClient: ref.watch(dioClientProvider),
    authService: ref.watch(authServiceProvider),
    preferencesService: ref.watch(preferencesServiceProvider),
  );
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthStateInitial());

  final AuthRepository _repository;

  Future<void> checkAuth() async {
    final hasToken = await _repository.hasToken();
    state = hasToken ? const AuthStateAuthenticated() : const AuthStateUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthStateLoading();
    try {
      await _repository.login(email: email, password: password);
      state = const AuthStateAuthenticated();
    } catch (e) {
      state = AuthStateError(_extractMessage(e));
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthStateLoading();
    try {
      final message = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AuthStateUnauthenticated();
      return message;
    } catch (e) {
      state = AuthStateError(_extractMessage(e));
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthStateUnauthenticated();
  }

  Future<String> sendVerificationEmail(String email) async {
    try {
      return await _repository.sendVerificationEmail(email);
    } catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<bool> checkVerificationStatus(String email) async {
    try {
      return await _repository.checkVerificationStatus(email);
    } catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  void clearError() {
    state = const AuthStateUnauthenticated();
  }

  String _extractMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('DioException')) {
      // Extract friendly message from DioException
      final match = RegExp(r'message: (.+?)[\)\]|$]').firstMatch(msg);
      if (match != null) return match.group(1)!.trim();
    }
    // Try extracting from AppException format
    if (msg.contains('AppException:')) {
      return msg
          .replaceAll('AppException: ', '')
          .split('(code:')
          .first
          .trim();
    }
    return 'An error occurred. Please try again 😅';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
