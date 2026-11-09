// lib/features/auth/data/auth_repository.dart
//
// Repositorio de autenticación.
//
// Combina el datasource remoto con el almacenamiento seguro de tokens.
// Es lo que consumen los providers de Riverpod.
//
// Responsabilidades:
// - Delegar llamadas al datasource.
// - Persistir/limpiar tokens después de login/refresh/logout.
// - Exponer el usuario actual desde la sesión guardada.

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/usuario_entity.dart';
import 'auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  // ==================================================================
  // Registro
  // ==================================================================
  Future<Usuario> registro({
    required String nombreCompleto,
    required String email,
    required String password,
    RolGlobal? rol,
  }) {
    return _remote.registro(
      nombreCompleto: nombreCompleto,
      email: email,
      password: password,
      rol: rol,
    );
  }

  // ==================================================================
  // Login
  // ==================================================================
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _remote.login(email: email, password: password);
    await _persistTokens(tokens);
    return tokens;
  }

  // ==================================================================
  // Refresh (llamado por el interceptor de ApiClient cuando recibe 401)
  // ==================================================================
  Future<AuthTokens?> refresh() async {
    final refresh = await _tokenStorage.getRefresh();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final tokens = await _remote.refresh(refreshToken: refresh);
      await _persistTokens(tokens);
      return tokens;
    } catch (_) {
      // Si el refresh falla, limpiamos la sesión.
      await logout();
      return null;
    }
  }

  // ==================================================================
  // Cambio de contraseña
  // ==================================================================
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) {
    return _remote.cambiarPassword(
      passwordActual: passwordActual,
      passwordNueva: passwordNueva,
    );
  }

  // ==================================================================
  // Recuperar sesión al arrancar
  // ==================================================================
  /// Devuelve el usuario autenticado si hay tokens válidos, o null.
  /// Es lo que llama `bootstrap` al inicio de la app.
  Future<Usuario?> usuarioActual() async {
    final access = await _tokenStorage.getAccess();
    if (access == null || access.isEmpty) return null;

    try {
      return await _remote.me();
    } catch (_) {
      // Token inválido o expirado: intentar refresh.
      final tokens = await refresh();
      return tokens?.usuario;
    }
  }

  // ==================================================================
  // Logout
  // ==================================================================
  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  // ==================================================================
  // Helpers privados
  // ==================================================================
  Future<void> _persistTokens(AuthTokens tokens) async {
    await _tokenStorage.set(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
    );
  }
}

// ======================================================================
// Excepciones de auth (para que el provider pueda mapear errores)
// ======================================================================
@immutable
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}