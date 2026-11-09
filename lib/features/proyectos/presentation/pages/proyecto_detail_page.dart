// lib/features/proyectos/presentation/pages/proyecto_detail_page.dart
//
// Detalle de proyecto (solo lectura): metadata, miembros y diagramas.
//
// App informativa: sin archivar/eliminar ni crear diagramas — todo eso
// se hace desde la web. Aquí se observa cómo va el proyecto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../diagrama_viewer/presentation/providers/diagrama_provider.dart';
import '../../../diagrama_viewer/domain/diagrama_entity.dart';
import '../../../diagrama_viewer/data/diagrama_remote_datasource.dart';
import '../../domain/proyecto_entity.dart';
import '../providers/proyecto_detalle_provider.dart';

class ProyectoDetailPage extends ConsumerStatefulWidget {
  final String proyectoId;

  const ProyectoDetailPage({super.key, required this.proyectoId});

  @override
  ConsumerState<ProyectoDetailPage> createState() => _ProyectoDetailPageState();
}

class _ProyectoDetailPageState extends ConsumerState<ProyectoDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar el estado anterior y cargar el nuevo proyecto
      ref.read(proyectoDetalleProvider.notifier).limpiar();
      ref.read(proyectoDetalleProvider.notifier).cargar(widget.proyectoId);
      _cargarDiagramas();
    });
  }

  List<Diagrama> _diagramas = [];
  bool _cargandoDiagramas = true;

  Future<void> _cargarDiagramas() async {
    setState(() => _cargandoDiagramas = true);
    try {
      final remote = ref.read(diagramaRemoteDataSourceProvider);
      final items = await remote.listarPorProyecto(widget.proyectoId);
      if (mounted) {
        setState(() {
          _diagramas = items;
          _cargandoDiagramas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _diagramas = [];
          _cargandoDiagramas = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proyectoDetalleProvider);
    final proyecto = state.proyecto?.proyecto;
    final miembros = state.proyecto?.miembros ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.proyectos),
        ),
        title: Text(proyecto?.nombre ?? 'Proyecto'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(
                  message: state.error!.userMessage,
                  onRetry: () => ref
                      .read(proyectoDetalleProvider.notifier)
                      .cargar(widget.proyectoId),
                )
              : proyecto == null
                  ? const Center(child: Text('Proyecto no encontrado'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(proyectoDetalleProvider.notifier)
                            .cargar(widget.proyectoId);
                        await _cargarDiagramas();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metadata
                            _InfoCard(
                              proyecto: proyecto,
                              miembros: miembros.length,
                            ),
                            const SizedBox(height: 24),

                            // Miembros
                            const _SectionTitle(title: 'Miembros'),
                            const SizedBox(height: 8),
                            _MiembrosList(miembros: miembros),
                            const SizedBox(height: 24),

                            // Diagramas
                            _SectionTitle(
                              title: 'Diagramas UML (${_diagramas.length})',
                            ),
                            const SizedBox(height: 8),
                            _cargandoDiagramas
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  )
                                : _diagramas.isEmpty
                                    ? const _DiagramasVacio()
                                    : _DiagramasList(
                                        diagramas: _diagramas,
                                        // push (no go): conserva la pila para
                                        // que el botón atrás vuelva al detalle
                                        // del proyecto y no cierre la app.
                                        onAbrir: (id) => context
                                            .push(AppRoutes.diagramaViewer(id)),
                                      ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

// ======================================================================
// Widgets auxiliares
// ======================================================================
class _InfoCard extends StatelessWidget {
  final Proyecto proyecto;
  final int miembros;

  const _InfoCard({required this.proyecto, required this.miembros});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: proyecto.estaActivo
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surface700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    proyecto.estado.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: proyecto.estaActivo
                          ? AppColors.success
                          : AppColors.surface300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (proyecto.descripcion != null &&
                proyecto.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                proyecto.descripcion!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.surface300,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('Miembros', '$miembros'),
                const SizedBox(width: 24),
                _stat(
                  'Creado',
                  '${proyecto.createdAt.day}/${proyecto.createdAt.month}/${proyecto.createdAt.year}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.surface500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MiembrosList extends StatelessWidget {
  final List<MiembroProyecto> miembros;

  const _MiembrosList({required this.miembros});

  @override
  Widget build(BuildContext context) {
    if (miembros.isEmpty) {
      return const Text(
        'Sin miembros cargados.',
        style: TextStyle(fontSize: 13, color: AppColors.surface500),
      );
    }

    return Column(
      children: miembros.map((m) {
        final nombre = m.nombreUsuario ?? 'Usuario ${m.idUsuario.substring(0, 6)}';
        final iniciales = nombre.trim().isEmpty
            ? '?'
            : nombre
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w[0])
                .join()
                .toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.colorPorId(m.idUsuario),
                child: Text(
                  iniciales,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (m.emailUsuario != null)
                      Text(
                        m.emailUsuario!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.surface500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: m.esPropietario
                      ? AppColors.brand600.withValues(alpha: 0.15)
                      : AppColors.surface800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m.rol.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: m.esPropietario
                        ? AppColors.brand300
                        : AppColors.surface400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DiagramasVacio extends StatelessWidget {
  const _DiagramasVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface800),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 40, color: AppColors.surface500),
          SizedBox(height: 8),
          Text(
            'No hay diagramas todavía',
            style: TextStyle(fontSize: 13, color: AppColors.surface400),
          ),
          SizedBox(height: 4),
          Text(
            'Se crean desde la web y aparecen acá automáticamente',
            style: TextStyle(fontSize: 11, color: AppColors.surface500),
          ),
        ],
      ),
    );
  }
}

class _DiagramasList extends StatelessWidget {
  final List<Diagrama> diagramas;
  final void Function(String id) onAbrir;

  const _DiagramasList({
    required this.diagramas,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: diagramas.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surface800),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brand600.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: AppColors.brand400,
                ),
              ),
              title: Text(
                d.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'UML ${d.versionUml} · v${d.numeroVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.surface500,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.surface500,
              ),
              onTap: () => onAbrir(d.id),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.surface300),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
