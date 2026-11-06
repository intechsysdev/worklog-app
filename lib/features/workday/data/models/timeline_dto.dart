import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';
import 'today_dto.dart';

part 'timeline_dto.g.dart';

/// `GET /me/timeline?date`: bar segments and the list (most recent first).
@JsonSerializable()
class TimelineDto {
  const TimelineDto({
    required this.date,
    this.shiftStart,
    this.shiftEnd,
    this.workday,
    this.segments = const [],
    this.entries = const [],
  });

  factory TimelineDto.fromJson(Map<String, dynamic> json) => _$TimelineDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TimelineDtoToJson(this);

  final String date;
  final String? shiftStart;
  final String? shiftEnd;
  final WorkdayDto? workday;
  final List<SegmentDto> segments;
  final List<TimelineEntryDto> entries;
}

@JsonSerializable()
class SegmentDto {
  const SegmentDto({
    required this.kind,
    required this.start,
    required this.title,
    required this.color,
    this.end,
    this.minutes = 0,
    this.timeClass,
  });

  factory SegmentDto.fromJson(Map<String, dynamic> json) => _$SegmentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SegmentDtoToJson(this);

  final SegmentKind kind;
  final DateTime start;
  final DateTime? end;
  final int minutes;
  final String title;
  final String color;
  final TimeClass? timeClass;
}

@JsonSerializable()
class TimelineEntryDto {
  const TimelineEntryDto({
    required this.kind,
    required this.title,
    required this.start,
    required this.color,
    this.end,
    this.minutes = 0,
    this.running = false,
    this.workOrderNumber,
    this.siteName,
    this.outcome,
    this.outcomeLabel,
    this.autoFinished = false,
    this.photoCount = 0,
    this.hasSignature = false,
    this.geofence = GeofenceStatus.notApplicable,
  });

  factory TimelineEntryDto.fromJson(Map<String, dynamic> json) => _$TimelineEntryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TimelineEntryDtoToJson(this);

  /// `start`, `activity`, `idle` or `close`.
  final String kind;
  final String title;
  final DateTime start;
  final DateTime? end;
  final int minutes;
  final String color;
  final bool running;
  final String? workOrderNumber;
  final String? siteName;
  final ActivityOutcome? outcome;
  final String? outcomeLabel;
  final bool autoFinished;
  final int photoCount;
  final bool hasSignature;
  @JsonKey(unknownEnumValue: GeofenceStatus.unknown)
  final GeofenceStatus geofence;
}
