// lib/features/trazabilidad/presentation/pages/trazabilidad_page.dart
//
// Vista de TRAZABILIDAD del diagrama (solo lectura) — Tanda M5.
//
// "Cómo va el diseño" en tres pestañas, todo generado por el equipo en
// la web y consultado por REST (sin WebSocket, D33):
//   · Historial    — feed de cambios (GET /trazabilidad/diagramas/{id}/historial)
//   · Versiones    — snapshots guardados (GET .../versiones; el detalle
//                    con contenido usa GET /trazabilidad/versiones/{id})
//   · Comentarios  — discusión del equipo (GET .../comentarios)
//
// 100 % lectura: crear/resolver/eliminar comentarios y guardar
// versiones son acciones de la web; aquí solo se consulta.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/trazabilidad_entity.dart';
import '../providers/trazabilidad_provider.dart';

class TrazabilidadPage extends ConsumerStatefulWidget {
  const TrazabilidadPage({
    super.key,
    required this.diagramaId,
    this.diagramaNombre = '',
  });

  final String diagramaId;
  final String diagramaNombre;

  @override
  ConsumerState<TrazabilidadPage> createState() => _TrazabilidadPageState();
}

class _TrazabilidadPageState extends ConsumerState<TrazabilidadPage> {
  @override
  void initState() {
    super.initState();
    // Los comentarios usan un StateNotifier: hay que pedir la carga.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(comentariosProvider(widget.diagramaId).notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.diagramaNombre.isNotEmpty
        ? widget.diagramaNombre
        : 'Trazabilidad';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface950,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Trazabilidad · solo lectura',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.surface400,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Versiones'),
              Tab(text: 'Comentarios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PestanaHistorial(diagramaId: widget.diagramaId),
            _PestanaVersiones(diagramaId: widget.diagramaId),
            _PestanaComentarios(diagramaId: widget.diagramaId),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Pestaña 1 — Historial de cambios
// ======================================================================
class _PestanaHistorial extends ConsumerWidget {
  const _PestanaHistorial({required this.diagramaId});

  final String diagramaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialProvider(diagramaId));

    return historialAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Refrescable(
        onRefresh: () async =>
            ref.invalidate(historialProvider(diagramaId)),
        hijo: _Vacio(
          icon: Icons.cloud_off_outlined,
          color: AppColors.danger,
          titulo: 'No se pudo cargar el historial',
          detalle: 'Desliza hacia abajo para reintentar.',
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _Refrescable(
            onRefresh: () async =>
                ref.invalidate(historialProvider(diagramaId)),
            hijo: const _Vacio(
              icon: Icons.timeline_outlined,
              color: AppColors.surface500,
              titulo: 'Sin cambios todavía',
              detalle:
                  'Cuando el equipo edite el diseño en la web, cada '
                  'cambio aparecerá aquí.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(historialProvider(diagramaId)),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _TileCambio(historial: items[i]),
          ),
        );
      },
    );
  }
}

class _TileCambio extends StatelessWidget {
  const _TileCambio({required this.historial});

  final HistorialCambio historial;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = _estiloCambio(historial.tipoCambio);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _descripcion(historial),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.surface100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_usuarioCorto(historial.idUsuario)} · '
                  '${_fechaRelativa(historial.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
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

  String _descripcion(HistorialCambio h) {
    final accion = switch (h.tipoCambio) {
      TipoCambio.crear => 'Creó',
      TipoCambio.modificar => 'Modificó',
      TipoCambio.eliminar => 'Eliminó',
    };
    final entidad = switch (h.tipoEntidad.toUpperCase()) {
      'CLASE' => 'clase',
      'ATRIBUTO' => 'atributo',
      'OPERACION' => 'operación',
      'RELACION' => 'relación',
      'INTERFAZ' => 'interfaz',
      _ => h.tipoEntidad.toLowerCase(),
    };
    final detalle = _etiquetaDetalle(h.datosCambio);
    if (detalle != null && detalle.isNotEmpty) {
      return '$accion $entidad «$detalle»';
    }
    return '$accion $entidad';
  }

  /// `datos_cambio` es el payload del evento y varía por tipo: se
  /// extrae la etiqueta de forma defensiva, sin asumir estructura.
  String? _etiquetaDetalle(Map<String, dynamic> d) {
    for (final clave in [
      'etiqueta', 'nombre', 'nombre_asociacion', 'texto',
      'atributo', 'operacion', 'descripcion',
    ]) {
      final v = d[clave];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}

// ======================================================================
// Pestaña 2 — Versiones
// ======================================================================
class _PestanaVersiones extends ConsumerWidget {
  const _PestanaVersiones({required this.diagramaId});

  final String diagramaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionesAsync = ref.watch(versionesProvider(diagramaId));

    return versionesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Refrescable(
        onRefresh: () async =>
            ref.invalidate(versionesProvider(diagramaId)),
        hijo: _Vacio(
          icon: Icons.cloud_off_outlined,
          color: AppColors.danger,
          titulo: 'No se pudieron cargar las versiones',
          detalle: 'Desliza hacia abajo para reintentar.',
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _Refrescable(
            onRefresh: () async =>
                ref.invalidate(versionesProvider(diagramaId)),
            hijo: const _Vacio(
              icon: Icons.history_outlined,
              color: AppColors.surface500,
              titulo: 'Sin versiones guardadas',
              detalle:
                  'Las versiones se guardan desde la web; aquí podrás '
                  'ver el avance del diseño.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(versionesProvider(diagramaId)),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final v = items[i];
              return _TileVersion(
                version: v,
                onTap: () => _abrirDetalle(context, v),
              );
            },
          ),
        );
      },
    );
  }

  void _abrirDetalle(BuildContext context, VersionDiagramaResumen v) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DetalleVersionSheet(versionId: v.id),
    );
  }
}

