// lib/features/trazabilidad/presentation/providers/trazabilidad_provider.dart
//
// Providers de trazabilidad (solo lectura): versiones, detalle e
// historial/comentarios de consulta.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/trazabilidad_remote_datasource.dart';
import '../../data/trazabilidad_repository.dart';
import '../../domain/trazabilidad_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final trazabilidadRemoteDataSourceProvider =
    Provider<TrazabilidadRemoteDataSource>((ref) {
  return TrazabilidadRemoteDataSource(ref.watch(apiClientProvider));
});

final trazabilidadRepositoryProvider =
    Provider<TrazabilidadRepository>((ref) {
  return TrazabilidadRepository(
    ref.watch(trazabilidadRemoteDataSourceProvider),
  );
});

// ======================================================================
// Versiones (solo lectura — historial del diagrama)
// ======================================================================
final versionesProvider = FutureProvider.family<
    List<VersionDiagramaResumen>, String>((ref, diagramaId) async {
  final repo = ref.watch(trazabilidadRepositoryProvider);
  return repo.listarVersiones(diagramaId);
});

final versionDetalleProvider =
    FutureProvider.family<VersionDiagrama, String>((ref, versionId) async {
  final repo = ref.watch(trazabilidadRepositoryProvider);
  return repo.obtenerVersion(versionId);
});

// ======================================================================
// Actividad reciente (solo lectura — Tanda M3, según D33/CU22)
// ======================================================================
// Feed de cambios del diagrama que el equipo hizo en la web
// (GET /trazabilidad/diagramas/{id}/historial). El visor lo muestra
// como "cómo va el diseño"; refrescar con ref.invalidate(...).
final historialProvider = FutureProvider.family<
    List<HistorialCambio>, String>((ref, diagramaId) async {
  final repo = ref.watch(trazabilidadRepositoryProvider);
  return repo.listarHistorial(diagramaId);
});

// ======================================================================
// Comentarios (solo lectura — actividad del diagrama)
// ======================================================================
@immutable
class ComentariosState {
  final List<ComentarioDiagrama> comentarios;
  final bool isLoading;
  final ApiError? error;

  const ComentariosState({
    this.comentarios = const [],
    this.isLoading = false,
    this.error,
  });

  ComentariosState copyWith({
    List<ComentarioDiagrama>? comentarios,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return ComentariosState(
      comentarios: comentarios ?? this.comentarios,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ComentariosNotifier extends StateNotifier<ComentariosState> {
  ComentariosNotifier(this._repo, this._diagramaId)
      : super(const ComentariosState());

  final TrazabilidadRepository _repo;
  final String _diagramaId;

  Future<void> cargar({bool soloNoResueltos = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listarComentarios(
        _diagramaId,
        soloNoResueltos: soloNoResueltos,
      );
      state = ComentariosState(comentarios: items);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    }
  }
}

final comentariosProvider = StateNotifierProvider.family<ComentariosNotifier,
    ComentariosState, String>((ref, diagramaId) {
  return ComentariosNotifier(
    ref.watch(trazabilidadRepositoryProvider),
    diagramaId,
  );
});
