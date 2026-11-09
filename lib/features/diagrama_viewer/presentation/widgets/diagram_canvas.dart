// lib/features/diagrama_viewer/presentation/widgets/diagram_canvas.dart
//
// Canvas del visor (solo lectura).
//
// Usa InteractiveViewer para pan/zoom. Dentro, un Stack posiciona:
//   1. Un CustomPaint con todas las relaciones (abajo).
//   2. Los ClassNode en sus posiciones (arriba).
//   3. Los InterfaceNode (Tanda M3: antes las interfaces llegaban del
//      backend y no se dibujaban).
//
// Corrección del lienzo (tanda M2): cada nodo se MIDE su tamaño real
// después del primer frame (widget _Medidor) y el painter usa esas
// medidas para anclar las relaciones en los bordes de las cajas.
//
// Sin colaboración en vivo: sin cursores remotos ni drag. El tap solo
// resalta el elemento seleccionado (clase, interfaz o relación).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/relacion_uml_entity.dart';
import '../providers/diagrama_provider.dart';
import 'class_node.dart';
import 'interface_node.dart';
import 'relationship_painter.dart';


class DiagramCanvas extends ConsumerStatefulWidget {
  final TransformationController controller;

  const DiagramCanvas({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  // Tamaño del "lienzo lógico". Es grande para permitir mucho espacio.
  static const double canvasWidth = 3000;
  static const double canvasHeight = 3000;

  /// Tamaño real medido de cada nodo (id de clase → Size). Lo reporta
  /// _Medidor tras el primer frame y en cada cambio de contenido.
  final Map<String, Size> _medidas = {};

  void _onMedida(String claseId, Size medida) {
    if (_medidas[claseId] == medida) return; // sin cambios: no repintar
    setState(() => _medidas[claseId] = medida);
  }

  @override
  Widget build(BuildContext context) {
    final clases = ref.watch(clasesProvider);
    final interfaces = ref.watch(interfacesProvider);
    final relaciones = ref.watch(relacionesProvider);
    final seleccion = ref.watch(diagramaProvider).seleccion;
    final lienzoVacio = clases.isEmpty && interfaces.isEmpty;

    return InteractiveViewer(
      transformationController: widget.controller,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      constrained: false,
      child: GestureDetector(
        onTap: () {
          // Tap fuera de una clase: limpiar el resaltado
          ref.read(diagramaProvider.notifier).seleccionar(null);
        },
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // -------- Fondo con grid --------
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),

              // -------- Relaciones (CustomPaint) --------
              // Map.of() crea una identidad nueva para que el painter
              // repinte cuando cambian las medidas.
              Positioned.fill(
                child: CustomPaint(
                  painter: RelationshipPainter(
                    clases: clases,
                    relaciones: relaciones,
                    seleccionadaId: seleccion?.esRelacion == true
                        ? seleccion!.id
                        : null,
                    medidasNodos: Map.of(_medidas),
                  ),
                ),
              ),

              // -------- Nodos (solo lectura) --------
              for (final clase in clases)
                Positioned(
                  left: clase.posX,
                  top: clase.posY,
                  child: _NodoClase(
                    clase: clase,
                    seleccionada: seleccion?.esClase == true &&
                        seleccion!.id == clase.id,
                    onMedida: _onMedida,
                  ),
                ),

              // -------- Interfaces (Tanda M3: antes no se dibujaban) ---
              for (final interfaz in interfaces)
                Positioned(
                  left: interfaz.posX,
                  top: interfaz.posY,
                  child: _NodoInterfaz(
                    interfaz: interfaz,
                    seleccionada: seleccion?.esInterfaz == true &&
                        seleccion!.id == interfaz.id,
                    onMedida: _onMedida,
                  ),
                ),

              // -------- Estado vacío del diseño --------
              if (lienzoVacio)
                const Positioned.fill(
                  child: Center(
                    child: _LienzoVacio(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Nodo sin drag (solo lectura) + medición de tamaño real
// ======================================================================
class _NodoClase extends ConsumerStatefulWidget {
  final ClaseUml clase;
  final bool seleccionada;
  final void Function(String claseId, Size medida) onMedida;

  const _NodoClase({
    required this.clase,
    required this.seleccionada,
    required this.onMedida,
  });

  @override
  ConsumerState<_NodoClase> createState() => _NodoClaseState();
}

class _NodoClaseState extends ConsumerState<_NodoClase> {
  @override
  Widget build(BuildContext context) {
    return _Medidor(
      onMedida: (medida) => widget.onMedida(widget.clase.id, medida),
      child: ClassNode(
        clase: widget.clase,
        seleccionada: widget.seleccionada,
        onTap: () {
          ref.read(diagramaProvider.notifier).seleccionar(
                ElementoSeleccionado.clase(widget.clase.id),
              );
        },
      ),
    );
  }
}

// ======================================================================
// Nodo de interfaz (solo lectura, Tanda M3) + medición
// ======================================================================
class _NodoInterfaz extends ConsumerStatefulWidget {
  final InterfazUml interfaz;
  final bool seleccionada;
  final void Function(String elementoId, Size medida) onMedida;

  const _NodoInterfaz({
    required this.interfaz,
    required this.seleccionada,
    required this.onMedida,
  });

  @override
  ConsumerState<_NodoInterfaz> createState() => _NodoInterfazState();
}

class _NodoInterfazState extends ConsumerState<_NodoInterfaz> {
  @override
  Widget build(BuildContext context) {
    return _Medidor(
      onMedida: (medida) => widget.onMedida(widget.interfaz.id, medida),
      child: InterfaceNode(
        interfaz: widget.interfaz,
        seleccionada: widget.seleccionada,
        onTap: () {
          ref.read(diagramaProvider.notifier).seleccionar(
                ElementoSeleccionado.interfaz(widget.interfaz.id),
              );
        },
      ),
    );
  }
}

// ======================================================================
// Mensaje del lienzo sin contenido (el equipo diseña desde la web)
// ======================================================================
class _LienzoVacio extends StatelessWidget {
  const _LienzoVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface800),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schema_outlined, size: 36, color: AppColors.surface500),
          SizedBox(height: 10),
          Text(
            'Este diagrama aún no tiene clases ni interfaces',
            style: TextStyle(fontSize: 13, color: AppColors.surface300),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'El equipo las crea y edita desde la web — aquí se observan.',
            style: TextStyle(fontSize: 11, color: AppColors.surface500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Medidor de tamaño: reporta el Size real del hijo tras cada layout
// ======================================================================
class _Medidor extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onMedida;

  const _Medidor({required this.onMedida, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMedidor(onMedida);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMedidor renderObject,
  ) {
    renderObject.onMedida = onMedida;
  }
}

class _RenderMedidor extends RenderProxyBox {
  _RenderMedidor(this.onMedida);

  ValueChanged<Size> onMedida;
  Size? _ultima;

  @override
  void performLayout() {
    super.performLayout();
    if (child == null || size == _ultima) return;

    _ultima = size;
    final medida = size;
    final callback = onMedida;
    // Fuera del layout: evitar setState durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(medida));
  }
}

// ======================================================================
// Grid de fondo
// ======================================================================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 24.0;
    final paint = Paint()
      ..color = AppColors.surface800.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
