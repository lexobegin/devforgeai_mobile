// lib/features/proyectos/presentation/providers/proyecto_detalle_provider.dart
//
// Provider del proyecto activo (detalle) — solo lectura.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../data/proyecto_repository.dart';
import '../../domain/proyecto_entity.dart';
import 'proyectos_provider.dart';

// ======================================================================
// Estado del detalle
// ======================================================================
@immutable
class ProyectoDetalleState {
  final ProyectoConMiembros? proyecto;
  final bool isLoading;
  final ApiError? error;

  const ProyectoDetalleState({
    this.proyecto,
    this.isLoading = false,
    this.error,
  });

  ProyectoDetalleState copyWith({
    ProyectoConMiembros? proyecto,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
    bool clearProyecto = false,
  }) {
    return ProyectoDetalleState(
      proyecto: clearProyecto ? null : (proyecto ?? this.proyecto),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ======================================================================
// Notifier
// ======================================================================
class ProyectoDetalleNotifier extends StateNotifier<ProyectoDetalleState> {
  ProyectoDetalleNotifier(this._repo)
      : super(const ProyectoDetalleState());

  final ProyectoRepository _repo;

  /// Carga (o recarga) el proyecto con sus miembros.
  Future<void> cargar(String proyectoId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final proyecto = await _repo.obtener(proyectoId);
      state = ProyectoDetalleState(proyecto: proyecto);
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

  void limpiar() => state = const ProyectoDetalleState();
  void limpiarError() => state = state.copyWith(clearError: true);
}

// ======================================================================
// Provider principal
// ======================================================================
final proyectoDetalleProvider = StateNotifierProvider<
    ProyectoDetalleNotifier, ProyectoDetalleState>((ref) {
  return ProyectoDetalleNotifier(
    ref.watch(proyectoRepositoryProvider),
  );
});
