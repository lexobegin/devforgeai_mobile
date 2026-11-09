// lib/features/diagrama_viewer/data/diagrama_remote_datasource.dart
//
// Datasource remoto del visor de diagramas (solo lectura).
//
// App informativa CU10/CU22: carga el diagrama completo para observarlo.
// Toda operación de escritura vive en la web.

import '../../../core/network/api_client.dart';
import '../domain/diagrama_entity.dart';
import 'diagrama_model.dart';

class DiagramaRemoteDataSource {
  DiagramaRemoteDataSource(this._client);

  final ApiClient _client;

  /// Lista los diagramas de un proyecto.
  Future<List<Diagrama>> listarPorProyecto(String proyectoId) async {
    final json = await _client.get<List<dynamic>>(
      '/diagramas/proyecto/$proyectoId',
    );
    return json
        .map((d) => DiagramaModel.fromJson((d as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Obtiene la metadata de un diagrama.
  Future<Diagrama> obtener(String diagramaId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/diagramas/$diagramaId',
    );
    return DiagramaModel.fromJson(json);
  }

  /// Obtiene el diagrama completo (clases + relaciones + interfaces).
  /// Este es el payload que consume el visor.
  Future<DiagramaCompleto> obtenerCompleto(String diagramaId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/diagramas/$diagramaId/completo',
    );
    return DiagramaModel.completoFromJson(json);
  }
}
