// lib/features/auth/data/auth_remote_datasource.dart
//
// Datasource remoto de autenticación.
//
// Se encarga exclusivamente de hablar con la API: no aplica reglas de
// negocio ni persiste nada. Devuelve entidades de dominio (ya mapeadas).

import '../../../core/network/api_client.dart';
import '../domain/usuario_entity.dart';
import 'usuario_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Endpoints
  // ==================================================================

  /// Registra un usuario nuevo y devuelve sus datos.
  Future<Usuario> registro({
    required String nombreCompleto,
    required String email,
    required String password,
    RolGlobal? rol,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/auth/registro',
      body: UsuarioModel.toCreateJson(
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
        rol: rol,
      ),
    );
    return UsuarioModel.fromJson(json);
  }

  /// Inicia sesión y devuelve los tokens + datos del usuario.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthTokensModel.fromJson(json);
  }

  /// Renueva los tokens a partir del refresh token.
  Future<AuthTokens> refresh({required String refreshToken}) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthTokensModel.fromJson(json);
  }

  /// Cambia la contraseña del usuario autenticado.
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    await _client.post<void>(
      '/auth/cambiar-password',
      body: {
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      },
    );
  }

  /// Devuelve el perfil del usuario autenticado.
  Future<Usuario> me() async {
    final json = await _client.get<Map<String, dynamic>>('/auth/me');
    return UsuarioModel.fromJson(json);
  }
}