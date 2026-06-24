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
    final isIndo = lang == 'id';
    switch (statusCode) {
      case 400:
        return ValidationException(
          message: serverMessage ??
              (isIndo
                  ? 'Data tidak valid. Silakan periksa kembali 😊'
                  : 'Invalid data. Please check again 😊'),
        );
      case 401:
        return AuthException(
          message: isIndo
              ? 'Oops, email atau password salah 😅'
              : 'Oops, incorrect email or password 😅',
          statusCode: statusCode,
        );
      case 403:
        return AuthException(
          message: serverMessage?.contains('verifikasi') == true ||
                  serverMessage?.toLowerCase().contains('verify') == true
              ? (isIndo
                  ? 'Akun belum diverifikasi. Periksa email Anda 📧'
                  : 'Account not verified. Check your email 📧')
              : (isIndo
                  ? 'Anda tidak memiliki akses di sini 🚫'
                  : 'You do not have access here 🚫'),
          statusCode: statusCode,
        );
      case 404:
        return NetworkException(
          message: isIndo ? 'Data tidak ditemukan 🔍' : 'Data not found 🔍',
          statusCode: statusCode,
        );
      case 409:
        return ValidationException(
          message: serverMessage ??
              (isIndo ? 'Data sudah ada ⚠️' : 'Data already exists ⚠️'),
        );
      case 422:
        return ValidationException(
          message: serverMessage ??
              (isIndo
                  ? 'Format data salah. Silakan periksa kembali 😊'
                  : 'Incorrect data format. Please check again 😊'),
        );
      case 429:
        return NetworkException(
          message: isIndo
              ? 'Terlalu banyak percobaan. Silakan tunggu sebentar ⏳'
              : 'Too many attempts. Please wait a moment ⏳',
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: isIndo
              ? 'Oops, server sedang sibuk. Silakan coba lagi nanti 🙏'
              : 'Oops, the server is busy. Please try again later 🙏',
          statusCode: statusCode,
        );
      default:
        return NetworkException(
          message: isIndo
              ? 'Terjadi kesalahan. Silakan coba lagi nanti 😅'
              : 'An error occurred. Please try again later 😅',
          statusCode: statusCode,
        );
    }
  }

  static AppException fromConnectionError({String lang = 'en'}) {
    final isIndo = lang == 'id';
    return NetworkException(
      message: isIndo
          ? 'Masalah koneksi internet. Silakan periksa koneksi Anda 📶'
          : 'Internet connection issue. Please check your connection 📶',
    );
  }

  static AppException fromTimeout({String lang = 'en'}) {
    final isIndo = lang == 'id';
    return NetworkException(
      message: isIndo
          ? 'Koneksi lambat. Silakan coba lagi nanti ⏳'
          : 'Slow connection. Please try again later ⏳',
    );
  }
}
