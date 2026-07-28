import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

export 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dioClient: ref.watch(dioClientProvider),
    authService: ref.watch(authServiceProvider),
    preferencesService: ref.watch(preferencesServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthStateInitial());

  final AuthRepository _repository;

  Future<void> checkAuth() async {

    final hasRefreshToken = await _repository.authService.hasValidRefreshToken();
    if (!hasRefreshToken) {

      state = const AuthStateUnauthenticated();
      return;
    }

    final accessToken = await _repository.authService.getAccessToken();
    final needsRefresh = accessToken == null ||
        accessToken.isEmpty ||
        _repository.authService.isTokenExpired(accessToken);

    if (needsRefresh) {

      final refreshed = await _repository.refreshTokens();
      if (!refreshed) {

        state = const AuthStateUnauthenticated();
        return;
      }
    }

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
    if (e is DioException) {
      if (e.error is AppException) {
        return (e.error as AppException).message;
      }
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final msg = data['message'] ?? data['error'] ?? data['detail'];
        if (msg != null && msg.toString().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    if (e is AppException) {
      return e.message;
    }
    final msg = e.toString();
    if (msg.contains('AppException:')) {
      return msg.replaceAll('AppException: ', '').split('(code:').first.trim();
    }
    return 'Terjadi kesalahan. Silakan coba lagi 😅';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
