import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'session_source.dart';

/// Adds `Authorization`, `X-Tenant-Id` and `X-Client: mobile` to every WorkLog call and, with
/// renewable tokens (WorkLog or ONE), refreshes once and retries when the API answers 401.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this._sessions, required this._retry});

  static const _retriedKey = 'wl.retried';
  static const skipTenantKey = 'wl.skipTenant';

  final SessionSource _sessions;
  final Dio _retry;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final session = await _sessions.current();
    options.headers['X-Client'] = 'mobile';
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      final tenant = session.tenantId;
      if (tenant != null && options.extra[skipTenantKey] != true) {
        options.headers['X-Tenant-Id'] = tenant;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || request.extra[_retriedKey] == true) {
      if (err.response?.statusCode == 401) _sessions.onUnauthorized();
      return handler.next(err);
    }

    final current = await _sessions.current();
    if (current == null || current.mode == AuthMode.development) {
      _sessions.onUnauthorized();
      return handler.next(err);
    }

    // Null when the refresh token was rejected: the repository already signed out.
    final renewed = await _sessions.refresh();
    if (renewed == null) return handler.next(err);

    try {
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer ${renewed.accessToken}';
      final response = await _retry.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) _sessions.onUnauthorized();
      handler.next(e);
    }
  }
}
