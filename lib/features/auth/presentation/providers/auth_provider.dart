// lib/features/auth/presentation/providers/auth_provider.dart
//
// Provider de autenticación.
//
// Mantiene el estado del usuario autenticado y expone las acciones:
// bootstrap, login, registro, logout, cambio de password.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/auth_remote_datasource.dart';
import '../../data/auth_repository.dart';
import '../../domain/usuario_entity.dart';

// ======================================================================
// Providers base del feature
// ======================================================================
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ======================================================================
// Estado de autenticación
// ======================================================================
@immutable
class AuthState {
  final Usuario? usuario;
  final bool isAuthenticated;
  final bool isBootstrapping;
  final bool isLoading;
  final ApiError? error;

  const AuthState({
    this.usuario,
    this.isAuthenticated = false,
    this.isBootstrapping = true,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    Usuario? usuario,
    bool? isAuthenticated,
    bool? isBootstrapping,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
    bool clearUsuario = false,
  }) {
    return AuthState(
      usuario: clearUsuario ? null : (usuario ?? this.usuario),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAdmin => usuario?.isAdmin ?? false;
}

// ======================================================================
// Notifier
// ======================================================================
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  // ==================================================================
  // Bootstrap: al arrancar la app
  // ==================================================================
  Future<void> bootstrap() async {
    print('[BOOTSTRAP] inicio');
    state = state.copyWith(isBootstrapping: true, clearError: true);
    try {
      print('[BOOTSTRAP] llamando usuarioActual');
      final usuario = await _repo.usuarioActual();
      print('[BOOTSTRAP] resultado: $usuario');
      if (usuario != null) {
        state = state.copyWith(
          usuario: usuario,
          isAuthenticated: true,
          isBootstrapping: false,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isBootstrapping: false,
          clearUsuario: true,
        );
      }
    } catch (e, st) {
      print('[BOOTSTRAP] error: $e\n$st');
      state = state.copyWith(
        isAuthenticated: false,
        isBootstrapping: false,
        clearUsuario: true,
      );
    }
  }

  // ==================================================================
  // Login
  // ==================================================================
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokens = await _repo.login(email: email, password: password);
      state = state.copyWith(
        usuario: tokens.usuario,
        isAuthenticated: true,
        //isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(
          status: e.status,
          code: e.code,
          detail: e.detail,
        ),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
      rethrow;
    }
  }

  // ==================================================================
  // Registro
  // ==================================================================
  Future<void> registro({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.registro(
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(
          status: e.status,
          code: e.code,
          detail: e.detail,
        ),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
      rethrow;
    }
  }

  // ==================================================================
  // Logout
  // ==================================================================
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(isBootstrapping: false);
  }

  // ==================================================================
  // Cambio de contraseña
  // ==================================================================
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.cambiarPassword(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );
      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(
          status: e.status,
          code: e.code,
          detail: e.detail,
        ),
      );
      rethrow;
    }
  }

  // ==================================================================
  // Refrescar usuario (por si cambia el perfil en otro lado)
  // ==================================================================
  Future<void> refrescarUsuario() async {
    if (!state.isAuthenticated) return;
    try {
      final usuario = await _repo.usuarioActual();
      if (usuario != null) {
        state = state.copyWith(usuario: usuario);
      }
    } catch (_) {
      // Silencioso
    }
  }

  // ==================================================================
  // Limpiar error
  // ==================================================================
  void limpiarError() {
    state = state.copyWith(clearError: true);
  }
}

// ======================================================================
// Provider principal
// ======================================================================
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// ======================================================================
// Derivados (selectores)
// ======================================================================
final usuarioActualProvider = Provider<Usuario?>((ref) {
  return ref.watch(authProvider).usuario;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});