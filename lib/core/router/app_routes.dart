// lib/core/router/app_routes.dart
//
// Constantes de rutas de la app informativa.
//
// Centraliza todos los paths para evitar strings repetidos y facilitar
// refactors. Los ids viajan como String (ObjectId de MongoDB).

class AppRoutes {
  const AppRoutes._();

  // ==================================================================
  // Públicas
  // ==================================================================
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ==================================================================
  // Protegidas
  // ==================================================================
  static const String proyectos = '/proyectos';
  static const String notificaciones = '/notificaciones';
  static const String perfil = '/perfil';

  // ==================================================================
  // Con parámetros — usar los helpers para construirlas
  // ==================================================================
  static const String proyectoDetallePattern = '/proyectos/:proyectoId';
  static const String diagramaViewerPattern = '/diagramas/:diagramaId';
  static const String diagramaTrazabilidadPattern =
      '/diagramas/:diagramaId/trazabilidad';

  static String proyectoDetalle(String proyectoId) =>
      '/proyectos/$proyectoId';
  static String diagramaViewer(String diagramaId) => '/diagramas/$diagramaId';

  /// Trazabilidad del diagrama (solo lectura — Tanda M5).
  /// El nombre viaja como query para el título de la página.
  static String diagramaTrazabilidad(String diagramaId, {String? nombre}) {
    final base = '/diagramas/$diagramaId/trazabilidad';
    if (nombre == null || nombre.isEmpty) return base;
    return '$base?nombre=${Uri.encodeComponent(nombre)}';
  }
}
