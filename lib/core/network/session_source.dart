import '../../features/auth/domain/session.dart';

/// What the HTTP layer needs from the auth feature.
abstract interface class SessionSource {
  /// Current session, refreshed first when the access token is about to expire.
  Future<Session?> current();

  /// Forces a token refresh. Returns null when the session can no longer be renewed.
  Future<Session?> refresh();

  /// A request was rejected with 401 even after refreshing.
  void onUnauthorized();
}
