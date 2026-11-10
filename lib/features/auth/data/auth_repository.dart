import 'dart:async';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_source.dart';
import '../domain/session.dart';
import 'one_auth_api.dart';
import 'session_store.dart';
import 'sso_service.dart';
import 'worklog_auth_api.dart';

/// Owns the session: loads it from secure storage, saves it, refreshes the token (WorkLog or ONE,
/// one refresh at a time) and announces when it can no longer be renewed.
class AuthRepository implements SessionSource {
  AuthRepository({required this._store, required this._oneApi, required this._worklogApi, required this._sso});

  final SessionStore _store;
  final OneAuthApi _oneApi;
  final WorklogAuthApi _worklogApi;
  final SsoService _sso;
  final _expired = StreamController<void>.broadcast();

  Session? _session;
  bool _loaded = false;
  Future<Session?>? _refreshing;

  /// Fires when the refresh token is rejected: the user must sign in again.
  Stream<void> get expired => _expired.stream;

  Session? get session => _session;

  Future<Session?> load() async {
    if (!_loaded) {
      _session = await _store.read();
      _loaded = true;
    }
    return _session;
  }

  @override
  Future<Session?> current() async {
    final session = await load();
    if (session != null && session.expiresSoon(DateTime.now().toUtc())) {
      return await refresh() ?? session;
    }
    return session;
  }

  Future<Session> signInDevelopment(String email) => _save(Session.development(email.trim().toLowerCase()));

  Future<Session> signInWithPassword(String email, String password) async {
    final tokens = await _oneApi.login(email.trim(), password);
    return _save(_fromTokens(tokens, email.trim()));
  }

  /// WorkLog account. Returns the session, or the companies to choose from (then call again with one).
  Future<(Session?, List<WorklogTenantOption>)> signInWithWorklog(
    String email,
    String password, {
    String? tenantId,
    String? device,
  }) async {
    final result = await _worklogApi.login(email.trim(), password, tenantId: tenantId, device: device);
    final tokens = result.tokens;
    if (tokens == null) return (null, result.tenants);
    return (await _save(_fromWorklog(tokens)), const <WorklogTenantOption>[]);
  }

  /// The temporary password was replaced: the app can be used normally.
  Future<Session> markPasswordChanged() {
    final session = _session;
    if (session == null) throw StateError('No hay sesión.');
    return _save(session.copyWith(mustChangePassword: false));
  }

  /// Returns the session and the company chosen in the portal, if any.
  Future<(Session, String?)> signInWithSso() async {
    final tokens = await _sso.signIn();
    return (await _save(_fromTokens(tokens, tokens.email ?? '')), tokens.tenantId);
  }

  Future<Session> selectTenant(String tenantId, String tenantName) {
    final session = _session;
    if (session == null) throw StateError('No hay sesión.');
    return _save(session.copyWith(tenantId: tenantId, tenantName: tenantName));
  }

  @override
  Future<Session?> refresh() {
    final session = _session;
    if (session == null || !session.canRefresh) return Future.value(session);
    return _refreshing ??= _doRefresh(session).whenComplete(() => _refreshing = null);
  }

  Future<Session?> _doRefresh(Session session) async {
    try {
      if (session.mode == AuthMode.worklog) {
        final tokens = await _worklogApi.refresh(session.refreshToken!);
        return await _save(
          session.copyWith(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: tokens.expiresAt,
            mustChangePassword: tokens.mustChangePassword,
          ),
        );
      }
      final tokens = await _oneApi.refresh(session.refreshToken!);
      return await _save(
        session.copyWith(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.expiresAt,
        ),
      );
    } on ApiException catch (e) {
      if (e.isTransient) return session;
      await signOut();
      _expired.add(null);
      return null;
    }
  }

  @override
  void onUnauthorized() {
    if (_session?.mode == AuthMode.development) return;
    unawaited(signOut().then((_) => _expired.add(null)));
  }

  Future<void> signOut() async {
    final session = _session;
    _session = null;
    _loaded = true;
    await _store.clear();
    if (session?.mode == AuthMode.one && session?.refreshToken != null) {
      unawaited(_oneApi.logout(session!.accessToken, session.refreshToken!));
    }
    if (session?.mode == AuthMode.worklog && session?.refreshToken != null) {
      unawaited(_worklogApi.logout(session!.refreshToken!));
    }
  }

  Future<Session> _save(Session session) async {
    _session = session;
    _loaded = true;
    await _store.write(session);
    return session;
  }

  Session _fromTokens(OneTokens tokens, String fallbackEmail) => Session(
    mode: AuthMode.one,
    email: tokens.email ?? fallbackEmail,
    displayName: tokens.fullName,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt: tokens.expiresAt,
  );

  Session _fromWorklog(WorklogTokens tokens) => Session(
    mode: AuthMode.worklog,
    email: tokens.email,
    displayName: tokens.fullName,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt: tokens.expiresAt,
    tenantId: tokens.tenantId,
    tenantName: tokens.tenantName,
    mustChangePassword: tokens.mustChangePassword,
  );

  void dispose() => _expired.close();
}
