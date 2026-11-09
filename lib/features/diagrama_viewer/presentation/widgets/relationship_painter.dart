// lib/features/diagrama_viewer/presentation/widgets/relationship_painter.dart
//
// CustomPainter que dibuja todas las relaciones UML entre clases.
//
// Se dibuja POR DEBAJO de los nodos en el Stack, para que las líneas
// queden "detrás" de las cajas.
//
// Alcance (Tanda M3): las relaciones van SIEMPRE de clase a clase —
// el backend valida ambos extremos contra diagrama.clase(id) en
// DiagramaService.crear_relacion, así que las interfaces nunca son
// extremos y este painter no las resuelve (las interfaces se pintan
// como nodos en diagram_canvas.dart, sin relaciones propias).
//
// Corrección del lienzo (Ciclo 2, tanda M2):
//   - Los extremos se calculan en el BORDE REAL de cada caja
//     (intersección del rayo centro→centro con el rectángulo del nodo),
//     no en el centro: las líneas ya no atraviesan las clases ni quedan
//     escondidas detrás de ellas.
//   - El alto de cada nodo se MIDE en pantalla (ver diagram_canvas.dart);
//     si aún no hay medición se usa una estimación por contenido.
//   - Flechas/triángulos apuntan al borde del destino y los diamantes
//     de composición/agregación quedan pegados al borde del origen
//     (antes se dibujaban en el centro, tapados por la caja).
//   - Los ids son String (ObjectId de MongoDB), alineado con el backend.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/relacion_uml_entity.dart';
import 'class_node.dart';

class RelationshipPainter extends CustomPainter {
  final List<ClaseUml> clases;
  final List<RelacionUml> relaciones;
  final String? seleccionadaId;

  /// Alto/ancho medido de cada nodo (id → Size), reportado por el canvas
  /// después del primer frame. Si falta una medida se estima.
  final Map<String, Size> medidasNodos;

  RelationshipPainter({
    required this.clases,
    required this.relaciones,
    this.seleccionadaId,
    this.medidasNodos = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final relacion in relaciones) {
      final origen = _clasePorId(relacion.idClaseOrigen);
      final destino = _clasePorId(relacion.idClaseDestino);
      if (origen == null || destino == null) continue;

      final seleccionada = relacion.id == seleccionadaId;
      _dibujarRelacion(canvas, origen, destino, relacion, seleccionada);
    }
  }

  // ==================================================================
  // Dibujo de una relación
  // ==================================================================
  void _dibujarRelacion(
    Canvas canvas,
    ClaseUml origen,
    ClaseUml destino,
    RelacionUml relacion,
    bool seleccionada,
  ) {
    // Rectángulos reales (o estimados) de cada caja
    final rectOrigen = _rectDe(origen);
    final rectDestino = _rectDe(destino);

    // Centros y dirección del segmento centro→centro
    final c1 = rectOrigen.center;
    final c2 = rectDestino.center;
    final delta = c2 - c1;
    if (delta.distance < 1) return; // cajas superpuestas: nada que dibujar
    final dir = delta / delta.distance;

    // Extremos EN LOS BORDES de las cajas (rayo desde el centro)
    final p1 = _puntoSalida(rectOrigen, c1, dir);
    final p2 = _puntoSalida(rectDestino, c2, -dir);

    final color = seleccionada ? AppColors.brand400 : AppColors.surface500;
    final paint = Paint()
      ..color = color
      ..strokeWidth = seleccionada ? 2.5 : 1.8
      ..style = PaintingStyle.stroke;

    // Aplicar estilo según tipo
    if (relacion.tipoRelacion == TipoRelacion.dependencia ||
        relacion.tipoRelacion == TipoRelacion.realizacion) {
      _dibujarLineaDiscontinua(canvas, p1, p2, paint);
    } else {
      canvas.drawLine(p1, p2, paint);
    }

    // Extremo decorativo: punta en el borde del destino y diamante
    // pegado al borde del origen
    _dibujarExtremo(
      canvas: canvas,
      punta: p2,
      desde: p1,
      tipo: relacion.tipoRelacion,
      color: color,
    );

    // Multiplicidades y nombre sobre el tramo visible
    _dibujarMultiplicidades(canvas, p1, p2, relacion);

    if (relacion.nombreAsociacion != null &&
        relacion.nombreAsociacion!.isNotEmpty) {
      _dibujarTextoCentro(canvas, p1, p2, relacion.nombreAsociacion!);
    }
  }

