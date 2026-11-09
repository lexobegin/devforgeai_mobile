// test/widget_test.dart
//
// Pruebas de la app informativa (Ciclo 2) — Tanda M5.
//
// 1. La app arranca y construye su MaterialApp.router.
// 2. Las rutas se construyen bien (helpers de AppRoutes).
// 3. El modelo de Notificación parsea el contrato real del backend
//    (id String, id_usuario, leida, created_at, contador).
// 4. El enum TipoRelacion mantiene los 6 literales del contrato UML.
//
// Son pruebas sin red ni plugins nativos (secure storage solo se
// toca en bootstrap, que captura el fallo en entorno de test).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devforge_mobile/app.dart';
import 'package:devforge_mobile/core/router/app_routes.dart';
import 'package:devforge_mobile/features/diagrama_viewer/domain/relacion_uml_entity.dart';
import 'package:devforge_mobile/features/notificaciones/data/notificacion_model.dart';
import 'package:devforge_mobile/features/notificaciones/domain/notificacion_entity.dart';

void main() {
  testWidgets('DevForgeApp se construye correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DevForgeApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DevForgeApp), findsOneWidget);
  });

  group('AppRoutes (contrato Id=String)', () {
    test('construye la ruta del detalle de proyecto', () {
      expect(
        AppRoutes.proyectoDetalle('64b1f0a9c3e5d2a1b4c6d7e8'),
        '/proyectos/64b1f0a9c3e5d2a1b4c6d7e8',
      );
    });

    test('construye la ruta del visor de diagrama', () {
      expect(
        AppRoutes.diagramaViewer('64b1f0a9c3e5d2a1b4c6d7e8'),
        '/diagramas/64b1f0a9c3e5d2a1b4c6d7e8',
      );
    });

    test('construye la ruta de trazabilidad con y sin nombre (M5)', () {
      expect(
        AppRoutes.diagramaTrazabilidad('64b1f0a9'),
        '/diagramas/64b1f0a9/trazabilidad',
      );
      expect(
        AppRoutes.diagramaTrazabilidad('64b1f0a9',
            nombre: 'Sistema de Ventas'),
        '/diagramas/64b1f0a9/trazabilidad?nombre=Sistema%20de%20Ventas',
      );
    });
  });

  group('NotificacionModel (contrato CU15)', () {
    test('parsea una notificación del backend con ids String', () {
      final n = NotificacionModel.fromJson(const {
        'id': '64b1f0a9c3e5d2a1b4c6d7e8',
        'id_usuario': '64b1f0a9c3e5d2a1b4c6d7e9',
        'tipo': 'COMENTARIO',
        'mensaje': 'María comentó tu diagrama',
        'id_referencia': '64b1f0a9c3e5d2a1b4c6d7e0',
        'leida': false,
        'created_at': '2026-11-09T10:30:00Z',
      });

      expect(n.id, '64b1f0a9c3e5d2a1b4c6d7e8');
      expect(n.tipo, TipoNotificacion.comentario);
      expect(n.leida, isFalse);
      expect(n.mensaje, 'María comentó tu diagrama');
    });

    test('parsea el contador de no leídas', () {
      final c = NotificacionModel.contadorFromJson(
        const {'total_no_leidas': 4},
      );
      expect(c.total, 4);
      expect(c.tieneNuevas, isTrue);
    });

    test('tipo desconocido cae en SISTEMA (defensivo)', () {
      final n = NotificacionModel.fromJson(const {
        'id': '1',
        'id_usuario': '2',
        'tipo': 'TIPO_FUTURO',
        'mensaje': 'x',
        'leida': true,
        'created_at': '2026-11-09T10:30:00Z',
      });
      expect(n.tipo, TipoNotificacion.sistema);
    });
  });

  group('TipoRelacion (contrato UML 2.5.1)', () {
    test('mantiene los 6 literales del backend', () {
      expect(
        TipoRelacion.values.map((t) => t.value).toSet(),
        {'ASOCIACION', 'AGREGACION', 'COMPOSICION', 'DEPENDENCIA',
         'GENERALIZACION', 'REALIZACION'},
      );
      expect(TipoRelacion.values.length, 6);
    });
  });
}
