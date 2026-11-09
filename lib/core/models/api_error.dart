// lib/core/models/api_error.dart
//
// Error normalizado de la API.
//
// Refleja el formato uniforme que devuelve el backend:
//   {
//     "error": "NOT_FOUND",
//     "detail": "El proyecto no existe",
//     "path": "/api/v1/proyectos/42"
//   }

import 'package:flutter/foundation.dart';

@immutable
class ApiError {
  final int status;
  final String code;
  final String detail;
  final String? path;
  final Map<String, dynamic>? extra;

  const ApiError({
    required this.status,
    required this.code,
    required this.detail,
    this.path,
    this.extra,
  });

  // ==================================================================
  // Getters semánticos
  // ==================================================================
  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;
  bool get isServer => status >= 500;

  /// Mensaje apto para mostrar al usuario.
  String get userMessage {
    if (isNetwork) return detail;
    if (isUnauthorized) return 'La sesión expiró. Iniciá sesión nuevamente.';
    if (isForbidden) return 'No tenés permisos para hacer esto.';
    if (isNotFound) return detail.isEmpty ? 'Recurso no encontrado.' : detail;
    if (isConflict) return detail.isEmpty ? 'Conflicto con el estado actual.' : detail;
    if (isValidation) return detail.isEmpty ? 'Datos inválidos.' : detail;
    if (isServer) return 'Error en el servidor. Intentá de nuevo más tarde.';
    return detail.isEmpty ? 'Ocurrió un error inesperado.' : detail;
  }

  // ==================================================================
  // Constructores auxiliares
  // ==================================================================
  factory ApiError.fromJson(
    Map<String, dynamic> json, {
    int? status,
  }) {
    return ApiError(
      status: status ?? 500,
      code: (json['error'] as String?) ?? 'UNKNOWN_ERROR',
      detail: (json['detail'] as String?) ?? 'Error inesperado.',
      path: json['path'] as String?,
      extra: (json['extra'] as Map?)?.cast<String, dynamic>(),
    );
  }

  factory ApiError.network([String? message]) {
    return ApiError(
      status: 0,
      code: 'NETWORK_ERROR',
      detail: message ?? 'No se pudo conectar con el servidor.',
    );
  }

  factory ApiError.unknown([String? message]) {
    return ApiError(
      status: 0,
      code: 'UNKNOWN_ERROR',
      detail: message ?? 'Ocurrió un error inesperado.',
    );
  }

  // ==================================================================
  // CopyWith y toString
  // ==================================================================
  ApiError copyWith({
    int? status,
    String? code,
    String? detail,
    String? path,
    Map<String, dynamic>? extra,
  }) {
    return ApiError(
      status: status ?? this.status,
      code: code ?? this.code,
      detail: detail ?? this.detail,
      path: path ?? this.path,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() => 'ApiError($status $code): $detail';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError &&
        other.status == status &&
        other.code == code &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(status, code, detail);
}