// lib/features/trazabilidad/data/trazabilidad_model.dart
//
// Mappers JSON ↔ entidades de Trazabilidad.
// App informativa (solo lectura): solo mappers de respuesta.

import '../domain/trazabilidad_entity.dart';

class TrazabilidadModel {
  const TrazabilidadModel._();

  // ==================================================================
  // Historial
  // ==================================================================
  static HistorialCambio historialFromJson(Map<String, dynamic> json) {
    return HistorialCambio(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      idUsuario: _parseId(json['id_usuario']),
      tipoCambio: TipoCambio.fromValue(
        json['tipo_cambio'] as String? ?? 'MODIFICAR',
      ),
      tipoEntidad: json['tipo_entidad'] as String? ?? '',
      idEntidad: _parseId(json['id_entidad']),
      datosCambio:
          (json['datos_cambio'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  // ==================================================================
  // Versiones
  // ==================================================================
  static VersionDiagramaResumen versionResumenFromJson(
    Map<String, dynamic> json,
  ) {
    return VersionDiagramaResumen(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      numeroVersion: (json['numero_version'] as num?)?.toInt() ?? 1,
      idUsuario: _parseId(json['id_usuario']),
      comentario: json['comentario'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static VersionDiagrama versionFromJson(Map<String, dynamic> json) {
    return VersionDiagrama(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      numeroVersion: (json['numero_version'] as num?)?.toInt() ?? 1,
      contenidoJson:
          (json['contenido_json'] as Map?)?.cast<String, dynamic>() ?? {},
      idUsuario: _parseId(json['id_usuario']),
      comentario: json['comentario'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  // ==================================================================
  // Comentarios
  // ==================================================================
  static ComentarioDiagrama comentarioFromJson(Map<String, dynamic> json) {
    return ComentarioDiagrama(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      idUsuario: _parseId(json['id_usuario']),
      tipoEntidad: json['tipo_entidad'] as String?,
      idEntidad:
          json['id_entidad'] == null ? null : json['id_entidad'].toString(),
      texto: json['texto'] as String? ?? '',
      resuelto: json['resuelto'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
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
