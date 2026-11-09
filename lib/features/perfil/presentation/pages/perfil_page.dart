// lib/features/perfil/presentation/pages/perfil_page.dart
//
// Pantalla de perfil del usuario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  Future<void> _cambiarPassword(BuildContext context, WidgetRef ref) async {
    final passActual = TextEditingController();
    final passNueva = TextEditingController();
    final passConfirm = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passActual,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passNueva,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                hintText: 'Mínimo 8 caracteres',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passConfirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passNueva.text.length < 8) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('La nueva contraseña debe tener 8+ caracteres'),
                  ),
                );
                return;
              }
              if (passNueva.text != passConfirm.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(authProvider.notifier).cambiarPassword(
            passwordActual: passActual.text,
            passwordNueva: passNueva.text,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _acercaDe(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DevForge AI móvil'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compañera informativa de la plataforma web para el '
              'Ciclo 2: permite observar cómo va el proyecto.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              '• Consultar proyectos y miembros\n'
              '• Ver diagramas UML (solo lectura)\n'
              '• Recibir notificaciones\n'
              '• Revisar versiones y comentarios',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 10),
            Text(
              'La creación y edición se realizan desde la web.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Cerrar sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final iniciales = usuario.nombreCompleto.trim().isEmpty
        ? '?'
        : usuario.nombreCompleto
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.proyectos),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header con avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.colorPorId(usuario.id),
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.surface400,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: usuario.isAdmin
                        ? AppColors.brand600.withValues(alpha: 0.15)
                        : AppColors.surface800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    usuario.rol.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: usuario.isAdmin
                          ? AppColors.brand300
                          : AppColors.surface400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sección: cuenta
          const _SectionHeader(titulo: 'Cuenta'),
          _MenuItem(
            icon: Icons.lock_outline,
            label: 'Cambiar contraseña',
            onTap: () => _cambiarPassword(context, ref),
          ),
          _MenuItem(
            icon: Icons.calendar_today_outlined,
            label: 'Miembro desde',
            trailing: Text(
              '${usuario.createdAt.day}/${usuario.createdAt.month}/${usuario.createdAt.year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.surface400,
              ),
            ),
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.info_outline,
            label: 'Acerca de la app',
            onTap: () => _acercaDe(context),
          ),
          const SizedBox(height: 24),

          // Sección: sesión
          const _SectionHeader(titulo: 'Sesión'),
          _MenuItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            isDestructive: true,
            onTap: () => _logout(context, ref),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'DevForge AI · v${Env.appVersion}',
              style: TextStyle(fontSize: 11, color: AppColors.surface500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titulo;

  const _SectionHeader({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.surface500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.danger : AppColors.surface200;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: color),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.surface500,
          ),
      onTap: onTap,
      dense: true,
    );
  }
}