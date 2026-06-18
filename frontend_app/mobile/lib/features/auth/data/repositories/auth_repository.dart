import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../models/auth_model.dart';

class AuthRepository {
  AuthRepository({
    required this.dioClient,
    required this.authService,
    required this.preferencesService,
  });

  final DioClient dioClient;
  final AuthService authService;
  final PreferencesService preferencesService;

  Dio get _dio => dioClient.dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await authService.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<String> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Registration successful!';
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await authService.clearTokens();
    await preferencesService.setProfileComplete(false);
    await preferencesService.setBackupSetupComplete(false);
  }

  Future<String> sendVerificationEmail(String email) async {
    final response = await _dio.post('/auth/send-verification', data: {'email': email});
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Verification email sent!';
  }

  Future<bool> checkVerificationStatus(String email) async {
    final response = await _dio.get('/auth/status', queryParameters: {'email': email});
    final data = response.data as Map<String, dynamic>;
    return data['isActive'] as bool? ?? false;
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _dio.post('/auth/forgot-password', data: {'email': email});
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'OTP sent!';
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Password successfully changed!';
  }

  Future<bool> hasToken() => authService.hasValidToken();
}
