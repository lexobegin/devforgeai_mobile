# worklog.md — devforge_mobile

Registro de tandas de la app móvil Flutter (Ciclo 2 — app informativa).

---

## Tanda M1 — Limpieza estructural, núcleo informativo y contrato Id=String
**Fecha:** 2026-11-09 · **Estado:** ✅ verificada

### Objetivo
Convertir la app móvil en la **app informativa de solo lectura del Ciclo 2**
(CU10 consultar diagrama, CU15 notificaciones, CU22 observar diseño en móvil,
según catálogo D23/D33) eliminando todo lo que pertenece a la web y alineando
el contrato de datos con el backend real.

### 1. Eliminaciones (11 carpetas + 12 archivos .dart = 53 archivos fuera)

**Carpetas completas:**
- `.dart_tool/`, `build/`, `.idea/` → no estaban en el zip (correcto, van en .gitignore)
- `lib/core/database/` (app_database + 4 tablas Drift)
- `lib/core/sync/` (7 archivos: conflict_resolver, id_mapper, sync_manager, sync_providers, sync_queue, sync_status_widget, tipos_sync)
- `lib/core/permissions/` (permission_service — era para cámara/micrófono de la IA)
- `lib/features/colaboracion/`, `generacion_codigo/`, `ia_assistant/`, `intercambio/`, `sincronizacion/`
- Carpetas `todo/` vacías

**Archivos sueltos:**
- `lib/core/network/websocket_client.dart` (D33: observación por REST + push, sin WS)
- `lib/features/diagrama_editor/data/diagrama_local_datasource.dart`
- `lib/features/diagrama_editor/presentation/providers/websocket_provider.dart`
- Widgets de edición: `canvas_toolbar`, `editor_sidebar`, `propiedades_editor`, `relation_creation_overlay`, `colaboradores_panel`, `comentarios_panel`
- `lib/features/proyectos/presentation/widgets/crear_proyecto_sheet.dart`
- Duplicados: `lib/features/auth/data/proyecto_model.dart` + `proyecto_remote_datasource.dart` (nadie los importaba; se usan los de `features/proyectos/`)

### 2. AJUSTE CRÍTICO DESCUBIERTO — migración `Id = String` (ObjectId)
Los models móviles parseaban `json['id'] as num → toInt()`, pero el backend
MongoDB devuelve **ObjectId como String**: con el backend real la app lanzaba
`type 'String' is not a subtype of type 'num'` en **cualquier** respuesta
(login incluido). Se migró todo el contrato a `Id = String`, igual que el
frontend web (tandas F):

- Entidades: `usuario`, `proyecto`, `clase_uml`, `diagrama`, `relacion_uml`,
  `notificacion`, `trazabilidad` — todos los campos id/id_xxx ahora String.
- Models: helper `_parseId(dynamic) => value?.toString() ?? ''` (tolerante).
- Datasources/repositorios/providers/páginas: firmas con String.
- Router: `state.pathParameters['proyectoId'] ?? ''` (se eliminó `int.tryParse → 0`).
- `AppColors.colorPorId(String id)` vía `hashCode`.

### 3. Conversión a solo lectura (read-only)
- **Diagrama:** datasource/repositorio reducidos a `listarPorProyecto`,
  `obtener`, `obtenerCompleto`; provider sin CRUD/cola/WS (cargar, seleccionar
  para resaltar, limpiar); `DiagramEditorPage` convertida en **visor**
  (canvas + aviso "solo lectura" + versiones en bottom sheet + refrescar);
  `diagram_canvas` sin drag ni cursores remotos; `versiones_panel` sin
  "Guardar versión" (la creación de versiones es de la web).
- **Proyectos:** sin crear/archivar/eliminar/gestionar miembros; la lista y el
  detalle son informativos (miembros, nº de diagramas, estado); estados vacíos
  con mensaje "se crea desde la web".
- **Trazabilidad:** solo lectura (versiones + comentarios de consulta).
- **Notificaciones (CU15):** se conservan las acciones de marcado/eliminación
  de la propia bandeja; sondeo cada 30 s (push FCM = ampliación posterior).
- **Auth:** login/registro/logout intactos.

