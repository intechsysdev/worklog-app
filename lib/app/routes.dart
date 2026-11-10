/// Route paths of the app.
abstract final class Routes {
  static const splash = '/';
  static const login = '/ingreso';
  static const tenants = '/empresa';
  static const changePassword = '/contrasena';
  static const policy = '/politica';
  static const permissions = '/permisos';

  static const home = '/inicio';
  static const history = '/historial';
  static const selectActivity = '/actividad/nueva';
  static const finishActivity = '/actividad/finalizar';
  static const closeWorkday = '/jornada/cerrar';
  static const pending = '/sincronizacion';
  static const profile = '/perfil';
  static const policyView = '/perfil/politica';
  static const deviceReview = '/perfil/dispositivo';

  // Phase 2.
  static const week = '/semana';
  static const requests = '/solicitudes';
  static const newRequest = '/solicitudes/nueva';
  static const adjustmentRequest = '/solicitudes/ajuste';
  static const overtimeRequest = '/solicitudes/horas-extra';
  static const shiftChangeRequest = '/solicitudes/cambio-de-turno';
  static const kiosk = '/kiosco';
  static const shiftEndNotice = '/aviso-fin-de-turno';

  /// Routes reachable before finishing the onboarding.
  static const public = {splash, login};
}
