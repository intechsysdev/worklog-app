import 'package:json_annotation/json_annotation.dart';

// Enums travel as text in PascalCase (`JsonStringEnumConverter` of the API). Fields that could
// receive a value added later by the server declare an `unknown` fallback.

@JsonEnum(fieldRename: FieldRename.pascal)
enum DayKind { shift, absence, override, holiday, rest, unscheduled, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum WorkdayStatus { open, closed, pendingReview, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum ActivityStatus { running, paused, finished, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum GeofenceStatus { notApplicable, inside, outside, unknown, noLocation }

@JsonEnum(fieldRename: FieldRename.pascal)
enum TimeClass { productive, paidNonProductive, unproductive }

@JsonEnum(fieldRename: FieldRename.pascal)
enum ActivityOutcome { completed, incomplete, rescheduled }

@JsonEnum(fieldRename: FieldRename.pascal)
enum SyncOutcome { accepted, adjusted, rejected }

@JsonEnum(fieldRename: FieldRename.pascal)
enum SegmentKind { activity, idle }

@JsonEnum(fieldRename: FieldRename.pascal)
enum CloseKind { manual, automatic }

@JsonEnum(fieldRename: FieldRename.pascal)
enum WorkOrderStatus { open, inProgress, completed, incomplete, rescheduled, cancelled, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum ObservationPolicy { optional, always }

@JsonEnum(fieldRename: FieldRename.pascal)
enum EvidenceKind { photo, signature }

extension DayKindX on DayKind {
  /// Days on which a workday can be started.
  bool get isWorkingDay => this == DayKind.shift || this == DayKind.override;
}

extension ActivityOutcomeX on ActivityOutcome {
  /// Wire value (`Completed`).
  String get wire => switch (this) {
    ActivityOutcome.completed => 'Completed',
    ActivityOutcome.incomplete => 'Incomplete',
    ActivityOutcome.rescheduled => 'Rescheduled',
  };

  String get defaultLabel => switch (this) {
    ActivityOutcome.completed => 'Completada',
    ActivityOutcome.incomplete => 'Incompleta',
    ActivityOutcome.rescheduled => 'Reprogramar',
  };
}

extension EvidenceKindX on EvidenceKind {
  String get wire => this == EvidenceKind.photo ? 'Photo' : 'Signature';
}
