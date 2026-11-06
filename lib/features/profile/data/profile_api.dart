import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/http_clients.dart';
import '../../../core/storage/kv_store.dart';
import 'models/profile_models.dart';

/// `/me`, `/me/tenants` and the privacy policy.
class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<MeDto> me() async => MeDto.fromJson(await _get('/me'));

  Future<List<TenantDto>> tenants() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/me/tenants',
        options: Options(extra: {AuthInterceptor.skipTenantKey: true}),
      );
      return (response.data ?? const []).map((t) => TenantDto.fromJson(Map<String, dynamic>.from(t as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PrivacyPolicyDto> privacyPolicy() async => PrivacyPolicyDto.fromJson(await _get('/me/privacy-policy'));

  Future<void> acceptPolicy(String version) async {
    try {
      await _dio.post<void>('/me/privacy-policy/accept', data: {'version': version});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(worklogDioProvider)));

/// `GET /me`, cached for offline use.
final profileProvider = FutureProvider<MeDto?>((ref) async {
  final api = ref.watch(profileApiProvider);
  final kv = ref.watch(kvStoreProvider);
  try {
    final me = await api.me();
    await kv.setJson(KvKeys.profile, me.toJson());
    return me;
  } on ApiException catch (e) {
    if (!e.isTransient) rethrow;
    final cached = await kv.getJson(KvKeys.profile);
    return cached == null ? null : MeDto.fromJson(cached);
  }
});
