// lib/features/auth/domain/usuario_entity.dart
//
// Entidad de dominio: Usuario.
//
// Refleja el schema `UsuarioResponse` del backend (MongoDB → ObjectId
// como String). Es inmutable y pura (sin JSON, sin dependencias externas).

import 'package:flutter/foundation.dart';

/// Rol global del usuario en la plataforma.
enum RolGlobal {
  admin('ADMIN', 'Administrador'),
  desarrollador('DESARROLLADOR', 'Desarrollador');

  const RolGlobal(this.value, this.label);

  final String value;
  final String label;

  static RolGlobal fromValue(String value) {
    return RolGlobal.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RolGlobal.desarrollador,
    );
  }
}

@immutable
class Usuario {
  final String id;
  final String nombreCompleto;
  final String email;
  final RolGlobal rol;
  final bool activo;
  final DateTime createdAt;

  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
    required this.activo,
    required this.createdAt,
  });

  // ==================================================================
  // Derivados
  // ==================================================================
  bool get isAdmin => rol == RolGlobal.admin;

  /// Iniciales del nombre (para el avatar).
  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      return partes.first.substring(0, partes.first.length.clamp(0, 2)).toUpperCase();
    }
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  // ==================================================================
  // CopyWith y toString
  // ==================================================================
  Usuario copyWith({
    String? id,
    String? nombreCompleto,
    String? email,
    RolGlobal? rol,
    bool? activo,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Usuario(id: $id, email: $email, rol: ${rol.value}, activo: $activo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario &&
        other.id == id &&
        other.nombreCompleto == nombreCompleto &&
        other.email == email &&
        other.rol == rol &&
        other.activo == activo;
  }

  @override
  int get hashCode => Object.hash(id, nombreCompleto, email, rol, activo);
}

// ======================================================================
// Token de autenticación
// ======================================================================
@immutable
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Usuario usuario;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.usuario,
  });

  @override
  String toString() =>
      'AuthTokens(usuario: ${usuario.email}, expiresIn: ${expiresIn}s)';
}
