import 'package:json_annotation/json_annotation.dart';

import '../../../workday/data/models/enums.dart';
import '../../../workday/data/models/today_dto.dart';

part 'sync_models.g.dart';

/// Kinds accepted by `POST /me/workday/sync`.
abstract final class SyncEventKind {
  static const workdayStart = 'workday.start';
  static const workdayClose = 'workday.close';
  static const activityStart = 'activity.start';
  static const activityPause = 'activity.pause';
  static const activityResume = 'activity.resume';
  static const activityFinish = 'activity.finish';
}

/// GPS reading sent by the phone.
@JsonSerializable()
class LocationInputDto {
  const LocationInputDto({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  factory LocationInputDto.fromJson(Map<String, dynamic> json) => _$LocationInputDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LocationInputDtoToJson(this);

  final double latitude;
  final double longitude;
  final double accuracy;
  @JsonKey(toJson: _utc)
  final DateTime capturedAt;
}

/// Event of the phone queue, flat: each kind uses the fields it needs. The phone generates the
/// workday and activity ids so queued events can point at records the server has not seen yet.
@JsonSerializable()
class SyncEventDto {
  const SyncEventDto({
    required this.clientEventId,
    required this.kind,
    required this.occurredAt,
    this.workdayId,
    this.activityId,
    this.activityTypeId,
    this.workOrderId,
    this.outcome,
    this.observation,
    this.photoCount,
    this.hasSignature,
    this.note,
    this.location,
  });

  factory SyncEventDto.fromJson(Map<String, dynamic> json) => _$SyncEventDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SyncEventDtoToJson(this);

  final String clientEventId;
  final String kind;
  @JsonKey(toJson: _utc)
  final DateTime occurredAt;
  final String? workdayId;
  final String? activityId;
  final String? activityTypeId;
  final String? workOrderId;
  final ActivityOutcome? outcome;
  final String? observation;
  final int? photoCount;
  final bool? hasSignature;
  final String? note;
  final LocationInputDto? location;
}

@JsonSerializable(createToJson: false)
class SyncEventResultDto {
  const SyncEventResultDto({
    required this.clientEventId,
    required this.outcome,
    this.message,
    this.code,
    this.resultId,
  });

  factory SyncEventResultDto.fromJson(Map<String, dynamic> json) => _$SyncEventResultDtoFromJson(json);

  final String clientEventId;
  final SyncOutcome outcome;
  final String? message;
  final String? code;
  final String? resultId;
}

@JsonSerializable(createToJson: false)
class SyncBatchResultDto {
  const SyncBatchResultDto({this.results = const [], this.today});

  factory SyncBatchResultDto.fromJson(Map<String, dynamic> json) => _$SyncBatchResultDtoFromJson(json);

  final List<SyncEventResultDto> results;
  final TodayDto? today;
}

String _utc(DateTime value) => value.toUtc().toIso8601String();
