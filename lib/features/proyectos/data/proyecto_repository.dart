// lib/features/proyectos/data/proyecto_repository.dart
//
// Repositorio de proyectos (solo lectura para la app informativa).
//
// Delega en el datasource remoto. La creación, edición y gestión de
// miembros se hace desde la web.

import '../domain/proyecto_entity.dart';
import 'proyecto_remote_datasource.dart';

class ProyectoRepository {
  ProyectoRepository(this._remote);

  final ProyectoRemoteDataSource _remote;

  /// Lista los proyectos del usuario con paginación.
  Future<List<Proyecto>> listar({
    int skip = 0,
    int limit = 50,
    bool incluirArchivados = false,
  }) {
    return _remote.listar(
      skip: skip,
      limit: limit,
      incluirArchivados: incluirArchivados,
    );
  }

  /// Obtiene un proyecto con sus miembros.
  Future<ProyectoConMiembros> obtener(String id) {
    return _remote.obtener(id);
  }

  /// Lista los miembros de un proyecto.
  Future<List<MiembroProyecto>> listarMiembros(String proyectoId) {
    return _remote.listarMiembros(proyectoId);
  }
}
