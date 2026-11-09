// lib/features/notificaciones/domain/notificacion_entity.dart
//
// Entidad de dominio: Notificación.
// Los ids son String (ObjectId de MongoDB).

import 'package:flutter/foundation.dart';

// ======================================================================
// Tipo de notificación
// ======================================================================
enum TipoNotificacion {
  comentario('COMENTARIO', 'Comentario'),
  cambioDiagrama('CAMBIO_DIAGRAMA', 'Cambio en diagrama'),
  generacionCompleta('GENERACION_COMPLETA', 'Generación completada'),
  generacionFallida('GENERACION_FALLIDA', 'Generación fallida'),
  miembroAgregado('MIEMBRO_AGREGADO', 'Miembro agregado'),
  conflictoPendiente('CONFLICTO_PENDIENTE', 'Conflicto pendiente'),
  versionGuardada('VERSION_GUARDADA', 'Versión guardada'),
  sistema('SISTEMA', 'Sistema');

  const TipoNotificacion(this.value, this.label);

  final String value;
  final String label;

  static TipoNotificacion fromValue(String value) {
    return TipoNotificacion.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoNotificacion.sistema,
    );
  }
}

// ======================================================================
// Notificación
// ======================================================================
@immutable
class Notificacion {
  final String id;
  final String idUsuario;
  final TipoNotificacion tipo;
  final String mensaje;
  final String? idReferencia;
  final bool leida;
  final DateTime createdAt;

  const Notificacion({
    required this.id,
    required this.idUsuario,
    required this.tipo,
    required this.mensaje,
    this.idReferencia,
    this.leida = false,
    required this.createdAt,
  });

  Notificacion copyWith({
    String? id,
    String? idUsuario,
    TipoNotificacion? tipo,
    String? mensaje,
    String? idReferencia,
    bool? leida,
    DateTime? createdAt,
  }) {
    return Notificacion(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      idReferencia: idReferencia ?? this.idReferencia,
      leida: leida ?? this.leida,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notificacion &&
        other.id == id &&
        other.leida == leida &&
        other.mensaje == mensaje;
  }

  @override
  int get hashCode => Object.hash(id, leida, mensaje);

  @override
  String toString() =>
      'Notificacion(id: $id, tipo: ${tipo.value}, leida: $leida)';
}

// ======================================================================
// Contador
// ======================================================================
@immutable
class ContadorNoLeidas {
  final int total;

  const ContadorNoLeidas({required this.total});

  bool get tieneNuevas => total > 0;
}
