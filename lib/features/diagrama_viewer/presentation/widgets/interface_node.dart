// lib/features/diagrama_viewer/presentation/widgets/interface_node.dart
//
// Caja visual de una interfaz UML (solo lectura — Tanda M3).
//
// Antes el visor recibía las interfaces de GET /diagramas/{id}/completo
// y NO las dibujaba: cualquier «interfaz» creada en la web era invisible
// en el móvil. Ahora se renderiza como nodo UML:
//
//   ┌─────────────────────────┐
//   │ «interface»             │
//   │ NombreInterfaz          │
//   ├─────────────────────────┤
//   │ + operacion(): Tipo     │
//   └─────────────────────────┘
//
// Las relaciones NO apuntan a interfaces: el backend valida que ambos
// extremos sean clases embebidas (DiagramaService.crear_relacion usa
// diagrama.clase(id)); por eso el RelationshipPainter no necesita
// resolver interfaces.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/relacion_uml_entity.dart';

class InterfaceNode extends StatelessWidget {
  final InterfazUml interfaz;
  final bool seleccionada;
  final VoidCallback? onTap;

  const InterfaceNode({
    super.key,
    required this.interfaz,
    this.seleccionada = false,
    this.onTap,
  });

  static const double width = 200;

  /// Alto estimado de la caja según su contenido (espejo del layout de
  /// [build], misma fórmula que ClassNode.alturaEstimada).
  static double alturaEstimada(InterfazUml interfaz) {
    const anchoTexto = width - 16; // 8 de padding por lado
    double cabecera = 12; // padding vertical 6 + 6
    cabecera += 13; // línea «interface» (9px)
    // Nombre: hasta 2 líneas de ~18px (13px de fuente × 1.4)
    cabecera += _altoTextoAprox(interfaz.nombre, anchoTexto, 18, maxLineas: 2);

    double operaciones = 0;
    if (interfaz.operaciones.isNotEmpty) {
      operaciones = 8 + interfaz.operaciones.length * 16;
    }

    return cabecera + operaciones + 3; // + bordes
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
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: seleccionada ? AppColors.brand500 : AppColors.surface600,
            width: seleccionada ? 2 : 1.5,
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
            // -------- Cabecera: «interface» + nombre --------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  const Text(
                    '«interface»',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.surface400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    interfaz.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface100,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // -------- Operaciones declaradas --------
            if (interfaz.operaciones.isNotEmpty)
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
                  children: interfaz.operaciones
                      .map((op) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style:
                                    const TextStyle(fontSize: 10, height: 1.4),
                                children: [
                                  TextSpan(
                                    text: '+ ${op.nombre}()',
                                    style: const TextStyle(
                                        color: AppColors.surface200),
                                  ),
                                  if (op.tipoRetorno.isNotEmpty) ...[
                                    const TextSpan(text: ': '),
                                    TextSpan(
                                      text: op.tipoRetorno,
                                      style: const TextStyle(
                                          color: AppColors.surface500),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
