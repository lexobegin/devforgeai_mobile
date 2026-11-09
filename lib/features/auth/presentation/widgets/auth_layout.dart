// lib/features/auth/presentation/widgets/auth_layout.dart
//
// Layout compartido por Login y Registro.
// Card centrada con logo + contenido + footer.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Logo(),
                const SizedBox(height: 24),
                Text(
                  'DevForge AI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plataforma CASE colaborativa con IA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.surface400,
                      ),
                ),
                const SizedBox(height: 32),

                // Card con el formulario
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.surface400),
                        ),
                      ],
                      const SizedBox(height: 20),
                      child,
                    ],
                  ),
                ),

                if (footer != null) ...[
                  const SizedBox(height: 24),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand500, AppColors.brand700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'DF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}