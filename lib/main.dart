// lib/main.dart
//
// Punto de entrada de la app móvil informativa de DevForge AI.
//
// - Inicializa los bindings de Flutter.
// - Configura el ProviderScope de Riverpod (estado global).
// - Configura la orientación (solo vertical por defecto).
// - Monta el widget raíz `DevForgeApp`.
//
// Ciclo 2: sin base de datos local, sin cola de sincronización y sin
// WebSocket — la app observa el proyecto por REST (CU10/CU15/CU22).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  // Asegura que los plugins nativos estén inicializados antes de usar
  // cualquier API de plataforma (secure storage, conectividad, etc).
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear la orientación a vertical (para simplificar el diseño).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado en modo oscuro para integrarse con el tema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: DevForgeApp(),
    ),
  );
}