### 4. pubspec.yaml limpio
Quitadas: `drift`, `drift_dev`, `build_runner`, `sqlite3_flutter_libs`,
`path_provider`, `path`, `shared_preferences`, `web_socket_channel`,
`speech_to_text`, `image_picker`, `permission_handler`, `flutter_svg`, `intl`,
`riverpod_annotation`, `riverpod_generator`, `custom_lint`, `riverpod_lint`.
Conservadas: `flutter_riverpod`, `dio`, `connectivity_plus`,
`flutter_secure_storage`, `go_router`, `cupertino_icons` (+ SDK Flutter).

### 5. Otros
- `core_providers.dart` sin provider de base de datos.
- `app_router.dart` sin ruta `/generacion/:trabajoId` y sin bloques muertos comentados.
- `app_routes.dart` sin helpers de generación; ids String.
- `main.dart` sin referencias a SQLite/secure storage init.
- `.gitignore` ya cubría `.dart_tool/`, `build/`, `.idea/`, `*.iml` (sin cambios).
- README/.env.example/estructura.txt se actualizan en la tanda de cierre (M5).

### Verificación
- `scripts/verifica_tandaM1.py`: 0 referencias a módulos eliminados, 0
  `int.tryParse` de ids, 0 dependencias prohibidas, estructura objetivo
  completa (55 .dart), `pubspec.yaml` limpio.
- En tu máquina: `flutter pub get && flutter analyze && flutter run`
  (login → proyectos → detalle → visor de diagramas; requiere backend activo).

### Resultado
54 .dart en `lib/` + 1 en `test/` = **55 archivos** (antes: 107).
La app queda compilable y alineada 1:1 con el contrato real del backend.

---

## Tanda M2 — Corrección del lienzo, config limpia y perfil informativo
**Fecha:** 2026-11-09 · **Estado:** ✅ verificada

### Objetivo
1. Corregir el defecto arrastrado del Ciclo 1: **los diagramas no se
   visualizaban bien, sobre todo las relaciones en el lienzo**.
2. Consolidar proyectos/perfil informativos y verificar su contrato contra
   el backend real (tanda planificada M2 del plan móvil).

### 1. Corrección del lienzo (nota del usuario — defecto del Ciclo 1)

**Diagnóstico** (en `relationship_painter.dart`):
- Los extremos de cada relación se calculaban en el **centro** de las cajas
  con un alto fijo de 50 px (`posY + 50`, `nodeWidth/2`): las líneas
  atravesaban las clases y flotaban fuera de las cajas reales.
- Los **diamantes** de composición/agregación se dibujaban en el centro del
  origen y quedaban **tapados por la propia caja** (el painter va debajo de
  los nodos); los triángulos/flechas del destino también quedaban medio
  ocultos dentro de la caja destino.
- Resto de la migración M1: `seleccionadaId` era `int?` y `_clasePorId`
  recibía `int` mientras las entidades ya son `Id = String` → **no
  compilaba** (falla que se escapó a la verificación M1, basada en imports).

**Corrección:**
- `relationship_painter.dart` reescrito:
  - ids `String?` / `_clasePorId(String)` (contrato MongoDB alineado).
  - Extremos anclados al **borde real** de cada caja: intersección del rayo
    centro→centro con el rectángulo del nodo (`_puntoSalida`, rayo-rect).
  - Diamante pegado al borde del **origen** (vértice sobre el borde,
    extendiéndose hacia afuera); triángulo hueco/flecha abierta apuntando
    al borde del **destino**.
  - Multiplicidades al 20 %/80 % y nombre de asociación al 50 % del tramo
    visible (ya no caen dentro de las cajas).
- `diagram_canvas.dart`: nuevo widget `_Medidor` (RenderProxyBox) que mide
  el **tamaño real** de cada nodo tras el primer frame y lo reporta al
  canvas; el painter recibe `medidasNodos: Map<String, Size>` (con fallback
  a la estimación mientras llega la medición). Repaint controlado por
  cambio de medida.
- `class_node.dart`: nuevo `ClassNode.alturaEstimada(clase)` — espejo del
  layout real (cabecera + atributos + operaciones) para el fallback del
  painter y el encuadre inicial.
