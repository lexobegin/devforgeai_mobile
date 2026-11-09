// lib/core/network/api_client.dart
//
// Cliente HTTP basado en Dio.
//
// - Configura baseUrl, timeout y headers por defecto.
// - Interceptor de request: adjunta el JWT desde secure storage.
// - Interceptor de response:
//     - Normaliza errores a `ApiException`.
//     - Ante 401, intenta refrescar el access token UNA vez y reintenta.
//     - Si el refresh falla, dispara logout (limpia tokens).
//
// El cliente es un singleton accesible vía `ApiClient.instance`.
// No contiene lógica de negocio: los repositorios lo usan para hacer
// las requests concretas.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env.dart';

/// Excepción normalizada de la API.
class ApiException implements Exception {
  final int status;
  final String code;
  final String detail;
  final String? path;

  ApiException({
    required this.status,
    required this.code,
    required this.detail,
    this.path,
  });

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;
  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status $code): $detail';
}

/// Almacenamiento seguro de tokens.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccess() =>
      _storage.read(key: Env.storageKeyAccessToken);

  Future<String?> getRefresh() =>
      _storage.read(key: Env.storageKeyRefreshToken);

  Future<void> set({required String access, required String refresh}) async {
    await _storage.write(key: Env.storageKeyAccessToken, value: access);
    await _storage.write(key: Env.storageKeyRefreshToken, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: Env.storageKeyAccessToken);
    await _storage.delete(key: Env.storageKeyRefreshToken);
    await _storage.delete(key: Env.storageKeyUsuarioId);
  }
}

