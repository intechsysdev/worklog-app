// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftChangeDayDto _$ShiftChangeDayDtoFromJson(Map<String, dynamic> json) => ShiftChangeDayDto(
  date: json['date'] as String,
  start: json['start'] as String?,
  end: json['end'] as String?,
  lunchMinutes: (json['lunchMinutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ShiftChangeDayDtoToJson(ShiftChangeDayDto instance) => <String, dynamic>{
  'date': instance.date,
  'start': ?instance.start,
  'end': ?instance.end,
  'lunchMinutes': instance.lunchMinutes,
};

RequestDto _$RequestDtoFromJson(Map<String, dynamic> json) => RequestDto(
  id: json['id'] as String,
  type: $enumDecode(_$RequestTypeEnumMap, json['type'], unknownValue: RequestType.unknown),
  status: $enumDecode(_$RequestStatusEnumMap, json['status'], unknownValue: RequestStatus.unknown),
  title: json['title'] as String,
  submittedAt: DateTime.parse(json['submittedAt'] as String),
  memberName: json['memberName'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  reason: json['reason'] as String? ?? '',
  date: json['date'] as String?,
  workdayId: json['workdayId'] as String?,
  activityRecordId: json['activityRecordId'] as String?,
  target: $enumDecodeNullable(_$AdjustmentTargetEnumMap, json['target']),
  originalValue: json['originalValue'] == null ? null : DateTime.parse(json['originalValue'] as String),
  proposedValue: json['proposedValue'] == null ? null : DateTime.parse(json['proposedValue'] as String),
  overtimeFrom: json['overtimeFrom'] as String?,
  overtimeTo: json['overtimeTo'] as String?,
  authorizationReference: json['authorizationReference'] as String?,
  days:
      (json['days'] as List<dynamic>?)?.map((e) => ShiftChangeDayDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  resolverName: json['resolverName'] as String?,
  resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String),
  resolverComment: json['resolverComment'] as String?,
);

const _$RequestTypeEnumMap = {
  RequestType.recordAdjustment: 'RecordAdjustment',
  RequestType.overtime: 'Overtime',
  RequestType.shiftChange: 'ShiftChange',
  RequestType.unknown: 'Unknown',
};

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'Pending',
  RequestStatus.approved: 'Approved',
  RequestStatus.rejected: 'Rejected',
  RequestStatus.cancelled: 'Cancelled',
  RequestStatus.unknown: 'Unknown',
};

const _$AdjustmentTargetEnumMap = {
  AdjustmentTarget.workdayStart: 'WorkdayStart',
  AdjustmentTarget.workdayEnd: 'WorkdayEnd',
  AdjustmentTarget.activityStart: 'ActivityStart',
  AdjustmentTarget.activityEnd: 'ActivityEnd',
};

RequestPageDto _$RequestPageDtoFromJson(Map<String, dynamic> json) => RequestPageDto(
  items:
      (json['items'] as List<dynamic>?)?.map((e) => RequestDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
  hasNext: json['hasNext'] as bool? ?? false,
);