  // ==================================================================
  // Geometría: rectángulo del nodo y borde de salida
  // ==================================================================
  Rect _rectDe(ClaseUml clase) {
    final medida = medidasNodos[clase.id];
    final ancho = medida?.width ?? ClassNode.width;
    final alto = medida?.height ?? ClassNode.alturaEstimada(clase);
    return Rect.fromLTWH(clase.posX, clase.posY, ancho, alto);
  }

  /// Punto donde el rayo que sale de [centro] en dirección [dir]
  /// cruza el borde del rectángulo [r].
  Offset _puntoSalida(Rect r, Offset centro, Offset dir) {
    double tx = double.infinity;
    double ty = double.infinity;

    if (dir.dx > 0) {
      tx = (r.right - centro.dx) / dir.dx;
    } else if (dir.dx < 0) {
      tx = (r.left - centro.dx) / dir.dx;
    }

    if (dir.dy > 0) {
      ty = (r.bottom - centro.dy) / dir.dy;
    } else if (dir.dy < 0) {
      ty = (r.top - centro.dy) / dir.dy;
    }

    final t = math.min(tx, ty);
    if (!t.isFinite || t < 0) return centro; // centro fuera de su caja
    return centro + dir * t;
  }

  // ==================================================================
  // Extremos según tipo
  // ==================================================================
  void _dibujarExtremo({
    required Canvas canvas,
    required Offset punta,
    required Offset desde,
    required TipoRelacion tipo,
    required Color color,
  }) {
    final angulo = math.atan2(punta.dy - desde.dy, punta.dx - desde.dx);

    switch (tipo) {
      case TipoRelacion.generalizacion:
      case TipoRelacion.realizacion:
        _dibujarTrianguloHueco(canvas, punta, angulo, color);
        break;
      case TipoRelacion.composicion:
      case TipoRelacion.agregacion:
        // Diamante pegado al borde del ORIGEN (desde), extendiéndose
        // hacia afuera: el vértice cercano queda exactamente en el borde
        // (centro = borde + 0.3·tam en dirección de la línea, porque el
        // diamante mide tam hacia adelante y 0.3·tam hacia atrás).
        const tam = 10.0;
        _dibujarDiamante(
          canvas,
          desde +
              Offset(
                tam * 0.3 * math.cos(angulo),
                tam * 0.3 * math.sin(angulo),
              ),
          angulo,
          color,
          relleno: tipo == TipoRelacion.composicion,
        );
        break;
      case TipoRelacion.asociacion:
      case TipoRelacion.dependencia:
        _dibujarFlechaAbierta(canvas, punta, angulo, color);
        break;
    }
  }

