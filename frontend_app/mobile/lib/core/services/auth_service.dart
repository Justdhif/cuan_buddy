import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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

      try {
        await _storage.deleteAll();
        await Future.wait([
          _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
          _storage.write(
              key: AppConstants.refreshTokenKey, value: refreshToken),
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

      await clearTokens();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {

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

  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = data['exp'];
      if (exp == null) return true;

      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);

      return DateTime.now()
          .isAfter(expiryDate.subtract(const Duration(seconds: 30)));
    } catch (_) {

      return true;
    }
  }

  Future<bool> hasValidRefreshToken() async {
    try {
      final token = await getRefreshToken();
      if (token == null || token.isEmpty) return false;
      return !isTokenExpired(token);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasValidToken() async {
    try {
      return await hasValidRefreshToken();
    } catch (e) {
      return false;
    }
  }
}
