import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import 'api_exceptions.dart';

class DioClient {
  DioClient({required this.authService, required this.prefs}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(authService: authService, dio: _dio, prefs: prefs),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  late final Dio _dio;
  final AuthService authService;
  final PreferencesService prefs;

  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
      {required this.authService, required this.dio, required this.prefs});

  final AuthService authService;
  final Dio dio;
  final PreferencesService prefs;

  // ─── Refresh State ─────────────────────────────────────────────────────────
  // Completer dipakai agar multiple request yang expired secara bersamaan
  // hanya trigger satu refresh — yang lain menunggu hasilnya (seperti antrian).
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Lewati interceptor untuk endpoint refresh itu sendiri (pakai refresh token manual)
    if (options.path.endsWith('/auth/refresh')) {
      handler.next(options);
      return;
    }

    final accessToken = await authService.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      // Proactive refresh: jika access token expired/hampir expired, refresh dulu
      if (authService.isTokenExpired(accessToken)) {
        final refreshed = await _doRefresh();
        if (refreshed) {
          final newToken = await authService.getAccessToken();
          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
          }
        }
        // Tetap lanjut request (akan kena 401 jika refresh gagal → ditangani onError)
      } else {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 dari endpoint selain /auth/refresh → coba refresh lalu retry
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.endsWith('/auth/refresh')) {
      final refreshed = await _doRefresh();
      if (refreshed) {
        try {
          final newToken = await authService.getAccessToken();
          final retryOptions = err.requestOptions.copyWith(
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newToken',
            },
          );
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          // Retry gagal — lanjut ke error handling di bawah
        }
      }
      // Refresh gagal → hapus token agar user diarahkan ke login
      await authService.clearTokens();
    }

    handler.reject(_convertToAppException(err));
  }

  // ─── Core Refresh Logic ────────────────────────────────────────────────────
  /// Refresh access token menggunakan refresh token yang tersimpan.
  /// Jika sudah ada refresh yang sedang berjalan, request lain menunggu
  /// hasilnya via Completer (tidak ada race condition / double refresh).
  Future<bool> _doRefresh() async {
    // Jika ada refresh yang sedang berjalan, tunggu hasilnya
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    bool success = false;

    try {
      final refreshToken = await authService.getRefreshToken();

      // Kalau refresh token tidak ada atau sudah expired → tidak bisa refresh
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          authService.isTokenExpired(refreshToken)) {
        await authService.clearTokens();
      } else {
        // Gunakan Dio instance terpisah (tanpa interceptor) untuk menghindari loop
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final response = await refreshDio.post(
          '/auth/refresh',
          options: Options(
            headers: {'Authorization': 'Bearer $refreshToken'},
          ),
        );

        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await authService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          success = true;
        } else {
          await authService.clearTokens();
        }
      }
    } catch (_) {
      await authService.clearTokens();
    } finally {
      // Selesaikan semua request yang menunggu, reset state
      _refreshCompleter!.complete(success);
      _isRefreshing = false;
    }

    return success;
  }

  DioException _convertToAppException(DioException err) {
    AppException appException;
    final lang = prefs.languageCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      appException = ApiExceptionMapper.fromTimeout(lang: lang);
    } else if (err.type == DioExceptionType.connectionError) {
      appException = ApiExceptionMapper.fromConnectionError(lang: lang);
    } else if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;
      final serverMessage = _extractServerMessage(err.response!.data);
      appException = ApiExceptionMapper.fromStatusCode(
        statusCode,
        serverMessage: serverMessage,
        lang: lang,
      );
    } else {
      appException = NetworkException(
        message: lang == 'id'
            ? 'Terjadi kesalahan. Coba lagi nanti ya 😅'
            : 'Something went wrong. Please try again later 😅',
      );
    }

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
      message: appException.message,
    );
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString();
    }
    return null;
  }
}

extension RequestOptionsExtension on RequestOptions {
  RequestOptions copyWith({
    String? path,
    Map<String, dynamic>? headers,
    dynamic data,
  }) {
    return RequestOptions(
      path: path ?? this.path,
      method: method,
      headers: headers ?? this.headers,
      data: data ?? this.data,
      queryParameters: queryParameters,
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }
}

