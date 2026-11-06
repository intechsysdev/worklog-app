// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimelineDto _$TimelineDtoFromJson(Map<String, dynamic> json) => TimelineDto(
  date: json['date'] as String,
  shiftStart: json['shiftStart'] as String?,
  shiftEnd: json['shiftEnd'] as String?,
  workday: json['workday'] == null ? null : WorkdayDto.fromJson(json['workday'] as Map<String, dynamic>),
  segments:
      (json['segments'] as List<dynamic>?)?.map((e) => SegmentDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  entries:
      (json['entries'] as List<dynamic>?)?.map((e) => TimelineEntryDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
);

Map<String, dynamic> _$TimelineDtoToJson(TimelineDto instance) => <String, dynamic>{
  'date': instance.date,
  'shiftStart': ?instance.shiftStart,
  'shiftEnd': ?instance.shiftEnd,
  'workday': ?instance.workday?.toJson(),
  'segments': instance.segments.map((e) => e.toJson()).toList(),
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};

SegmentDto _$SegmentDtoFromJson(Map<String, dynamic> json) => SegmentDto(
  kind: $enumDecode(_$SegmentKindEnumMap, json['kind']),
  start: DateTime.parse(json['start'] as String),
  title: json['title'] as String,
  color: json['color'] as String,
  end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
  minutes: (json['minutes'] as num?)?.toInt() ?? 0,
  timeClass: $enumDecodeNullable(_$TimeClassEnumMap, json['timeClass']),
);

Map<String, dynamic> _$SegmentDtoToJson(SegmentDto instance) => <String, dynamic>{
  'kind': _$SegmentKindEnumMap[instance.kind]!,
  'start': instance.start.toIso8601String(),
  'end': ?instance.end?.toIso8601String(),
  'minutes': instance.minutes,
  'title': instance.title,
  'color': instance.color,
  'timeClass': ?_$TimeClassEnumMap[instance.timeClass],
};

const _$SegmentKindEnumMap = {SegmentKind.activity: 'Activity', SegmentKind.idle: 'Idle'};

const _$TimeClassEnumMap = {
  TimeClass.productive: 'Productive',
  TimeClass.paidNonProductive: 'PaidNonProductive',
  TimeClass.unproductive: 'Unproductive',
};

TimelineEntryDto _$TimelineEntryDtoFromJson(Map<String, dynamic> json) => TimelineEntryDto(
  kind: json['kind'] as String,
  title: json['title'] as String,
  start: DateTime.parse(json['start'] as String),
  color: json['color'] as String,
  end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
  minutes: (json['minutes'] as num?)?.toInt() ?? 0,
  running: json['running'] as bool? ?? false,
  workOrderNumber: json['workOrderNumber'] as String?,
  siteName: json['siteName'] as String?,
  outcome: $enumDecodeNullable(_$ActivityOutcomeEnumMap, json['outcome']),
  outcomeLabel: json['outcomeLabel'] as String?,
  autoFinished: json['autoFinished'] as bool? ?? false,
  photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
  hasSignature: json['hasSignature'] as bool? ?? false,
  geofence:
      $enumDecodeNullable(_$GeofenceStatusEnumMap, json['geofence'], unknownValue: GeofenceStatus.unknown) ??
      GeofenceStatus.notApplicable,
);

Map<String, dynamic> _$TimelineEntryDtoToJson(TimelineEntryDto instance) => <String, dynamic>{
  'kind': instance.kind,
  'title': instance.title,
  'start': instance.start.toIso8601String(),
  'end': ?instance.end?.toIso8601String(),
  'minutes': instance.minutes,
  'color': instance.color,
  'running': instance.running,
  'workOrderNumber': ?instance.workOrderNumber,
  'siteName': ?instance.siteName,
  'outcome': ?_$ActivityOutcomeEnumMap[instance.outcome],
  'outcomeLabel': ?instance.outcomeLabel,
  'autoFinished': instance.autoFinished,
  'photoCount': instance.photoCount,
  'hasSignature': instance.hasSignature,
  'geofence': _$GeofenceStatusEnumMap[instance.geofence]!,
};

const _$ActivityOutcomeEnumMap = {
  ActivityOutcome.completed: 'Completed',
  ActivityOutcome.incomplete: 'Incomplete',
  ActivityOutcome.rescheduled: 'Rescheduled',
};

const _$GeofenceStatusEnumMap = {
  GeofenceStatus.notApplicable: 'NotApplicable',
  GeofenceStatus.inside: 'Inside',
  GeofenceStatus.outside: 'Outside',
  GeofenceStatus.unknown: 'Unknown',
  GeofenceStatus.noLocation: 'NoLocation',
};
