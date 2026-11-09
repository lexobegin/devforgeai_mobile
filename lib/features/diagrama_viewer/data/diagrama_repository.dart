// lib/features/diagrama_viewer/data/diagrama_repository.dart
//
// Repositorio del visor de diagramas (solo lectura).
//
// App informativa CU10/CU22: consulta directa al backend por REST.
// Sin cache local, sin cola de sincronización y sin WebSocket.

import '../../../core/network/api_client.dart';
import '../domain/diagrama_entity.dart';
import 'diagrama_remote_datasource.dart';

class DiagramaRepository {
  DiagramaRepository({required DiagramaRemoteDataSource remote})
      : _remote = remote;

  final DiagramaRemoteDataSource _remote;

  /// Lista los diagramas de un proyecto.
  Future<List<Diagrama>> listarPorProyecto(String proyectoId) {
    return _remote.listarPorProyecto(proyectoId);
  }

  /// Obtiene la metadata de un diagrama.
  Future<Diagrama> obtener(String diagramaId) {
    return _remote.obtener(diagramaId);
  }

  /// Obtiene el diagrama completo (clases + relaciones + interfaces).
  Future<DiagramaCompleto> obtenerCompleto(String diagramaId) async {
    try {
      return await _remote.obtenerCompleto(diagramaId);
    } on ApiException catch (e) {
      if (e.status == 0) {
        throw ApiException(
          status: 0,
          code: 'SIN_CONEXION',
          detail:
              'Sin conexión con el servidor. La app informativa requiere '
              'conectividad para mostrar el estado del proyecto.',
        );
      }
      rethrow;
    }
  }
}
