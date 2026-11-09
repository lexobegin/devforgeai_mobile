// lib/features/diagrama_viewer/data/clase_uml_model.dart
//
// Mappers JSON ↔ entidades de Clase UML, Atributo, Operación y Parámetro.
//
// El backend devuelve la clase con sus atributos y operaciones embebidos.
// App informativa (solo lectura): solo mappers de respuesta.

import '../domain/clase_uml_entity.dart';

class ClaseUmlModel {
  const ClaseUmlModel._();

  static ClaseUml fromJson(Map<String, dynamic> json) {
    final atributosJson = (json['atributos'] as List?) ?? [];
    final operacionesJson = (json['operaciones'] as List?) ?? [];

    return ClaseUml(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      nombre: json['nombre'] as String? ?? '',
      esAbstracta: json['es_abstracta'] as bool? ?? false,
      estereotipo: json['estereotipo'] as String?,
      posX: _parseDouble(json['pos_x']),
      posY: _parseDouble(json['pos_y']),
      idCreador: _parseId(json['id_creador']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      atributos: atributosJson
          .map((a) =>
              AtributoUmlModel.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
      operaciones: operacionesJson
          .map((o) =>
              OperacionUmlModel.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

// ======================================================================
// Atributo
// ======================================================================
class AtributoUmlModel {
  const AtributoUmlModel._();

  static AtributoUml fromJson(Map<String, dynamic> json) {
    return AtributoUml(
      id: _parseId(json['id']),
      idClase: _parseId(json['id_clase']),
      nombre: json['nombre'] as String? ?? '',
      tipoDato: json['tipo_dato'] as String? ?? 'String',
      visibilidad: VisibilidadUml.fromValue(
        json['visibilidad'] as String? ?? '-',
      ),
      esEstatico: json['es_estatico'] as bool? ?? false,
      valorDefecto: json['valor_defecto'] as String?,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }
}

// ======================================================================
// Operación
// ======================================================================
class OperacionUmlModel {
  const OperacionUmlModel._();

  static OperacionUml fromJson(Map<String, dynamic> json) {
    final paramsJson = (json['parametros'] as List?) ?? [];

    return OperacionUml(
      id: _parseId(json['id']),
      idClase: _parseId(json['id_clase']),
      nombre: json['nombre'] as String? ?? '',
      tipoRetorno: json['tipo_retorno'] as String? ?? 'void',
      visibilidad: VisibilidadUml.fromValue(
        json['visibilidad'] as String? ?? '+',
      ),
      esEstatico: json['es_estatico'] as bool? ?? false,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      parametros: paramsJson
          .map((p) => ParametroOperacionUmlModel.fromJson(
                (p as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}

// ======================================================================
// Parámetro
// ======================================================================
class ParametroOperacionUmlModel {
  const ParametroOperacionUmlModel._();

  static ParametroOperacionUml fromJson(Map<String, dynamic> json) {
    return ParametroOperacionUml(
      id: _parseId(json['id']),
      idOperacion: _parseId(json['id_operacion']),
      nombre: json['nombre'] as String? ?? '',
      tipoDato: json['tipo_dato'] as String? ?? 'String',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }
}

// ======================================================================
// Helpers
// ======================================================================

/// Los ids del backend son ObjectId de MongoDB serializados como String.
String _parseId(dynamic value) => value?.toString() ?? '';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}
