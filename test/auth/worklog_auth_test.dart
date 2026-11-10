import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/app/router.dart';
import 'package:worklog_mobile/app/routes.dart';
import 'package:worklog_mobile/core/config/app_config.dart';
import 'package:worklog_mobile/features/auth/domain/session.dart';
import 'package:worklog_mobile/features/auth/presentation/auth_controller.dart';
import 'package:worklog_mobile/features/onboarding/presentation/onboarding_controller.dart';
import 'package:worklog_mobile/features/profile/data/models/profile_models.dart';

Session _worklog({bool mustChange = false, DateTime? expiresAt}) => Session(
  mode: AuthMode.worklog,
  email: 'amora@intechsys.co',
  accessToken: 'wlm_access',
  refreshToken: 'wlm_refresh',
  expiresAt: expiresAt ?? DateTime.utc(2026, 11, 10, 12),
  tenantId: 'tenant-1',
  tenantName: 'INTECHSYS',
  mustChangePassword: mustChange,
);

const _ready = OnboardingState(loaded: true, policyAccepted: true, deviceReviewed: true);

void main() {
  test('con contraseña temporal la app pide cambiarla antes que la política', () {
    final auth = SignedIn(_worklog(mustChange: true));
    expect(gateRedirect(auth, const OnboardingState(), Routes.home), Routes.changePassword);
    expect(gateRedirect(auth, const OnboardingState(), Routes.changePassword), isNull);
  });

  test('después de cambiarla sigue el flujo normal y sale de la pantalla de contraseña', () {
    final auth = SignedIn(_worklog());
    expect(gateRedirect(auth, _ready, Routes.changePassword), Routes.home);
    expect(gateRedirect(auth, const OnboardingState(loaded: true), Routes.home), Routes.policy);
  });

  test('si la cuenta está en varias empresas muestra el selector', () {
    const auth = PendingTenant([TenantDto(tenantId: 't1', name: 'Uno'), TenantDto(tenantId: 't2', name: 'Dos')]);
    expect(gateRedirect(auth, const OnboardingState(), Routes.login), Routes.tenants);
  });

  test('la sesión de WorkLog se guarda y se lee igual, y se renueva antes de vencer', () {
    final session = _worklog(mustChange: true);
    final restored = Session.fromJson(session.toJson());

    expect(restored.mode, AuthMode.worklog);
    expect(restored.mustChangePassword, isTrue);
    expect(restored.tenantName, 'INTECHSYS');
    expect(restored.canRefresh, isTrue);
    expect(restored.expiresSoon(DateTime.utc(2026, 11, 10, 11, 59, 30)), isTrue);
    expect(restored.expiresSoon(DateTime.utc(2026, 11, 10, 11)), isFalse);
  });

  test('las sesiones guardadas antes del cambio siguen leyéndose', () {
    final old = Session.fromJson({'mode': 'one', 'email': 'a@b.co', 'accessToken': 'x', 'refreshToken': 'y'});
    expect(old.mode, AuthMode.one);
    expect(old.mustChangePassword, isFalse);
    expect(Session.fromJson({'mode': 'development', 'email': 'a@b.co', 'accessToken': 'dev:a@b.co'}).canRefresh, isFalse);
  });

  test('sin AUTH_MODE la app usa la cuenta de WorkLog', () {
    expect(AppConfig.fromEnvironment().authMode, AuthMode.worklog);
  });
}
