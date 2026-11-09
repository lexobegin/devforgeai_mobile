// lib/features/diagrama_viewer/data/relacion_uml_model.dart
//
// Mappers JSON ↔ entidades de Relación e Interfaz UML.
// App informativa (solo lectura): solo mappers de respuesta.

import '../domain/relacion_uml_entity.dart';

// ======================================================================
// Relación
// ======================================================================
class RelacionUmlModel {
  const RelacionUmlModel._();

  static RelacionUml fromJson(Map<String, dynamic> json) {
    return RelacionUml(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      idClaseOrigen: _parseId(json['id_clase_origen']),
      idClaseDestino: _parseId(json['id_clase_destino']),
      tipoRelacion: TipoRelacion.fromValue(
        json['tipo_relacion'] as String? ?? 'ASOCIACION',
      ),
      multiplicidadOrigen: json['multiplicidad_origen'] as String?,
      multiplicidadDestino: json['multiplicidad_destino'] as String?,
      nombreAsociacion: json['nombre_asociacion'] as String?,
      rolOrigen: json['rol_origen'] as String?,
      rolDestino: json['rol_destino'] as String?,
    );
  }
}

// ======================================================================
// Interfaz
// ======================================================================
class InterfazUmlModel {
  const InterfazUmlModel._();

  static InterfazUml fromJson(Map<String, dynamic> json) {
    final opsJson = (json['operaciones'] as List?) ?? [];

    return InterfazUml(
      id: _parseId(json['id']),
      idDiagrama: _parseId(json['id_diagrama']),
      nombre: json['nombre'] as String? ?? '',
      posX: _parseDouble(json['pos_x']),
      posY: _parseDouble(json['pos_y']),
      operaciones: opsJson
          .map((o) => OperacionInterfazUmlModel.fromJson(
                (o as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}

class OperacionInterfazUmlModel {
  const OperacionInterfazUmlModel._();

  static OperacionInterfazUml fromJson(Map<String, dynamic> json) {
    return OperacionInterfazUml(
      id: _parseId(json['id']),
      idInterfaz: _parseId(json['id_interfaz']),
      nombre: json['nombre'] as String? ?? '',
      tipoRetorno: json['tipo_retorno'] as String? ?? 'void',
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
