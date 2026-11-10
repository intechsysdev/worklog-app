# WorkLog móvil (Fases 1 y 2)

App Flutter de **WorkLog · Bitácora de actividades** (INTECHSYS ONE) para técnicos de campo: jornada, actividades y órdenes de trabajo, evidencias (fotos y firma), GPS y operación sin conexión. El diseño de referencia está en `docs/design/*.dc.html` y la especificación en `docs/design/ESPECIFICACION.md`. El contrato de la API está en `docs/openapi.v1.json`.

## Requisitos

- Flutter 3.44 (Dart 3.12) y el SDK de Android (API 36). Para iOS se necesita Xcode en macOS.
- La API de WorkLog (`work_log_api`) corriendo. En desarrollo escucha en `http://localhost:5290`:

```bash
dotnet run --project F:\Intechsys_Proj\worklog\work_log_api\src\WorkLog.Api --launch-profile http
```

## Configuración (`--dart-define`)

| Clave | Por defecto | Uso |
|---|---|---|
| `AUTH_MODE` | `worklog` | `worklog`: correo y contraseña de WorkLog (los técnicos no tienen cuenta de ONE); con contraseña temporal pide crear la propia. `one`: correo y contraseña de INTECHSYS ONE, más el SSO. `development`: Ingreso solo pide el correo y usa el token `dev:<correo>`. |
| `WORKLOG_API_URL` | API de producción | API de WorkLog, sin `/api/v1`. En el emulador de Android `localhost` es `10.0.2.2`. |
| `ONE_URL` | API de ONE de producción | API de ONE (`/api/v1/auth/login`, `/auth/refresh`, `/sso/token`). |
| `ONE_PORTAL_URL` | `https://intechsysone.com` | Portal de ONE, que sirve la página `/autorizar` del SSO. |

Sin `--dart-define` la app apunta a producción (las mismas URLs de `worklog-front/.env.production`, definidas en
`lib/core/config/app_config.dart`) y no usa datos de demostración; esos solo se activan con `DATA_MODE=mock`.

## APK de producción

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`, firmado con la clave de debug.
| `ONE_CLIENT_ID` | `worklog` | Slug de la app en ONE (`client_id` del SSO). |
| `ONE_REDIRECT_URI` | `com.intechsys.worklog://sso/callback` | Redirect del SSO. |

## Correr en modo desarrollo contra la API local

1. Crea un técnico como administrador (el rol "Usuario móvil" y la sede salen de `GET /api/v1/roles` y `GET /api/v1/branches`):

```bash
curl -X POST http://localhost:5290/api/v1/members \
  -H "Authorization: Bearer dev:admin@intechsys.dev" \
  -H "X-Tenant-Id: 0199f0a0-0000-7000-8000-000000000001" \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Andres Mora","email":"amora@intechsys.dev","usage":"Mobile","roleId":"<rol móvil>","branchId":"<sede>","workGroupId":null,"supervisorId":null}'
```

2. Corre la app en el emulador:

```bash
flutter run --dart-define=AUTH_MODE=development --dart-define=WORKLOG_API_URL=http://10.0.2.2:5290
```

En un teléfono físico usa la IP del PC en la red (`http://192.168.x.x:5290`) y abre el puerto en el firewall.

3. En Ingreso escribe `amora@intechsys.dev`. La app pide la política, revisa los permisos y abre Inicio de jornada.

Prueba de humo de la capa de datos contra la API, con los mismos modelos de la app: acepta la política, registra una jornada completa si hoy no hay una, y en la parte de Fase 2 lee la semana y envía y cancela las tres solicitudes. Úsala con un técnico de prueba:

```bash
dart run tool/api_smoke.dart http://localhost:5290 amora@intechsys.dev 0199f0a0-0000-7000-8000-000000000001
```

## APK de demostración (sin servidor)

```bash
flutter build apk --release --dart-define=DATA_MODE=mock
```

Con `DATA_MODE=mock`, `MockHttpAdapter` atiende en el teléfono todos los endpoints de la app (incluido el login de ONE) con `MockBackend` (`lib/features/demo`). Usa las mismas formas JSON de la API y sus reglas principales: ventana de inicio, una sola actividad abierta, exigencias al finalizar, idempotencia, cierre automático, Mi semana y solicitudes que "Laura Gómez" aprueba a los 2 minutos. El estado se guarda en `worklog_demo.json`, en la carpeta de la app. El turno se adapta a la hora real: es 07:00–16:00 entre semana dentro de ese horario, y si no, un turno de 8 h que empezó hace 10 minutos. La primera ubicación recibida es el centro de los sitios. En Perfil están los escenarios (Normal, Vacaciones, Kiosco compartido y asignado, Aviso de fin de turno), "Simular sin conexión" y "Reiniciar datos de demostración". El APK queda en `build/app/outputs/flutter-apk/app-release.apk`, firmado con la clave de debug.

