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
    // Langkah 1: Cek apakah refresh token ada dan masih valid
    final hasRefreshToken = await _repository.authService.hasValidRefreshToken();
    if (!hasRefreshToken) {
      // Tidak ada refresh token atau sudah expired → harus login ulang
      state = const AuthStateUnauthenticated();
      return;
    }

    // Langkah 2: Cek apakah access token perlu di-refresh
    final accessToken = await _repository.authService.getAccessToken();
    final needsRefresh = accessToken == null ||
        accessToken.isEmpty ||
        _repository.authService.isTokenExpired(accessToken);

    if (needsRefresh) {
      // Access token expired tapi refresh token masih valid → refresh dulu
      final refreshed = await _repository.refreshTokens();
      if (!refreshed) {
        // Refresh gagal (misal server down, token dicabut) → harus login ulang
        state = const AuthStateUnauthenticated();
        return;
      }
    }

    // Langkah 3: Load profile untuk verifikasi session masih valid
    try {
      final profile = await _repository.getProfile();
      final fullName = profile['fullName'] as String?;
      if (fullName == null || fullName.trim().isEmpty) {
        await _repository.preferencesService.setProfileComplete(false);
      } else {
        await _repository.preferencesService.setProfileComplete(true);
      }
      state = const AuthStateAuthenticated();
    } catch (_) {
      state = const AuthStateUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthStateLoading();
    try {
      await _repository.login(email: email, password: password);
      try {
        final profile = await _repository.getProfile();
        final fullName = profile['fullName'] as String?;
        if (fullName == null || fullName.trim().isEmpty) {
          await _repository.preferencesService.setProfileComplete(false);
        } else {
          await _repository.preferencesService.setProfileComplete(true);
        }
      } catch (_) {
        await _repository.preferencesService.setProfileComplete(false);
      }
      state = const AuthStateAuthenticated();
    } catch (e) {
      state = AuthStateError(_extractMessage(e));
    }
  }

  Future<String?> register({
    required String email,
    required String password,
  }) async {
    state = const AuthStateLoading();
    try {
      final message = await _repository.register(
        email: email,
        password: password,
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
      return msg.replaceAll('AppException: ', '').split('(code:').first.trim();
    }
    return 'An error occurred. Please try again 😅';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
