// lib/features/trazabilidad/data/trazabilidad_repository.dart
//
// Repositorio de trazabilidad (solo lectura).
//
// App informativa: consulta de historial, versiones y comentarios.
// La escritura se hace desde la web.

import '../domain/trazabilidad_entity.dart';
import 'trazabilidad_remote_datasource.dart';

class TrazabilidadRepository {
  TrazabilidadRepository(this._remote);

  final TrazabilidadRemoteDataSource _remote;

  // Historial
  Future<List<HistorialCambio>> listarHistorial(
    String diagramaId, {
    DateTime? desde,
    DateTime? hasta,
    int skip = 0,
    int limit = 100,
  }) =>
      _remote.listarHistorial(
        diagramaId,
        desde: desde,
        hasta: hasta,
        skip: skip,
        limit: limit,
      );

  // Versiones
  Future<List<VersionDiagramaResumen>> listarVersiones(
    String diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarVersiones(diagramaId, skip: skip, limit: limit);

  Future<VersionDiagrama> obtenerVersion(String versionId) =>
      _remote.obtenerVersion(versionId);

  Future<VersionDiagrama?> obtenerUltimaVersion(String diagramaId) =>
      _remote.obtenerUltimaVersion(diagramaId);

  // Comentarios
  Future<List<ComentarioDiagrama>> listarComentarios(
    String diagramaId, {
    bool soloNoResueltos = false,
    int skip = 0,
    int limit = 100,
  }) =>
      _remote.listarComentarios(
        diagramaId,
        soloNoResueltos: soloNoResueltos,
        skip: skip,
        limit: limit,
      );
}
