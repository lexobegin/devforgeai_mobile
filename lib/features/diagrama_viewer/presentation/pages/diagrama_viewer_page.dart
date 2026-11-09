// lib/features/diagrama_viewer/presentation/pages/diagrama_viewer_page.dart
//
// Visor de diagramas (solo lectura — CU10/CU22).
//
// La app móvil del Ciclo 2 es informativa: muestra el estado del
// diseño que el equipo edita en la web. Según D33 la observación
// móvil es por REST + aviso push, SIN WebSocket:
//
//   • Carga inicial por GET /diagramas/{id}/completo (CU10).
//   • Sondeo opcional cada 30 s (refresco silencioso, no parpadea el
//     lienzo; avisa con un SnackBar cuando el diseño cambió).
//   • Refresco manual (botón) y pull-to-refresh en los paneles
//     informativos (versiones / actividad reciente).
//   • Sin edición, sin IA y sin colaboración en vivo.
//
// Tanda M3: renombrada desde la página del editor del Ciclo 1; añade
// sondeo, actividad reciente y persistencia de la cámara entre refrescos.
//
// Layout:
//   ┌──────────────────────────────────────────────┐
//   │ AppBar (nombre + actividad + versiones +     │
//   │         sondeo + refrescar)                  │
//   ├──────────────────────────────────────────────┤
//   │   Canvas (InteractiveViewer)                 │
//   │   + aviso "solo lectura"                     │
//   └──────────────────────────────────────────────┘

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/diagrama_provider.dart';
import '../widgets/actividad_reciente_panel.dart';
import '../widgets/class_node.dart';
import '../widgets/diagram_canvas.dart';
import '../widgets/interface_node.dart';
import '../widgets/versiones_panel.dart';

/// Intervalo del sondeo de observación (CU22 — D33). Mismo ritmo que
/// la bandeja de notificaciones (M4): 30 s.
const _intervaloSondeo = Duration(seconds: 30);

class DiagramaViewerPage extends ConsumerStatefulWidget {
  final String diagramaId;

  const DiagramaViewerPage({super.key, required this.diagramaId});

  @override
  ConsumerState<DiagramaViewerPage> createState() =>
      _DiagramaViewerPageState();
}

class _DiagramaViewerPageState extends ConsumerState<DiagramaViewerPage> {
  final _transformationController = TransformationController();

  /// Sondeo de observación (REST) activado por defecto; se puede
  /// pausar desde el AppBar.
  Timer? _sondeo;
  bool _sondeoActivo = true;

  DateTime? _ultimaActualizacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar cualquier estado previo del diagrama anterior
      ref.read(diagramaProvider.notifier).limpiar();

      // Cargar el nuevo diagrama
      _cargar();

