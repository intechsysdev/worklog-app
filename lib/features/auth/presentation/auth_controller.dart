import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../profile/data/models/profile_models.dart';
import '../../profile/data/profile_api.dart';
import '../../requests/presentation/requests_controller.dart';
import '../../sync/presentation/sync_controller.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/auth_providers.dart';
import '../domain/session.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedOut extends AuthState {
  const SignedOut([this.message]);

  /// Why the user is here again (expired session).
  final String? message;
}

/// The WorkLog email and password work in several companies: the user picks one.
class PendingTenant extends AuthState {
  const PendingTenant(this.tenants);

  final List<TenantDto> tenants;
}

class SignedIn extends AuthState {
  const SignedIn(this.session, {this.tenants = const []});

  final Session session;

  /// Companies to choose from when the session has none yet.
  final List<TenantDto> tenants;

  bool get needsTenant => !session.hasTenant;
}

class AuthController extends Notifier<AuthState> {
  /// Credentials kept in memory only while choosing the company (WorkLog login in several companies).
  ({String email, String password, String? device})? _pending;

  /// Password just typed, so the forced change does not ask for it again. Memory only.
  String? _recentPassword;

  String? get recentPassword => _recentPassword;

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.expired.listen((_) {
      state = const SignedOut('Tu sesión expiró. Ingresa de nuevo.');
    });
    ref.onDispose(subscription.cancel);
    unawaited(_restore());
    return const AuthLoading();
  }

  Future<void> _restore() async {
    var session = await ref.read(authRepositoryProvider).load();
    if (session != null && !session.hasTenant) {
      // Closed during the company selection: start over.
      await ref.read(authRepositoryProvider).signOut();
      session = null;
    }
    if (!ref.mounted) return;
    state = session == null ? const SignedOut() : SignedIn(session);
    if (session != null && session.hasTenant && !session.mustChangePassword) {
      // Refresh the policy in the background; offline the cached acceptance is used.
      unawaited(ref.read(onboardingProvider.notifier).checkPolicy().catchError((_) {}));
    }
  }

  Future<void> signInDevelopment(String email) async {
    final session = await ref.read(authRepositoryProvider).signInDevelopment(email);
    await _afterSignIn(session);
  }

  Future<void> signInWithPassword(String email, String password) async {
    final session = await ref.read(authRepositoryProvider).signInWithPassword(email, password);
    await _afterSignIn(session);
  }

  /// WorkLog account (default): the session already brings its company.
  Future<void> signInWithWorklog(String email, String password, {String? device}) async {
    final (session, tenants) = await ref.read(authRepositoryProvider).signInWithWorklog(email, password, device: device);
    _recentPassword = password;
    if (session == null) {
      _pending = (email: email, password: password, device: device);
      state = PendingTenant(tenants.map((t) => TenantDto(tenantId: t.tenantId, name: t.name)).toList());
      return;
    }
    await _afterWorklogSignIn(session);
  }

  /// With a temporary password the router shows the change first; the policy is checked after it.
  Future<void> _afterWorklogSignIn(Session session) async {
    if (!session.mustChangePassword) {
      _recentPassword = null;
      await ref.read(onboardingProvider.notifier).checkPolicy();
    }
    state = SignedIn(session);
  }

  /// Replaces the temporary (or current) WorkLog password and continues to the app.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await ref.read(profileApiProvider).changePassword(currentPassword, newPassword);
    _recentPassword = null;
    final session = await ref.read(authRepositoryProvider).markPasswordChanged();
    await ref.read(onboardingProvider.notifier).checkPolicy();
    state = SignedIn(session);
  }

  Future<void> signInWithSso() async {
    final (session, tenant) = await ref.read(authRepositoryProvider).signInWithSso();
    await _afterSignIn(session, preferredTenant: tenant);
  }

  /// Loads the companies of the user: one is chosen automatically, several show the selector.
  Future<void> _afterSignIn(Session session, {String? preferredTenant}) async {
    final List<TenantDto> tenants;
    try {
      tenants = await ref.read(profileApiProvider).tenants();
    } on ApiException {
      await ref.read(authRepositoryProvider).signOut();
      rethrow;
    }

    if (tenants.isEmpty) {
      await ref.read(authRepositoryProvider).signOut();
      throw const ApiException(
        message: 'Tu usuario no tiene acceso a WorkLog en ninguna empresa. Pide a tu administrador que te invite.',
        code: 'access.not_invited',
      );
    }

    final preferred = tenants.where((t) => t.tenantId == preferredTenant).firstOrNull;
    final chosen = preferred ?? (tenants.length == 1 ? tenants.single : null);
    if (chosen != null) {
      await selectTenant(chosen);
    } else {
      state = SignedIn(session, tenants: tenants);
    }
  }

  Future<void> selectTenant(TenantDto tenant) async {
    final pending = _pending;
    if (state is PendingTenant && pending != null) {
      final (session, _) = await ref
          .read(authRepositoryProvider)
          .signInWithWorklog(pending.email, pending.password, tenantId: tenant.tenantId, device: pending.device);
      _pending = null;
      if (session == null) {
        throw const ApiException(message: 'No se pudo entrar a esa empresa. Intenta de nuevo.', code: 'auth.tenant');
      }
      await _afterWorklogSignIn(session);
      return;
    }

    final session = await ref.read(authRepositoryProvider).selectTenant(tenant.tenantId, tenant.name);
    // The policy decides the next screen, so it is checked before leaving the login.
    await ref.read(onboardingProvider.notifier).checkPolicy();
    state = SignedIn(session);
  }

  /// Signs out and removes everything local (queue included).
  Future<void> signOut() async {
    _pending = null;
    _recentPassword = null;
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(appDatabaseProvider).wipe();
    ref.read(onboardingProvider.notifier).reset();
    // Nothing of the previous user may survive in memory either.
    ref
      ..invalidate(todayControllerProvider)
      ..invalidate(activityOptionsProvider)
      ..invalidate(syncControllerProvider)
      ..invalidate(profileProvider)
      ..invalidate(timelineProvider)
      ..invalidate(requestsControllerProvider);
    state = const SignedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
