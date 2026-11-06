// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_options_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityOptionsDto _$ActivityOptionsDtoFromJson(Map<String, dynamic> json) => ActivityOptionsDto(
  assigned:
      (json['assigned'] as List<dynamic>?)
          ?.map((e) => AssignedOptionDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  catalog:
      (json['catalog'] as List<dynamic>?)?.map((e) => CatalogOptionDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  outcomes:
      (json['outcomes'] as List<dynamic>?)?.map((e) => OutcomeDto.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
);

Map<String, dynamic> _$ActivityOptionsDtoToJson(ActivityOptionsDto instance) => <String, dynamic>{
  'assigned': instance.assigned.map((e) => e.toJson()).toList(),
  'catalog': instance.catalog.map((e) => e.toJson()).toList(),
  'outcomes': instance.outcomes.map((e) => e.toJson()).toList(),
};

AssignedOptionDto _$AssignedOptionDtoFromJson(Map<String, dynamic> json) => AssignedOptionDto(
  workOrderId: json['workOrderId'] as String,
  number: json['number'] as String,
  activityTypeId: json['activityTypeId'] as String,
  title: json['title'] as String,
  siteName: json['siteName'] as String?,
  scheduledTime: json['scheduledTime'] as String?,
  status:
      $enumDecodeNullable(_$WorkOrderStatusEnumMap, json['status'], unknownValue: WorkOrderStatus.unknown) ??
      WorkOrderStatus.open,
);

Map<String, dynamic> _$AssignedOptionDtoToJson(AssignedOptionDto instance) => <String, dynamic>{
  'workOrderId': instance.workOrderId,
  'number': instance.number,
  'activityTypeId': instance.activityTypeId,
  'title': instance.title,
  'siteName': ?instance.siteName,
  'scheduledTime': ?instance.scheduledTime,
  'status': _$WorkOrderStatusEnumMap[instance.status]!,
};

const _$WorkOrderStatusEnumMap = {
  WorkOrderStatus.open: 'Open',
  WorkOrderStatus.inProgress: 'InProgress',
  WorkOrderStatus.completed: 'Completed',
  WorkOrderStatus.incomplete: 'Incomplete',
  WorkOrderStatus.rescheduled: 'Rescheduled',
  WorkOrderStatus.cancelled: 'Cancelled',
  WorkOrderStatus.unknown: 'Unknown',
};

CatalogOptionDto _$CatalogOptionDtoFromJson(Map<String, dynamic> json) => CatalogOptionDto(
  activityTypeId: json['activityTypeId'] as String,
  title: json['title'] as String,
  categoryName: json['categoryName'] as String,
  timeClass: $enumDecode(_$TimeClassEnumMap, json['timeClass']),
  color: json['color'] as String,
  requiresPhoto: json['requiresPhoto'] as bool? ?? false,
  requiresSignature: json['requiresSignature'] as bool? ?? false,
  observation: $enumDecodeNullable(_$ObservationPolicyEnumMap, json['observation']) ?? ObservationPolicy.optional,
);

Map<String, dynamic> _$CatalogOptionDtoToJson(CatalogOptionDto instance) => <String, dynamic>{
  'activityTypeId': instance.activityTypeId,
  'title': instance.title,
  'categoryName': instance.categoryName,
  'timeClass': _$TimeClassEnumMap[instance.timeClass]!,
  'color': instance.color,
  'requiresPhoto': instance.requiresPhoto,
  'requiresSignature': instance.requiresSignature,
  'observation': _$ObservationPolicyEnumMap[instance.observation]!,
};

const _$TimeClassEnumMap = {
  TimeClass.productive: 'Productive',
  TimeClass.paidNonProductive: 'PaidNonProductive',
  TimeClass.unproductive: 'Unproductive',
};

const _$ObservationPolicyEnumMap = {ObservationPolicy.optional: 'Optional', ObservationPolicy.always: 'Always'};

OutcomeDto _$OutcomeDtoFromJson(Map<String, dynamic> json) => OutcomeDto(
  outcome: $enumDecode(_$ActivityOutcomeEnumMap, json['outcome']),
  label: json['label'] as String,
  description: json['description'] as String? ?? '',
  requiresObservation: json['requiresObservation'] as bool? ?? false,
);

Map<String, dynamic> _$OutcomeDtoToJson(OutcomeDto instance) => <String, dynamic>{
  'outcome': _$ActivityOutcomeEnumMap[instance.outcome]!,
  'label': instance.label,
  'description': instance.description,
  'requiresObservation': instance.requiresObservation,
};

const _$ActivityOutcomeEnumMap = {
  ActivityOutcome.completed: 'Completed',
  ActivityOutcome.incomplete: 'Incomplete',
  ActivityOutcome.rescheduled: 'Rescheduled',
};