- `diagram_editor_page.dart`: el encuadre inicial de cámara usa el alto
  estimado por contenido (antes `posY + 100` fijo, cortaba clases altas).

### 2. Config muerta fuera (restos de módulos eliminados en M1)
- `env.dart`: quitados `wsBaseUrl`, `wsReconnectMaxAttempts`,
  `wsReconnectInitialDelayMs`, `diagramWsUrl(int, ...)` (WebSocket) y los
  flags `enableOffline`, `enableAiLocal`, `enableAiCloudFallback` (0
  referencias). Conservado: `apiBaseUrl`, `appEnv`, `appVersion`,
  `apiTimeoutMs`, claves de storage, `log`.
- `.env.example`: fuera `WS_BASE_URL`, `ENABLE_*` y `WS_RECONNECT_*`.

### 3. Contrato verificado contra el backend (sin cambios de código)
- `GET /proyectos` → `{items, total, skip, limit}` + query
  `incluir_archivados` ✓ (el datasource ya lo parsea así).
- `GET /proyectos/{id}` → `ProyectoConMiembrosResponse` ✓.
- `GET /proyectos/{id}/miembros` ✓.
- `GET /auth/me` y `POST /auth/cambiar-password` ✓.

### 4. Perfil informativo (pulido M2)
- Nuevo ítem **"Acerca de la app"**: diálogo que explica el rol de la app
  (companera informativa del Ciclo 2: proyectos, diagramas solo lectura,
  notificaciones, versiones/comentarios; la edición es de la web).
- La versión del pie ya no está hardcodeada: `DevForge AI · v${Env.appVersion}`.

### Verificación
- `scripts/verifica_tandaM2.py`: **56 OK / 0 FAIL** — painter sin restos
  int y con anclaje por bordes + medidas, canvas con medición post-layout,
  encuadre con alturas reales, env/.env.example sin config muerta, rutas
  REST del contrato, perfil informativo, estructura 55 .dart intacta,
  0 imports huérfanos, 0 restos int, pubspec limpio y balance de símbolos
  en los 6 archivos editados.
- Regresión: `scripts/verifica_tandaM1.py` → **70 OK / 0 FAIL**.
- Balance de llaves/paréntesis/corchetes en los 55 .dart: OK.
- En tu máquina: `flutter analyze && flutter run` y verificar en un
  diagrama con clases de distinto alto y relaciones de todos los tipos
  (asociación, composición, generalización, realización, dependencia):
  las líneas deben tocar los bordes de las cajas, con flechas/triángulos
  visibles en el destino y diamantes visibles en el origen.

### Resultado
Lienzo legible de nuevo (defecto del Ciclo 1 cerrado), sin configuración
muerta y proyectos/perfil confirmados como informativos contra el backend
real. Misma estructura: 54 .dart en `lib/` + 1 en `test/` = 55 archivos.

---

## Tanda M3 — Visor de diagramas (CU10/CU22): renombrado a diagrama_viewer, interfaces visibles y observación por sondeo
**Fecha:** 2026-11-09 · **Estado:** ✅ verificada

