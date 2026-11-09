// lib/features/notificaciones/data/notificacion_model.dart
//
// Mappers JSON ↔ entidades de Notificación.
// Los ids son String (ObjectId de MongoDB).

import '../domain/notificacion_entity.dart';

class NotificacionModel {
  const NotificacionModel._();

  static Notificacion fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: _parseId(json['id']),
      idUsuario: _parseId(json['id_usuario']),
      tipo: TipoNotificacion.fromValue(json['tipo'] as String? ?? 'SISTEMA'),
      mensaje: json['mensaje'] as String? ?? '',
      idReferencia:
          json['id_referencia'] == null ? null : json['id_referencia'].toString(),
      leida: json['leida'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static ContadorNoLeidas contadorFromJson(Map<String, dynamic> json) {
    return ContadorNoLeidas(
      total: (json['total_no_leidas'] as num?)?.toInt() ?? 0,
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
