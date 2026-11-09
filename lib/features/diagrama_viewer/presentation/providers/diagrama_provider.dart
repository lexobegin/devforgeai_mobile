// lib/features/diagrama_viewer/presentation/providers/diagrama_provider.dart
//
// Provider del visor de diagramas (solo lectura — CU10/CU22).
//
// Mantiene el diagrama cargado (metadata + clases + relaciones +
// interfaces) y la selección actual (solo para resaltar en el lienzo).
// No hay edición, ni cola de sincronización, ni WebSocket: la
// observación es por REST — carga manual (botón/pull en los paneles)
// y sondeo silencioso `refrescar()` que usa la página del visor
// (Tanda M3, según D33).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/diagrama_remote_datasource.dart';
import '../../data/diagrama_repository.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/diagrama_entity.dart';
import '../../domain/relacion_uml_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final diagramaRemoteDataSourceProvider =
    Provider<DiagramaRemoteDataSource>((ref) {
  return DiagramaRemoteDataSource(ref.watch(apiClientProvider));
});

final diagramaRepositoryProvider = Provider<DiagramaRepository>((ref) {
  return DiagramaRepository(
    remote: ref.watch(diagramaRemoteDataSourceProvider),
  );
});

// ======================================================================
// Selección (solo resaltado visual)
// ======================================================================
@immutable
class ElementoSeleccionado {
  final String tipo; // 'clase' | 'interfaz' | 'relacion'
  final String id;

  const ElementoSeleccionado({required this.tipo, required this.id});

  const ElementoSeleccionado.clase(String id) : this(tipo: 'clase', id: id);
  const ElementoSeleccionado.interfaz(String id)
      : this(tipo: 'interfaz', id: id);
  const ElementoSeleccionado.relacion(String id)
      : this(tipo: 'relacion', id: id);

  bool get esClase => tipo == 'clase';
  bool get esInterfaz => tipo == 'interfaz';
  bool get esRelacion => tipo == 'relacion';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ElementoSeleccionado &&
        other.tipo == tipo &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(tipo, id);
}

// ======================================================================
// Estado
// ======================================================================
@immutable
class DiagramaState {
  final Diagrama? diagrama;
  final List<ClaseUml> clases;
  final List<RelacionUml> relaciones;
  final List<InterfazUml> interfaces;

  final ElementoSeleccionado? seleccion;

  final bool isLoading;
  final ApiError? error;

  const DiagramaState({
    this.diagrama,
    this.clases = const [],
    this.relaciones = const [],
    this.interfaces = const [],
    this.seleccion,
    this.isLoading = false,
    this.error,
  });

  DiagramaState copyWith({
    Diagrama? diagrama,
    List<ClaseUml>? clases,
    List<RelacionUml>? relaciones,
    List<InterfazUml>? interfaces,
    ElementoSeleccionado? seleccion,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
    bool clearSeleccion = false,
  }) {
    return DiagramaState(
      diagrama: diagrama ?? this.diagrama,
      clases: clases ?? this.clases,
      relaciones: relaciones ?? this.relaciones,
      interfaces: interfaces ?? this.interfaces,
      seleccion: clearSeleccion ? null : (seleccion ?? this.seleccion),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ==================================================================
  // Getters derivados
  // ==================================================================
  ClaseUml? clasePorId(String id) {
    for (final c in clases) {
      if (c.id == id) return c;
    }
    return null;
  }
}

// ======================================================================
// Notifier (solo lectura)
// ======================================================================
class DiagramaNotifier extends StateNotifier<DiagramaState> {
  DiagramaNotifier(this._repo) : super(const DiagramaState());

  final DiagramaRepository _repo;

  /// Id del diagrama cargado (para el sondeo silencioso del visor).
  String? _diagramaIdActual;

  // ==================================================================
  // Cargar / refrescar
  // ==================================================================
  Future<void> cargar(String diagramaId) async {
    _diagramaIdActual = diagramaId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final completo = await _repo.obtenerCompleto(diagramaId);
      state = DiagramaState(
        diagrama: completo.diagrama,
        clases: completo.clases,
        relaciones: completo.relaciones,
        interfaces: completo.interfaces,
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

  /// Refresco SILENCIOSO para el sondeo de observación (CU22 — D33):
  /// trae el diagrama completo de nuevo y sustituye el estado sin pasar
  /// por `isLoading`, para que el lienzo no parpadee cada ciclo.
  ///
  /// - Si el elemento resaltado ya no existe (lo borraron en la web),
  ///   se limpia la selección.
  /// - Si la petición falla, se conserva el contenido actual: un sondeo
  ///   fallido no debe romper la observación (el refresh manual sí
  ///   reporta el error).
  ///
  /// Devuelve true si el contenido cambió respecto al estado previo
  /// (la página lo usa para avisar "el diseño se actualizó").
  Future<bool> refrescar() async {
    final id = _diagramaIdActual;
    if (id == null || state.isLoading) return false;

    final previo = state;
    try {
      final completo = await _repo.obtenerCompleto(id);
      final sel = state.seleccion;
      final selViva = sel == null || _existeElemento(completo, sel);

      state = DiagramaState(
        diagrama: completo.diagrama,
        clases: completo.clases,
        relaciones: completo.relaciones,
        interfaces: completo.interfaces,
        seleccion: selViva ? sel : null,
      );

      return previo.diagrama?.updatedAt != completo.diagrama.updatedAt ||
          previo.clases.length != completo.clases.length ||
          previo.relaciones.length != completo.relaciones.length ||
          previo.interfaces.length != completo.interfaces.length;
    } on ApiException {
      return false; // silencioso: se mantiene el contenido previo
    } catch (_) {
      return false;
    }
  }

  /// ¿El elemento seleccionado sigue existiendo en el contenido nuevo?
  bool _existeElemento(DiagramaCompleto completo, ElementoSeleccionado sel) {
    switch (sel.tipo) {
      case 'clase':
        return completo.clases.any((c) => c.id == sel.id);
      case 'interfaz':
        return completo.interfaces.any((i) => i.id == sel.id);
      case 'relacion':
        return completo.relaciones.any((r) => r.id == sel.id);
      default:
        return false;
    }
  }

  void limpiar() {
    _diagramaIdActual = null;
    state = const DiagramaState();
  }

  // ==================================================================
  // Selección (resaltado)
  // ==================================================================
  void seleccionar(ElementoSeleccionado? elemento) {
    state = elemento == null
        ? state.copyWith(clearSeleccion: true)
        : state.copyWith(seleccion: elemento);
  }

  void limpiarError() => state = state.copyWith(clearError: true);
}

// ======================================================================
// Provider principal
// ======================================================================
final diagramaProvider =
    StateNotifierProvider<DiagramaNotifier, DiagramaState>((ref) {
  return DiagramaNotifier(ref.watch(diagramaRepositoryProvider));
});

// ======================================================================
// Selectores útiles
// ======================================================================
final clasesProvider = Provider<List<ClaseUml>>((ref) {
  return ref.watch(diagramaProvider).clases;
});

final relacionesProvider = Provider<List<RelacionUml>>((ref) {
  return ref.watch(diagramaProvider).relaciones;
});

final interfacesProvider = Provider<List<InterfazUml>>((ref) {
  return ref.watch(diagramaProvider).interfaces;
});
