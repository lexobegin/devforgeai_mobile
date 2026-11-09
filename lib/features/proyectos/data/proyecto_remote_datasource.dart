// lib/features/proyectos/data/proyecto_remote_datasource.dart
//
// Datasource remoto de proyectos.
//
// App informativa (solo lectura): la creación, edición y gestión de
// miembros se hace desde la web. Solo consultas.

import '../../../core/network/api_client.dart';
import '../domain/proyecto_entity.dart';
import 'proyecto_model.dart';

class ProyectoRemoteDataSource {
  ProyectoRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Consultas
  // ==================================================================

  /// Lista los proyectos del usuario con paginación.
  Future<List<Proyecto>> listar({
    int skip = 0,
    int limit = 50,
    bool incluirArchivados = false,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/proyectos',
      query: {
        'skip': skip,
        'limit': limit,
        'incluir_archivados': incluirArchivados,
      },
    );

    final items = (json['items'] as List?) ?? [];
    return items
        .map((p) => ProyectoModel.fromJson((p as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Obtiene un proyecto con sus miembros.
  Future<ProyectoConMiembros> obtener(String id) async {
    final json = await _client.get<Map<String, dynamic>>('/proyectos/$id');
    return ProyectoConMiembrosModel.fromJson(json);
  }

  /// Lista los miembros de un proyecto.
  Future<List<MiembroProyecto>> listarMiembros(String proyectoId) async {
    final json = await _client.get<List<dynamic>>(
      '/proyectos/$proyectoId/miembros',
    );
    return json
        .map((m) =>
            MiembroProyectoModel.fromJson((m as Map).cast<String, dynamic>()))
        .toList();
  }
}
