// lib/features/notificaciones/presentation/pages/notificaciones_page.dart
//
// Bandeja de notificaciones (CU15) — Tanda M4.
//
// · Sondeo REST cada 30 s mientras la bandeja está visible
//   (`refrescarSilencioso`: sin spinner, no borra la lista si falla).
// · Pull-to-refresh para recargar a mano.
// · Estados de carga, vacío (total y filtrado), error con reintento.
// · Marcado de leídas (una / todas / volver a no leída), eliminar y
//   limpiar leídas — la gestión del propio usuario dentro de CU15.
// · Sin WebSocket (D33); el push FCM es la ampliación opcional.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/notificacion_entity.dart';
import '../providers/notificaciones_provider.dart';

class NotificacionesPage extends ConsumerStatefulWidget {
  const NotificacionesPage({super.key});

  @override
  ConsumerState<NotificacionesPage> createState() =>
      _NotificacionesPageState();
}

class _NotificacionesPageState extends ConsumerState<NotificacionesPage> {
  bool _soloNoLeidas = false;
  Timer? _sondeoTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificacionesProvider.notifier).cargar();
    });
    // Sondeo de la bandeja: refresco silencioso cada 30 s (D33 — REST).
    _sondeoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.read(notificacionesProvider.notifier).refrescarSilencioso();
    });
  }

  @override
  void dispose() {
    _sondeoTimer?.cancel();
    super.dispose();
  }

  Future<void> _recargar() async {
    await ref.read(notificacionesProvider.notifier).cargar();
  }

  Future<void> _marcarTodasLeidas() async {
    final n = await ref.read(notificacionesProvider.notifier).marcarTodasLeidas();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n > 0
              ? '$n notificación${n == 1 ? '' : 'es'} marcada${n == 1 ? '' : 's'} como leída${n == 1 ? '' : 's'}'
              : 'No había notificaciones sin leer',
        ),
      ),
    );
  }

  Future<void> _limpiarLeidas() async {
    final eliminadas =
        await ref.read(notificacionesProvider.notifier).limpiarLeidas();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eliminadas > 0
              ? 'Se eliminaron $eliminadas notificaciones'
              : 'No había notificaciones leídas',
        ),
      ),
    );
  }

  /// Vuelve atrás sin arriesgarse a cerrar la app: si la ruta se puede
  /// hacer pop (venimos de Proyectos con `push`), hace pop normal; si la
  /// pantalla quedó como raíz de la pila, navega a Proyectos en lugar de
  /// dejar que Android cerrara la aplicación.
  void _volverAtras() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.proyectos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificacionesProvider);

    final lista = _soloNoLeidas
        ? state.notificaciones.where((n) => !n.leida).toList()
        : state.notificaciones;

    final hayError = state.error != null && state.notificaciones.isEmpty;

    return PopScope(
      // Intercepta el botón físico "atrás" de Android: si no hay pantalla
      // debajo de esta, vuelve a Proyectos en vez de cerrar la app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _volverAtras();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          // Botón de retroceso visible siempre (no dependía del estado de
          // la pila de navegación).
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
            onPressed: _volverAtras,
          ),
          actions: [
            if (state.noLeidas > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Marcar todas leídas',
                onPressed: _marcarTodasLeidas,
              ),
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Limpiar leídas',
              onPressed: _limpiarLeidas,
            ),
          ],
        ),
        body: hayError
            ? _EstadoVacio(
                icon: Icons.cloud_off_outlined,
                color: AppColors.danger,
                titulo: 'No se pudieron cargar las notificaciones',
                detalle: state.error!.detail.isNotEmpty
                    ? state.error!.detail
                    : 'Revisa tu conexión e inténtalo de nuevo.',
                accionLabel: 'Reintentar',
                onAccion: _recargar,
              )
            : Column(
                children: [
                  // Filtro "solo no leídas" + resumen
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          state.noLeidas > 0
                              ? '${state.noLeidas} sin leer'
                              : 'Todas leídas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: state.noLeidas > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: state.noLeidas > 0
                                ? AppColors.brand300
                                : AppColors.surface400,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Solo no leídas',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.surface400,
                          ),
                        ),
                        Switch(
                          value: _soloNoLeidas,
                          onChanged: (v) =>
                              setState(() => _soloNoLeidas = v),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: state.isLoading && state.notificaciones.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : lista.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _recargar,
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context)
                                              .size
                                              .height *
                                          0.55,
                                      child: _EstadoVacio(
                                        icon: _soloNoLeidas
                                            ? Icons.mark_email_read_outlined
                                            : Icons
                                                .notifications_none_outlined,
                                        color: _soloNoLeidas
                                            ? AppColors.success
                                            : AppColors.surface500,
                                        titulo: _soloNoLeidas
                                            ? 'Todo leído'
                                            : 'No hay notificaciones',
                                        detalle: _soloNoLeidas
                                            ? 'No tienes notificaciones sin leer.'
                                            : 'Cuando el equipo comente, cambie un '
                                                'diseño o guarde una versión, '
                                                'verás el aviso aquí.',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _recargar,
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(12),
                                  itemCount: lista.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) => _NotificacionCard(
                                    notificacion: lista[i],
                                    onToggle: () {
                                      final n = lista[i];
                                      if (n.leida) {
                                        ref
                                            .read(notificacionesProvider
                                                .notifier)
                                            .marcarNoLeida(n.id);
                                      } else {
                                        ref
                                            .read(notificacionesProvider
                                                .notifier)
                                            .marcarLeida(n.id);
                                      }
                                    },
                                    onEliminar: () => ref
                                        .read(notificacionesProvider.notifier)
                                        .eliminar(lista[i].id),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
        ),
    );
  }
}