class _TileVersion extends StatelessWidget {
  const _TileVersion({required this.version, required this.onTap});

  final VersionDiagramaResumen version;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = version;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface800.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface800),
        ),
        child: Row(
          children: [
            // Nº de versión
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brand600.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v${v.numeroVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand300,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.comentario != null && v.comentario!.isNotEmpty
                        ? v.comentario!
                        : 'Versión ${v.numeroVersion}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.surface100,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_usuarioCorto(v.idUsuario)} · '
                    '${_fechaRelativa(v.createdAt)} · toca para ver detalle',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.surface500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.surface500),
          ],
        ),
      ),
    );
  }
}

/// Detalle de una versión (GET /trazabilidad/versiones/{id}, con
/// contenido). Se muestran los CONTEOS del snapshot — no el JSON crudo.
class _DetalleVersionSheet extends ConsumerWidget {
  const _DetalleVersionSheet({required this.versionId});

  final String versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(versionDetalleProvider(versionId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: detalleAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => const Text(
            'No se pudo cargar el detalle de la versión.',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
          data: (v) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versión ${v.numeroVersion}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface100,
                ),
              ),
              if (v.comentario != null && v.comentario!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  v.comentario!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.surface300,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Guardada por ${_usuarioCorto(v.idUsuario)} · '
                '${_fechaRelativa(v.createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.surface500,
                ),
              ),
              const Divider(height: 24),
              ..._conteos(v.contenidoJson).entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 15, color: AppColors.brand300),
                          const SizedBox(width: 8),
                          Text(
                            '${e.value} ${e.key}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.surface200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Conteos del snapshot de forma defensiva (clases / interfaces /
  /// relaciones). Si el contenido no trae listas, no muestra nada.
  Map<String, int> _conteos(Map<String, dynamic> contenido) {
    final res = <String, int>{};
    void cuenta(String clave, String etiqueta) {
      final v = contenido[clave];
      if (v is List && v.isNotEmpty) res[etiqueta] = v.length;
    }

    cuenta('clases', 'clases');
    cuenta('interfaces', 'interfaces');
    cuenta('relaciones', 'relaciones');
    return res;
  }
}

// ======================================================================
// Pestaña 3 — Comentarios (solo lectura)
// ======================================================================
class _PestanaComentarios extends ConsumerWidget {
  const _PestanaComentarios({required this.diagramaId});

  final String diagramaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comentariosProvider(diagramaId));

    if (state.isLoading && state.comentarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.comentarios.isEmpty) {
      return _Refrescable(
        onRefresh: () async =>
            ref.read(comentariosProvider(diagramaId).notifier).cargar(),
        hijo: _Vacio(
          icon: Icons.cloud_off_outlined,
          color: AppColors.danger,
          titulo: 'No se pudieron cargar los comentarios',
          detalle: 'Desliza hacia abajo para reintentar.',
        ),
      );
    }
    if (state.comentarios.isEmpty) {
      return _Refrescable(
        onRefresh: () async =>
            ref.read(comentariosProvider(diagramaId).notifier).cargar(),
        hijo: const _Vacio(
          icon: Icons.forum_outlined,
          color: AppColors.surface500,
          titulo: 'Sin comentarios',
          detalle:
              'La discusión del equipo sobre este diseño aparecerá aquí.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(comentariosProvider(diagramaId).notifier).cargar(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: state.comentarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _TileComentario(c: state.comentarios[i]),
      ),
    );
  }
}

class _TileComentario extends StatelessWidget {
  const _TileComentario({required this.c});

  final ComentarioDiagrama c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 14, color: AppColors.brand300),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_usuarioCorto(c.idUsuario)} · '
                  '${_fechaRelativa(c.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.surface500,
                  ),
                ),
              ),
              // Ámbito: general o sobre un elemento
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.esGeneral
                      ? AppColors.brand600.withValues(alpha: 0.15)
                      : AppColors.surface700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.esGeneral ? 'General' : 'Sobre elemento',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.surface300,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.resuelto
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.resuelto ? 'Resuelto' : 'Abierto',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: c.resuelto ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.texto,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.surface100,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Widgets y helpers compartidos
// ======================================================================
class _Refrescable extends StatelessWidget {
  const _Refrescable({required this.onRefresh, required this.hijo});

  final Future<void> Function() onRefresh;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: hijo,
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.detalle,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.surface200,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.surface500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ObjectId de MongoDB acortado (p. ej. "68d4a2…") para no ocupar ancho.
String _usuarioCorto(String id) {
  if (id.length <= 6) return id.isEmpty ? '—' : id;
  return '${id.substring(0, 6)}…';
}

String _fechaRelativa(DateTime fecha) {
  final diff = DateTime.now().difference(fecha);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inHours < 1) return 'hace ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'hace ${diff.inDays}d';
  return '${fecha.day}/${fecha.month}/${fecha.year}';
}
