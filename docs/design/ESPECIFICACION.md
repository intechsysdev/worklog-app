## Especificación funcional: WorkLog · Bitácora de actividades (INTECHSYS ONE)

Leí completas las 32 pantallas y canvas.json, incluidos markup, scripts `renderVals()` y estilos. No modifiqué ningún archivo del proyecto. En el scratchpad quedaron una copia sin estilos y un script auxiliar (`...\scratchpad\stripped\`, `...\scratchpad\tools\strip.py`).

Carpeta del diseño: `C:\Users\Jeffo-PC\AppData\Local\Temp\claude\4ecb26a4d0bc88eb\b5b62391-4fed-4019-9d08-d15588a94b4b\scratchpad\artifact-files\7d0e9d26-af92-4f5e-a194-82d1993e0f65\project\`

Personas de ejemplo:
- Andrés Mora: técnico.
- Laura Gómez: supervisora.
- Marta Ríos: administradora.
- Paola Cruz: Recursos humanos.
- Julián Mesa: Nómina, en estado invitado.

---

## 1. Pantallas

### App móvil (390×844, Flutter)

Header común: logo INTECHSYS "one", separador, "WorkLog / Bitácora de actividades" y avatar con iniciales que lleva a Perfil.

La navegación inferior tiene 3 tabs: **Actividad · Historial · Jornada**. Aparece en Actividad, Historial, Semana y Perfil. En Perfil el tab "Jornada" apunta a Perfil.dc.html, así que no está claro si el tercer tab es Jornada o Perfil.

1. **Inicio de jornada (Main)**
   - Muestra: saludo, fecha, card "Turno de hoy" (07:00–16:00), "Lunes a viernes · almuerzo 12:00–13:00 · Sede Bogotá Norte", chips "GPS activo" y "Conectado", reloj grande con "Hora del servidor" y aviso de privacidad ("ubicación solo durante la jornada…").
   - Acción: CTA "Iniciar jornada", que lleva a Actividad.
2. **Actividad en curso**
   - Header "Jornada activa · Desde 07:03 · Turno hasta 16:00", icono GPS e icono de sincronización que lleva a Pendientes.
   - Card de actividad: chip EN CURSO / EN PAUSA, nombre ("Instalación de equipo"), sitio y OT ("Almacén Norte · OT-1042"), cronómetro hh:mm:ss, "Iniciada a las 08:12", "Dentro de la geocerca del sitio · precisión 6 m".
   - Botones: Pausar/Reanudar (alterna), Finalizar (lleva a Finalizar), "Cambiar actividad" (lleva a Seleccionar).
   - "Resumen del día": n.º de actividades (3), Productivo (2 h 31 m), Sin actividad (7 m).
3. **Seleccionar / Nueva actividad**
   - Buscador "Buscar actividad u orden".
   - Pestañas segmentadas:
     - **Asignadas hoy** (OT): título, sitio · OT · hora programada. Ej.: "Mantenimiento preventivo · Bodega Sur · OT-1043 · 10:00", "Visita técnica · Oficina Centro · OT-1047 · 13:30", "Revisión de garantía · Almacén Norte · OT-1051 · 15:00".
     - **Catálogo**: título y categoría. Ej.: Traslado entre sitios (Desplazamiento), Labores administrativas (Interna), Capacitación (Interna), Espera de materiales (Tiempo improductivo).
   - Selección única (radio).
   - Aviso: "Tienes X en curso. Al iniciar otra, se finalizará automáticamente a las 09:40."
   - CTA "Iniciar actividad".
4. **Finalizar actividad**
   - Resumen: nombre, sitio·OT, 08:12 → 09:40, duración 1 h 28 m.
   - Resultado (selección única): Completada / Incompleta / Reprogramar (ids ok/partial/resched).
   - "Observación (opcional)".
   - Evidencia: "Tomar foto", "Firma del cliente".
   - "Ubicación capturada · precisión 8 m · 09:40".
   - CTA "Confirmar y finalizar", que lleva a Historial.
5. **Historial "Mi día"**
   - Tabs Día/Semana. Subtítulo "Jueves 29 de octubre · 07:03 – en curso".
   - Barra de distribución del día (07:00 / 11:30 / 16:00) con leyenda Productivo 2 h 28 m, Traslado 1 h, Sin actividad 12 m.
   - Timeline (más reciente primero), cada evento con título, duración y meta, y color por tipo:
     - Mantenimiento preventivo · En curso · "09:45 – ahora · Bodega Sur · OT-1043" (#E51E49).
     - Sin actividad · 5 m · 09:40–09:45 (#DA830B).
     - Instalación de equipo · 1 h 28 m · "08:12–09:40 · Completada · 1 foto" (#AF1839).
     - Sin actividad · 7 m.
     - Traslado entre sitios · 1 h (#868787).
     - Inicio de jornada · 07:03 · "Sede Bogotá Norte · dentro de geocerca" (#1E1F1D).
   - Pie: "¿Algo quedó mal registrado? Los ajustes los aprueba tu supervisor" y botón "Solicitar ajuste".
6. **Notificaciones en segundo plano** (sombra de notificaciones)
   - Notificación fija (foreground service): "INTECHSYS ONE · Jornada activa", actividad, cronómetro, "Bodega Sur · OT-1043 · desde 09:45", botones Pausar/Finalizar.
   - Recordatorio: "Llevas 20 minutos sin actividad. Inicia tu siguiente actividad…".
   - Aviso de fin de turno: "Tu turno termina en 15 minutos. A las 16:00 se cerrarán la actividad abierta y la jornada."
7. **Ingreso**
   - Logo y "WorkLog / Bitácora de actividades".
   - Campo "Usuario corporativo · asignado a este dispositivo", precargado (amora@[DOMINIO]); Contraseña.
   - Botones: "Ingresar", separador "o", "Ingresar con la cuenta de la empresa" (SSO), "¿Olvidaste tu contraseña?".
   - Taglines "Conectamos tecnología. / Impulsamos negocios."
   - Pie: "Dispositivo administrado por SOTI MobiControl · serie [SERIE]", "INTECHSYS ONE · WorkLog 1.0.0".
   - Navega a Política.
8. **Política / Tratamiento de datos**
   - Resumen en 4 puntos:
     - Ubicación solo en jornada: al iniciar, cambiar y finalizar actividades, y cada 15 min.
     - Horas y actividades: para calcular jornada, extras y recargos.
     - Fotos y firma: como evidencia.
     - Derechos: conocer, actualizar, rectificar y revocar (Ley 1581 de 2012).
   - Link "Leer la política completa".
   - Checkbox "Leí y acepto… Versión 1.0 · vigente desde [FECHA]".
   - CTA "Aceptar y continuar", deshabilitado si no se marca el checkbox. Navega a Permisos.
9. **Revisión del dispositivo (Permisos)**
   - Card "Administrado por SOTI MobiControl · [MODELO] · serie · Grupo: INTECHSYS / Campo / Bogotá Norte".
   - Lista de permisos con estado "Por política" (verde) o "Falta" (ámbar):
     - Ubicación siempre.
     - Notificaciones.
     - Cámara.
     - Sin optimización de batería.
     - Configuración de la app ("Servidor y usuario enviados por MobiControl").
   - Si falta alguno: "Notificaciones no está activo… Ya avisamos a soporte TI" y botón "Volver a revisar".
   - CTA "Continuar", que lleva a Main.
10. **Sin turno hoy**
    - "Hoy no tienes turno", fecha.
    - Card Novedad: "Vacaciones · Del martes 3 al viernes 13 de noviembre. Aprobadas por Laura Gómez".
    - Card "Tu próximo turno": martes 17 nov, 07:00–16:00 · Sede, nota "El lunes 16 es festivo".
    - Botón "Iniciar jornada" deshabilitado, con "No puedes iniciar jornada en días sin turno. No se registra tu ubicación."
    - Link "¿Es un error? Solicitar cambio de turno", que lleva a Solicitudes.
11. **Mi semana**
    - Tabs Día/Semana. Rango "Lunes 26 a viernes 30 de octubre".
    - Total "31 h 20 m de 42 h legales", barra con "Programadas: 40 h · Te faltan 8 h 40 m".
    - Barras por día (Lun–Vie). Día en curso con #E51E49; día sin registro "—".
    - Desglose: Ordinarias diurnas, Ordinarias nocturnas, Horas extra aprobadas "0 de 12", Dominical o festivo.
    - Nota: "Cifras provisionales hasta el cierre del periodo, el 15 de noviembre".
12. **Mis solicitudes**
    - Tabs: Todas / Pendientes / Resueltas.
    - Cada item: tipo, chip de estado, título, detalle y meta. Ejemplos:
      - Ajuste de registro, Pendiente: "Fin 09:40 → 09:55. Olvidé finalizar…", "Enviada hoy 10:05 · Laura Gómez".
      - Horas extra, Aprobada: "1 h 30 m · cierre de obra", "Aprobada por Laura Gómez el 23 oct".
      - Cambio de turno, Rechazada: "07:00–11:00", "Rechazada: la sede está cerrada ese día".
    - CTA "Nueva solicitud" (formulario no diseñado).
13. **Pendiente de sincronizar**
    - Banner "Sin conexión desde las 10:12. Tu trabajo está guardado en el teléfono…".
    - "En cola · 3 eventos y 2 archivos". Cada item: hora, título, meta y estado (En cola / Espera wifi). Ejemplos: Pausa, Reanudar, Finalizar actividad (Completada · ubicación 7 m), Foto 1 de 2 (1,8 MB), Firma del cliente (0,1 MB).
    - Card "Rechazado por el servidor": "06:41 · Inicio de jornada · Fuera de la ventana del turno (desde 06:45). Se registró a las 06:45", con link "Solicitar ajuste".
    - Toggle "Subir archivos con datos móviles" (por defecto apagado; al activarlo, los archivos pasan de "Espera wifi" a "En cola").
    - "Última sincronización: hoy 10:11" y botón "Reintentar ahora".
14. **Cerrar jornada**
    - Resumen: 07:03 → 15:58, fecha, total "7 h 55 m · provisional".
    - Barra y leyenda: Productivo 6 h 40 m, Traslado 1 h, Sin actividad 15 m, "Almuerzo 1 h (no cuenta)".
    - Aviso: "Tienes Mantenimiento preventivo en curso. Se finalizará como Completada a las 15:58."
    - "Ubicación de cierre capturada · precisión 9 m".
    - "Nota del día (opcional)".
    - Botones "Cerrar jornada" y "Seguir trabajando".
15. **Perfil**
    - Avatar, nombre, "Usuario móvil · Sede Bogotá Norte", "Supervisora: Laura Gómez".
    - "Mi horario": Campo L–V 07:00–16:00, almuerzo 12–13, 40 h semanales.
    - "Mi dispositivo": modelo, serie, "Administrado por SOTI MobiControl · última conexión hoy 10:09", link a revisión del dispositivo.
    - Menú con badges: Mis solicitudes "1 pendiente", Mi semana "31 h 20 m", Sincronización "Todo enviado", Política de datos "v1.0 aceptada", Ayuda y soporte.
    - "Cerrar sesión" y versión.
16. **Kiosco fuera de jornada**
    - Barra superior: "Dispositivo compartido · sesión de Andrés Mora" o "En jornada · apps de trabajo habilitadas", más "Administrado por MobiControl".
    - Título "Hola, Andrés" o "Jornada iniciada"; "Martes 3 de noviembre · Turno 07:00–16:00".
    - Simulador de hora: "06:55 · dentro de la tolerancia" / "05:40 · muy temprano".
    - Card "Apps de trabajo" con estado Bloqueadas / Habilitando / Habilitadas: Correo, Órdenes de trabajo, Inventario, Chat del equipo (atenuadas y con candado cuando están bloqueadas).
    - "Siempre disponibles: Teléfono para emergencias y WorkLog".
    - CTA "Iniciar jornada": bloqueado si es muy temprano; luego "Habilitando tus apps de trabajo…" y "Ir a mi jornada".
    - Hints:
      - "Tu turno empieza a las 07:00. Puedes iniciar desde las 06:50" (10 min antes).
      - "Al iniciar, WorkLog pide a MobiControl que habilite tus apps".
      - "Registrada a las 06:55. MobiControl aplicó el perfil «En jornada»".
      - "Se ocultan de nuevo al cerrar tu jornada o al terminar tu turno. Te avisaremos 15 y 5 minutos antes."
    - Link "Pedir autorización al supervisor" (si es muy temprano) y link a AvisoCierre.
17. **Aviso de fin de turno** (bottom sheet alertdialog sobre la actividad en curso)
    - Variantes por tipo de dispositivo: Dispositivo compartido / Asignado a mí.
    - Variantes por momento: 15:55 (15 min), 16:05 (5 min), 16:10 (cierre).
    - Título: "Tu sesión se cerrará en N min" (compartido) / "Tus apps se ocultarán en N min" (asignado). Subtítulo "Tu turno termina a las 16:00".
    - Cuerpo: "A las 16:10, después de los 10 minutos de gracia, …. Guarda tu trabajo y cierra tu jornada para registrar la hora real de salida."
    - Botones: "Cerrar jornada ahora", "Pedir horas extra al supervisor", "Entendido, seguir trabajando".
    - Al llegar al cierre:
      - Compartido: "Sesión cerrada"; "Tu jornada quedó pendiente de cierre para que tu supervisor la revise"; el dispositivo vuelve al ingreso de Shared Device; botón "Volver al ingreso".
      - Asignado: "Apps de trabajo ocultas"; vuelve al kiosco; botón "Ver kiosco".
    - Pie: "Aviso enviado por WorkLog y por MobiControl. Si tienes horas extra autorizadas, el cierre se corre hasta su fin" y "MobiControl aplicó el cambio a las 16:10. Queda en Auditoría."
    - Color del icono: ámbar a 15 min, rojo suave a 5 min o menos, gris al cerrar.

### Panel web (1440×1000, React)

- **Equipo hoy**
  - Header: "Jueves 29 de octubre · actualizado 10:42", selector Sede (Bogotá Norte/Sur), usuario "LG Laura Gómez · Supervisora".
  - 4 KPIs:
    - En actividad 8 de 14 usuarios.
    - En pausa 1 (almuerzo).
    - Sin actividad 2, "1 lleva más de 20 min" (borde ámbar).
    - Sin iniciar jornada 3, "1 tarde · 2 con novedad".
  - Filtros: Todos / Trabajando (actividad + pausa) / Sin actividad / Sin iniciar (incluye novedad). Buscador "usuario u OT".
  - Columnas de la tabla: Usuario (link), Estado (chip), Actividad, Sitio, Desde, Semana, Geocerca, Dispositivo.
  - Estados: En actividad, En pausa, Sin actividad, Sin iniciar, Vacaciones (novedad).
  - Valores de ejemplo:
    - Actividad: "— hace 38 min", "Turno desde 07:00 · 3 h 42 m tarde", "Vacaciones hasta el 6 nov".
    - Semana: "38 h 40 m · cerca del tope" en ámbar y negrita.
    - Geocerca: "Dentro", "Dentro · 6 m", "En ruta", "—".
    - Dispositivo: "En línea · 78%", "Batería baja · 12%", "Sin conexión desde ayer", "Apagado". Batería baja y sin conexión en ámbar.
  - Pie: "Mostrando 9 de 14 usuarios · Ver todos".
- **Aprobaciones**
  - Contador de pendientes. Layout lista + detalle.
  - Tabs: Todas / Ajustes / Horas extra / Cambios de turno.
  - Item: tipo, chip de estado (Pendiente/Aprobada/Rechazada), persona · título, resumen.
  - Detalle: tipo, título, "Enviada…", campos clave-valor, "Efecto en las horas" (lista de impactos).
  - Si está pendiente: "Comentario para el usuario (obligatorio si rechazas)", botones Aprobar / Rechazar.
  - Resuelta: "Aprobada. El usuario verá el cambio en su historial" / "Rechazada. El usuario recibirá tu comentario".
  - Ejemplo de ajuste:
    - Registro: OT-1042 · Almacén Norte.
    - Cambio: Fin 09:40 → 09:55.
    - Motivo: "Olvidé finalizar al salir del sitio".
    - Ubicación a las 09:55: "Dentro de la geocerca · 8 m".
    - Impacto: "Productivo 2 h 28 m → 2 h 43 m; Sin actividad 12 m → 0 m".
  - Ejemplo de horas extra:
    - Horario: 16:00–18:00 (diurnas).
    - Motivo.
    - "Autorización Mintrabajo: Vigente · [NÚMERO DE RESOLUCIÓN]".
    - Impacto: "Semana: 40 h ordinarias + 2 h extra; Extra usadas: 2 de 12 en la semana, 2 de 2 en el día".
  - Ejemplo de cambio de turno:
    - Turno actual: Viernes 30 07:00–16:00.
    - Propuesto: Viernes 07:00–12:00 y sábado 07:00–10:00.
    - Motivo: cita médica.
    - Impacto: "40 h → 40 h, sin horas extra; Sábado dentro de la jornada de 6 días".
- **Horas del equipo**
  - Subtítulo "Semana del 26 al 30 oct · cifras al jueves 29, 10:42 · provisionales". Toggle "Solo con alertas". Botón Exportar.
  - Leyenda: Ordinarias (#AF1839), Nocturnas (#3C3C3B), Extra (#DA830B), marca "Tope legal 42 h" (#1E1F1D). Nota: "Extra: máximo 2 h al día y 12 h a la semana, con autorización vigente".
  - Columnas: Usuario, Semana frente al tope (barra apilada 0–54 h), Total, Extra ("X de 12 h"), Dom. y fest., Alerta.
  - Alertas: "Pasó 42 h" (rojo), "Cerca del tope" (≥38 h, ámbar), "Extra en uso" (gris), "—".
- **Plantillas de horario**
  - Lista: nombre, chip Válida/No cumple, línea "LMXJV · 07:00–16:00 · 40 h/sem", uso ("12 personas · Sede Bogotá Norte", "Sin asignar · del primer diseño", "Borrador · sin asignar").
  - Editor:
    - Nombre.
    - Días L M X J V S D (toggle).
    - Steppers Entrada / Salida / Almuerzo (±30 min).
    - Horas por día y por semana calculadas.
    - Validaciones (Cumple / No cumple / Aviso).
    - Nota de recargo nocturno.
  - Botón "Guardar plantilla", bloqueado si no es válida.
  - Mensajes:
    - "Escribe el nombre…".
    - "Ya existe una plantilla con ese nombre".
    - "Corrige lo que no cumple…".
    - "Plantilla creada. Ya se puede usar en Asignaciones".
    - "Aplica a nuevas asignaciones desde la fecha que elijas".
  - Botón "Nueva plantilla".
  - Ejemplos:
    - Campo L–V: 07:00–16:00, almuerzo 60.
    - Administrativo L–V: 08:00–17:00, almuerzo 60.
    - Media jornada L–S: 07:00–11:00, almuerzo 0.
    - Campo L–S (anterior): 07:00–17:00, almuerzo 0, no cumple.
- **Asignaciones y calendario**
  - Formulario "Nueva asignación":
    - Aplica a: Persona / Grupo / Sede.
    - Destino: personas, grupos (Instalaciones, Mantenimiento, Administrativo) o sedes.
    - Horario (plantilla) y "Desde" (fecha).
    - Hint de precedencia.
    - Botones "Crear asignación" / "Cancelar".
    - Errores: "Elige la persona/el grupo/la sede", "Elige la fecha de inicio", "Ya existe una asignación igual desde esa fecha".
    - Éxito: "Asignación creada: X para Y desde el D. El calendario ya la usa".
  - "Asignaciones vigentes": nivel, tag "Nueva", destino, "plantilla · desde el D".
  - "Ver calendario de": selector de persona con nota ("Instalaciones · vacaciones del 3 al 13 nov").
  - Calendario mensual (Lun–Dom, 42 celdas):
    - Título "Persona · noviembre de 2026".
    - "Programadas: N h".
    - "Turno según: Sede Bogotá Norte (Campo L–V) · …".
    - Leyenda: Turno, Novedad, Cambio puntual, Festivo o descanso.
    - Tipos de celda: turno (nombre de plantilla y horas), Vacaciones "Novedad aprobada", Cambio (horas, borde punteado), Festivo (nombre), Descanso, "Sin horario · No hay asignación".
- **Parámetros**: ver §3. Header "Tu rol: Administrador".
  - Selector de nivel: Global · producto / País · Colombia / País · México / Empresa · INTECHSYS / Sede · Bogotá Norte (Colombia), más "+ Agregar país".
  - Tabla: Parámetro (grupo y nombre), Valor, "Viene de" (chip: Este nivel / Global / Colombia / Empresa / Sin definir), Acción (Editar o "Se edita en el país").
  - Panel lateral de edición:
    - Nombre y ayuda; "Heredado de X" o "Valor actual"; "Rango permitido".
    - Stepper "Nuevo valor"; "Aplica desde" (fecha).
    - "Norma o soporte del cambio (obligatorio)" si es legal.
    - Texto de impacto.
    - Botones "Guardar" / "Usar el heredado".
  - Card "Reglas de {país}" (Validadas/Borrador) con checklist, campo "Asesor laboral que validó", botones "Cargar festivos del año" / "Marcar como validadas".
  - Modal "Agregar país":
    - Búsqueda en lista ISO (sin acentos).
    - Punto de partida "Desde cero" / "Copiar valores de Colombia".
    - Botón "Crear país en borrador".
- **Actividades y resultados**
  - Tabla del catálogo: Actividad (tag "Nueva"), Categoría (con color), Foto Sí/No, Firma Sí/No, Observación Siempre/Opcional, Activa/Inactiva. Todas son toggles inline.
  - Formulario "Nueva actividad": nombre, categoría, "Al finalizar exige" Foto / Firma del cliente / Observación (multi).
  - Validaciones: nombre ≥3 y único. Mensaje: "Aparece en el catálogo de la app en la siguiente sincronización".
  - "Resultados de cierre": Completada (La actividad terminó, sin observación), Incompleta (Quedó trabajo pendiente, pide observación), Reprogramar (Se mueve a otra fecha, pide observación), con toggle "Pide observación / Sin observación".
  - "Categorías": nombre · cómo cuenta el tiempo. Formulario: nombre, cómo cuenta (Productivo / Pagado, no productivo / Improductivo), color de una paleta de 6.
  - Ejemplos de actividades:
    - Instalación de equipo: Productivo, foto y firma.
    - Mantenimiento preventivo: foto.
    - Visita técnica: firma.
    - Revisión de garantía: foto, firma y observación.
    - Traslado entre sitios: Traslado.
    - Labores administrativas: Interna.
    - Capacitación: Interna.
    - Espera de materiales: Improductivo, observación.
    - Inventario de bodega: inactiva.
- **Sitios y geocercas**
  - Lista: nombre, dirección, "Círculo de N m · K OT esta semana" o "· sede".
  - Mapa ilustrativo ("en producción, MapLibre con mapa base") con puntos del día dentro/fuera (verde/ámbar), contadores "Puntos de hoy dentro 5 de 8 · Fuera de la geocerca 3".
  - Formulario: Nombre, Dirección, Forma (Círculo/Polígono), Radio con stepper ±10 m.
  - Botones "Crear sitio" / "Guardar sitio", "Descartar" (borrador).
  - Validaciones: nombre ≥2 y único.
  - Polígono: "haz clic en el mapa para marcar cada esquina".
  - Ejemplos: Almacén Norte 120 m, Bodega Sur 80, Oficina Centro 60, Sede Bogotá Norte 150.
- **Cierre de periodo**
  - Header: "Quincena del 16 al 31 de octubre de 2026 · Sede Bogotá Norte · abierto, listo para revisar / cerrado". Selector de periodo (incluye "1–15 oct 2026 (cerrado)").
  - Columnas: Usuario, Ord. diurnas, Ord. noct., Extra diurnas, Extra noct., Dom. y fest., Novedades (texto), Estado (Pendiente/Listo/Cerrado), con fila Total.
  - Panel "Antes de cerrar":
    - Aviso de solicitudes pendientes (n y nombres) con link a Aprobaciones.
    - Checklist obligatorio (3): "Revisé las alertas de horas del equipo", "Revisé las novedades del periodo", "Resolví las solicitudes pendientes".
    - Botón "Cerrar periodo" (bloqueado hasta completar el checklist) y el texto de congelamiento.
  - Cerrado: "Por Laura Gómez", "Exportar para nómina: Excel (.xlsx) / CSV", "Reabrir (solo administrador)".
- **Novedades**
  - Texto: "Mientras dure una novedad el usuario no tiene turno".
  - Tabs: Todas / Vacaciones / Incapacidades / Licencias / Permisos.
  - Columnas: Usuario, Tipo, Fechas, Días háb., Soporte, Estado (botón Aprobar o "Aprobada").
  - Formulario "Registrar novedad":
    - Usuario (select).
    - Tipo: Vacaciones / Incapacidad / Licencia / Permiso / Compensatorio.
    - Desde / Hasta.
    - "Adjuntar soporte (PDF o foto)".
    - Cálculo "Se descontarán 2 días hábiles. El usuario verá «Hoy no tienes turno» esos días".
    - Botón Registrar (queda Pendiente y "Sin soporte").
  - Ejemplos: "Falta el soporte de la EPS" (ámbar); permiso por horas "10 nov · 14:00–16:00 · 2 h"; compensatorio.
- **Auditoría**
  - Texto: "Registro de solo lectura: nadie puede editarlo ni borrarlo, ni siquiera un administrador." Botón Exportar.
  - Filtros:
    - Origen (tabs): Todo / Panel web / App / Sistema.
    - Entidad: Todas / Registros / Parámetros / Horarios / Ubicación.
    - Desde (fecha).
  - Tabla: Fecha, Quién, Qué pasó, Origen (chip).
  - Detalle:
    - Fecha y hora completa con segundos, más "(recibido 08:20)" para eventos offline.
    - Quién · rol.
    - Entidad.
    - Origen largo: "Panel web · navegador" / "App móvil · Android" / "Proceso automático del servidor".
    - Antes / Después.
  - Ejemplos de eventos:
    - Cambio de parámetro.
    - Solicitud de ajuste.
    - "Consultó la ubicación de un usuario" (14 puntos).
    - "Inició actividad sin conexión".
    - Solicitud de horas extra.
    - "Sistema · Regla de cierre automático · Cerró una jornada al fin del turno".
    - Crear plantilla.
    - Desactivar plantilla ("no cumple el tope de 42 h").
- **Usuarios y roles**
  - Tabs: Usuarios / Roles y permisos. Botón "Invitar usuario".
  - Tabla de usuarios: Nombre y email, Rol, Sede, Grupo, Estado (Activo/Inactivo/Invitado).
  - Panel de edición:
    - Rol (chips con 5 roles).
    - Campos: Sede, Grupo, Supervisor, Horario, Dispositivo ("[MODELO] · en línea · batería 78%" / "sin conexión desde…" / "apagado (vacaciones)" / "Solo panel web" / "Sin dispositivo vinculado"), Grupo MobiControl, Política de datos ("v1.0 aceptada el 29 oct" / "Pendiente").
    - Botones Guardar, "Desvincular dispositivo", "Desactivar/Activar usuario".
  - Tab de permisos: matriz Permiso × Rol con toggles. La columna Administrador está bloqueada.
- **Invitar usuario** (wizard de 3 pasos)
  - Pasos:
    1. Datos: nombre completo, correo corporativo (validación de formato y duplicado: "Ya existe un usuario con este correo: Andrés Mora"), "Cómo usará WorkLog": Usuario móvil / Solo panel web.
    2. Rol y horario: rol (móvil: Usuario móvil o Supervisor; panel: Supervisor / RR. HH. / Nómina / Administrador), Sede, Grupo, Supervisor, Desde, Horario (plantilla con "07:00–16:00 · 40 h/sem · válida").
    3. Dispositivo:
       - Móvil: lista de dispositivos MobiControl sin usuario (serie, grupo MC, "inscrito el 30 oct", estado "En línea · 92%" / "Sin conexión desde el 31 oct") y opción "Asignar después" ("no podrá iniciar jornada hasta tener dispositivo").
       - Panel: "no necesita dispositivo, recibirá un correo".
  - Panel "Resumen" y "Qué pasa después" (MobiControl instala, la app se identifica con el id del dispositivo, el usuario ingresa y acepta la política, pasa a Activo, todo queda auditado).
  - Al enviar: "Invitación enviada", con los botones "Ver usuarios" / "Invitar a otra persona".
- **Organización** (tabs Sedes / Grupos / Roles; "Solo los administradores pueden cambiarlos")
  - **Sedes**
    - Cards: nombre, estado (Activa/Inactiva/Borrador), ciudad y país · zona horaria, "N grupos · M personas".
    - Editor:
      - Nombre.
      - País: combobox ISO 3166 con "Código ISO CO" y "Cambiar".
      - Ciudad: combobox GeoNames filtrado por país; mínimo 2 caracteres; muestra departamento, país y código DANE; deshabilitado sin país.
      - Sitio principal (chips más "+ Crear sitio", que crea un círculo de 100 m).
      - Horario por defecto.
      - Solo lectura: Festivos ("Festivos de Colombia"), Zona horaria ("America/Bogota · se toma de la ciudad"), Reglas laborales ("Ley 2101 de 2021 y CST" / "Por configurar").
    - Botones Guardar/Crear sede, Desactivar/Activar/Descartar.
  - **Grupos**
    - Tabla: Grupo, Sede, Supervisor, Grupo MobiControl ("— (solo panel web)"), Personas.
    - Editor: nombre, sede (solo activas), supervisor (incluye "Sin asignar"), horario por defecto, Grupo MobiControl (texto tipo "INTECHSYS / Campo / Medellín"; sirve para sugerir el grupo al invitar).
  - **Roles**
    - Lista: nombre, "N personas · M permisos", tipo (Fijo / Base / Personalizado).
    - Detalle "Permisos de X" con link a Usuarios y roles.
    - "Nuevo rol": nombre (más de 2 caracteres, único) y "Copiar permisos de" (roles no fijos).
- **Control de dispositivos**
  - Switch "Apps corporativas solo en jornada" (aplica a Shared Device y asignados). No se puede activar si falla la verificación.
  - Verificación MobiControl (5 checks):
    - Conexión con MobiControl ("Configurada en INTECHSYS ONE · versión 2026.0").
    - Perfil «WorkLog · Fuera de jornada» (Lockdown con WorkLog y Teléfono).
    - Perfil «WorkLog · En jornada» (Lockdown con WorkLog y apps corporativas).
    - Atributo WL_JORNADA y filtros de asignación (valores ABIERTA / CERRADA).
    - "Shared Device abre WorkLog al ingresar".
  - Resumen "Todo listo en MobiControl / 1 punto pendiente" y botón "Verificar de nuevo".
  - Reglas:
    - Alcance: sedes/grupos (multi): Bogotá Norte, Bogotá Sur, Medellín, Grupo Administrativo.
    - Avisos antes del cierre (multi): 30/15/10/5 min.
    - Gracia: Sin gracia / 5 / 10 / 15 min.
    - Inicio antes del turno: 5 / 10 / 15 min.
    - Preview: "se puede iniciar desde 06:50; avisos a las 15:55 y 16:05; cierre a las 16:10".
    - Switch "cerrar sesión de Shared Device al cerrar la jornada".
    - "Si MobiControl no responde al iniciar la jornada": "Dejar iniciar la jornada y avisar al administrador" / "No dejar iniciar hasta que MobiControl responda".
  - "Apps del dispositivo" (del catálogo de MobiControl): dos columnas "Solo en jornada" ↔ "Siempre disponibles" con botones mover. WorkLog y Teléfono son fijas. Ejemplos de paquetes: com.[EMPRESA].mail / .ot / .inventario / .chat, com.android.camera, com.google.android.apps.maps.
  - "Dispositivos ahora": dispositivo, quién, tipo (Compartido/Asignado), "Jornada Abierta/Cerrada · desde", "Orden a MobiControl: Aplicada / En cola · sin conexión". Link a Auditoría y a las vistas Kiosco/Aviso.
  - Botón "Guardar cambios". Validaciones al guardar:
    - Con el switch encendido: al menos un alcance y al menos un aviso.
    - Éxito encendido: "WorkLog empezará a enviar órdenes a MobiControl en los próximos minutos. Queda en Auditoría".
    - Éxito apagado: "La opción está apagada: los dispositivos no cambian".

---

## 2. Modelo de dominio inferido

### Organización y estructura

- **País**: Code (ISO 3166 alfa-2), Name.
  - Paquete de reglas legales: State {Borrador, Validadas}, ValidatedBy (asesor laboral), ValidatedAt, CopiedFrom (opcional), HolidaysLoaded por año.
  - Base legal (texto, p. ej. "Ley 2101 de 2021 y CST", "Por configurar").
  - Festivos (Date, Name). Ej.: 2 nov "Todos los Santos", 16 nov "Independencia de Cartagena".
- **Ciudad** (catálogo GeoNames): Id, Name, Region/Departamento, CountryCode, TimeZone (IANA), DaneCode (opcional, Colombia).
- **Empresa/Organización (tenant)**: Name ("INTECHSYS"). Es un nivel de parámetros.
- **Sede**: Id, Name, CountryCode, CityId. Derivados de la ciudad y el país: TimeZone, festivos y reglas. Además: PrincipalSiteId, DefaultScheduleTemplateId, Status {Activa, Inactiva, Borrador}, conteos de grupos y personas.
- **Grupo**: Id, Name, SedeId, SupervisorUserId (nullable, "Sin asignar"), DefaultScheduleTemplateId, MobiControlGroupPath (string), Active, conteo de personas.
- **Sitio**: Id, Name, Address, Shape {Círculo, Polígono}, Center (lat, lng), RadiusM (30–500), PolygonVertices[], Draft. Relación: OT por semana. Puede ser el "sitio principal" de una sede.

### Usuarios y seguridad

- **Usuario**:
  - Id, FullName, Email corporativo (único).
  - Usage {Usuario móvil, Solo panel web}, RoleId.
  - SedeId ("Todas" para roles globales), GroupId, SupervisorId.
  - ScheduleTemplate (vía asignación) y fecha "Desde".
  - DeviceId (nullable).
  - Status {Invitado, Activo, Inactivo}.
  - PolicyAcceptance (versión y fecha, o "Pendiente").
- **Rol**:
  - Id, Name, Kind {Base, Fijo, Personalizado}.
  - Base: Usuario móvil (tec), Supervisor (sup), Recursos humanos (rh), Nómina (nom), Administrador (adm, fijo).
  - Permisos[]; "copiar permisos de" al crear.
- **Permiso** (12): ver_propio, registrar, ver_equipo, ver_ubicacion, aprobar, novedades, cerrar, exportar, horarios, parametros, usuarios, auditoria. Grupos: Mi información / Equipo / Periodo / Configuración.
- **Invitación**: Name, Email, Usage, Role, Sede, Group, Supervisor, StartDate, TemplateId, DeviceId o "Asignar después", Status. Envía correo si el usuario es solo de panel.
- **Consentimiento / Política de datos**: PolicyVersion ("1.0", vigente desde fecha), texto, UserAcceptance (UserId, Version, AcceptedAt, Device).

### Dispositivos (SOTI MobiControl)

- **Dispositivo**:
  - DeviceId de MobiControl, Model, Serial.
  - MobiControlGroupPath ("INTECHSYS / Campo / Bogotá Norte"), EnrolledAt.
  - Kind {Compartido (Shared Device), Asignado}.
  - Online, BatteryPct, LastSeenAt, estado (En línea / Sin conexión desde… / Apagado / Batería baja).
  - AssignedUserId, sesión actual.
- **Revisión de permisos del dispositivo**: Permission {Ubicación siempre, Notificaciones, Cámara, Sin optimización de batería, Configuración de la app} × Status {Por política, Falta}. Al fallar se notifica a soporte TI.
- **Política de control de apps** (configuración por empresa):
  - Enabled.
  - Scope (sedes/grupos).
  - WarningsMinutes[] ⊂ {30, 15, 10, 5}.
  - GraceMinutes ∈ {0, 5, 10, 15}.
  - EarlyStartMinutes ∈ {5, 10, 15}.
  - LogoutSharedOnClose (bool).
  - OfflineMode {allow (dejar iniciar y avisar al admin), block}.
  - CorporateApps[] (paquetes "solo en jornada") y AlwaysAvailableApps[]. WorkLog y Teléfono son fijas.
- **Verificación MobiControl**: 5 checks (conexión y versión, perfil Fuera de jornada, perfil En jornada, atributo WL_JORNADA = ABIERTA/CERRADA con filtros, Shared Device con WorkLog como app de inicio).
- **Orden a MobiControl**: DeviceId, UserId, Type (aplicar perfil En jornada / Fuera de jornada, cerrar sesión), Status {Aplicada, En cola · sin conexión}, timestamps. Se audita.

### Horarios

- **Plantilla de horario**: Id, Name (único), Days[7] (L M X J V S D), Start (min), End (min), LunchMinutes. Derivados: horas por día y por semana. Estado: Válida / No cumple, Borrador, Activa/Inactiva. Uso: n.º de personas y sede.
- **Asignación**: Id, Level {Sede, Grupo, Persona}, TargetId, TemplateId, FromDate (sin fecha fin visible), Tag "Nueva".
- **Cambio puntual de turno** (de una solicitud aprobada): UserId, Date, Start–End, minutos.
- **Turno efectivo del día** (calculado): Turno (plantilla) | Novedad | Cambio puntual | Festivo | Descanso | Sin horario. También se calcula la fuente ("Turno según: …").

### Jornada y actividades

- **Jornada**:
  - Id, UserId, Date, SedeId.
  - StartAt (hora del servidor), StartLocation (dentro/fuera de geocerca, precisión).
  - EndAt, EndLocation.
  - Status {Abierta/activa, Cerrada, Pendiente de cierre (revisión del supervisor), Cerrada automáticamente}.
  - CloseType {manual, automático}.
  - Nota del día.
  - Totales provisionales: productivo, traslado, sin actividad, almuerzo (no cuenta), total.
  - Indicador de tardanza (p. ej. "3 h 42 m tarde").
- **Catálogo de actividades**: Id, Name (único), CategoryId, RequirePhoto, RequireSignature, ObservationRequired {Siempre, Opcional}, Active.
- **Categoría de actividad**: Name (único), Color (de la paleta), TimeKind con 3 valores:
  - prod: Productivo, "cuenta como tiempo productivo".
  - pag: Pagado, no productivo, "tiempo pagado, no productivo".
  - imp: Improductivo, "se reporta como sin actividad".

  Categorías base: Productivo (#AF1839, prod), Traslado (#868787, pag), Interna (#3C3C3B, pag), Improductivo (#DA830B, imp). En la app aparecen etiquetas "Desplazamiento", "Interna", "Tiempo improductivo".
- **Orden de trabajo (OT) / actividad asignada**: Number ("OT-1042"), ActivityTypeId, SiteId, UserId, ScheduledDate y hora (10:00), Status. Fuente externa probable (app "Órdenes de trabajo").
- **Registro de actividad (ejecución)**:
  - Id, JornadaId, ActivityTypeId, WorkOrderId (nullable), SiteId.
  - StartAt, EndAt, Status {En curso, En pausa, Finalizada}.
  - Result {Completada (ok), Incompleta (partial), Reprogramar (resched)}.
  - Observation.
  - StartLocation y EndLocation (geocerca dentro/fuera y precisión).
  - AutoFinished (al cambiar de actividad o cerrar la jornada).
- **Pausa**: ActivityRecordId, StartAt, EndAt. El tiempo máximo es un parámetro. Aparece "En pausa · almuerzo".
- **Segmento de tiempo** (derivado para la timeline): Type {Productivo, Traslado, Sin actividad, Pausa/Almuerzo, Inicio de jornada}, Start, End, Color. "Sin actividad" son los huecos entre actividades.
- **Resultado de cierre (catálogo)**: Name, Description, RequiresObservation. Valores: Completada / Incompleta / Reprogramar.
- **Evidencia**: Id, ActivityRecordId, Type {Foto, Firma del cliente}, File (tamaño, p. ej. 1,8 MB), CapturedAt, UploadStatus {En cola, Espera wifi, Subido}. Hay contador ("1 foto", "Foto 1 de 2").
- **Punto de ubicación**: UserId, JornadaId, ActivityRecordId?, Timestamp, Lat, Lng, AccuracyM, Event {inicio jornada, inicio/cambio/fin de actividad, muestreo periódico, cierre}, InsideGeofence (bool o null si la precisión es insuficiente). Las consultas del supervisor se auditan.

### Solicitudes y novedades

- **Solicitud** (de la app):
  - Id, UserId, Type con 3 valores: Ajuste de registro (aj), Horas extra (he), Cambio de turno (ct). Además existe una posible "autorización de inicio anticipado" (ver §7).
  - Title, Detail, Reason/Motivo.
  - Payload según el tipo:
    - Ajuste: RecordId, campo, antes → después, ubicación a la hora propuesta.
    - Horas extra: fecha, rango, diurnas/nocturnas, autorización Mintrabajo vigente (n.º de resolución).
    - Cambio de turno: turno actual, turno propuesto.
  - SentAt, Channel ("desde la app"), ApproverId.
  - Status {Pendiente, Aprobada, Rechazada}, ResolverComment (obligatorio al rechazar), ResolvedAt.
  - Impacto calculado en horas.
- **Novedad**:
  - Id, UserId.
  - Type con 5 valores: Vacaciones (vac), Incapacidad (inc), Licencia (lic), Permiso (perm), Compensatorio (comp).
  - From, To, posible rango horario (permiso por horas), BusinessDays u horas.
  - Support (PDF/foto; estado faltante).
  - Status {Pendiente, Aprobada}. No se ve "Rechazada" en Novedades.
  - ApprovedBy.

### Horas y cierre

- **Clasificación de horas por usuario y periodo**: Ordinarias diurnas, Ordinarias nocturnas, Extra diurnas, Extra nocturnas, Dominical y festivo, Novedades (texto). Vista semanal con total, extra y alertas.
- **Periodo de nómina**: SedeId, Type (quincena), From, To, Status {abierto, cerrado}, ClosedBy, ClosedAt, checklist (3 bools), estado por usuario {Pendiente, Listo, Cerrado}. Exportación xlsx/csv. Reapertura solo por administrador.

### Parámetros

- **Definición de parámetro**: Id, Group, Name, Unit, Min, Max, Step, Help, IsLegal, Default.
- **Valor de parámetro**:
  - Level {Global, País:XX, Empresa, Sede}, Value, EffectiveFrom (fecha), Norma/soporte (si es legal).
  - Cadena de herencia para una sede: Global → País → Empresa → Sede.
  - Cadena para un país: Global → País. Para la empresa: Global → Empresa.

### Auditoría, notificaciones y sincronización

- **Evento de auditoría** (inmutable):
  - Id, OccurredAt (segundos), ReceivedAt (si fue offline).
  - ActorUserId o "Sistema", ActorRole (o la regla, p. ej. "Regla de cierre automático").
  - Action (texto).
  - EntityType {Registros, Parámetros, Horarios, Ubicación; más Jornada, Plantilla, Horas extra, Usuarios, Dispositivos/órdenes MC, Permisos}, EntityRef.
  - Origin {Panel web, App, Sistema}, con descripción larga "Panel web · navegador" / "App móvil · Android" / "Proceso automático del servidor".
  - Before, After.
- **Notificación**:
  - Fija de jornada: actividad, cronómetro, botones Pausar/Finalizar.
  - Recordatorio por inactividad.
  - Aviso de fin de turno (15 y 5 min).
  - Recordatorio si no inicia jornada (al usuario y al supervisor).
  - Aviso por pausa excedida.
  - Resolución de solicitud.
  - Aviso a soporte TI por un permiso faltante.
  - Aviso al administrador si MobiControl no responde.
- **Cola de sincronización offline** (cliente):
  - Evento: tipo (Pausa, Reanudar, Finalizar actividad, Inicio jornada…), timestamp local, payload, estado {En cola, Espera wifi, Enviado, Rechazado por el servidor (con motivo y valor corregido)}.
  - Archivo: tamaño, solo wifi o datos móviles.
  - Datos: LastSyncAt, "Sin conexión desde".

---

## 3. Reglas de negocio y parámetros

### Parámetros configurables (valores de ejemplo)

| Id | Grupo | Nombre | Unidad | Rango / paso | Global | Otros niveles |
|---|---|---|---|---|---|---|
| ant | Jornada | Inicio anticipado permitido | min antes | 0–60 / 5 | 15 | |
| tol | Jornada | Tolerancia de llegada (después se marca tarde) | min | 0–30 / 5 | 5 | Sede Bogotá Norte = 10 (desde 3 nov) |
| rec | Jornada | Recordatorio si no inicia (al usuario y al supervisor) | min después | 5–60 / 5 | 15 | |
| rad | Ubicación | Radio de geocerca por defecto | m | 30–500 / 10 | 100 | |
| pre | Ubicación | Precisión GPS mínima (con peor precisión el punto se guarda pero no valida geocerca) | m | 10–200 / 10 | 50 | |
| mue | Ubicación | Muestreo en actividad | min | 5–60 / 5 | 15 | |
| ina | Avisos | Aviso por inactividad | min | 5–60 / 5 | 20 | |
| fin | Avisos | Aviso de fin de turno (antes del cierre automático) | min antes | 5–60 / 5 | 15 | |
| paus | Pausas | Duración máxima de pausa (al pasarla se avisa) | min | 10–120 / 5 | 30 | |
| top | Legal | Tope semanal | h | 30–60 / 1 | default 42 | CO = 42 |
| noc | Legal | Inicio de franja nocturna | hora | 18–22 / 1 | default 20 | CO = 19 (19:00) |
| dom | Legal | Recargo dominical y festivo | % | 0–200 / 5 | default 25 | CO = 90 |

Reglas de los parámetros:
- **Herencia**: gana el valor del nivel más específico. La UI muestra "Viene de" y permite "Usar el heredado" (borra el override). Global no hereda de nadie.
- **Parámetros legales**:
  - Solo se editan en el nivel País. En Global y Empresa no se muestran; en Sede aparecen con "Se edita en el país".
  - Exigen "Norma o soporte del cambio" (≥5 caracteres).
  - Cambian el cálculo desde la fecha elegida. Las horas ya cerradas no se recalculan.
  - Guardar uno en un país con reglas "Validadas" las devuelve a Borrador.
- Los parámetros no legales se aplican en la siguiente sincronización de cada dispositivo. Todo cambio queda en auditoría.
- **Validación del paquete legal de un país**: requiere 3 de 3 reglas legales completas, festivos del año cargados y el nombre del asesor laboral (≥3 caracteres). Mientras esté en Borrador, las sedes de ese país registran jornada pero no se calculan horas extra ni recargos.
- **Nuevo país**:
  - "Desde cero": reglas legales vacías; el resto se hereda de Global.
  - "Copiar valores de Colombia": se marcan para revisar ("no son la ley del nuevo país").

### Jornada, turno y control de dispositivos

- Solo se puede iniciar jornada en días con turno. Con una novedad aprobada o un día sin turno (festivo, descanso, sin asignación), el botón queda deshabilitado y no se registra ubicación.
- **Ventana de inicio**:
  - Se puede iniciar desde turno − inicio anticipado. Hay valores inconsistentes entre pantallas (ver §7).
  - Si es muy temprano, el inicio se bloquea y se ofrece "Pedir autorización al supervisor".
  - Si se envía antes de la ventana estando offline, el servidor lo rechaza o corrige al inicio de la ventana (06:41 → registrado 06:45).
- Se usa la hora del servidor.
- **Tardanza**: llegada después de turno + tolerancia. Se ve en el panel ("3 h 42 m tarde") y en los KPIs ("1 tarde").
- **Actividades**:
  - Solo una actividad en curso a la vez. Iniciar otra finaliza la actual automáticamente a esa hora.
  - Al cerrar la jornada, la actividad en curso se finaliza como "Completada" a la hora de cierre.
- **Finalización**:
  - Se exige resultado.
  - Foto, firma y observación según la actividad.
  - Observación obligatoria según el resultado (Incompleta y Reprogramar la piden).
  - Se captura la ubicación con su precisión.
- **Geocerca**: se valida al iniciar y al finalizar cada actividad y al iniciar la jornada. Precisión mínima de 50 m.
- **Ubicación**: solo durante la jornada. Se registra en cada inicio, cambio y fin de actividad, y cada 15 min (muestreo).
- **Clasificación del tiempo**:
  - Productivo según la categoría.
  - Traslado e Interna se pagan pero no son productivos.
  - Improductivo se reporta como "Sin actividad".
  - Los huecos entre actividades son "Sin actividad".
  - El almuerzo no cuenta.
- **Avisos**:
  - Inactividad a los 20 min (notificación al usuario; el panel resalta "más de 20 min").
  - Pausa > 30 min.
  - Fin de turno 15 y 5 min antes.
  - No inicio a los 15 min (al usuario y al supervisor).
- **Cierre automático**: al fin del turno + gracia (10 min, a las 16:10). Si hay horas extra autorizadas, el cierre se corre hasta su fin. El resultado difiere entre pantallas (ver §7).
- **Control de apps**:
  - Al iniciar la jornada, WorkLog pide a MobiControl aplicar el perfil «En jornada» (atributo WL_JORNADA=ABIERTA). Al cerrar la jornada o terminar el turno vuelve a «Fuera de jornada» (kiosco con WorkLog y Teléfono).
  - En dispositivos compartidos, al cerrar la jornada se cierra la sesión de Shared Device (configurable).
  - No se puede activar la opción si alguna verificación falla.
  - Al guardar con la opción encendida se exige al menos un alcance y al menos un aviso.
  - Si MobiControl no responde al iniciar: dejar iniciar y avisar al administrador, o bloquear (por defecto: dejar iniciar).
- **Desvincular dispositivo**: cierra la sesión de WorkLog en ese dispositivo y se pierde lo que estaba en cola sin sincronizar.
- Un usuario móvil sin dispositivo no puede iniciar jornada.

### Horas legales (Colombia)

- Tope de 42 h semanales ordinarias (Ley 2101 de 2021). Lo que pase es suplementario.
- Horas extra: máximo 2 h al día y 12 h a la semana, solo con autorización vigente (resolución de Mintrabajo).
- Barra visual de 0 a 54 h (42 + 12).
- Alertas: ≥42 h "Pasó 42 h"; ≥38 h "Cerca del tope"; extra > 0 "Extra en uso".
- Recargo nocturno del 35% desde las 19:00. Recargo dominical y festivo del 90%. Jornada de 5 o 6 días ("Sábado dentro de la jornada de 6 días").
- Las horas de la app son "provisionales" hasta el cierre del periodo.

### Plantillas

Validaciones bloqueantes:
- Entre 4 y 9 horas diarias (240–540 min netos de almuerzo).
- Máximo 42 h semanales.
- Repartidas en 5 o 6 días.

Validaciones no bloqueantes:
- Aviso si incluye domingo (recargo del 90%).
- Nota si la salida es después de las 19:00 (recargo nocturno del 35%).

Controles del editor:
- Entrada: mínimo 05:00; al menos 60 min antes de la salida.
- Salida: máximo 23:00.
- Pasos de 30 min.
- Almuerzo: 0–120 min.
- Nombre de ≥3 caracteres, único sin distinguir mayúsculas.

Las plantillas aplican a nuevas asignaciones desde una fecha. Una plantilla que no cumple se desactiva (caso auditado).

### Asignaciones y calendario

- Precedencia del turno del día, de mayor a menor:
  1. Novedad aprobada.
  2. Cambio puntual.
  3. Asignación a la persona.
  4. Asignación al grupo.
  5. Asignación a la sede.
- Dentro del mismo nivel gana la fecha "desde" más reciente que sea ≤ al día.
- Si no hay asignación: "Sin horario".
- Los días fuera de la plantilla son "Descanso". Los festivos del país se marcan.
- En el calendario, los festivos se evalúan antes que el cambio puntual y las vacaciones solo marcan días hábiles (L–V).
- No puede haber dos asignaciones con el mismo nivel, destino y fecha desde.
- Por defecto se usa el horario de la sede o del grupo.

### Novedades

- Durante una novedad no hay turno: la app no deja iniciar jornada ni registra ubicación.
- Se descuentan días hábiles. El permiso puede ser por horas.
- El soporte es opcional al registrar y se marca cuando falta.
- La novedad requiere aprobación.

### Solicitudes y aprobaciones

- El supervisor aprueba ajustes, horas extra y cambios de turno.
- El comentario es obligatorio al rechazar.
- El usuario ve el resultado en su historial y en Mis solicitudes.
- Al aprobar un ajuste se recalculan productivo y sin actividad del día.

### Cierre de periodo

- Periodo quincenal por sede.
- Para cerrar se requieren los 3 checks. El aviso de solicitudes pendientes no bloquea por sí solo; es el check "Resolví…" el que lo exige.
- Al cerrar, las horas quedan congeladas. Cualquier cambio posterior entra como ajuste en el periodo siguiente.
- Solo el administrador puede reabrir.
- Exportación a xlsx o csv.

### Auditoría

- Es inmutable: no se puede editar ni borrar, ni siquiera un administrador.
- Se registran: cambios de parámetros, solicitudes, consultas de ubicación, eventos offline (con hora de recepción), cierres automáticos, plantillas, permisos, órdenes a MobiControl, el proceso de invitación y activación, y la configuración de dispositivos.

### Organización

- No se puede desactivar una sede o un grupo con personas asignadas ("Muévelas antes de desactivarlo").
- Nombres únicos: sede y grupo con ≥2 caracteres; rol con más de 2.
- La sede requiere país y ciudad elegidos de la lista. La zona horaria sale de la ciudad; festivos y reglas, del país.
- Un sitio creado desde una sede nace como círculo de 100 m.

### Usuarios e invitaciones

- El usuario queda "Invitado" hasta su primer ingreso; después pasa a Activo.
- Un usuario móvil solo puede tener rol Usuario móvil o Supervisor. Un usuario solo de panel no puede ser Usuario móvil.
- El email debe ser válido y único.
- Un dispositivo solo se puede elegir si está inscrito en MobiControl y no tiene usuario.
- El grupo MobiControl del dispositivo sugiere el grupo de WorkLog.

### Sincronización offline

- Los eventos se guardan localmente con su hora real y se envían solos al volver la señal.
- Los archivos esperan wifi salvo que el usuario active "Subir archivos con datos móviles".
- El servidor puede rechazar o ajustar un evento; en ese caso se ofrece "Solicitar ajuste".
- "Reintentar ahora" fuerza el envío.
- El catálogo y los parámetros llegan en la siguiente sincronización.

### Política de datos

- Se exige aceptar la versión vigente (v1.0) antes de usar la app.
- La aceptación es visible en Perfil y en el panel ("v1.0 aceptada el 29 oct").
- Marco legal: Ley 1581 de 2012.

---

## 4. Roles y permisos (matriz por defecto de Usuarios y roles)

| Permiso | Usuario móvil | Supervisor | RR. HH. | Nómina | Admin |
|---|---|---|---|---|---|
| ver_propio (jornada, semana, solicitudes propias) | ✓ | ✓ | ✓ | ✓ | ✓ |
| registrar (jornada y actividades en la app) | ✓ | – | – | – | ✓ |
| ver_equipo (Equipo hoy y horas) | – | ✓ | ✓ | ✓ | ✓ |
| ver_ubicacion (puntos del equipo) | – | ✓ | – | – | ✓ |
| aprobar (ajustes, extra, cambios de turno) | – | ✓ | – | – | ✓ |
| novedades (registrar y aprobar) | – | – | ✓ | – | ✓ |
| cerrar (periodo) | – | ✓ | – | ✓ | ✓ |
| exportar (para nómina) | – | – | – | ✓ | ✓ |
| horarios (plantillas y asignaciones) | – | – | ✓ | – | ✓ |
| parametros (parámetros, actividades, sitios) | – | – | – | – | ✓ |
| usuarios (invitar y cambiar roles) | – | – | ✓ | – | ✓ |
| auditoria | – | – | – | – | ✓ |

- El Administrador tiene todos los permisos y no se puede limitar. Además puede reabrir periodos, administrar Organización (sedes, grupos, roles) y Control de dispositivos (inferido).
- Los permisos de cada rol son editables y se pueden crear roles personalizados copiando los de uno base. Cada cambio se audita.
- Por pantalla:
  - Usuario móvil: toda la app.
  - Supervisor: Equipo hoy, Aprobaciones, Horas, Cierre. Puede usar la app si es usuario móvil.
  - RR. HH.: Novedades, Plantillas, Asignaciones, Usuarios.
  - Nómina: Horas, Cierre y exportación.
  - Admin: todo.

---

## 5. Casos de uso / endpoints (REST, agrupados)

**Auth y sesión**
- `POST /auth/login`: usuario y contraseña.
- `POST /auth/sso`: "cuenta de la empresa".
- `POST /auth/forgot-password`.
- `POST /auth/logout`.
- `POST /auth/refresh`.
- `GET /me`: perfil, rol, permisos, sede, supervisor, horario y dispositivo.
- `GET /devices/{mcDeviceId}/bootstrap`: usuario asignado, servidor y config enviada por MobiControl.

**Consentimiento**
- `GET /privacy-policy/current`.
- `POST /me/policy-acceptances`.
- `GET /users/{id}/policy-acceptances`.

**Revisión del dispositivo**
- `POST /me/device/permission-report`: estado de los 5 permisos; dispara aviso a soporte TI.
- `GET /me/device`.

**Turno del día y calendario**
- `GET /me/today`: turno, novedad, próximo turno, festivo, ventana de inicio, hora del servidor.
- `GET /me/week?from=`: horas por día y clasificación.
- `GET /users/{id}/calendar?month=`.
- `GET /time`: hora del servidor.

**Jornada (móvil)**
- `POST /workdays`: iniciar, con ubicación y precisión; valida turno, ventana y geocerca.
- `GET /workdays/current`.
- `POST /workdays/{id}/close`: nota del día y ubicación; autofinaliza la actividad abierta.
- `GET /me/workdays/{date}/timeline`: segmentos y eventos.

**Actividades (móvil)**
- `GET /me/assigned-activities?date=`: OT del día.
- `GET /activity-catalog`: activas, con requisitos.
- `POST /workdays/{id}/activities`: iniciar; autofinaliza la anterior; con ubicación.
- `POST /activities/{id}/pause`.
- `POST /activities/{id}/resume`.
- `POST /activities/{id}/finish`: resultado, observación y ubicación; valida requisitos.
- `POST /activities/{id}/evidences`: foto o firma, multipart, subida diferida.
- `POST /locations/batch`: muestreo periódico.

**Sincronización offline**
- `POST /sync/events`: lote idempotente con ids de cliente y timestamps locales; responde aceptado, rechazado o corregido con motivo.
- `GET /sync/changes?since=`: catálogo, parámetros, turnos y estados de solicitudes.

**Solicitudes (móvil)**
- `GET /me/requests?status=`.
- `POST /me/requests`: tipo ajuste, horas extra, cambio de turno o (por confirmar) inicio anticipado.

**Aprobaciones (panel)**
- `GET /approvals?type=&status=`.
- `GET /approvals/{id}`: detalle e impacto calculado.
- `POST /approvals/{id}/approve`.
- `POST /approvals/{id}/reject`: comentario obligatorio.

**Equipo hoy**
- `GET /team/today?sedeId=&filter=&q=`: KPIs, filas y estado del dispositivo.
- `GET /users/{id}/locations?date=`: auditado.

**Horas**
- `GET /hours/weekly?week=&onlyAlerts=`.
- `GET /hours/weekly/export`.

**Plantillas**
- `GET /schedule-templates`.
- `POST /schedule-templates`.
- `PUT /schedule-templates/{id}`.
- `POST /schedule-templates/validate`.
- `PATCH /schedule-templates/{id}/status`.

**Asignaciones**
- `GET /schedule-assignments`.
- `POST /schedule-assignments`.
- `DELETE /schedule-assignments/{id}`: por confirmar.
- `GET /shift-overrides`: cambios puntuales.

**Novedades**
- `GET /absences?type=`.
- `POST /absences`: calcula días hábiles.
- `POST /absences/{id}/support`.
- `POST /absences/{id}/approve`.

**Cierre de periodo**
- `GET /payroll-periods?sedeId=`.
- `GET /payroll-periods/{id}/summary`.
- `POST /payroll-periods/{id}/close`: con checklist.
- `POST /payroll-periods/{id}/reopen`: solo admin.
- `GET /payroll-periods/{id}/export?format=xlsx|csv`.

**Parámetros**
- `GET /parameters/definitions`.
- `GET /parameters?level=global|country:XX|company|sede:{id}`: valor efectivo y origen.
- `PUT /parameters/{level}/{paramId}`: valor, effectiveFrom y norma.
- `DELETE /parameters/{level}/{paramId}`: usar el heredado.
- `POST /countries`: desde cero o copiando de otro país.
- `GET /countries/{cc}/rules-package`.
- `POST /countries/{cc}/holidays/load?year=`.
- `POST /countries/{cc}/rules-package/validate`: asesor.
- `GET /catalog/countries`.
- `GET /catalog/cities?country=&q=`.

**Actividades (configuración)**
- `GET /activity-types`.
- `POST /activity-types`.
- `PATCH /activity-types/{id}`: requisitos y activa.
- `GET /activity-categories`.
- `POST /activity-categories`.
- `GET /closing-results`.
- `PATCH /closing-results/{id}`: pide observación.

**Sitios**
- `GET /sites`.
- `POST /sites`.
- `PUT /sites/{id}`: forma, radio, polígono, dirección.
- `GET /sites/{id}/points?date=`: dentro o fuera.
- `GET /work-orders`: OT por sitio y semana.

**Organización**
- `GET|POST|PUT /sedes`.
- `PATCH /sedes/{id}/status`: valida que no tenga personas.
- `GET|POST|PUT /groups`.
- `PATCH /groups/{id}/status`.
- `GET|POST /roles`: copiar de un base.
- `PUT /roles/{id}/permissions`.
- `GET /permissions`.

**Usuarios**
- `GET /users?…`.
- `GET /users/{id}`.
- `PUT /users/{id}`: rol, sede, grupo, supervisor.
- `PATCH /users/{id}/status`.
- `DELETE /users/{id}/device`: desvincular.
- `POST /invitations`.
- `GET /invitations`.
- `POST /invitations/{id}/resend`.
- `GET /mobicontrol/devices?unassigned=true`.

**Control de dispositivos (MobiControl)**
- `GET /device-control/settings`.
- `PUT /device-control/settings`.
- `POST /device-control/verify`: 5 checks.
- `GET /mobicontrol/apps`: catálogo.
- `GET /device-control/devices`: estado actual y última orden.
- Interno: `POST` de órdenes a MobiControl (set custom attribute WL_JORNADA, aplicar perfil, logout de Shared Device) con cola y reintentos.

**Auditoría**
- `GET /audit-events?origin=&entity=&from=`.
- `GET /audit-events/{id}`.
- `GET /audit-events/export`.

**Notificaciones y jobs del servidor**
- Recordatorio de no inicio.
- Inactividad.
- Pausa excedida.
- Avisos de fin de turno.
- Cierre automático de jornada (más gracia o extra autorizada).
- Cálculo y clasificación de horas.
- Push al móvil (FCM) y bandeja de notificaciones.
- Notificación al supervisor.

---

## 6. Design tokens

### Paleta (hex exactos y uso)

**Marca y primario**
- `#AF1839`: primario. CTA, links, nav activo, borde de selección (2px), avatar, chip seleccionado, categoría Productivo, barra de ordinarias.
- `#751326`: primario oscuro / borgoña. Hover de links, texto sobre fondo rosa, errores y "No cumple".
- `#E51E49`: rojo de marca. Wordmark "one"; actividad "en curso" en timeline y semana.
- `#FBE9EE`: rosa suave. Fondo de nav activo, card seleccionada, chip "En actividad", alerta "Pasó 42 h", aviso legal.
- `#FBF7F8`: fondo de fila seleccionada en tablas (más un marcador `inset 3px 0 0 #AF1839`).

**Neutros**
- `#1E1F1D`: texto principal. También fondo de la sombra de notificaciones, chip oscuro seleccionado (simuladores), marca de tope legal, color "Inicio de jornada".
- `#3C3C3B`: texto secundario fuerte, items de nav inactivos, texto de chip neutro, barra de nocturnas, categoría Interna, celda de admin bloqueada, avatar del supervisor.
- `#5A5958`: texto atenuado (subtítulos, labels) y botón deshabilitado (fondo con texto blanco).
- `#868787`: icono sutil, anillo de radio, categoría Traslado.
- `#C9C9C8`: borde de inputs, selects y chips no seleccionados; switch apagado.
- `#E2E2E1`: borde de cards, separadores, borde del sidebar.
- `#E8E8E7`: fondo de control segmentado, chip neutro o rechazado, festivo/descanso, almuerzo, botón bloqueado.
- `#EFEFEE`: divisores de filas.
- `#F5F5F4`: fondo de la app y del panel, cajas informativas.
- `#FFFFFF`: superficies.

**Estados**
- Éxito: fondo `#E6F4EC` (variante `#E7F4EC`), texto `#1E6B3F`, punto `#1E7A46`.
- Advertencia: fondo `#FEF3DA`, texto `#8A4105`, punto y borde `#DA830B`, texto oscuro `#6E3504`. `#DA830B` también es "Sin actividad", Improductivo y barra de extra.
- Overlay modal: `rgba(30,31,29,0.55)`.

**Paleta de categorías**: Borgoña `#751326`, Rojo principal `#E51E49`, Gris medio `#5A5958`, Gris profundo `#1E1F1D`, Amarillo `#F8B21D`, Verde `#1E6B3F`.

**Mapeo de chips de estado**

| Estado | Fondo | Texto | Punto |
|---|---|---|---|
| Pendiente | `#FEF3DA` | `#8A4105` | `#DA830B` |
| Aprobada / Activo / Válida / Listo | `#E6F4EC` | `#1E6B3F` | `#1E7A46` |
| Rechazada / Inactivo | `#E8E8E7` | `#3C3C3B` | `#5A5958` |
| En actividad | `#FBE9EE` | `#751326` | `#AF1839` |
| En pausa | `#E8E8E7` | `#3C3C3B` | |
| Sin actividad | `#FEF3DA` | `#8A4105` | |
| Sin iniciar / novedad | `#FFFFFF` | `#3C3C3B` | `#C9C9C8` |
| Invitado / Borrador | `#FEF3DA` | `#8A4105` | |

Origen en Auditoría: Panel `#FBE9EE`/`#751326`, App `#E8E8E7`/`#3C3C3B`, Sistema `#FEF3DA`/`#8A4105`.

### Tipografía

- Inter (Google Fonts) con pesos 400/500/600/700/800. Fallback system-ui.
- Tamaños:
  - 11: etiquetas de sección uppercase con letter-spacing 0.1em, 700.
  - 12: encabezados de tabla uppercase con 0.06em y 600; labels de la nav inferior; badges.
  - 13: chips, metadatos.
  - 14: cuerpo del panel (el más usado).
  - 15: cuerpo y subtítulos en móvil; subtítulo del header del panel.
  - 16–18: botones móviles.
  - 20–22: h2.
  - h1: 26 en móvil, 28 en panel (24 en responsive).
  - 32: KPI y hora del turno.
  - 52: cronómetro con tabular-nums.
  - 64: reloj del servidor.
- Wordmark "one": 27px, 800, letter-spacing −0.045em, `#E51E49`. Logo imagen de 30×31.

### Radios

| Radio | Uso |
|---|---|
| 10px (dominante) | Inputs, selects, botones e items de nav del panel |
| 12 | Cajas info, textarea, contenedor segmentado |
| 9 | Pestaña interna del segmentado |
| 14 | KPI cards, botones móviles 52px |
| 16 | Cards móviles, CTA 64px |
| 20 | Card de actividad, notificaciones |
| 24 | Bottom sheet (24 24 0 0) |
| 999 | Pills y chips |
| 22 | Avatar 44 |

### Tamaños y espaciado

- Alturas: touch target de 44 px; controles del panel de 40; botones móviles de 48 / 52 / 56 / 64 (CTA principal).
- Espaciado: escala 2/4/6/8/10/12/14/16/18/20/24/32/40.
- Padding: móvil 20px horizontal; cards 20; KPI 18; celdas 12px (primera columna 12px 20px); main del panel 32px 40px con gap de 24.

### Patrones de componentes

- **Chips de estado**: pill con punto de 8px, 13px, 600.
- **Chips de selección**: seleccionado = fondo `#AF1839` con texto blanco; no seleccionado = blanco con borde `#C9C9C8`. Variante oscura `#1E1F1D` para simuladores.
- **Control segmentado (tabs)**: contenedor `#E8E8E7`, radio 12, padding 4. Tab activa blanca, 600, `#1E1F1D`; inactiva transparente, 500, `#3C3C3B`.
- **Cards seleccionables**: borde de 2px `#AF1839` con fondo `#FBE9EE`; si no, 1px transparente o `#E2E2E1` sobre blanco.
- **Botones**:
  - Primario: `#AF1839` con texto blanco.
  - Secundario: blanco con borde `#C9C9C8`.
  - Terciario: texto `#AF1839`.
  - Deshabilitado: `#5A5958` o `#E8E8E7`, con aria-disabled.
- **Switch**: pista `#AF1839` / `#C9C9C8`, knob desplazado 22/2 px.
- **Steppers** − valor + (horas en pasos de 30 min, radio de 10 m, parámetros).
- **Mensajes inline**: éxito `#E6F4EC`/`#1E6B3F`; error `#FEF3DA`/`#8A4105`; con role status o alert.
- **Barras apiladas** de distribución de tiempo con leyenda de puntos.
- **Timeline vertical** con color por tipo.
- **Listas clave-valor** (dl).
- **Wizard por pasos** con número o ✓.
- **Combobox de autocompletado** (país y ciudad) con mensaje "No encontramos…".
- **Matriz de permisos** con celdas toggle (✓ sobre `#AF1839`; admin `#3C3C3B`).
- **Calendario mensual** de 7 columnas: celda de turno rosa con borde `#AF1839`; novedad ámbar; cambio puntual con borde punteado de 2px `#3C3C3B`; festivo/descanso `#E8E8E7`; fuera de mes `#F5F5F4` con opacidad 0.45.
- **Bottom sheet alertdialog** con overlay.
- **Nav inferior móvil**: grid de 3, blanca, borde superior `#E2E2E1`, padding 8 8 16. Item activo `#AF1839` 600, inactivo `#5A5958` 500, 12px, icono encima.

### Layout del panel web

- `.shell`: grid `288px | 1fr`.
- **Sidebar** (`aside.side`):
  - Fondo blanco, borde derecho `#E2E2E1`, padding 24px 16px, gap 24.
  - Logo INTECHSYS "one" + separador + "WorkLog / Bitácora de actividades".
  - `nav.sidenav` con dos grupos y etiqueta uppercase de 11px:
    - **Operación**: Equipo hoy · Aprobaciones (badge pill `#AF1839` con conteo "3") · Horas del equipo · Cierre de periodo.
    - **Configuración**: Organización · Plantillas de horario · Asignaciones · Novedades · Parámetros · Actividades · Sitios y geocercas · Usuarios y roles · Control de dispositivos · Auditoría.
  - Item: min-height 40, padding 0 12, radio 10, 14px. Activo: fondo `#FBE9EE`, texto `#AF1839`, 600. Inactivo: `#3C3C3B`, 500.
- **Main**: padding 32px 40px, gap 24.
  - No hay topbar global. Cada página tiene un header propio: h1 de 28/700, subtítulo de 15 `#5A5958` y, a la derecha, la acción primaria, filtros o el usuario actual (en Equipo hoy: selector de Sede y avatar con nombre y rol).
- **Layouts de contenido**:
  - `.kpis`: 4 columnas.
  - `.split`: 1fr | 1fr.
  - `.split3`: lista de 320px | detalle.
  - `.split4`: contenido | panel lateral de 360px.
- **Tablas** (div role=table, `.tbl`): min-width 1000, thead uppercase de 12px `#5A5958`, filas con borde superior `#EFEFEE`, columnas en CSS grid.
- **Responsive**:
  - ≤900px: el sidebar pasa a barra superior con botón hamburguesa (checkbox toggle), main con padding 20 16, h1 de 24, KPIs en 2 columnas, splits en 1 columna.
  - ≤640px: las tablas se vuelven tarjetas de 2 columnas con etiquetas `data-label` (::before) y el calendario se vuelve lista.
- Focus visible: outline de 2px `#AF1839`.

### Móvil

- Lienzo de 390×844 sobre fondo `#F5F5F4`.
- Header con logo y avatar de 44 (o botón volver con título).
- Contenido con padding de 20 y CTA principal abajo.

---

## 7. Ambigüedades y decisiones abiertas

1. **Valores inconsistentes entre pantallas**:
   - Inicio anticipado: Parámetros Global = 15 min (y Pendientes: "desde 06:45"); Kiosco y Dispositivos = 10 min ("desde 06:50"). ¿Cuál manda: el parámetro "ant" o la regla de Control de dispositivos? ¿Son el mismo concepto?
   - Kiosco llama "tolerancia" al inicio anticipado. ¿Se distingue de la tolerancia de llegada (tardanza)?
   - Aviso de fin de turno: parámetro "fin" (15) frente a la lista multi de avisos de Dispositivos (15 y 5) y la gracia (10).
   - Notificaciones dice "A las 16:00 se cerrarán…" y AvisoCierre dice 16:10 (con gracia).
   - Auditoría cita "5 min (heredado de la empresa)", pero en Parámetros el 5 viene de Global.
   - Franja nocturna: default 20, Colombia 19.
2. **Cierre automático**: ¿la jornada queda "Cerrada" (Auditoría: "Cerrada a las 16:00 · cierre automático") o "pendiente de cierre para revisión del supervisor" (AvisoCierre)? ¿Con qué hora de fin? ¿Y la actividad abierta con qué resultado?
3. **Permisos frente a pantallas**:
   - Auditoría muestra a una Supervisora cambiando un parámetro de sede, pero la matriz da "parametros" solo al Admin.
   - En Organización, los permisos de RR. HH. y Supervisor no coinciden exactamente con la matriz.
   - ¿El alcance de los datos es por sede o grupo (el supervisor solo ve a su equipo)?
   - ¿Quién aprueba novedades y quién registra las que vienen de la app?
4. **Multiempresa**: hay nivel "Empresa · INTECHSYS" y la plataforma "INTECHSYS ONE". ¿Es SaaS multi-tenant (empresas clientes) o una sola empresa? ¿Los niveles Global y País son del producto, administrados por quién?
5. **Autenticación**: ¿qué proveedor tiene el SSO "cuenta de la empresa" (Entra ID/Azure AD, Google, IdP de INTECHSYS ONE)? ¿Hay contraseña local? ¿Cómo funciona la recuperación? ¿Cómo se hace el binding usuario–dispositivo (id de MobiControl vía AppConfig)? ¿El panel web usa el mismo IdP?
6. **Integración con SOTI MobiControl**: ¿API REST (versión 2026.0)? ¿Credenciales y tenant? ¿Sincronización de dispositivos, grupos y catálogo de apps (pull periódico o webhook)? ¿Mecanismo de órdenes (custom attribute WL_JORNADA y perfiles Lockdown)? ¿Reintentos y cola? ¿Es obligatorio en el MVP?
7. **Órdenes de trabajo**: ¿de dónde vienen las OT "Asignadas hoy" (sistema externo / app "Órdenes de trabajo") o se crean en WorkLog? No hay pantalla para crearlas ni asignarlas. ¿"Reprogramar" crea una nueva OT o una fecha?
8. **Formulario "Nueva solicitud"**: no está diseñado. ¿Cuáles son los tipos exactos (¿incluye "autorización de inicio anticipado"?) y sus campos? ¿Se puede cancelar una solicitud? ¿Hay solicitud de novedad desde la app?
9. **Offline**:
   - ¿Qué alcance tiene (iniciar jornada offline sí o no; el diseño sugiere que sí)?
   - Resolución de conflictos y reglas de corrección del servidor.
   - Idempotencia.
   - ¿Se confía en el reloj del dispositivo o en el del servidor?
   - Límites de la cola.
10. **Ubicación**: ¿se guarda la ubicación continua en jornada o solo en eventos y muestreo cada 15 min? ¿Cuánto tiempo se retiene? ¿Fuera de geocerca solo se alerta o se bloquea el inicio o fin? ¿Polígono en el MVP? ¿Proveedor de mapas (MapLibre con qué tiles) y de geocodificación de direcciones?
11. **Cálculo de horas**: ¿motor de clasificación completo (diurna/nocturna/extra/dominical por país) en el MVP? ¿Las quincenas son configurables (semanal, mensual)? ¿El periodo es por sede o por empresa? Hay una fecha de cierre "15 de noviembre" para la quincena 16–31 oct. ¿Formato del export para nómina (columnas, integración con un sistema de nómina concreto)?
12. **Novedades**: ¿hay estado Rechazada? ¿Saldo de vacaciones? ¿Reglas de días hábiles con festivos del país? ¿Almacenamiento de soportes (Blob storage)?
13. **Asignaciones**: ¿tienen fecha fin, se pueden editar o eliminar? ¿Cómo se versionan los cambios de plantilla en asignaciones existentes?
14. **Notificaciones**: ¿push con FCM? ¿Email para invitaciones y al supervisor? ¿Notificaciones in-app en el panel?
15. **Estados del dispositivo** (batería, en línea): ¿vienen de MobiControl o de heartbeat de la app?
16. **Catálogos de países y ciudades** (ISO 3166, GeoNames, DANE): ¿se cargan en BD o se consultan externamente? ¿Hay fuente oficial de festivos por país (carga manual o API)?
17. **Idioma y zona horaria**: ¿solo español? ¿Cada sede usa su TZ para turnos y cálculo?
18. **Kiosco en dispositivo compartido**: ¿cómo se identifica el usuario en Shared Device (login de MobiControl o de WorkLog)? ¿Qué pasa si alguien con jornada abierta cambia de dispositivo?
19. **Versionado de la política de datos**: ¿quién publica nuevas versiones y se fuerza la re-aceptación? ¿Revocación del consentimiento desde la app?
20. **Auditoría**: ¿retención, tamaño y exportación (formato)? ¿Se auditan las lecturas además de las consultas de ubicación?
21. **Tercer tab de la nav inferior**: en el diseño, "Jornada" apunta a Main o a Perfil según la pantalla; falta definir ese tab.
