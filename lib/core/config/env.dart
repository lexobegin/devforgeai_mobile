// lib/core/config/env.dart
//
// Configuración de entorno de la app móvil.
//
// Lee las variables desde `--dart-define` en tiempo de compilación:
//
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api/v1
//
// Los valores por defecto están pensados para el emulador de Android
// (10.0.2.2 es el host local desde el emulador).

import 'package:flutter/foundation.dart';

/// Configuración inmutable de la app.
class Env {
  const Env._();

  // ==================================================================
  // Backend
  // ==================================================================
  /// URL base de la API REST.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://10.0.2.2:8000/api/v1',
    defaultValue: 'http://192.168.1.4:8000/api/v1',
    //defaultValue: 'https://api-devforgeai.duckdns.org/api/v1',
  );

  // ==================================================================
  // Entorno
  // ==================================================================
  /// Entorno actual: 'development', 'production' o 'test'.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Versión de la app.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.3.0',
  );

  // ==================================================================
  // Timeouts
  // ==================================================================
  /// Timeout por defecto de las requests HTTP (ms).
  static const int apiTimeoutMs = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 30000,
  );

  // ==================================================================
  // Helpers
  // ==================================================================
  static bool get isDev => appEnv == 'development';
  static bool get isProd => appEnv == 'production';

  /// Claves de almacenamiento seguro.
  static const String storageKeyAccessToken = 'devforge_access_token';
  static const String storageKeyRefreshToken = 'devforge_refresh_token';
  static const String storageKeyUsuarioId = 'devforge_usuario_id';

  /// Log para debug (solo en modo desarrollo).
  static void log(String message) {
    if (isDev) {
      debugPrint('[DevForge] $message');
    }
  }
}