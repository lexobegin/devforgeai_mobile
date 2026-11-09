// lib/features/notificaciones/presentation/providers/notificaciones_provider.dart
//
// Provider de notificaciones (CU15) — Tanda M4.
//
// Mantiene la lista de notificaciones del usuario y el contador de no
// leídas. El sondeo es REST (sin WebSocket según D33):
//   · el contador se refresca cada 30 s (badge del AppBar de proyectos);
//   · la bandeja (página) refresca la lista en silencio con
//     `refrescarSilencioso()` desde su propio Timer de 30 s.
// El sondeo queda en PAUSA cuando no hay sesión activa (tras cerrar
// sesión no se siguen lanzando peticiones que terminan en 401).
// El push FCM sigue siendo la ampliación opcional del plan (M4).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show isAuthenticatedProvider;
import '../../data/notificacion_remote_datasource.dart';
import '../../data/notificacion_repository.dart';
import '../../domain/notificacion_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final notificacionRemoteDataSourceProvider =
    Provider<NotificacionRemoteDataSource>((ref) {
  return NotificacionRemoteDataSource(ref.watch(apiClientProvider));
});

final notificacionRepositoryProvider =
    Provider<NotificacionRepository>((ref) {
  return NotificacionRepository(
    ref.watch(notificacionRemoteDataSourceProvider),
  );
});

// ======================================================================
// Estado
// ======================================================================
@immutable
class NotificacionesState {
  final List<Notificacion> notificaciones;
  final int noLeidas;
  final bool isLoading;
  final ApiError? error;

  const NotificacionesState({
    this.notificaciones = const [],
    this.noLeidas = 0,
    this.isLoading = false,
    this.error,
  });

  NotificacionesState copyWith({
    List<Notificacion>? notificaciones,
    int? noLeidas,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return NotificacionesState(
      notificaciones: notificaciones ?? this.notificaciones,
      noLeidas: noLeidas ?? this.noLeidas,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get tieneNuevas => noLeidas > 0;
}

// ======================================================================
// Notifier
// ======================================================================
class NotificacionesNotifier extends StateNotifier<NotificacionesState> {
  /// `sesionActiva` evita que el sondeo siga llamando a la API cuando
  /// el usuario ya cerró sesión (se inyecta desde authProvider).
  NotificacionesNotifier(this._repo, {bool Function()? sesionActiva})
      : _sesionActiva = sesionActiva,
        super(const NotificacionesState()) {
    _iniciarPolling();
  }

  final NotificacionRepository _repo;
  final bool Function()? _sesionActiva;
  Timer? _pollTimer;

  bool get _haySesion => _sesionActiva?.call() ?? true;

  // ==================================================================
  // Polling del contador cada 30s (sondeo REST — D33, sin WebSocket)
  // ==================================================================
  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refrescarContador(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refrescarContador() async {
    if (!_haySesion) return; // sin sesión → no consultar
    try {
      final contador = await _repo.contador();
      if (mounted) {
        state = state.copyWith(noLeidas: contador.total);
      }
    } catch (_) {
      // Silencioso: el badge no debe molestar si la red falla.
    }
  }

  // ==================================================================
  // Cargar lista completa (con spinner)
  // ==================================================================
  Future<void> cargar({bool soloNoLeidas = false}) async {
    if (!_haySesion) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listar(soloNoLeidas: soloNoLeidas);
      final contador = await _repo.contador();
      state = NotificacionesState(
        notificaciones: items,
        noLeidas: contador.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
    }
  }

  // ==================================================================
  // Refresco silencioso (sondeo de la bandeja — Tanda M4)
  // ==================================================================
  /// Recarga lista + contador SIN spinner (el contenido no parpadea) y
  /// conserva la lista previa si la petición falla. Devuelve `true` si
  /// la lista cambió respecto a lo que se mostraba.
  Future<bool> refrescarSilencioso() async {
    if (!_haySesion) return false;
    try {
      final items = await _repo.listar();
      final contador = await _repo.contador();
      if (!mounted) return false;

      final previos = {for (final n in state.notificaciones) n.id: n};
      final cambio = items.length != state.notificaciones.length ||
          items.any((n) {
            final previa = previos[n.id];
            return previa == null ||
                previa.leida != n.leida ||
                previa.mensaje != n.mensaje;
          });

      state = state.copyWith(
        notificaciones: items,
        noLeidas: contador.total,
        clearError: true,
      );
      return cambio;
    } catch (_) {
      return false; // silencioso: se conserva lo que había
    }
  }

  // ==================================================================
  // Refrescar solo el contador (para badge)
  // ==================================================================
  Future<void> refrescarContador() => _refrescarContador();

  // ==================================================================
  // Marcar una como leída / no leída
  // ==================================================================
  Future<void> marcarLeida(String id) async {
    try {
      final actualizada = await _repo.marcarLeida(id);
      state = state.copyWith(
        notificaciones: state.notificaciones
            .map((n) => n.id == id ? actualizada : n)
            .toList(),
        noLeidas: (state.noLeidas - 1).clamp(0, 999999),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException
            ? ApiError(status: e.status, code: e.code, detail: e.detail)
            : ApiError.unknown(e.toString()),
      );
    }
  }

  Future<void> marcarNoLeida(String id) async {
    try {
      final actualizada = await _repo.marcarNoLeida(id);
      state = state.copyWith(
        notificaciones: state.notificaciones
            .map((n) => n.id == id ? actualizada : n)
            .toList(),
        noLeidas: state.noLeidas + 1,
        clearError: true,
      );
    } catch (_) {}
  }

  // ==================================================================
  // Marcar todas (devuelve cuántas se actualizaron — Tanda M4)
  // ==================================================================
  Future<int> marcarTodasLeidas() async {
    try {
      final actualizadas = await _repo.marcarVariasLeidas(todas: true);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.map((n) => n.copyWith(leida: true)).toList(),
        noLeidas: 0,
        clearError: true,
      );
      return actualizadas;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException
            ? ApiError(status: e.status, code: e.code, detail: e.detail)
            : ApiError.unknown(e.toString()),
      );
      return 0;
    }
  }

  // ==================================================================
  // Eliminar una
  // ==================================================================
  Future<void> eliminar(String id) async {
    // Búsqueda segura (antes lanzaba StateError si no existía).
    Notificacion? notif;
    for (final n in state.notificaciones) {
      if (n.id == id) {
        notif = n;
        break;
      }
    }

    try {
      await _repo.eliminar(id);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => n.id != id).toList(),
        noLeidas: (notif != null && !notif.leida)
            ? (state.noLeidas - 1).clamp(0, 999999)
            : state.noLeidas,
        clearError: true,
      );
    } catch (_) {}
  }

  // ==================================================================
  // Limpiar leídas
  // ==================================================================
  Future<int> limpiarLeidas() async {
    try {
      final eliminadas = await _repo.limpiarLeidas();
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => !n.leida).toList(),
        clearError: true,
      );
      return eliminadas;
    } catch (_) {
      return 0;
    }
  }
}

// ======================================================================
// Provider principal
// ======================================================================
final notificacionesProvider =
    StateNotifierProvider<NotificacionesNotifier, NotificacionesState>((ref) {
  return NotificacionesNotifier(
    ref.watch(notificacionRepositoryProvider),
    // El sondeo se detiene en cuanto la sesión termina (logout).
    sesionActiva: () => ref.read(isAuthenticatedProvider),
  );
});

// ======================================================================
// Selector del badge (solo contador)
// ======================================================================
final noLeidasCountProvider = Provider<int>((ref) {
  return ref.watch(notificacionesProvider).noLeidas;
});
