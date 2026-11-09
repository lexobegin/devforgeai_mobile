// lib/core/providers/core_providers.dart
//
// Providers base de la app informativa.
//
// Expone los singletons y las dependencias compartidas (ApiClient,
// TokenStorage, conectividad). Sin base de datos local ni WebSocket:
// la app móvil del Ciclo 2 es de solo lectura y online.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/connectivity_service.dart';

// ======================================================================
// ApiClient + TokenStorage
// ======================================================================
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage.instance;
});

// ======================================================================
// Conectividad
// ======================================================================
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Stream de cambios de conectividad (para que la UI reaccione).
final connectivityStreamProvider = StreamProvider<ConnectivityInfo>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.stream;
});

/// Estado actual de conexión (online / offline).
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.maybeWhen(
    data: (info) => info.isOnline,
    orElse: () => true, // Asumimos online hasta saber lo contrario
  );
});