      // Arrancar el sondeo de observación (CU22)
      _iniciarSondeo();
    });
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  // ==================================================================
  // Carga y sondeo
  // ==================================================================
  Future<void> _cargar() async {
    await ref.read(diagramaProvider.notifier).cargar(widget.diagramaId);
    // Ajustar la vista SOLO en la primera carga (o si el lienzo quedó
    // vacío); en los refrescos se mantiene la cámara del usuario.
    if (_ultimaActualizacion == null) {
      _ajustarVistaInicial();
    }
    if (mounted) {
      setState(() => _ultimaActualizacion = DateTime.now());
    }
  }

  void _iniciarSondeo() {
    _sondeo?.cancel();
    _sondeo = Timer.periodic(_intervaloSondeo, (_) => _cicloSondeo());
  }

  Future<void> _cicloSondeo() async {
    if (!mounted) return;
    final cambio = await ref.read(diagramaProvider.notifier).refrescar();
    if (cambio && mounted) {
      setState(() => _ultimaActualizacion = DateTime.now());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'El diseño se actualizó desde la web — vista renovada',
              style: TextStyle(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.surface800,
          ),
        );
    }
  }

  void _alternarSondeo() {
    setState(() => _sondeoActivo = !_sondeoActivo);
    if (_sondeoActivo) {
      _iniciarSondeo();
    } else {
      _sondeo?.cancel();
      _sondeo = null;
    }
  }

  void _ajustarVistaInicial() {
    final clases = ref.read(diagramaProvider).clases;
    final interfaces = ref.read(diagramaProvider).interfaces;
    if (clases.isEmpty && interfaces.isEmpty) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    // Calcular el bounding box de todas las clases usando el alto
    // estimado por contenido (el mismo fallback del painter); las
    // interfaces se incluyen para encuadrarlas también.
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    void incluir(double x, double y, double ancho, double alto) {
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x + ancho > maxX) maxX = x + ancho;
      if (y + alto > maxY) maxY = y + alto;
    }

    for (final c in clases) {
      incluir(c.posX, c.posY, ClassNode.width, ClassNode.alturaEstimada(c));
    }
    for (final i in interfaces) {
      incluir(
        i.posX,
        i.posY,
        InterfaceNode.width,
        InterfaceNode.alturaEstimada(i),
      );
    }

    // Mover la cámara para centrar el bounding box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final scale = 0.8;
      final offsetX = (screenWidth - (maxX - minX) * scale) / 2 - minX * scale;
      final offsetY = (screenHeight - (maxY - minY) * scale) / 2 - minY * scale;

      final m = Matrix4.identity()
        ..translate(offsetX, offsetY)
        ..scale(scale);
      _transformationController.value = m;
    });
  }

  // ==================================================================
  // Paneles informativos (bottom sheets, con pull-to-refresh)
  // ==================================================================
  void _abrirVersiones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: VersionesPanel(diagramaId: widget.diagramaId),
      ),
    );
  }

  void _abrirActividad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ActividadRecientePanel(diagramaId: widget.diagramaId),
      ),
    );
  }

  // ==================================================================
  // Render
  // ==================================================================
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagramaProvider);
    final diagrama = state.diagrama;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagrama')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  state.error!.userMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.surface300),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (diagrama == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagrama')),
        body: const Center(
          child: Text('No se pudo cargar el diagrama'),
        ),
      );
    }

    final actualizado = _ultimaActualizacion;
    final horaActualizado = actualizado == null
        ? ''
        : ' · Act. '
            '${actualizado.hour.toString().padLeft(2, '0')}:'
            '${actualizado.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diagrama.nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'UML ${diagrama.versionUml} · v${diagrama.numeroVersion} '
              '· Solo lectura$horaActualizado',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.surface400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            AppRoutes.proyectoDetalle(diagrama.idProyecto),
          ),
        ),
        actions: [
          // Trazabilidad completa (historial / versiones / comentarios — M5)
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Trazabilidad',
            onPressed: () => context.push(
              AppRoutes.diagramaTrazabilidad(
                diagrama.id,
                nombre: diagrama.nombre,
              ),
            ),
          ),

          // Actividad reciente (quién cambió qué — D33)
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Actividad reciente',
            onPressed: _abrirActividad,
          ),

          // Versiones (historial informativo)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Versiones',
            onPressed: _abrirVersiones,
          ),

          // Sondeo de observación CU22 (pausar / reanudar)
          IconButton(
            icon: Icon(
              _sondeoActivo ? Icons.autorenew : Icons.sync_disabled,
              color: _sondeoActivo ? AppColors.success : AppColors.surface500,
            ),
            tooltip: _sondeoActivo
                ? 'Sondeo activo (30 s) — pausar'
                : 'Sondeo pausado — reanudar',
            onPressed: _alternarSondeo,
          ),

          // Refrescar (observación por REST, manual)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar ahora',
            onPressed: _cargar,
          ),
        ],
      ),
      body: Stack(
        children: [
          DiagramCanvas(controller: _transformationController),

          // Aviso informativo de solo lectura + estado del sondeo
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface900.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surface800),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sondeoActivo
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 14,
                      color: _sondeoActivo
                          ? AppColors.success
                          : AppColors.surface400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _sondeoActivo
                          ? 'Observando (REST · 30 s) — la edición se hace en la web'
                          : 'Observación en pausa — la edición se hace en la web',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.surface400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
