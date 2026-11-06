import 'package:json_annotation/json_annotation.dart';

part 'request_models.g.dart';

@JsonEnum(fieldRename: FieldRename.pascal)
enum RequestType { recordAdjustment, overtime, shiftChange, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum RequestStatus { pending, approved, rejected, cancelled, unknown }

@JsonEnum(fieldRename: FieldRename.pascal)
enum AdjustmentTarget { workdayStart, workdayEnd, activityStart, activityEnd }

extension AdjustmentTargetX on AdjustmentTarget {
  String get wire => switch (this) {
    AdjustmentTarget.workdayStart => 'WorkdayStart',
    AdjustmentTarget.workdayEnd => 'WorkdayEnd',
    AdjustmentTarget.activityStart => 'ActivityStart',
    AdjustmentTarget.activityEnd => 'ActivityEnd',
  };

  bool get isActivity => this == AdjustmentTarget.activityStart || this == AdjustmentTarget.activityEnd;

  String get label => switch (this) {
    AdjustmentTarget.workdayStart => 'Inicio de jornada',
    AdjustmentTarget.workdayEnd => 'Fin de jornada',
    AdjustmentTarget.activityStart => 'Inicio de actividad',
    AdjustmentTarget.activityEnd => 'Fin de actividad',
  };
}

extension RequestTypeX on RequestType {
  String get label => switch (this) {
    RequestType.recordAdjustment => 'Ajuste de registro',
    RequestType.overtime => 'Horas extra',
    RequestType.shiftChange => 'Cambio de turno',
    RequestType.unknown => 'Solicitud',
  };
}

extension RequestStatusX on RequestStatus {
  String get label => switch (this) {
    RequestStatus.pending => 'Pendiente',
    RequestStatus.approved => 'Aprobada',
    RequestStatus.rejected => 'Rechazada',
    RequestStatus.cancelled => 'Cancelada',
    RequestStatus.unknown => '—',
  };

  bool get isResolved => this != RequestStatus.pending;
}

/// A day proposed in a shift change. Without [start] and [end] the day is proposed as day off.
@JsonSerializable()
class ShiftChangeDayDto {
  const ShiftChangeDayDto({required this.date, this.start, this.end, this.lunchMinutes = 0});

  factory ShiftChangeDayDto.fromJson(Map<String, dynamic> json) => _$ShiftChangeDayDtoFromJson(json);

  /// Nulls are sent explicitly: a day without hours means "day off".
  Map<String, dynamic> toJson() => {'date': date, 'start': start, 'end': end, 'lunchMinutes': lunchMinutes};

  final String date;

  /// TimeOnly `HH:mm:ss`.
  final String? start;
  final String? end;
  final int lunchMinutes;

  bool get isDayOff => start == null && end == null;
}

@JsonSerializable(createToJson: false)
class RequestDto {
  const RequestDto({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.submittedAt,
    this.memberName = '',
    this.detail = '',
    this.reason = '',
    this.date,
    this.workdayId,
    this.activityRecordId,
    this.target,
    this.originalValue,
    this.proposedValue,
    this.overtimeFrom,
    this.overtimeTo,
    this.authorizationReference,
    this.days = const [],
    this.resolverName,
    this.resolvedAt,
    this.resolverComment,
  });

  factory RequestDto.fromJson(Map<String, dynamic> json) => _$RequestDtoFromJson(json);

  final String id;
  final String memberName;
  @JsonKey(unknownEnumValue: RequestType.unknown)
  final RequestType type;
  @JsonKey(unknownEnumValue: RequestStatus.unknown)
  final RequestStatus status;
  final String title;
  final String detail;
  final String reason;
  final String? date;
  final DateTime submittedAt;
  final String? workdayId;
  final String? activityRecordId;
  final AdjustmentTarget? target;
  final DateTime? originalValue;
  final DateTime? proposedValue;
  final String? overtimeFrom;
  final String? overtimeTo;
  final String? authorizationReference;
  final List<ShiftChangeDayDto> days;
  final String? resolverName;
  final DateTime? resolvedAt;
  final String? resolverComment;
}

@JsonSerializable(createToJson: false)
class RequestPageDto {
  const RequestPageDto({this.items = const [], this.totalCount = 0, this.hasNext = false});

  factory RequestPageDto.fromJson(Map<String, dynamic> json) => _$RequestPageDtoFromJson(json);

  final List<RequestDto> items;
  final int totalCount;
  final bool hasNext;
}
