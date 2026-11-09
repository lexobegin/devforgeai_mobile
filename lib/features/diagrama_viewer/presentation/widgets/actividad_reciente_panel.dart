// lib/features/diagrama_viewer/presentation/widgets/actividad_reciente_panel.dart
//
// Panel de ACTIVIDAD RECIENTE del diagrama (solo lectura — Tanda M3).
//
// Según D33 (CU22 "Observar Diseño en Móvil"), la observación móvil es
// por REST + aviso push, sin WebSocket. Este panel es la mitad
// informativa de esa observación: muestra el feed de cambios que el
// equipo hizo en la web (GET /trazabilidad/diagramas/{id}/historial):
//   • QUIÉN lo hizo (id del usuario, acortado)
//   • QUÉ tocó (tipo de cambio + tipo de entidad + etiqueta si hay datos)
//   • CUÁNDO (fecha relativa corta)
//
// Solo lectura: no hay comentarios ni ediciones aquí — la bandeja de
// notificaciones (M4) cubrirá el aviso push.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../trazabilidad/domain/trazabilidad_entity.dart';
import '../../../trazabilidad/presentation/providers/trazabilidad_provider.dart';

class ActividadRecientePanel extends ConsumerWidget {
  final String diagramaId;

  const ActividadRecientePanel({super.key, required this.diagramaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialProvider(diagramaId));

    return Column(
      children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.timeline,
                  size: 16, color: AppColors.surface400),
              const SizedBox(width: 8),
              const Text(
                'Actividad reciente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Pull-to-refresh explícito también como botón
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Actualizar actividad',
                onPressed: () => ref
                    .invalidate(historialProvider(diagramaId)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Feed
        Expanded(
          child: historialAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(historialProvider(diagramaId)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No se pudo cargar la actividad.\nDesliza para reintentar.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(historialProvider(diagramaId)),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Sin actividad todavía — el diseño no ha cambiado',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.surface500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(historialProvider(diagramaId)),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final h = items[i];
                    return _ActividadTile(historial: h);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Tile de un cambio
// ======================================================================
class _ActividadTile extends StatelessWidget {
  final HistorialCambio historial;

  const _ActividadTile({required this.historial});

  @override
  Widget build(BuildContext context) {
    final (icono, color) = _estiloCambio(historial.tipoCambio);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _descripcion(historial),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.surface200,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'por ${_usuarioCorto(historial.idUsuario)}'
                  ' · ${_fechaRelativa(historial.createdAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.surface500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Icono/color según el tipo de cambio
  // ------------------------------------------------------------------
  (IconData, Color) _estiloCambio(TipoCambio tipo) {
    switch (tipo) {
      case TipoCambio.crear:
        return (Icons.add_circle_outline, AppColors.success);
      case TipoCambio.eliminar:
        return (Icons.remove_circle_outline, AppColors.danger);
      case TipoCambio.modificar:
        return (Icons.edit_outlined, AppColors.warning);
    }
  }

  // ------------------------------------------------------------------
  // Descripción legible: "Modificó CLASE «Usuario»" / "Eliminó RELACION"
  //
  // datos_cambio es el payload WS del evento (varía por tipo): se
  // extrae la etiqueta de forma defensiva (nombre → nombre_asociacion →
  // atributo/operación) sin asumir estructura fija.
  // ------------------------------------------------------------------
  String _descripcion(HistorialCambio h) {
    final accion = switch (h.tipoCambio) {
      TipoCambio.crear => 'Creó',
      TipoCambio.modificar => 'Modificó',
      TipoCambio.eliminar => 'Eliminó',
    };
    final entidad = _etiquetaEntidad(h.tipoEntidad);
    final detalle = _etiquetaDetalle(h.datosCambio);

    if (detalle != null && detalle.isNotEmpty) {
      return '$accion $entidad «$detalle»';
    }
    return '$accion $entidad';
  }

  String _etiquetaEntidad(String tipoEntidad) {
    switch (tipoEntidad.toUpperCase()) {
      case 'CLASE':
        return 'clase';
      case 'ATRIBUTO':
        return 'atributo';
      case 'OPERACION':
        return 'operación';
      case 'RELACION':
        return 'relación';
      case 'INTERFAZ':
        return 'interfaz';
      default:
        return tipoEntidad.toLowerCase().isEmpty
            ? 'elemento'
            : tipoEntidad.toLowerCase();
    }
  }

  String? _etiquetaDetalle(Map<String, dynamic> datos) {
    for (final clave in [
      'nombre',
      'nombre_asociacion',
      'atributo',
      'operacion',
      'nombre_operacion',
    ]) {
      final v = datos[clave];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  String _usuarioCorto(String id) {
    if (id.length <= 8) return id.isEmpty ? '—' : id;
    return '${id.substring(0, 8)}…';
  }

  String _fechaRelativa(DateTime fecha) {
    final d = DateTime.now().difference(fecha);
    if (d.inSeconds < 60) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays < 7) return 'hace ${d.inDays} d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
