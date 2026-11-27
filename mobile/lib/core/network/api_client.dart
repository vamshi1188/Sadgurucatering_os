import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_response.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    Dio? dio,
    TokenStorage? secureStorage,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: connectTimeout,
               receiveTimeout: receiveTimeout,
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           ) {
    _secureStorage = secureStorage;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage?.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.endsWith('/auth/login')) {
            await _secureStorage?.clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static Future<ApiClient> create({
    required String baseUrl,
    Dio? dio,
    TokenStorage? secureStorage,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) async {
    return ApiClient(
      baseUrl: baseUrl,
      dio: dio,
      secureStorage: secureStorage ?? SecureStorage(),
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  final Dio _dio;
  late final TokenStorage? _secureStorage;
  TokenStorage? get secureStorage => _secureStorage;

  void Function()? onUnauthorized;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
      parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    T Function(dynamic data)? parser,
  }) {
    return _request(() => _dio.post<dynamic>(path, data: data), parser);
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    T Function(dynamic data)? parser,
  }) {
    return _request(() => _dio.patch<dynamic>(path, data: data), parser);
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data)? parser,
  ) async {
    try {
      final response = await request();

      final body = response.data;

      if (body is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid server response');
      }

      if (!body.containsKey('data')) {
        throw const ApiException(message: 'Invalid server response');
      }

      final data = parser == null ? body['data'] as T : parser(body['data']);

      String? requestId;

      final meta = body['meta'];
      if (meta is Map<String, dynamic>) {
        final value = meta['request_id'];
        if (value is String && value.isNotEmpty) {
          requestId = value;
        }
      }

      return ApiResponse<T>(data: data, requestId: requestId);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } on TypeError {
      throw const ApiException(message: 'Invalid server response');
    }
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      final errorBody = body['error'];

      if (errorBody is Map<String, dynamic>) {
        final code = errorBody['code'];
        final message = errorBody['message'];

        if (code is String && message is String) {
          return ApiException(
            code: code,
            message: message,
            statusCode: statusCode,
          );
        }
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'The request timed out',
        statusCode: statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'Unable to connect to the server',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: 'Unable to complete the request',
      statusCode: statusCode,
    );
  }
}