## Ingreso con la cuenta de WorkLog (por defecto)

- **Ingresar**: `POST {WORKLOG_API_URL}/api/v1/mobile-auth/login {email, password, device}`. Si el correo y la contraseña sirven en varias empresas responde `tenants` y la app muestra el selector y repite con `tenantId`.
- **Contraseña temporal**: el administrador la genera en el panel (Usuarios → Accesos). Con ella la app solo deja crear la contraseña propia (`POST /api/v1/me/password`); el API responde 403 `auth.password_change_required` a lo demás.
- **Renovar y salir**: `POST /mobile-auth/refresh` (rota ambos tokens) y `POST /mobile-auth/logout`, con un cliente HTTP sin el interceptor de sesión.
- Desactivar a la persona, desvincular su dispositivo o restablecer su contraseña cierra sus sesiones.

## Correr en modo ONE

```bash
flutter run --dart-define=AUTH_MODE=one \
  --dart-define=WORKLOG_API_URL=https://<api-worklog> \
  --dart-define=ONE_URL=https://<api-one> \
  --dart-define=ONE_PORTAL_URL=https://<portal-one>
```

- **Ingresar**: `POST {ONE_URL}/api/v1/auth/login {email, password}` responde `{accessToken, refreshToken, expiresAt, user}`. Si responde 403 con `requiresTwoFactor`, la app pide usar "Ingresar con la cuenta de la empresa".
- **Ingresar con la cuenta de la empresa**: SSO con PKCE (S256) en el navegador del sistema (`flutter_web_auth_2`). Abre `{ONE_PORTAL_URL}/autorizar?client_id=worklog&redirect_uri=com.intechsys.worklog://sso/callback&code_challenge=…&state=…`, recibe `code` (y `tenant`) en el redirect y lo canjea en `POST {ONE_URL}/api/v1/sso/token`. **Requiere registrar `com.intechsys.worklog://sso/callback` entre los redirect URIs de la app `worklog` en ONE** (ya está en la propuesta `work_log_api/docs/one-api/WorkLogContrato.cs`, que aún no está aplicada).
- **Refresco**: `POST {ONE_URL}/api/v1/auth/refresh {refreshToken}`, antes de que venza el token y ante un 401 (un solo refresco a la vez, y se reintenta la petición). Si ONE rechaza el refresh token, la sesión se cierra.
- Los tokens se guardan en `flutter_secure_storage` (Keystore/Keychain).
- Cada llamada a WorkLog lleva `Authorization: Bearer <token>`, `X-Tenant-Id` (de `GET /me/tenants`; con varias empresas aparece un selector) y `X-Client: mobile`.

## Offline y sincronización

- Cada acción (inicio y cierre de jornada, iniciar, pausar, reanudar y finalizar actividad) se guarda **primero** en SQLite (`events`) con un `clientEventId` UUID v7 y la hora real (`occurredAt`, reloj del teléfono corregido con el delta del servidor). La app genera los ids de jornada y de actividad, así los eventos siguientes apuntan a ellos sin conexión.
- La UI es optimista: `DayProjection` aplica la cola pendiente sobre el último `today` del servidor (en caché), y se reconcilia con el `today` que devuelve `/me/workday/sync`.
- `SyncService` envía la cola en orden por `POST /me/workday/sync` (lotes de 200) en cuanto se encola, al volver la red (`connectivity_plus`), al volver la app al primer plano, cada minuto si hay pendientes y con "Reintentar ahora". Los reintentos son idempotentes (el servidor deduplica por `clientEventId`). Los rechazos quedan marcados con su motivo y no se reenvían; los ajustes guardan el mensaje del servidor.
- Fotos y firma van a otra cola (`files`) y suben por multipart a `/activities/{id}/evidences`, idempotente por `clientId`. Por defecto solo con wifi; el toggle "Subir archivos con datos móviles" lo cambia. Un archivo espera a que el evento de su actividad llegue al servidor.
- El muestreo de ubicación (cada `settings.samplingMinutes`) se guarda en `location_samples` y se envía a `/me/workday/locations`. Va detrás de la interfaz `LocationTracker`:
  - **Android**: servicio en primer plano (`flutter_foreground_task`, `foregroundServiceType="location"`) con la notificación fija "INTECHSYS ONE · Jornada activa" (actividad, tiempo y botones Pausar/Reanudar y Finalizar). El servicio corre en otro isolate: muestrea también con la app cerrada y escribe en la misma base SQLite; los botones encolan el evento allí mismo (Finalizar abre la pantalla si la actividad pide foto, firma u observación). Se detiene al cerrar la jornada.
  - **iOS y pruebas**: temporizador mientras la app está en memoria (`TimerLocationTracker`).
