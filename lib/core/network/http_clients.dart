import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/demo/data/mock_backend.dart';
import '../../features/demo/data/mock_http_adapter.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

BaseOptions _options(String baseUrl) => BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  contentType: Headers.jsonContentType,
);

/// Demo backend (only with `DATA_MODE=mock`; overridden in `main`).
final mockBackendProvider = Provider<MockBackend?>((ref) => null);

Dio _client(Ref ref, BaseOptions options) {
  final dio = Dio(options);
  final backend = ref.watch(mockBackendProvider);
  if (backend != null) dio.httpClientAdapter = MockHttpAdapter(backend);
  return dio;
}

/// Client for INTECHSYS ONE (no session headers).
final oneDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return _client(ref, _options(config.oneUrl));
});

/// Client for the WorkLog API (`/api/v1`), with the auth interceptor.
final worklogDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final options = _options('${config.worklogApiUrl}/api/v1');
  final dio = _client(ref, options);
  dio.interceptors.add(AuthInterceptor(sessions: ref.watch(authRepositoryProvider), retry: _client(ref, options)));
  return dio;
});
