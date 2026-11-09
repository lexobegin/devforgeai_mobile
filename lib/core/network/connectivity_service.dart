// lib/core/network/connectivity_service.dart
//
// Servicio de conectividad.
//
// - Expone un Stream<ConnectivityStatus> con cambios de conexión.
// - Distingue entre "conectado", "sin conexión" y "conexión débil".
// - Detecta el tipo de conexión (WiFi, móvil, ethernet).
//
// La app lo usa para:
//   - Activar/desactivar el modo offline.
//   - Disparar la sincronización cuando se recupera conexión.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de conectividad simplificado.
enum ConnectivityStatus {
  online,
  offline,
}

/// Info detallada de la conexión actual.
class ConnectivityInfo {
  final ConnectivityStatus status;
  final List<ConnectivityResult> tipos;
  final DateTime? lastChange;

  const ConnectivityInfo({
    required this.status,
    required this.tipos,
    this.lastChange,
  });

  bool get isOnline => status == ConnectivityStatus.online;

  bool get isWifi => tipos.contains(ConnectivityResult.wifi);
  bool get isMobile => tipos.contains(ConnectivityResult.mobile);
  bool get isEthernet => tipos.contains(ConnectivityResult.ethernet);
}

/// Servicio singleton.
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityInfo>.broadcast();

  ConnectivityInfo _current = const ConnectivityInfo(
    status: ConnectivityStatus.online,
    tipos: [ConnectivityResult.none],
  );

  StreamSubscription? _subscription;

  // ==================================================================
  // API pública
  // ==================================================================
  /// Estado actual.
  ConnectivityInfo get current => _current;

  /// Stream de cambios de conectividad.
  Stream<ConnectivityInfo> get stream => _controller.stream;

  /// Verifica el estado actual de forma explícita.
  Future<ConnectivityInfo> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _update(results);
    return _current;
  }

  // ==================================================================
  // Internos
  // ==================================================================
  Future<void> _init() async {
    // Estado inicial
    try {
      final results = await _connectivity.checkConnectivity();
      _update(results);
    } catch (_) {
      // Ignorar error de inicialización
    }

    // Suscribirse a cambios
    _subscription = _connectivity.onConnectivityChanged.listen(
      _update,
      onError: (_) {},
    );
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    _current = ConnectivityInfo(
      status: online ? ConnectivityStatus.online : ConnectivityStatus.offline,
      tipos: results,
      lastChange: DateTime.now(),
    );

    if (!_controller.isClosed) {
      _controller.add(_current);
    }
  }

  /// Limpieza (llamar desde el dispose de un Provider si aplica).
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}