- Cerrar sesión borra la base local; si hay pendientes, la app lo advierte antes.

## Fase 2

- **Mi semana** (`GET /me/week?date`): total frente al tope legal, barra con lo programado y lo que falta, barras por día (el día en curso en `#E51E49`), desglose y navegación entre semanas.
- **Mis solicitudes** (`GET /me/requests`, `POST /me/requests/{id}/cancel`) con pestañas Todas/Pendientes/Resueltas y "Nueva solicitud": Ajuste de registro, Horas extra y Cambio de turno. Las solicitudes van en línea (no por la cola) porque el servidor las valida al momento; sin red se muestra un mensaje. "Solicitar ajuste" está habilitado en Historial y en los rechazos/ajustes de Pendiente de sincronizar (formulario prellenado).
- **Kiosco** (dispositivo con `today.device.controlEnabled` y jornada sin iniciar): apps de trabajo bloqueadas, "Iniciar jornada" según la ventana y el mensaje del servidor si MobiControl no responde (`device.unreachable`). Con la jornada abierta aparece la barra "En jornada · apps de trabajo habilitadas".
- **Aviso de fin de turno**: bottom sheet en cada `device.warningMinutes` (o `settings.shiftEndWarningMinutes` sin control) antes de `autoCloseAt`, con las variantes compartido/asignado, y el estado "Sesión cerrada / Apps ocultas" cuando la jornada queda en `PendingReview`.
- **Avisos locales** (`flutter_local_notifications`, alarmas inexactas): inactividad, pausa excedida y fin de turno. `AlertPlanner` calcula los tiempos y se reprograman con cada `today` nuevo o cambio de la cola.
- Perfil con supervisor, Sin turno con "Aprobadas por…", Cerrar jornada e Historial con la leyenda por categoría (`summary.byCategory`).
- En el perfil, en modo desarrollo, hay vistas previas del kiosco y del aviso de fin de turno.

## Estructura

```
lib/
  main.dart                     abre SQLite e inyecta la base en Riverpod
  app/                          MaterialApp, rutas (go_router) y WorkSessionScope (muestreo y reanudación)
  core/
    config/                     AppConfig desde --dart-define
    theme/                      tokens del diseño (WlColors como ThemeExtension) y ThemeData con Inter
    network/                    Dio, AuthInterceptor (auth + refresh), ApiException (ProblemDetails)
    storage/                    AppDatabase (sqflite) y KvStore (cachés y preferencias)
    location/ connectivity/ clock/ format/ widgets/
  features/
    auth/          data (ONE, SSO PKCE, sesión segura) · domain (Session) · presentation (Ingreso, empresa)
    onboarding/    política de datos y revisión del dispositivo
    workday/       data (API, modelos json_serializable, caché de today) · domain (DayProjection)
                   presentation (Inicio, Sin turno, Actividad, Seleccionar, Finalizar, Firma, Historial, Cerrar jornada)
    sync/          data (colas SQLite) · domain (SyncService, puertos) · presentation (estado y Pendiente de sincronizar)
    profile/       Perfil y ajustes
    week/          Mi semana
    requests/      Mis solicitudes y los tres formularios (validaciones en domain/request_forms.dart)
    kiosk/         Kiosco fuera de jornada
    alerts/        AlertPlanner (tiempos de los avisos), notificaciones locales y aviso de fin de turno
    tracking/      LocationTracker: servicio en primer plano (Android) y temporizador
test/              cola y sincronización, proyección optimista, avisos, formularios, botones de la
                   notificación y widget tests de Inicio, Mi semana y Mis solicitudes
tool/api_smoke.dart prueba de humo contra la API
```

**Estado: Riverpod 3** (`Notifier`/`AsyncNotifier`, sin generación de código), porque deja componer estados derivados (la proyección del día sale de `today` + la cola) y sobrescribir dependencias en las pruebas sin infraestructura extra. Los modelos usan `json_serializable` (`dart run build_runner build` tras cambiarlos).

## Calidad

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
```

## Pendiente

- Integración directa con MobiControl en el teléfono (configuración administrada con servidor y usuario, serie y grupo del dispositivo). Hoy el control de apps lo hace el servidor y la app solo lo refleja.
- iOS: el muestreo en segundo plano y los botones de la notificación fija son solo de Android.
- Para producción hay que quitar `android:usesCleartextTraffic="true"` (solo existe para la API local por http).
