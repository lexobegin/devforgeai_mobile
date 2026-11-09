# devforge_mobile — App informativa de DevForge AI (Ciclo 2)

App móvil Flutter **de solo lectura** para "ver cómo va el proyecto":
el equipo edita los diseños en la web y desde el móvil se consulta el
estado, el avance y la actividad. **No se edita desde el móvil.**

| CU | Nombre | En la app |
|----|--------|-----------|
| CU10 | Consultar diagrama desde el móvil | Visor UML solo lectura (`GET /diagramas/{id}/completo`) |
| CU15 | Gestión de notificaciones | Bandeja por sondeo REST (30 s), marcado de leídas, estados vacíos |
| CU22 | Observar Diseño en Móvil | Observación por REST: sondeo silencioso + trazabilidad del diseño |

Fuera de alcance en móvil (vive en la web): edición colaborativa,
offline-first/sincronización, generación de código, IA (Agente Dev,
visión, voz) e intercambio XMI.

**Regla de oro del Ciclo 2:** si es una *acción* (crear, editar,
generar, importar, sincronizar) → está en la web. Si es *consulta*
(ver, listar, historial, notificaciones) → está en la app.

---

## 1. Requisitos y arranque

```bash
# Requisitos: Flutter SDK >= 3.5 (channel stable), Android SDK o iOS
flutter pub get

# Apuntar al backend (por defecto: https://api-devforgeai.duckdns.org/api/v1)
# Emulador Android (backend local):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Dispositivo físico (misma red Wi-Fi):
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api/v1

# Producción (es el valor por defecto de env.dart):
flutter run
```

Variables disponibles con `--dart-define` (ver `.env.example` y
`lib/core/config/env.dart`): `API_BASE_URL`, `APP_ENV`,
`API_TIMEOUT_MS`, `APP_VERSION`.

### Verificación y pruebas

```bash
flutter analyze          # 0 errores esperados
flutter test             # widget_test.dart: arranque, rutas y contratos
python3 scripts/verifica_tandaM5.py   # verificación estática de la tanda
```

---

## 2. Qué puede hacer el usuario en la app

1. **Login / Registro** (`/login`, `/register`) — token JWT en
   `flutter_secure_storage`.
2. **Proyectos** (`/proyectos`) — lista y detalle informativos: estado,
   miembros, nº de diagramas y avance. Con badge de notificaciones no
   leídas en el AppBar.
3. **Visor de diagramas** (`/diagramas/:id`) — lienzo UML 2.5.1 de
   solo lectura (clases, interfaces y relaciones con sus estilos,
   flechas y etiquetas), zoom/pan, versiones y actividad reciente.
   Sondeo de observación cada 30 s (pausable) que avisa cuando el
   diseño cambió en la web.
4. **Trazabilidad** (`/diagramas/:id/trazabilidad`) — historial de
   cambios, versiones guardadas y comentarios del equipo (todo lectura).
5. **Notificaciones** (`/notificaciones`) — bandeja por sondeo REST
   cada 30 s, pull-to-refresh, marcar leídas/una/todas, eliminar,
   limpiar leídas, filtro "solo no leídas".
6. **Perfil** (`/perfil`) — datos del usuario y cerrar sesión.

---

## 3. Decisiones de arquitectura del Ciclo 2

- **D33 — Sin WebSocket en móvil:** la observación (CU22) es
  **REST + aviso push**. El push FCM quedó como **ampliación opcional**
  (requiere Firebase); sin él la app funciona al 100 % por sondeo.
- **Contrato Id=String:** todos los ids son `String` (ObjectId de
  MongoDB serializado). Cero `int.tryParse` de ids.
- **TipoRelacion con 6 literales:** `ASOCIACION`, `AGREGACION`,
  `COMPOSICION`, `DEPENDENCIA`, `GENERALIZACION`, `REALIZACION`.
