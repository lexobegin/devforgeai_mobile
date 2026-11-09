// lib/features/trazabilidad/data/trazabilidad_remote_datasource.dart
//
// Datasource remoto de trazabilidad.
//
// App informativa (solo lectura): el historial, las versiones y los
// comentarios se generan desde la web; aquí solo se consultan.

import '../../../core/network/api_client.dart';
import '../domain/trazabilidad_entity.dart';
import 'trazabilidad_model.dart';

class TrazabilidadRemoteDataSource {
  TrazabilidadRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Historial
  // ==================================================================
  Future<List<HistorialCambio>> listarHistorial(
    String diagramaId, {
    DateTime? desde,
    DateTime? hasta,
    int skip = 0,
    int limit = 100,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/historial',
      query: {
        if (desde != null) 'desde': desde.toIso8601String(),
        if (hasta != null) 'hasta': hasta.toIso8601String(),
        'skip': skip,
        'limit': limit,
      },
    );
    return json
        .map((h) => TrazabilidadModel.historialFromJson(
              (h as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // Versiones
  // ==================================================================
  Future<List<VersionDiagramaResumen>> listarVersiones(
    String diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/versiones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((v) => TrazabilidadModel.versionResumenFromJson(
              (v as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  Future<VersionDiagrama> obtenerVersion(String versionId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/trazabilidad/versiones/$versionId',
    );
    return TrazabilidadModel.versionFromJson(json);
  }

  Future<VersionDiagrama?> obtenerUltimaVersion(String diagramaId) async {
    final json = await _client.get<Map<String, dynamic>?>(
      '/trazabilidad/diagramas/$diagramaId/versiones/ultima',
    );
    if (json == null) return null;
    return TrazabilidadModel.versionFromJson(json);
  }

  // ==================================================================
  // Comentarios
  // ==================================================================
  Future<List<ComentarioDiagrama>> listarComentarios(
    String diagramaId, {
    bool soloNoResueltos = false,
    int skip = 0,
    int limit = 100,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/comentarios',
      query: {
        'solo_no_resueltos': soloNoResueltos,
        'skip': skip,
        'limit': limit,
      },
    );
    return json
        .map((c) => TrazabilidadModel.comentarioFromJson(
              (c as Map).cast<String, dynamic>(),
            ))
        .toList();
  }
}
