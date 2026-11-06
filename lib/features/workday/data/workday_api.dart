import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../sync/data/models/sync_models.dart';
import '../../sync/domain/queued_file.dart';
import '../../sync/domain/sync_ports.dart';
import 'models/activity_options_dto.dart';
import 'models/enums.dart';
import 'models/timeline_dto.dart';
import 'models/today_dto.dart';

/// WorkLog endpoints of the technician (`/api/v1/me/...`).
class WorkdayApi implements SyncApi {
  WorkdayApi(this._dio);

  final Dio _dio;

  Future<TodayDto> today() => _get('/me/today', TodayDto.fromJson);

  Future<ActivityOptionsDto> activityOptions() => _get('/me/workday/activity-options', ActivityOptionsDto.fromJson);

  Future<TimelineDto> timeline(String date) => _get('/me/timeline', TimelineDto.fromJson, query: {'date': date});

  @override
  Future<SyncBatchResultDto> sync(List<SyncEventDto> events) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/me/workday/sync',
        data: {'events': events.map((e) => e.toJson()).toList()},
      );
      return SyncBatchResultDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<int> sendLocations(List<LocationInputDto> samples) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/me/workday/locations',
        data: {'samples': samples.map((s) => s.toJson()).toList()},
      );
      return (response.data?['stored'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> uploadEvidence(QueuedFile file) async {
    final source = File(file.path);
    if (!source.existsSync()) {
      throw const ApiException(message: 'El archivo ya no está en el teléfono.', code: 'evidence.missing');
    }
    final form = FormData.fromMap({
      'clientId': file.clientId,
      'kind': file.kind.wire,
      'capturedAt': file.capturedAt.toUtc().toIso8601String(),
      'file': await MultipartFile.fromFile(
        file.path,
        filename: '${file.clientId}.${file.contentType == 'image/png' ? 'png' : 'jpg'}',
        contentType: DioMediaType.parse(file.contentType),
      ),
    });
    try {
      await _dio.post<void>(
        '/me/workday/activities/${file.activityId}/evidences',
        data: form,
        options: Options(contentType: 'multipart/form-data', sendTimeout: const Duration(minutes: 2)),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> _get<T>(String path, T Function(Map<String, dynamic>) parse, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return parse(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
