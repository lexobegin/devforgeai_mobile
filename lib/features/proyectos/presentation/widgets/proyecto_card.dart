// lib/features/proyectos/presentation/widgets/proyecto_card.dart
//
// Tarjeta de proyecto para la lista.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/proyecto_entity.dart';

class ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;
  final VoidCallback onTap;

  const ProyectoCard({
    super.key,
    required this.proyecto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final archivado = proyecto.estaArchivado;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proyecto.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (archivado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ARCHIVADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              if (proyecto.descripcion != null &&
                  proyecto.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  proyecto.descripcion!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.surface400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppColors.surface500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Actualizado ${_formatFecha(proyecto.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.surface500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inMinutes < 1) return 'hace instantes';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';

    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}