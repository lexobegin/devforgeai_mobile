// lib/features/diagrama_viewer/presentation/widgets/versiones_panel.dart
//
// Panel de versiones guardadas del diagrama (solo lectura).
//
// App informativa: las versiones se crean desde la web; aquí se
// consultan para ver cómo evolucionó el diseño.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../trazabilidad/presentation/providers/trazabilidad_provider.dart';

class VersionesPanel extends ConsumerStatefulWidget {
  final String diagramaId;

  const VersionesPanel({super.key, required this.diagramaId});

  @override
  ConsumerState<VersionesPanel> createState() => _VersionesPanelState();
}

class _VersionesPanelState extends ConsumerState<VersionesPanel> {
  @override
  Widget build(BuildContext context) {
    final versionesAsync = ref.watch(versionesProvider(widget.diagramaId));

    return Column(
      children: [
        // Cabecera
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.surface400),
              SizedBox(width: 8),
              Text(
                'Historial de versiones',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista de versiones
        Expanded(
          child: versionesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (versiones) {
              if (versiones.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref
                      .invalidate(versionesProvider(widget.diagramaId)),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Sin versiones guardadas',
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
                    ref.invalidate(versionesProvider(widget.diagramaId)),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: versiones.length,
                  itemBuilder: (_, i) {
                    final v = versiones[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface800.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'v${v.numeroVersion}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatFecha(v.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.surface500,
                                ),
                              ),
                            ],
                          ),
                          if (v.comentario != null &&
                              v.comentario!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              v.comentario!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.surface400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
