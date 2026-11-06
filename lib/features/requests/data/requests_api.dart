import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/http_clients.dart';
import '../../week/data/week_models.dart';
import 'request_models.dart';

/// Requests and week of the technician. They go online (not through the queue): the server
/// validates them on the spot (period closed, overtime limits, overlapping days…).
class RequestsApi {
  RequestsApi(this._dio);

  final Dio _dio;

  Future<MyWeekDto> week(String date) async =>
      MyWeekDto.fromJson(await _send(() => _dio.get('/me/week', queryParameters: {'date': date})));

  /// Every request of the user, newest first. The tabs filter on the phone.
  Future<List<RequestDto>> list() async {
    final json = await _send(() => _dio.get('/me/requests', queryParameters: {'pageSize': 100}));
    return RequestPageDto.fromJson(json).items;
  }

  Future<RequestDto> cancel(String id) async =>
      RequestDto.fromJson(await _send(() => _dio.post('/me/requests/$id/cancel')));

  Future<RequestDto> submitAdjustment({
    required String workdayId,
    required AdjustmentTarget target,
    required DateTime proposedValue,
    required String reason,
    String? activityRecordId,
  }) async => RequestDto.fromJson(
    await _send(
      () => _dio.post(
        '/me/requests/adjustment',
        data: {
          'workdayId': workdayId,
          'activityRecordId': activityRecordId,
          'target': target.wire,
          'proposedValue': proposedValue.toUtc().toIso8601String(),
          'reason': reason,
        },
      ),
    ),
  );

  Future<RequestDto> submitOvertime({
    required String date,
    required String from,
    required String to,
    required String reason,
    String? authorizationReference,
  }) async => RequestDto.fromJson(
    await _send(
      () => _dio.post(
        '/me/requests/overtime',
        data: {
          'date': date,
          'from': from,
          'to': to,
          'authorizationReference': ?authorizationReference,
          'reason': reason,
        },
      ),
    ),
  );

  Future<RequestDto> submitShiftChange({required List<ShiftChangeDayDto> days, required String reason}) async =>
      RequestDto.fromJson(
        await _send(
          () => _dio.post(
            '/me/requests/shift-change',
            data: {'days': days.map((d) => d.toJson()).toList(), 'reason': reason},
          ),
        ),
      );

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final requestsApiProvider = Provider<RequestsApi>((ref) => RequestsApi(ref.watch(worklogDioProvider)));
