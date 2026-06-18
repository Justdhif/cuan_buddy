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
  String toString() => 'AppException: $message (code: $code, status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode, super.code});
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
  static AppException fromStatusCode(int statusCode, {String? serverMessage}) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          message: serverMessage ?? 'Invalid data. Please check again 😊',
        );
      case 401:
        return AuthException(
          message: 'Oops, incorrect email or password 😅',
          statusCode: statusCode,
        );
      case 403:
        return AuthException(
          message: serverMessage?.contains('verifikasi') == true
              ? 'Account not verified. Check your email 📧'
              : 'You do not have access here 🚫',
          statusCode: statusCode,
        );
      case 404:
        return NetworkException(
          message: 'Data not found 🔍',
          statusCode: statusCode,
        );
      case 409:
        return ValidationException(
          message: serverMessage ?? 'Data already exists ⚠️',
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? 'Incorrect data format. Please check again 😊',
        );
      case 429:
        return NetworkException(
          message: 'Too many attempts. Please wait a moment ⏳',
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'Oops, the server is busy. Please try again later 🙏',
          statusCode: statusCode,
        );
      default:
        return NetworkException(
          message: 'An error occurred. Please try again later 😅',
          statusCode: statusCode,
        );
    }
  }

  static AppException fromConnectionError() {
    return const NetworkException(
      message: 'Internet connection issue. Please check your connection 📶',
    );
  }

  static AppException fromTimeout() {
    return const NetworkException(
      message: 'Slow connection. Please try again later ⏳',
    );
  }
}
