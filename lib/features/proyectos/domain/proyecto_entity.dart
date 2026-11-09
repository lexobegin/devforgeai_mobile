// lib/features/proyectos/domain/proyecto_entity.dart
//
// Entidades de dominio: Proyecto y MiembroProyecto.
//
// Reflejan `ProyectoResponse` y `MiembroProyectoResponse` del backend.
// Los ids son String (ObjectId de MongoDB), igual que en el frontend web.

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum EstadoProyecto {
  activo('ACTIVO', 'Activo'),
  archivado('ARCHIVADO', 'Archivado');

  const EstadoProyecto(this.value, this.label);

  final String value;
  final String label;

  static EstadoProyecto fromValue(String value) {
    return EstadoProyecto.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoProyecto.activo,
    );
  }
}

enum RolEnProyecto {
  propietario('PROPIETARIO', 'Propietario'),
  editor('EDITOR', 'Editor'),
  lector('LECTOR', 'Lector');

  const RolEnProyecto(this.value, this.label);

  final String value;
  final String label;

  static RolEnProyecto fromValue(String value) {
    return RolEnProyecto.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RolEnProyecto.lector,
    );
  }

  /// Prioridad para comparaciones ("al menos rol X").
  int get prioridad {
    switch (this) {
      case RolEnProyecto.lector:
        return 1;
      case RolEnProyecto.editor:
        return 2;
      case RolEnProyecto.propietario:
        return 3;
    }
  }

  bool alMenos(RolEnProyecto otro) => prioridad >= otro.prioridad;
}

// ======================================================================
// Proyecto
// ======================================================================
@immutable
class Proyecto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String idPropietario;
  final EstadoProyecto estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Proyecto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.idPropietario,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get estaActivo => estado == EstadoProyecto.activo;
  bool get estaArchivado => estado == EstadoProyecto.archivado;

  Proyecto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? idPropietario,
    EstadoProyecto? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Proyecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      idPropietario: idPropietario ?? this.idPropietario,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proyecto &&
        other.id == id &&
        other.nombre == nombre &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(id, nombre, estado);

  @override
  String toString() => 'Proyecto(id: $id, nombre: $nombre, estado: ${estado.value})';
}

// ======================================================================
// MiembroProyecto
// ======================================================================
@immutable
class MiembroProyecto {
  final String id;
  final String idProyecto;
  final String idUsuario;
  final RolEnProyecto rol;
  final DateTime joinedAt;

  /// Datos del usuario (si el backend los incluye).
  final String? nombreUsuario;
  final String? emailUsuario;

  const MiembroProyecto({
    required this.id,
    required this.idProyecto,
    required this.idUsuario,
    required this.rol,
    required this.joinedAt,
    this.nombreUsuario,
    this.emailUsuario,
  });

  bool get esPropietario => rol == RolEnProyecto.propietario;

  MiembroProyecto copyWith({
    String? id,
    String? idProyecto,
    String? idUsuario,
    RolEnProyecto? rol,
    DateTime? joinedAt,
    String? nombreUsuario,
    String? emailUsuario,
  }) {
    return MiembroProyecto(
      id: id ?? this.id,
      idProyecto: idProyecto ?? this.idProyecto,
      idUsuario: idUsuario ?? this.idUsuario,
      rol: rol ?? this.rol,
      joinedAt: joinedAt ?? this.joinedAt,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      emailUsuario: emailUsuario ?? this.emailUsuario,
    );
  }
}

// ======================================================================
// ProyectoConMiembros
// ======================================================================
@immutable
class ProyectoConMiembros {
  final Proyecto proyecto;
  final List<MiembroProyecto> miembros;

  const ProyectoConMiembros({
    required this.proyecto,
    required this.miembros,
  });

  /// Devuelve el rol del usuario actual en este proyecto, o null si no
  /// es miembro.
  RolEnProyecto? rolDeUsuario(String idUsuario) {
    for (final m in miembros) {
      if (m.idUsuario == idUsuario) return m.rol;
    }
    return null;
  }
}
