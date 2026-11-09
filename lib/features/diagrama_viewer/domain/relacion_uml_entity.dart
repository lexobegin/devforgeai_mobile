// lib/features/diagrama_viewer/domain/relacion_uml_entity.dart
//
// Entidades: RelacionUml e InterfazUml.
// Los ids son String (ObjectId de MongoDB).

import 'package:flutter/foundation.dart';

// ======================================================================
// Tipo de relación
// ======================================================================
enum TipoRelacion {
  asociacion('ASOCIACION', 'Asociación'),
  agregacion('AGREGACION', 'Agregación'),
  composicion('COMPOSICION', 'Composición'),
  dependencia('DEPENDENCIA', 'Dependencia'),
  generalizacion('GENERALIZACION', 'Generalización'),
  realizacion('REALIZACION', 'Realización');

  const TipoRelacion(this.value, this.label);

  final String value;
  final String label;

  static TipoRelacion fromValue(String value) {
    return TipoRelacion.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoRelacion.asociacion,
    );
  }
}

// ======================================================================
// Relación
// ======================================================================
@immutable
class RelacionUml {
  final String id;
  final String idDiagrama;
  final String idClaseOrigen;
  final String idClaseDestino;
  final TipoRelacion tipoRelacion;
  final String? multiplicidadOrigen;
  final String? multiplicidadDestino;
  final String? nombreAsociacion;
  final String? rolOrigen;
  final String? rolDestino;

  const RelacionUml({
    required this.id,
    required this.idDiagrama,
    required this.idClaseOrigen,
    required this.idClaseDestino,
    this.tipoRelacion = TipoRelacion.asociacion,
    this.multiplicidadOrigen,
    this.multiplicidadDestino,
    this.nombreAsociacion,
    this.rolOrigen,
    this.rolDestino,
  });

  RelacionUml copyWith({
    String? id,
    String? idDiagrama,
    String? idClaseOrigen,
    String? idClaseDestino,
    TipoRelacion? tipoRelacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) {
    return RelacionUml(
      id: id ?? this.id,
      idDiagrama: idDiagrama ?? this.idDiagrama,
      idClaseOrigen: idClaseOrigen ?? this.idClaseOrigen,
      idClaseDestino: idClaseDestino ?? this.idClaseDestino,
      tipoRelacion: tipoRelacion ?? this.tipoRelacion,
      multiplicidadOrigen: multiplicidadOrigen ?? this.multiplicidadOrigen,
      multiplicidadDestino: multiplicidadDestino ?? this.multiplicidadDestino,
      nombreAsociacion: nombreAsociacion ?? this.nombreAsociacion,
      rolOrigen: rolOrigen ?? this.rolOrigen,
      rolDestino: rolDestino ?? this.rolDestino,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelacionUml &&
        other.id == id &&
        other.tipoRelacion == tipoRelacion &&
        other.idClaseOrigen == idClaseOrigen &&
        other.idClaseDestino == idClaseDestino;
  }

  @override
  int get hashCode =>
      Object.hash(id, tipoRelacion, idClaseOrigen, idClaseDestino);

  @override
  String toString() =>
      'RelacionUml(id: $id, ${tipoRelacion.value}, $idClaseOrigen→$idClaseDestino)';
}

// ======================================================================
// Interfaz
// ======================================================================
@immutable
class OperacionInterfazUml {
  final String id;
  final String idInterfaz;
  final String nombre;
  final String tipoRetorno;

  const OperacionInterfazUml({
    required this.id,
    required this.idInterfaz,
    required this.nombre,
    this.tipoRetorno = 'void',
  });
}

@immutable
class InterfazUml {
  final String id;
  final String idDiagrama;
  final String nombre;
  final double posX;
  final double posY;
  final List<OperacionInterfazUml> operaciones;

  const InterfazUml({
    required this.id,
    required this.idDiagrama,
    required this.nombre,
    this.posX = 0,
    this.posY = 0,
    this.operaciones = const [],
  });
}