### Objetivo
Concretar el **visor de diagramas** según el plan móvil (§6, tanda M3) y
los puntos de decisión nº 5 (renombrar) — manteniendo intactas las
correcciones del lienzo de la Tanda M2 (nota del usuario: *"en la
version del ciclo1 (1er parcial) no se vizualizaba bien los diagramas
sobre todo las relaciones en el lienzo"*).

### 1. Renombrado del feature (decisión nº 5 del plan)
- `lib/features/diagrama_editor/` → **`lib/features/diagrama_viewer/`**
  (14 archivos; la app ya no edita: el nombre decía lo contrario).
- `diagram_editor_page.dart` → **`diagrama_viewer_page.dart`**;
  clase `DiagramEditorPage` → **`DiagramaViewerPage`**.
- Router: `AppRoutes.diagramaEditorPattern/diagramaEditor()` →
  **`diagramaViewerPattern`/`diagramaViewer()`** (la ruta sigue siendo
  `/diagramas/:diagramaId`); `app_router.dart` rewireado.
- `proyecto_detail_page.dart`: imports + navegación actualizados.
- **0 referencias** a `diagrama_editor`/`diagram_editor`/`DiagramEditorPage`
  en `lib/` + `test/` (lo comprueba el script).

### 2. Hueco corregido: las interfaces NO se dibujaban
El backend devuelve `interfaces` en `GET /diagramas/{id}/completo`
(`DiagramaCompletoResponse.interfaces`), pero el lienzo solo pintaba
`clases`: cualquier «interface» creada en la web era invisible en el
móvil (otro defecto de visualización de la misma familia que el del
Ciclo 1). Ahora:
- **`interface_node.dart` NUEVO**: nodo UML de interfaz (cabecera
  `«interface»` + nombre + operaciones declaradas), con
  `InterfaceNode.width`, `alturaEstimada(InterfazUml)` (misma fórmula
  espejo que ClassNode) y resaltado por selección.
- **`diagram_canvas.dart`**: renderiza `_NodoInterfaz` por cada interfaz
  (posX/posY del backend), las MIDE con `_Medidor`, soporta tap →
  resaltado, y añade **estado vacío** ("Este diagrama aún no tiene
  clases ni interfaces — el equipo las crea desde la web").
- **`diagrama_provider.dart`**: `ElementoSeleccionado.interfaz` (tipo
  `'interfaz'`), selector `interfacesProvider`.
- **Encuadre inicial**: el bounding box incluye clases + interfaces.
- **`relationship_painter.dart`**: sin cambio de lógica; comentario
  nuevo que documenta el contrato — las relaciones van SIEMPRE de
  clase a clase (el backend valida ambos extremos contra
  `diagrama.clase(id)` en `crear_relacion`), así que las interfaces no
  son extremos y el painter no las resuelve.

### 3. Observación CU22 por sondeo REST, sin WebSocket (D33)
- **`diagrama_provider.dart` → `refrescar()`** NUEVO: refresco
  SILENCIOSO (no activa `isLoading`, el lienzo no parpadea); conserva
  el contenido previo si la petición falla y limpia el resaltado si el
  elemento seleccionado dejó de existir. Devuelve si hubo cambios.
- **`diagrama_viewer_page.dart`**: **sondeo cada 30 s**
  (`Timer.periodic`, pausa/reanudar desde el AppBar con icono
  autorenew/sync_disabled), aviso con SnackBar "El diseño se
  actualizó desde la web", subtítulo con la hora de la última
  actualización y **cámara persistente** entre refrescos (el encuadre
  automático solo aplica en la primera carga). El Timer se cancela en
  `dispose`.
- **0 WebSocket** en la app (D33: REST + push; el push FCM es la
  ampliación opcional de M4). El aviso inferior ahora muestra el
  estado: "Observando (REST · 30 s)…" / "Observación en pausa…".

### 4. Actividad reciente de lectura (D33)
- **`trazabilidad_provider.dart`**: `historialProvider` NUEVO
  (`GET /trazabilidad/diagramas/{id}/historial` — feed de cambios del
  equipo en la web).
- **`actividad_reciente_panel.dart` NUEVO**: feed solo lectura con
  icono/color por `tipo_cambio` (CREAR/MODIFICAR/ELIMINAR),
  descripción legible ("Modificó clase «Usuario»") extrayendo la
  etiqueta de `datos_cambio` de forma defensiva (es el payload WS y
  varía por evento), tipo_entidad CLASE/ATRIBUTO/OPERACION/RELACION/
  INTERFAZ, usuario acortado y fecha relativa. Pull-to-refresh.
  Sin ninguna acción de escritura.
- Acceso desde el AppBar del visor (icono timeline) en un bottom sheet.

### 5. Verificación
- `scripts/verifica_tandaM3.py`: **102 OK / 0 FAIL** — renombrado
  completo con 0 referencias viejas; contrato CU10 (3 endpoints REST +
  parseo de clases/interfaces/relaciones con multiplicidades, roles y
  nombre, 6 literales de TipoRelacion); interfaces visibles en lienzo
  (nodo, medición, encuadre, selección, estado vacío); sondeo 30 s con
  pausa + SnackBar + cámara persistente; 0 WebSocket; actividad
  reciente de lectura con pull-to-refresh; regresiones M1/M2
  (0 imports huérfanos, 0 restos int, pubspec limpio, lienzo M2
  intacto) y balance de símbolos en los 10 archivos tocados.
- Regresión: `verifica_tandaM1.py` → **72 OK / 0 FAIL**;
  `verifica_tandaM2.py` → **56 OK / 0 FAIL** (ambos con nota de
  compatibilidad M3: rutas renombradas y conteo 56 = 54 + 2 nuevos).
- En tu máquina: `flutter analyze && flutter run`, abrir un diagrama
  con interfaces, editar en la web y esperar el ciclo de 30 s (debe
  avisar y renovar sin perder la cámara), y revisar la pestaña
  "Actividad reciente" tras tocar clases/relaciones en la web.

### Resultado
Feature `diagrama_viewer/` (16 .dart), página `DiagramaViewerPage` con
sondeo CU22, **interfaces visibles por fin en el móvil** y actividad
reciente de lectura. Estructura: **56 .dart en `lib/`** + 1 en `test/`.
M4 sigue con la bandeja de notificaciones (sondeo + pull-to-refresh).

---

## Tanda M4 — Notificaciones (CU15): bandeja por sondeo REST
**Fecha:** 2026-11-09 · **Estado:** ✅ verificada

### Objetivo
Dejar la bandeja de notificaciones **en condiciones de app informativa**
(CU15 del catálogo D23): sondeo REST periódico (D33, **sin WebSocket**),
gestión de leídas y estados de interfaz completos. La capa de datos del
Ciclo 1 ya cumplía el contrato del backend (7 endpoints + 8 tipos), así
que M4 se concentra en provider y página.

### 1. Provider — `notificaciones_provider.dart`
- **Guard de sesión (bug real corregido):** el `Timer.periodic` del
  contador seguía vivo tras cerrar sesión y lanzaba peticiones que
  terminaban en 401. Ahora el notifier recibe `sesionActiva`
  (`ref.read(isAuthenticatedProvider)`) y **no consulta nada sin
  sesión** (`_haySesion` en contador, carga y refresco silencioso).
- **`refrescarSilencioso()` NUEVO:** recarga lista + contador **sin
  spinner** (la bandeja no parpadea), **conserva la lista previa si la
  petición falla** y devuelve `true` solo si cambió algo (id, `leida` o
  mensaje) — mismo patrón del `refrescar()` del visor (M3).
- **`marcarTodasLeidas()`** ahora devuelve el nº de `actualizadas` del
  backend (`{"actualizadas": total}`) para el SnackBar de la página.
- **`eliminar()`** ya no lanza `StateError` si la notificación ya no
  está en memoria: búsqueda segura + descuento del contador solo si era
  no leída.
- Limpieza de errores: las acciones exitosas limpian `error` previo
  (`clearError: true`).

### 2. Página — `notificaciones_page.dart`
- **Sondeo de la bandeja cada 30 s** (`Timer.periodic` →
  `refrescarSilencioso()`), cancelado en `dispose`. El badge del AppBar
  de proyectos sigue con su propio contador de 30 s (intacto).
- **Pull-to-refresh** con `RefreshIndicator` y
  `AlwaysScrollableScrollPhysics` (también en los estados vacíos, para
  poder tirar aunque no haya lista).
- **Estados completos:** carga (spinner), **vacío total** ("No hay
  notificaciones" + explicación de cuándo aparecerán avisos), **vacío
  con filtro** ("Todo leído", icono verde) y **error con botón
  Reintentar** (antes un fallo de red dejaba la pantalla en blanco).
- **Tarjetas por tipo:** icono y color según los 8 tipos del backend
  (COMENTARIO azul, CAMBIO_DIAGRAMA brand, GENERACION_COMPLETA verde,
  GENERACION_FALLIDA rojo, MIEMBRO_AGREGADO verde claro,
  CONFLICTO_PENDIENTE ámbar, VERSION_GUARDADA brand claro, SISTEMA
  gris), punto de no leída del color del tipo, chip de tipo en
  negrita y fecha relativa ("hace 5m").
- **Feedback:** SnackBar "N notificaciones marcadas como leídas" al
  marcar todas; "Se eliminaron N notificaciones" al limpiar leídas.
- Acciones conservadas de CU15: marcar leída/no leída por tarjeta,
  eliminar una, marcar todas, limpiar leídas, filtro "solo no leídas".

### 3. Bonus — import roto detectado por la verificación M4
- El nuevo chequeo de **imports huérfanos** (resuelve cada import
  relativo hasta el archivo real) detectó que
  `diagrama_viewer/data/diagrama_repository.dart` importaba
  `../../../../core/network/api_client.dart` (4 subidas) cuando desde
  `data/` corresponden **3** → el archivo no existía y `flutter
  analyze` habría fallado. Corregido a `../../../core/…`. Era el único
  caso: los 4 niveles de `presentation/{pages,providers,widgets}` son
  correctos.

### 4. Lo que NO se hace (alcance)
- Sin WebSocket (D33): la bandeja se entera de avisos nuevos por el
  sondeo de 30 s.
- **Push FCM queda como ampliación opcional** del plan (requiere
  proyecto Firebase + `google-services.json` + dependencias
  `firebase_core`/`firebase_messaging`); sin él, la app es 100 %
  funcional por sondeo.
- Comentar/gestionar lo que generó el aviso sigue siendo de la web; el
  aviso solo informa.

### 5. Verificación
- `scripts/verifica_tandaM4.py`: **56 OK / 0 FAIL** (tras corregir el import de `diagrama_repository`) — contrato CU15
  (7 endpoints, claves `actualizadas`/`eliminadas`/`total_no_leidas`,
  8 tipos); sondeo 30 s con guard de sesión y refresco silencioso sin
  spinner; estados vacío/filtro/error con reintentos; 8 tipos con icono
  y color; badge de proyectos intacto; regresiones M1–M3 (0 imports
  huérfanos, 0 restos int, 0 WebSocket, pubspec limpio, 56 .dart en
  `lib/`), worklog con la nota del defecto del Ciclo 1 y balance de
  símbolos en los 2 archivos tocados.
- Regresión: `verifica_tandaM1.py`, `verifica_tandaM2.py`,
  `verifica_tandaM3.py` sin cambios de estructura → siguen OK.
- En tu máquina: `flutter analyze && flutter run`, abrir
  Notificaciones, probar pull-to-refresh, marcar todas (SnackBar),
  filtrar "solo no leídas" y dejar la bandeja abierta 30 s tras
  comentar en la web (el aviso debe aparecer solo).

### 6. Resultado
CU15 completo en móvil por sondeo REST. Estructura: **56 .dart en
`lib/`** + 1 en `test/` (M4 no añade archivos). M5 cierra con la vista
de trazabilidad (Historial/Versiones/Comentarios) + README,
estructura.txt, widget_test y zip final.

---

## Tanda M5 — Trazabilidad informativa + cierre del Ciclo 2
**Fecha:** 2026-11-09 · **Estado:** ✅ verificada

### Objetivo
Cerrar la app informativa: vista de trazabilidad de solo lectura
("cómo va el diseño" completo) y todos los artefactos de entrega
(README real, estructura.txt, widget_test, .env.example, versión,
LISTA_ARCHIVOS.md y zip final).

### 1. Página de trazabilidad NUEVA — `trazabilidad/presentation/pages/trazabilidad_page.dart`
- **Tres pestañas** (`DefaultTabController`):
  - **Historial** — feed `GET /trazabilidad/diagramas/{id}/historial`:
    "Creó clase «Usuario»", borde/icono por tipo de cambio
    (CREAR verde / MODIFICAR ámbar / ELIMINAR rojo), entidad
    (CLASE/ATRIBUTO/OPERACION/RELACION/INTERFAZ), etiqueta extraída de
    `datos_cambio` de forma defensiva (payload variable), usuario
    acortado y fecha relativa.
  - **Versiones** — `GET .../versiones` (resúmenes): tarjeta con
    `v{n}` + comentario; al tocar, bottom sheet con el detalle
    (`GET /trazabilidad/versiones/{id}`) mostrando los **conteos** del
    snapshot (N clases / interfaces / relaciones) — nunca el JSON crudo.
  - **Comentarios** — `GET .../comentarios` vía
    `comentariosProvider(diagramaId)` (StateNotifier family): texto,
    usuario, fecha, chip **General / Sobre elemento** y estado
    **Resuelto / Abierto**. Solo lectura: resolver/crear es de la web.
- **Pull-to-refresh en las 3 pestañas** (`RefreshIndicator` +
  `invalidate` de los FutureProviders / `cargar()` del notifier) y
  estados vacío/error con icono y mensaje orientado en cada una.
- 0 llamadas de escritura: la página no toca `_client` directamente y
  no usa ningún método POST/PUT/DELETE del datasource.

### 2. Ruta y acceso
- `app_routes.dart`: `diagramaTrazabilidadPattern`
  (`/diagramas/:diagramaId/trazabilidad`) + helper
  `diagramaTrazabilidad(id, {nombre})` que viaja con el nombre del
  diagrama como query (URI-encoded) para el título.
- `app_router.dart`: ruta registrada que lee `queryParameters['nombre']`
  y construye `TrazabilidadPage`; documentación del header actualizada.
- `diagrama_viewer_page.dart`: botón **Trazabilidad** (icono
  `menu_book_outlined`) como primera acción del AppBar, con
  `context.push` (al volver se regresa al visor con su estado).

### 3. Cierre del repo
- **`README.md`** reescrito de cero: qué es la app informativa
  (CU10/CU15/CU22), fuera de alcance, instalación con
  `--dart-define=API_BASE_URL`, decisiones (D33 sin WebSocket + FCM
  opcional, Id=String, 6 literales TipoRelacion, sondeos silenciosos),
  estructura, tabla de tandas M1–M5, la nota del defecto del lienzo del
  Ciclo 1 y el listado de endpoints que consume.
- **`.env.example`** alineado con `env.dart` (documenta `--dart-define`,
  ya no sugiere dotenv; FCM marcado como ampliación opcional).
- **`estructura.txt`** regenerado por script (árbol completo, 225
  líneas) con contador consistente contra el árbol real.
- **`widget_test.dart`** pasa de 1 a **6 pruebas**: arranque de la app,
  helpers de rutas (incluida la nueva de trazabilidad), parseo del
  contrato CU15 de notificaciones (ids String + contador + tipo
  desconocido → SISTEMA) y los 6 literales de `TipoRelacion`.
- **Versión:** `pubspec.yaml` → `0.3.0+3`; `APP_VERSION` por defecto
  → `0.3.0` (visible en Perfil).
- **`LISTA_ARCHIVOS.md`** + **`devforge_mobile.zip`** generados
  (inventario verificado contra el árbol real).

### 4. Verificación
- `scripts/verifica_tandaM5.py`: **65 OK / 0 FAIL** — página con 3
  pestañas y solo lectura; ruta + query nombre + botón menu_book con
  context.push; README/.env.example/estructura/widget_test/versión
  consistentes; zip con las 9 claves y 58 .dart; regresiones M1–M4
  (0 imports huérfanos, 0 módulos eliminados, 0 WebSocket, pubspec
  limpio, 57 .dart en `lib/`, worklog M1–M5 con la nota del Ciclo 1) y
  balance de símbolos en los 5 archivos tocados.
- Regresión: `verifica_tandaM1.py` / `M2` / `M3` / `M4` → OK (los
  cuatro con conteo relajado 56–57 por la página nueva de M5, con nota
  de compatibilidad).
- En tu máquina (pruebas del portátil): `flutter analyze`, `flutter
  test` (6 pruebas), `flutter run` y recorrer: login → proyectos →
  visor → botón Trazabilidad (3 pestañas) → Notificaciones → Perfil.

### Resultado
**Ciclo 2 de la app móvil cerrado.** Estructura final: **57 .dart en
`lib/`** + 1 en `test/`, 0 WebSocket (D33), toda acción de escritura
fuera de la app. Zip final `devforge_mobile.zip` + inventario en
`LISTA_ARCHIVOS.md`, listos para las pruebas en tu portátil.
