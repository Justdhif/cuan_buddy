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
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await authService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await authService.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          await authService.clearTokens();
          handler.reject(_convertToAppException(err));
          return;
        }

        // Call refresh endpoint with current access token
        final refreshResponse = await dio.post(
          '/auth/refresh',
          options: Options(
            headers: {'Authorization': 'Bearer $refreshToken'},
          ),
        );

        final newAccessToken = refreshResponse.data['accessToken'] as String?;
        final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await authService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry original request
          final retryOptions = err.requestOptions.copyWith(
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newAccessToken',
            },
          );
          final retryResponse = await dio.fetch(retryOptions);
          _isRefreshing = false;
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        await authService.clearTokens();
      }
      _isRefreshing = false;
    }

    handler.reject(_convertToAppException(err));
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
