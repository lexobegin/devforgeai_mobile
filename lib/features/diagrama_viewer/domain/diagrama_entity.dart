// lib/features/diagrama_viewer/domain/diagrama_entity.dart
//
// Entidad de dominio: Diagrama.
//
// Es la metadata del diagrama (no incluye sus clases/relaciones).
// Los ids son String (ObjectId de MongoDB).

import 'package:flutter/foundation.dart';

import 'clase_uml_entity.dart';
import 'relacion_uml_entity.dart';

@immutable
class Diagrama {
  final String id;
  final String idProyecto;
  final String nombre;
  final String versionUml;
  final int numeroVersion;
  final String idCreador;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Diagrama({
    required this.id,
    required this.idProyecto,
    required this.nombre,
    required this.versionUml,
    required this.numeroVersion,
    required this.idCreador,
    required this.createdAt,
    required this.updatedAt,
  });

  Diagrama copyWith({
    String? id,
    String? idProyecto,
    String? nombre,
    String? versionUml,
    int? numeroVersion,
    String? idCreador,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Diagrama(
      id: id ?? this.id,
      idProyecto: idProyecto ?? this.idProyecto,
      nombre: nombre ?? this.nombre,
      versionUml: versionUml ?? this.versionUml,
      numeroVersion: numeroVersion ?? this.numeroVersion,
      idCreador: idCreador ?? this.idCreador,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Diagrama &&
        other.id == id &&
        other.nombre == nombre &&
        other.numeroVersion == numeroVersion;
  }

  @override
  int get hashCode => Object.hash(id, nombre, numeroVersion);

  @override
  String toString() =>
      'Diagrama(id: $id, nombre: $nombre, v: $numeroVersion)';
}

// ======================================================================
// DiagramaCompleto (con clases + relaciones + interfaces)
// ======================================================================
@immutable
class DiagramaCompleto {
  final Diagrama diagrama;
  final List<ClaseUml> clases;
  final List<InterfazUml> interfaces;
  final List<RelacionUml> relaciones;

  const DiagramaCompleto({
    required this.diagrama,
    required this.clases,
    required this.interfaces,
    required this.relaciones,
  });

  int get totalClases => clases.length;
  int get totalRelaciones => relaciones.length;
  int get totalInterfaces => interfaces.length;
}
