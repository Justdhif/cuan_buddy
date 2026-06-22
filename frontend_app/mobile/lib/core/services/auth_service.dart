import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Token Management ────────────────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
        _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      // If saving fails (e.g. key corruption), attempt to clear and retry once
      try {
        await _storage.deleteAll();
        await Future.wait([
          _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
          _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
        ]);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      // If decryption fails, clear tokens to resolve the error state
      await clearTokens();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      // If decryption fails, clear tokens to resolve the error state
      await clearTokens();
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.accessTokenKey),
        _storage.delete(key: AppConstants.refreshTokenKey),
      ]);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }

  Future<bool> hasValidToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