- **Estado:** Riverpod (`StateNotifier` + `FutureProvider.family`).
- **Capas por feature:** `data/` (datasource REST + model + repository)
  → `domain/` (entidades inmutables) → `presentation/` (pages,
  providers, widgets).
- **Sondeos:** contador de notificaciones y observación del diagrama
  cada 30 s; el sondeo falla en silencio y conserva el contenido
  previo (la pantalla nunca parpadea ni se vacía por un error de red).

---

## 4. Estructura del proyecto

```
lib/
├── main.dart                  # bootstrap de Riverpod + AuthNotifier
├── app.dart                   # MaterialApp.router (tema, locales es_BO)
├── core/
│   ├── config/env.dart        # --dart-define
│   ├── models/api_error.dart  # error de API tipado
│   ├── network/api_client.dart        # Dio + interceptor de token
│   ├── network/connectivity_service.dart  # banner "sin conexión"
│   ├── providers/core_providers.dart
│   ├── router/app_router.dart # go_router + guarda de sesión
│   ├── router/app_routes.dart # paths y helpers
│   └── theme/                 # paleta y tema (claro/oscuro)
└── features/
    ├── auth/                  # login, registro, bootstrap de sesión
    ├── proyectos/             # lista + detalle informativos
    ├── diagrama_viewer/       # visor CU10/CU22 (ex diagrama_editor)
    ├── notificaciones/        # bandeja CU15 por sondeo
    ├── trazabilidad/          # historial/versiones/comentarios (M5)
    └── perfil/                # perfil + logout
test/widget_test.dart          # arranque + contratos
scripts/verifica_tandaM*.py    # verificación estática por tanda
```

`estructura.txt` tiene el árbol completo; `worklog.md` el registro de
las tandas M1–M5 (qué se quitó, qué se arregló y cómo se verificó).

---

## 5. Tandas del Ciclo 2

| Tanda | Contenido | Estado |
|-------|-----------|--------|
| M1 | Limpieza estructural (53 archivos fuera), pubspec limpio, núcleo informativo, contrato Id=String | ✅ |
| M2 | Proyectos y perfil informativos + lienzo del visor corregido | ✅ |
| M3 | Visor CU10/CU22: renombrado a `diagrama_viewer`, interfaces visibles en el lienzo, sondeo 30 s, actividad reciente | ✅ |
| M4 | Notificaciones CU15: guard de sesión del sondeo, refresco silencioso, estados vacío/error, tarjetas por tipo | ✅ |
| M5 | Trazabilidad informativa (historial/versiones/comentarios) + README, estructura.txt, widget_test, zip final | ✅ |

Nota del defecto que motivó el lienzo de M2/M3 (registrado en
`worklog.md`): *"en la version del ciclo1 (1er parcial) no se vizualizaba
bien los diagramas sobre todo las relaciones en el lienzo"* — se
reescribieron `relationship_painter` y `diagram_canvas`
con anclaje por bordes, medidas reales de nodos y render de
interfaces.

---

## 6. Backend esperado

La app consume la API REST del backend FastAPI (Ciclo 2):

- `POST /auth/login` · `POST /auth/register` · `GET /auth/me`
- `GET /proyectos` · `GET /proyectos/{id}`
- `GET /diagramas/proyecto/{id}` · `GET /diagramas/{id}` ·
  `GET /diagramas/{id}/completo`
- `GET /notificaciones` · `GET /notificaciones/contador` ·
  `POST /notificaciones/marcar-leidas` · `POST /notificaciones/{id}/leer` ·
  `POST /notificaciones/{id}/no-leer` · `DELETE /notificaciones/{id}` ·
  `DELETE /notificaciones/leidas`
- `GET /trazabilidad/diagramas/{id}/historial` ·
  `GET /trazabilidad/diagramas/{id}/versiones` ·
  `GET /trazabilidad/versiones/{id}` ·
  `GET /trazabilidad/diagramas/{id}/comentarios`