// ======================================================================
// Estado vacío / error
// ======================================================================
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.detalle,
    this.accionLabel,
    this.onAccion,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String detalle;
  final String? accionLabel;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.surface200,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.surface500,
              ),
            ),
            if (accionLabel != null && onAccion != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(accionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Tarjeta de notificación
// ======================================================================
IconData _iconoDeTipo(TipoNotificacion tipo) {
  switch (tipo) {
    case TipoNotificacion.comentario:
      return Icons.comment_outlined;
    case TipoNotificacion.cambioDiagrama:
      return Icons.edit_note_outlined;
    case TipoNotificacion.generacionCompleta:
      return Icons.task_alt_outlined;
    case TipoNotificacion.generacionFallida:
      return Icons.error_outline;
    case TipoNotificacion.miembroAgregado:
      return Icons.person_add_alt_outlined;
    case TipoNotificacion.conflictoPendiente:
      return Icons.warning_amber_outlined;
    case TipoNotificacion.versionGuardada:
      return Icons.save_outlined;
    case TipoNotificacion.sistema:
      return Icons.info_outline;
  }
}

Color _colorDeTipo(TipoNotificacion tipo) {
  switch (tipo) {
    case TipoNotificacion.comentario:
      return AppColors.info;
    case TipoNotificacion.cambioDiagrama:
      return AppColors.brand400;
    case TipoNotificacion.generacionCompleta:
      return AppColors.success;
    case TipoNotificacion.generacionFallida:
      return AppColors.danger;
    case TipoNotificacion.miembroAgregado:
      return AppColors.successLight;
    case TipoNotificacion.conflictoPendiente:
      return AppColors.warning;
    case TipoNotificacion.versionGuardada:
      return AppColors.brand300;
    case TipoNotificacion.sistema:
      return AppColors.surface400;
  }
}

class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({
    required this.notificacion,
    required this.onToggle,
    required this.onEliminar,
  });

  final Notificacion notificacion;
  final VoidCallback onToggle;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final leida = notificacion.leida;
    final colorTipo = _colorDeTipo(notificacion.tipo);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: leida
            ? AppColors.surface900
            : AppColors.brand600.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: leida
              ? AppColors.surface800
              : colorTipo.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono según el tipo de aviso
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorTipo.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconoDeTipo(notificacion.tipo),
              size: 17,
              color: colorTipo,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Punto de no leída
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: leida
                            ? Colors.transparent
                            : colorTipo,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        notificacion.tipo.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: leida
                              ? AppColors.surface500
                              : colorTipo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notificacion.mensaje,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight:
                        leida ? FontWeight.w400 : FontWeight.w500,
                    color: leida
                        ? AppColors.surface300
                        : AppColors.surface100,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatFecha(notificacion.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.surface500,
                  ),
                ),
              ],
            ),
          ),

          // Acciones
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  leida
                      ? Icons.mark_email_unread_outlined
                      : Icons.done,
                  size: 18,
                ),
                color: AppColors.surface400,
                tooltip: leida ? 'Marcar no leída' : 'Marcar leída',
                onPressed: onToggle,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.surface400,
                tooltip: 'Eliminar',
                onPressed: onEliminar,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}