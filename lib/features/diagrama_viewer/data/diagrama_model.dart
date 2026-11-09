// lib/features/diagrama_viewer/data/diagrama_model.dart
//
// Mappers JSON ↔ entidades de Diagrama.
//
// El diagrama completo (con clases, relaciones e interfaces) se mapea
// aquí delegando a los models de clase y relación.
// App informativa (solo lectura): solo mappers de respuesta.

import '../domain/clase_uml_entity.dart';
import '../domain/diagrama_entity.dart';
import '../domain/relacion_uml_entity.dart';
import 'clase_uml_model.dart';
import 'relacion_uml_model.dart';

class DiagramaModel {
  const DiagramaModel._();

  // ==================================================================
  // Metadata
  // ==================================================================
  static Diagrama fromJson(Map<String, dynamic> json) {
    return Diagrama(
      id: _parseId(json['id']),
      idProyecto: _parseId(json['id_proyecto']),
      nombre: json['nombre'] as String? ?? '',
      versionUml: json['version_uml'] as String? ?? '2.5.1',
      numeroVersion: (json['numero_version'] as num?)?.toInt() ?? 1,
      idCreador: _parseId(json['id_creador']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // ==================================================================
  // Diagrama completo
  // ==================================================================
  /// Mapea el JSON de `/diagramas/{id}/completo` a un DiagramaCompleto
  /// con sus clases, relaciones e interfaces ya tipadas.
  static DiagramaCompleto completoFromJson(Map<String, dynamic> json) {
    final diagrama = fromJson(json);

    final clasesJson = (json['clases'] as List?) ?? [];
    final clases = clasesJson
        .map((c) => ClaseUmlModel.fromJson((c as Map).cast<String, dynamic>()))
        .toList();

    final relacionesJson = (json['relaciones'] as List?) ?? [];
    final relaciones = relacionesJson
        .map((r) => RelacionUmlModel.fromJson((r as Map).cast<String, dynamic>()))
        .toList();

    final interfacesJson = (json['interfaces'] as List?) ?? [];
    final interfaces = interfacesJson
        .map((i) => InterfazUmlModel.fromJson((i as Map).cast<String, dynamic>()))
        .toList();

    return DiagramaCompleto(
      diagrama: diagrama,
      clases: clases,
      interfaces: interfaces,
      relaciones: relaciones,
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
