// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationInputDto _$LocationInputDtoFromJson(Map<String, dynamic> json) => LocationInputDto(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  accuracy: (json['accuracy'] as num).toDouble(),
  capturedAt: DateTime.parse(json['capturedAt'] as String),
);

Map<String, dynamic> _$LocationInputDtoToJson(LocationInputDto instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'accuracy': instance.accuracy,
  'capturedAt': _utc(instance.capturedAt),
};

SyncEventDto _$SyncEventDtoFromJson(Map<String, dynamic> json) => SyncEventDto(
  clientEventId: json['clientEventId'] as String,
  kind: json['kind'] as String,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  workdayId: json['workdayId'] as String?,
  activityId: json['activityId'] as String?,
  activityTypeId: json['activityTypeId'] as String?,
  workOrderId: json['workOrderId'] as String?,
  outcome: $enumDecodeNullable(_$ActivityOutcomeEnumMap, json['outcome']),
  observation: json['observation'] as String?,
  photoCount: (json['photoCount'] as num?)?.toInt(),
  hasSignature: json['hasSignature'] as bool?,
  note: json['note'] as String?,
  location: json['location'] == null ? null : LocationInputDto.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SyncEventDtoToJson(SyncEventDto instance) => <String, dynamic>{
  'clientEventId': instance.clientEventId,
  'kind': instance.kind,
  'occurredAt': _utc(instance.occurredAt),
  'workdayId': ?instance.workdayId,
  'activityId': ?instance.activityId,
  'activityTypeId': ?instance.activityTypeId,
  'workOrderId': ?instance.workOrderId,
  'outcome': ?_$ActivityOutcomeEnumMap[instance.outcome],
  'observation': ?instance.observation,
  'photoCount': ?instance.photoCount,
  'hasSignature': ?instance.hasSignature,
  'note': ?instance.note,
  'location': ?instance.location?.toJson(),
};

const _$ActivityOutcomeEnumMap = {
  ActivityOutcome.completed: 'Completed',
  ActivityOutcome.incomplete: 'Incomplete',
  ActivityOutcome.rescheduled: 'Rescheduled',
};

SyncEventResultDto _$SyncEventResultDtoFromJson(Map<String, dynamic> json) => SyncEventResultDto(
  clientEventId: json['clientEventId'] as String,
  outcome: $enumDecode(_$SyncOutcomeEnumMap, json['outcome']),
  message: json['message'] as String?,
  code: json['code'] as String?,
  resultId: json['resultId'] as String?,
);

const _$SyncOutcomeEnumMap = {
  SyncOutcome.accepted: 'Accepted',
  SyncOutcome.adjusted: 'Adjusted',
  SyncOutcome.rejected: 'Rejected',
};

SyncBatchResultDto _$SyncBatchResultDtoFromJson(Map<String, dynamic> json) => SyncBatchResultDto(
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => SyncEventResultDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  today: json['today'] == null ? null : TodayDto.fromJson(json['today'] as Map<String, dynamic>),
);
