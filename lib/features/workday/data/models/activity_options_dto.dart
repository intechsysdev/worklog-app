import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'activity_options_dto.g.dart';

/// `GET /me/workday/activity-options`.
@JsonSerializable()
class ActivityOptionsDto {
  const ActivityOptionsDto({this.assigned = const [], this.catalog = const [], this.outcomes = const []});

  factory ActivityOptionsDto.fromJson(Map<String, dynamic> json) => _$ActivityOptionsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityOptionsDtoToJson(this);

  /// Work orders scheduled for today.
  final List<AssignedOptionDto> assigned;
  final List<CatalogOptionDto> catalog;
  final List<OutcomeDto> outcomes;

  CatalogOptionDto? catalogFor(String activityTypeId) {
    for (final c in catalog) {
      if (c.activityTypeId == activityTypeId) return c;
    }
    return null;
  }

  OutcomeDto? outcomeFor(ActivityOutcome outcome) {
    for (final o in outcomes) {
      if (o.outcome == outcome) return o;
    }
    return null;
  }
}

@JsonSerializable()
class AssignedOptionDto {
  const AssignedOptionDto({
    required this.workOrderId,
    required this.number,
    required this.activityTypeId,
    required this.title,
    this.siteName,
    this.scheduledTime,
    this.status = WorkOrderStatus.open,
  });

  factory AssignedOptionDto.fromJson(Map<String, dynamic> json) => _$AssignedOptionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AssignedOptionDtoToJson(this);

  final String workOrderId;
  final String number;
  final String activityTypeId;
  final String title;
  final String? siteName;

  /// TimeOnly `HH:mm:ss`.
  final String? scheduledTime;
  @JsonKey(unknownEnumValue: WorkOrderStatus.unknown)
  final WorkOrderStatus status;
}

@JsonSerializable()
class CatalogOptionDto {
  const CatalogOptionDto({
    required this.activityTypeId,
    required this.title,
    required this.categoryName,
    required this.timeClass,
    required this.color,
    this.requiresPhoto = false,
    this.requiresSignature = false,
    this.observation = ObservationPolicy.optional,
  });

  factory CatalogOptionDto.fromJson(Map<String, dynamic> json) => _$CatalogOptionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogOptionDtoToJson(this);

  final String activityTypeId;
  final String title;
  final String categoryName;
  final TimeClass timeClass;
  final String color;
  final bool requiresPhoto;
  final bool requiresSignature;
  final ObservationPolicy observation;
}

@JsonSerializable()
class OutcomeDto {
  const OutcomeDto({
    required this.outcome,
    required this.label,
    this.description = '',
    this.requiresObservation = false,
  });

  factory OutcomeDto.fromJson(Map<String, dynamic> json) => _$OutcomeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OutcomeDtoToJson(this);

  /// Used when the catalog was never downloaded.
  static const defaults = [
    OutcomeDto(outcome: ActivityOutcome.completed, label: 'Completada'),
    OutcomeDto(outcome: ActivityOutcome.incomplete, label: 'Incompleta', requiresObservation: true),
    OutcomeDto(outcome: ActivityOutcome.rescheduled, label: 'Reprogramar', requiresObservation: true),
  ];

  final ActivityOutcome outcome;
  final String label;
  final String description;
  final bool requiresObservation;
}
