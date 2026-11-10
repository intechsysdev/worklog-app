import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/session.dart';

/// Sign-in against the WorkLog API (`/api/v1/mobile-auth`). Uses a client without the auth
/// interceptor: renewing the session through the interceptor would wait on itself.
class WorklogAuthApi {
  WorklogAuthApi(this._dio);

  final Dio _dio;

  /// `POST /mobile-auth/login`. With [tenantId] null and the account in several companies, the
  /// answer is the list to choose from instead of a session.
  Future<WorklogLogin> login(String email, String password, {String? tenantId, String? device}) async {
    final data = await _post('/mobile-auth/login', {
      'email': email,
      'password': password,
      'tenantId': ?tenantId,
      'device': ?device,
    });
    final session = data['session'];
    if (session is Map) return WorklogLogin(tokens: WorklogTokens.fromJson(Map<String, dynamic>.from(session)));

    final tenants = (data['tenants'] as List<dynamic>? ?? const [])
        .map((t) => Map<String, dynamic>.from(t as Map))
        .map((t) => WorklogTenantOption(tenantId: t['tenantId'] as String, name: t['name'] as String))
        .toList();
    return WorklogLogin(tenants: tenants);
  }

  /// `POST /mobile-auth/refresh`: new tokens; the previous refresh token stops working.
  Future<WorklogTokens> refresh(String refreshToken) async =>
      WorklogTokens.fromJson(await _post('/mobile-auth/refresh', {'refreshToken': refreshToken}));

  /// `POST /mobile-auth/logout`. Best effort: the local session is removed anyway.
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>('/mobile-auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // Offline or already closed.
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
