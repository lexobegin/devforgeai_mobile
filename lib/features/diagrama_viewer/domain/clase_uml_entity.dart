// lib/features/diagrama_viewer/domain/clase_uml_entity.dart
//
// Entidades: ClaseUml, AtributoUml, OperacionUml, ParametroOperacionUml.
//
// Representan los nodos del diagrama. Los atributos y operaciones viven
// dentro de la clase. Los ids son String (ObjectId de MongoDB).

import 'package:flutter/foundation.dart';

// ======================================================================
// Visibilidad UML
// ======================================================================
enum VisibilidadUml {
  publico('+', 'Público'),
  privado('-', 'Privado'),
  protegido('#', 'Protegido'),
  paquete('~', 'Paquete');

  const VisibilidadUml(this.value, this.label);

  final String value;
  final String label;

  static VisibilidadUml fromValue(String value) {
    return VisibilidadUml.values.firstWhere(
      (v) => v.value == value,
      orElse: () => VisibilidadUml.privado,
    );
  }
}

// ======================================================================
// Atributo
// ======================================================================
@immutable
class AtributoUml {
  final String id;
  final String idClase;
  final String nombre;
  final String tipoDato;
  final VisibilidadUml visibilidad;
  final bool esEstatico;
  final String? valorDefecto;
  final int orden;

  const AtributoUml({
    required this.id,
    required this.idClase,
    required this.nombre,
    required this.tipoDato,
    this.visibilidad = VisibilidadUml.privado,
    this.esEstatico = false,
    this.valorDefecto,
    this.orden = 0,
  });

  /// Representación textual: "+ nombre: Tipo"
  String get display {
    final v = visibilidad.value;
    final t = tipoDato.isEmpty ? '' : ': $tipoDato';
    return '$v $nombre$t';
  }

  AtributoUml copyWith({
    String? id,
    String? idClase,
    String? nombre,
    String? tipoDato,
    VisibilidadUml? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) {
    return AtributoUml(
      id: id ?? this.id,
      idClase: idClase ?? this.idClase,
      nombre: nombre ?? this.nombre,
      tipoDato: tipoDato ?? this.tipoDato,
      visibilidad: visibilidad ?? this.visibilidad,
      esEstatico: esEstatico ?? this.esEstatico,
      valorDefecto: valorDefecto ?? this.valorDefecto,
      orden: orden ?? this.orden,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AtributoUml &&
        other.id == id &&
        other.nombre == nombre &&
        other.tipoDato == tipoDato &&
        other.visibilidad == visibilidad;
  }

  @override
  int get hashCode => Object.hash(id, nombre, tipoDato, visibilidad);
}

// ======================================================================
// Parámetro de operación
// ======================================================================
@immutable
class ParametroOperacionUml {
  final String id;
  final String idOperacion;
  final String nombre;
  final String tipoDato;
  final int orden;

  const ParametroOperacionUml({
    required this.id,
    required this.idOperacion,
    required this.nombre,
    required this.tipoDato,
    this.orden = 0,
  });

  String get display => '$nombre: $tipoDato';

  ParametroOperacionUml copyWith({
    String? id,
    String? idOperacion,
    String? nombre,
    String? tipoDato,
    int? orden,
  }) {
    return ParametroOperacionUml(
      id: id ?? this.id,
      idOperacion: idOperacion ?? this.idOperacion,
      nombre: nombre ?? this.nombre,
      tipoDato: tipoDato ?? this.tipoDato,
      orden: orden ?? this.orden,
    );
  }
}

// ======================================================================
// Operación
// ======================================================================
@immutable
class OperacionUml {
  final String id;
  final String idClase;
  final String nombre;
  final String tipoRetorno;
  final VisibilidadUml visibilidad;
  final bool esEstatico;
  final int orden;
  final List<ParametroOperacionUml> parametros;

  const OperacionUml({
    required this.id,
    required this.idClase,
    required this.nombre,
    this.tipoRetorno = 'void',
    this.visibilidad = VisibilidadUml.publico,
    this.esEstatico = false,
    this.orden = 0,
    this.parametros = const [],
  });

  /// Representación textual: "+ nombre(a: Tipo, b: Tipo): Retorno"
  String get display {
    final v = visibilidad.value;
    final params = parametros.map((p) => p.display).join(', ');
    final ret = tipoRetorno.isEmpty ? '' : ': $tipoRetorno';
    return '$v $nombre($params)$ret';
  }

  OperacionUml copyWith({
    String? id,
    String? idClase,
    String? nombre,
    String? tipoRetorno,
    VisibilidadUml? visibilidad,
    bool? esEstatico,
    int? orden,
    List<ParametroOperacionUml>? parametros,
  }) {
    return OperacionUml(
      id: id ?? this.id,
      idClase: idClase ?? this.idClase,
      nombre: nombre ?? this.nombre,
      tipoRetorno: tipoRetorno ?? this.tipoRetorno,
      visibilidad: visibilidad ?? this.visibilidad,
      esEstatico: esEstatico ?? this.esEstatico,
      orden: orden ?? this.orden,
      parametros: parametros ?? this.parametros,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperacionUml &&
        other.id == id &&
        other.nombre == nombre &&
        other.tipoRetorno == tipoRetorno;
  }

  @override
  int get hashCode => Object.hash(id, nombre, tipoRetorno);
}

// ======================================================================
// Clase
// ======================================================================
@immutable
class ClaseUml {
  final String id;
  final String idDiagrama;
  final String nombre;
  final bool esAbstracta;
  final String? estereotipo;
  final double posX;
  final double posY;
  final String idCreador;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AtributoUml> atributos;
  final List<OperacionUml> operaciones;

  const ClaseUml({
    required this.id,
    required this.idDiagrama,
    required this.nombre,
    this.esAbstracta = false,
    this.estereotipo,
    this.posX = 0,
    this.posY = 0,
    required this.idCreador,
    required this.createdAt,
    required this.updatedAt,
    this.atributos = const [],
    this.operaciones = const [],
  });

  ClaseUml copyWith({
    String? id,
    String? idDiagrama,
    String? nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
    String? idCreador,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AtributoUml>? atributos,
    List<OperacionUml>? operaciones,
  }) {
    return ClaseUml(
      id: id ?? this.id,
      idDiagrama: idDiagrama ?? this.idDiagrama,
      nombre: nombre ?? this.nombre,
      esAbstracta: esAbstracta ?? this.esAbstracta,
      estereotipo: estereotipo ?? this.estereotipo,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      idCreador: idCreador ?? this.idCreador,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      atributos: atributos ?? this.atributos,
      operaciones: operaciones ?? this.operaciones,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClaseUml && other.id == id && other.nombre == nombre;
  }

  @override
  int get hashCode => Object.hash(id, nombre);

  @override
  String toString() =>
      'ClaseUml(id: $id, nombre: $nombre, atributos: ${atributos.length})';
}
