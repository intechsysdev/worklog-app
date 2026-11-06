import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/session.dart';

/// Calls to INTECHSYS ONE: password login, token refresh and SSO code exchange.
class OneAuthApi {
  OneAuthApi(this._dio);

  final Dio _dio;

  /// `POST /api/v1/auth/login`. With two-step verification ONE answers 403 with
  /// `requiresTwoFactor`, surfaced as [ApiException.requiresTwoFactor].
  Future<OneTokens> login(String email, String password) =>
      _post('/api/v1/auth/login', {'email': email, 'password': password});

  /// `POST /api/v1/auth/refresh`. ONE rotates the refresh token on every call.
  Future<OneTokens> refresh(String refreshToken) => _post('/api/v1/auth/refresh', {'refreshToken': refreshToken});

  /// `POST /api/v1/sso/token`: exchanges the PKCE code for a session.
  Future<OneTokens> exchangeSsoCode({
    required String clientId,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => _post('/api/v1/sso/token', {
    'clientId': clientId,
    'code': code,
    'codeVerifier': codeVerifier,
    'redirectUri': redirectUri,
  });

  /// `POST /api/v1/auth/logout`: revokes the refresh token. Best effort.
  Future<void> logout(String accessToken, String refreshToken) async {
    try {
      await _dio.post<void>(
        '/api/v1/auth/logout',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException {
      // The local session is removed anyway.
    }
  }

  Future<OneTokens> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return OneTokens.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
