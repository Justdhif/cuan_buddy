import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_id.dart';

class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() =>
      'AppException: $message (code: $code, status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException(
      {required super.message, super.statusCode, super.code});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode, super.code});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode, super.code});
}

class ApiExceptionMapper {
  static AppException fromStatusCode(int statusCode,
      {String? serverMessage, String lang = 'en'}) {
    final l10n = lang == 'id' ? AppLocalizationsId() : AppLocalizationsEn();
    switch (statusCode) {
      case 400:
        return ValidationException(
          message: serverMessage ?? l10n.errInvalidData,
        );
      case 401:
        return AuthException(
          message: l10n.errAuthFailed,
          statusCode: statusCode,
        );
      case 403:
        return AuthException(
          message: serverMessage?.contains('verifikasi') == true ||
                  serverMessage?.toLowerCase().contains('verify') == true
              ? l10n.errUnverifiedAccount
              : l10n.errNoAccess,
          statusCode: statusCode,
        );
      case 404:
        return NetworkException(
          message: l10n.errDataNotFound,
          statusCode: statusCode,
        );
      case 409:
        return ValidationException(
          message: serverMessage ?? l10n.errDataExists,
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? l10n.errInvalidFormat,
        );
      case 429:
        return NetworkException(
          message: l10n.errTooManyRequests,
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: l10n.errServerBusy,
          statusCode: statusCode,
        );
      default:
        return NetworkException(
          message: l10n.errGeneric,
          statusCode: statusCode,
        );
    }
  }

  static AppException fromConnectionError({String lang = 'en'}) {
    final l10n = lang == 'id' ? AppLocalizationsId() : AppLocalizationsEn();
    return NetworkException(
      message: l10n.errNoInternet,
    );
  }

  static AppException fromTimeout({String lang = 'en'}) {
    final l10n = lang == 'id' ? AppLocalizationsId() : AppLocalizationsEn();
    return NetworkException(
      message: l10n.errTimeout,
    );
  }
}
