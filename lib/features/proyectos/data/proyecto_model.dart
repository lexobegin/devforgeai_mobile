// lib/features/proyectos/data/proyecto_model.dart
//
// Mappers JSON ↔ entidades de Proyecto y MiembroProyecto.
// App informativa (solo lectura): solo mappers de respuesta.

import '../domain/proyecto_entity.dart';

// ======================================================================
// ProyectoModel
// ======================================================================
class ProyectoModel {
  const ProyectoModel._();

  static Proyecto fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: _parseId(json['id']),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      idPropietario: _parseId(json['id_propietario']),
      estado: EstadoProyecto.fromValue(json['estado'] as String? ?? 'ACTIVO'),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

// ======================================================================
// MiembroProyectoModel
// ======================================================================
class MiembroProyectoModel {
  const MiembroProyectoModel._();

  static MiembroProyecto fromJson(Map<String, dynamic> json) {
    // El backend puede incluir un `usuario` embebido con nombre/email.
    final usuario = (json['usuario'] as Map?)?.cast<String, dynamic>();

    return MiembroProyecto(
      id: _parseId(json['id']),
      idProyecto: _parseId(json['id_proyecto']),
      idUsuario: _parseId(json['id_usuario']),
      rol: RolEnProyecto.fromValue(
        json['rol_en_proyecto'] as String? ?? 'LECTOR',
      ),
      joinedAt: _parseDateTime(json['joined_at']),
      nombreUsuario: usuario?['nombre_completo'] as String?,
      emailUsuario: usuario?['email'] as String?,
    );
  }
}

// ======================================================================
// ProyectoConMiembrosModel
// ======================================================================
class ProyectoConMiembrosModel {
  const ProyectoConMiembrosModel._();

  static ProyectoConMiembros fromJson(Map<String, dynamic> json) {
    final proyecto = ProyectoModel.fromJson(json);
    final miembrosJson = (json['miembros'] as List?) ?? [];
    final miembros = miembrosJson
        .map((m) => MiembroProyectoModel.fromJson((m as Map).cast<String, dynamic>()))
        .toList();

    return ProyectoConMiembros(proyecto: proyecto, miembros: miembros);
  }
}

// ======================================================================
// Helpers
// ======================================================================

/// Los ids del backend son ObjectId de MongoDB serializados como String.
String _parseId(dynamic value) => value?.toString() ?? '';

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}