/// Cliente HTTP.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Duration(milliseconds: Env.apiTimeoutMs),
        receiveTimeout: Duration(milliseconds: Env.apiTimeoutMs),
        sendTimeout: Duration(milliseconds: Env.apiTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// Dio subyacente (para casos especiales como descargas).
  Dio get dio => _dio;

  // Flag para evitar múltiples refresh simultáneos.
  bool _isRefreshing = false;

  // Cola de requests esperando al refresh.
  final _pendingQueue = <_PendingRequest>[];

  // ==================================================================
  // Interceptores
  // ==================================================================
  void _setupInterceptors() {
    // ------------------------------------------------------------------
    // Request: adjuntar JWT
    // ------------------------------------------------------------------
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // ------------------------------------------------------------------
    // Response: normalizar errores + refresh automático
    // ------------------------------------------------------------------
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final response = error.response;

          // ----------------------------------------------------------
          // Sin respuesta (timeout, red, DNS)
          // ----------------------------------------------------------
          if (response == null) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: ApiException(
                  status: 0,
                  code: 'NETWORK_ERROR',
                  detail: _networkMessage(error),
                ),
                type: error.type,
              ),
            );
          }

          final status = response.statusCode ?? 0;
          final path = response.requestOptions.path;
          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/registro');

          // ----------------------------------------------------------
          // 401 → intentar refresh (excepto en endpoints de auth)
          // ----------------------------------------------------------
          if (status == 401 && !isAuthEndpoint) {
            final requestOptions = error.requestOptions;
            final retried = requestOptions.extra['_retry'] == true;

            if (retried) {
              await _forceLogout();
              return handler.reject(
                DioException(
                  requestOptions: requestOptions,
                  error: ApiException(
                    status: 401,
                    code: 'SESSION_EXPIRED',
                    detail: 'La sesión expiró. Inicie sesión nuevamente.',
                  ),
                ),
              );
            }

            // Si ya hay un refresh en curso, esperar
            if (_isRefreshing) {
              final completer = Completer<String?>();
              _pendingQueue.add(
                _PendingRequest(
                  completer: completer,
                  requestOptions: requestOptions,
                ),
              );
              final newToken = await completer.future;
              if (newToken == null) {
                await _forceLogout();
                return handler.reject(
                  DioException(
                    requestOptions: requestOptions,
                    error: ApiException(
                      status: 401,
                      code: 'SESSION_EXPIRED',
                      detail: 'La sesión expiró.',
                    ),
                  ),
                );
              }
              return _retryWithToken(requestOptions, newToken, handler);
            }

            // Iniciar refresh
            _isRefreshing = true;
            try {
              final newToken = await _refreshToken();
              _flushQueue(newToken);

              if (newToken == null) {
                await _forceLogout();
                return handler.reject(
                  DioException(
                    requestOptions: requestOptions,
                    error: ApiException(
                      status: 401,
                      code: 'SESSION_EXPIRED',
                      detail: 'La sesión expiró.',
                    ),
                  ),
                );
              }
              return _retryWithToken(requestOptions, newToken, handler);
            } catch (_) {
              _flushQueue(null);
              await _forceLogout();
              return handler.reject(
                DioException(
                  requestOptions: requestOptions,
                  error: ApiException(
                    status: 401,
                    code: 'SESSION_EXPIRED',
                    detail: 'La sesión expiró.',
                  ),
                ),
              );
            } finally {
              _isRefreshing = false;
            }
          }

          // ----------------------------------------------------------
          // Cualquier otro error → normalizar
          // ----------------------------------------------------------
          final data = response.data;
          final errorBody = data is Map<String, dynamic> ? data : {};

          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              error: ApiException(
                status: status,
                code: errorBody['error'] as String? ?? 'HTTP_$status',
                detail: errorBody['detail'] as String? ??
                    'Ocurrió un error inesperado',
                path: errorBody['path'] as String?,
              ),
              response: response,
            ),
          );
        },
      ),
    );
  }

  // ==================================================================
  // Refresh token
  // ==================================================================
  Future<String?> _refreshToken() async {
    final refresh = await TokenStorage.instance.getRefresh();
    if (refresh == null) return null;

    try {
      // Llamada directa sin pasar por _dio (evita loops)
      final response = await Dio(
        BaseOptions(baseUrl: Env.apiBaseUrl),
      ).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );

      final access = response.data?['access_token'] as String?;
      final newRefresh = response.data?['refresh_token'] as String?;
      if (access == null || newRefresh == null) return null;

      await TokenStorage.instance.set(
        access: access,
        refresh: newRefresh,
      );
      return access;
    } catch (_) {
      return null;
    }
  }

  void _flushQueue(String? token) {
    for (final pending in _pendingQueue) {
      pending.completer.complete(token);
    }
    _pendingQueue.clear();
  }

  Future<void> _retryWithToken(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra['_retry'] = true;
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        return handler.reject(e);
      }
      return handler.reject(
        DioException(
          requestOptions: options,
          error: ApiException(
            status: 0,
            code: 'RETRY_FAILED',
            detail: 'No se pudo reintentar la request.',
          ),
        ),
      );
    }
  }

  Future<void> _forceLogout() async {
    await TokenStorage.instance.clear();
    // Aquí se puede emitir un evento global que el authProvider escucha
  }

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La solicitud tardó demasiado. Verifique su conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor.';
      default:
        if (error.error is SocketException) {
          return 'No hay conexión a internet.';
        }
        return 'Error de red inesperado.';
    }
  }

  // ==================================================================
  // Métodos de conveniencia
  // ==================================================================
  Future<T> get<T>(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<T>(url, queryParameters: query);
    return response.data as T;
  }

  Future<T> post<T>(
    String url, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.post<T>(
      url,
      data: body,
      queryParameters: query,
    );
    return response.data as T;
  }

  Future<T> put<T>(
    String url, {
    Object? body,
  }) async {
    final response = await _dio.put<T>(url, data: body);
    return response.data as T;
  }

  Future<T> delete<T>(String url) async {
    final response = await _dio.delete<T>(url);
    return response.data as T;
  }

  /// Subida de archivos (multipart).
  Future<T> upload<T>(
    String url, {
    required String fieldName,
    required String filePath,
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?extraFields,
    });
    final response = await _dio.post<T>(url, data: formData);
    return response.data as T;
  }

  /// Descarga de archivos con progreso.
  Future<void> download(
    String url, {
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}

/// Item en la cola de espera durante un refresh.
class _PendingRequest {
  final Completer<String?> completer;
  final RequestOptions requestOptions;

  _PendingRequest({
    required this.completer,
    required this.requestOptions,
  });
}