  void _dibujarTrianguloHueco(
    Canvas canvas,
    Offset punta,
    double angulo,
    Color color,
  ) {
    const tam = 12.0;
    final p1 = punta;
    final p2 = punta +
        Offset(
          -tam * math.cos(angulo - math.pi / 6),
          -tam * math.sin(angulo - math.pi / 6),
        );
    final p3 = punta +
        Offset(
          -tam * math.cos(angulo + math.pi / 6),
          -tam * math.sin(angulo + math.pi / 6),
        );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.surface900
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _dibujarDiamante(
    Canvas canvas,
    Offset centro,
    double angulo,
    Color color, {
    bool relleno = false,
  }) {
    const tam = 10.0;
    final p1 = centro +
        Offset(tam * math.cos(angulo), tam * math.sin(angulo));
    final p2 = centro +
        Offset(
          tam * 0.7 * math.cos(angulo + math.pi / 2),
          tam * 0.7 * math.sin(angulo + math.pi / 2),
        );
    final p3 = centro +
        Offset(
          -tam * 0.3 * math.cos(angulo),
          -tam * 0.3 * math.sin(angulo),
        );
    final p4 = centro +
        Offset(
          tam * 0.7 * math.cos(angulo - math.pi / 2),
          tam * 0.7 * math.sin(angulo - math.pi / 2),
        );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = relleno ? color : AppColors.surface900
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _dibujarFlechaAbierta(
    Canvas canvas,
    Offset punta,
    double angulo,
    Color color,
  ) {
    const tam = 10.0;
    final p1 = punta +
        Offset(
          -tam * math.cos(angulo - math.pi / 6),
          -tam * math.sin(angulo - math.pi / 6),
        );
    final p2 = punta +
        Offset(
          -tam * math.cos(angulo + math.pi / 6),
          -tam * math.sin(angulo + math.pi / 6),
        );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(punta, p1, paint);
    canvas.drawLine(punta, p2, paint);
  }

  // ==================================================================
  // Multiplicidades
  // ==================================================================
  void _dibujarMultiplicidades(
    Canvas canvas,
    Offset p1,
    Offset p2,
    RelacionUml relacion,
  ) {
    if (relacion.multiplicidadOrigen != null) {
      final pos = Offset.lerp(p1, p2, 0.2)!;
      _dibujarTexto(canvas, pos, relacion.multiplicidadOrigen!);
    }
    if (relacion.multiplicidadDestino != null) {
      final pos = Offset.lerp(p1, p2, 0.8)!;
      _dibujarTexto(canvas, pos, relacion.multiplicidadDestino!);
    }
  }

  void _dibujarTexto(Canvas canvas, Offset pos, String texto) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: AppColors.surface400,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Fondo
    final rect = Rect.fromLTWH(
      pos.dx - painter.width / 2 - 2,
      pos.dy - painter.height / 2 - 1,
      painter.width + 4,
      painter.height + 2,
    );
    canvas.drawRect(
      rect,
      Paint()..color = AppColors.surface950.withValues(alpha: 0.85),
    );

    painter.paint(
      canvas,
      Offset(pos.dx - painter.width / 2, pos.dy - painter.height / 2),
    );
  }

  void _dibujarTextoCentro(
    Canvas canvas,
    Offset p1,
    Offset p2,
    String texto,
  ) {
    final centro = Offset.lerp(p1, p2, 0.5)!;

    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: AppColors.surface300,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromLTWH(
      centro.dx - painter.width / 2 - 3,
      centro.dy - painter.height / 2 - 1,
      painter.width + 6,
      painter.height + 2,
    );
    canvas.drawRect(
      rect,
      Paint()..color = AppColors.surface950,
    );

    painter.paint(
      canvas,
      Offset(centro.dx - painter.width / 2, centro.dy - painter.height / 2),
    );
  }

  // ==================================================================
  // Línea discontinua
  // ==================================================================
  void _dibujarLineaDiscontinua(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dash = 6.0;
    const gap = 4.0;
    final total = (p2 - p1).distance;
    if (total < 1) return;
    final dir = (p2 - p1) / total;

    double recorrido = 0;
    while (recorrido < total) {
      final start = p1 + dir * recorrido;
      final end = p1 + dir * math.min(recorrido + dash, total);
      canvas.drawLine(start, end, paint);
      recorrido += dash + gap;
    }
  }

  // ==================================================================
  // Helpers
  // ==================================================================
  ClaseUml? _clasePorId(String id) {
    for (final c in clases) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant RelationshipPainter oldDelegate) {
    return oldDelegate.clases != clases ||
        oldDelegate.relaciones != relaciones ||
        oldDelegate.seleccionadaId != seleccionadaId ||
        oldDelegate.medidasNodos != medidasNodos;
  }
}
