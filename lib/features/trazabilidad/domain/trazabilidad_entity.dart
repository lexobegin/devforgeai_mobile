// lib/features/trazabilidad/domain/trazabilidad_entity.dart
//
// Entidades: HistorialCambio, VersionDiagrama, ComentarioDiagrama.
// Los ids son String (ObjectId de MongoDB).

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum TipoCambio {
  crear('CREAR', 'Crear'),
  modificar('MODIFICAR', 'Modificar'),
  eliminar('ELIMINAR', 'Eliminar');

  const TipoCambio(this.value, this.label);

  final String value;
  final String label;

  static TipoCambio fromValue(String value) {
    return TipoCambio.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoCambio.modificar,
    );
  }
}

// ======================================================================
// Historial
// ======================================================================
@immutable
class HistorialCambio {
  final String id;
  final String idDiagrama;
  final String idUsuario;
  final TipoCambio tipoCambio;
  final String tipoEntidad;
  final String idEntidad;
  final Map<String, dynamic> datosCambio;
  final DateTime createdAt;

  const HistorialCambio({
    required this.id,
    required this.idDiagrama,
    required this.idUsuario,
    required this.tipoCambio,
    required this.tipoEntidad,
    required this.idEntidad,
    required this.datosCambio,
    required this.createdAt,
  });
}

// ======================================================================
// Versión
// ======================================================================
@immutable
class VersionDiagramaResumen {
  final String id;
  final String idDiagrama;
  final int numeroVersion;
  final String idUsuario;
  final String? comentario;
  final DateTime createdAt;

  const VersionDiagramaResumen({
    required this.id,
    required this.idDiagrama,
    required this.numeroVersion,
    required this.idUsuario,
    this.comentario,
    required this.createdAt,
  });
}

@immutable
class VersionDiagrama {
  final String id;
  final String idDiagrama;
  final int numeroVersion;
  final Map<String, dynamic> contenidoJson;
  final String idUsuario;
  final String? comentario;
  final DateTime createdAt;

  const VersionDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.numeroVersion,
    required this.contenidoJson,
    required this.idUsuario,
    this.comentario,
    required this.createdAt,
  });
}

// ======================================================================
// Comentario
// ======================================================================
@immutable
class ComentarioDiagrama {
  final String id;
  final String idDiagrama;
  final String idUsuario;
  final String? tipoEntidad;
  final String? idEntidad;
  final String texto;
  final bool resuelto;
  final DateTime createdAt;

  const ComentarioDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.idUsuario,
    this.tipoEntidad,
    this.idEntidad,
    required this.texto,
    this.resuelto = false,
    required this.createdAt,
  });

  bool get esGeneral => tipoEntidad == null && idEntidad == null;
}
