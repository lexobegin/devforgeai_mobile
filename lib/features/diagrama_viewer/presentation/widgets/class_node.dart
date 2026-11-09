// lib/features/diagrama_viewer/presentation/widgets/class_node.dart
//
// Caja visual de una clase UML.
//
// Renderiza:
//   ┌─────────────────────────┐
//   │ <<stereotype>>          │
//   │ NombreClase             │  (en cursiva si es abstracta)
//   ├─────────────────────────┤
//   │ - atributo: Tipo        │
//   │ + otro: Tipo            │
//   ├─────────────────────────┤
//   │ + operacion(): Tipo     │
//   └─────────────────────────┘

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';

class ClassNode extends StatelessWidget {
  final ClaseUml clase;
  final bool seleccionada;
  final Color? colorColaborador;
  final String? nombreColaborador;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(Offset delta)? onDrag;

  const ClassNode({
    super.key,
    required this.clase,
    this.seleccionada = false,
    this.colorColaborador,
    this.nombreColaborador,
    this.onTap,
    this.onLongPress,
    this.onDrag,
  });

  static const double width = 200;

  /// Alto estimado de la caja según su contenido. Se usa como fallback
  /// del painter mientras el canvas aún no midió el nodo real (primer
  /// frame) y para el encuadre inicial de la cámara.
  ///
  /// Espeja el layout real de [build]: cabecera (6+6 de padding + texto
  /// de 13px), secciones de atributos/operaciones (4+4 de padding + una
  /// línea de ~16px por miembro) y bordes (~3px).
  static double alturaEstimada(ClaseUml clase) {
    const anchoTexto = width - 16; // 8 de padding por lado
    double cabecera = 12; // padding vertical 6 + 6
    if (clase.estereotipo != null && clase.estereotipo!.isNotEmpty) {
      cabecera += 13; // línea del estereotipo (9px)
    }
    // Nombre: hasta 2 líneas de ~18px (13px de fuente × 1.4)
    cabecera += _altoTextoAprox(clase.nombre, anchoTexto, 18, maxLineas: 2);

    double atributos = 0;
    if (clase.atributos.isNotEmpty) {
      atributos = 8 + clase.atributos.length * 16; // padding 4+4 + línea c/u
    }
    double operaciones = 0;
    if (clase.operaciones.isNotEmpty) {
      operaciones = 8 + clase.operaciones.length * 16;
    }

    return cabecera + atributos + operaciones + 3; // + bordes
  }

  /// Alto en px que ocuparía un texto (aprox. 7.5px por carácter,
  /// hasta [maxLineas] líneas).
  static int _altoTextoAprox(
    String texto,
    double anchoDisponible,
    double altoLinea, {
    int maxLineas = 1,
  }) {
    if (texto.isEmpty) return 1;
    final anchoAprox = texto.length * 7.5;
    final lineas = (anchoAprox / anchoDisponible).ceil().clamp(1, maxLineas);
    return (lineas * altoLinea).round();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onPanUpdate: onDrag != null
          ? (details) => onDrag!(details.delta)
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Caja principal
          Container(
            width: width,
            decoration: BoxDecoration(
              color: AppColors.surface900,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorColaborador ??
                    (seleccionada
                        ? AppColors.brand500
                        : AppColors.surface600),
                width: seleccionada || colorColaborador != null ? 2 : 1.5,
              ),
              boxShadow: seleccionada
                  ? [
                      BoxShadow(
                        color: AppColors.brand500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------- Cabecera --------
                _Header(clase: clase),

                // -------- Atributos --------
                if (clase.atributos.isNotEmpty) ...[
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surface700),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: clase.atributos
                          .map((a) => _MiembroLine(
                                texto: '${a.visibilidad.value} ${a.nombre}',
                                tipo: a.tipoDato,
                                esEstatico: a.esEstatico,
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // -------- Operaciones --------
                if (clase.operaciones.isNotEmpty) ...[
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surface700),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: clase.operaciones
                          .map((op) => _MiembroLine(
                                texto:
                                    '${op.visibilidad.value} ${op.nombre}()',
                                tipo: op.tipoRetorno,
                                esEstatico: op.esEstatico,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Etiqueta de colaborador (encima de la caja)
          if (colorColaborador != null && nombreColaborador != null)
            Positioned(
              top: -20,
              left: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorColaborador,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  nombreColaborador!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================================
// Cabecera
// ======================================================================
class _Header extends StatelessWidget {
  final ClaseUml clase;

  const _Header({required this.clase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          if (clase.estereotipo != null &&
              clase.estereotipo!.isNotEmpty) ...[
            Text(
              '«${clase.estereotipo}»',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.surface400,
                letterSpacing: 0.5,
              ),
            ),
          ],
          Text(
            clase.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontStyle:
                  clase.esAbstracta ? FontStyle.italic : FontStyle.normal,
              color: AppColors.surface100,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Línea de atributo u operación
// ======================================================================
class _MiembroLine extends StatelessWidget {
  final String texto;
  final String tipo;
  final bool esEstatico;

  const _MiembroLine({
    required this.texto,
    required this.tipo,
    this.esEstatico = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 10, height: 1.4),
          children: [
            TextSpan(
              text: texto,
              style: TextStyle(
                color: AppColors.surface200,
                decoration:
                    esEstatico ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
            if (tipo.isNotEmpty) ...[
              const TextSpan(text: ': '),
              TextSpan(
                text: tipo,
                style: const TextStyle(color: AppColors.surface500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}