import 'package:json_annotation/json_annotation.dart';

import '../../workday/data/models/enums.dart';

part 'week_models.g.dart';

/// `GET /me/week?date`: hours of the week of [date], provisional until the period closes.
@JsonSerializable()
class MyWeekDto {
  const MyWeekDto({
    required this.from,
    required this.to,
    required this.provisionalUntil,
    this.workedMinutes = 0,
    this.weeklyCapMinutes = 0,
    this.scheduledMinutes = 0,
    this.remainingMinutes = 0,
    this.approvedOvertimeMinutes = 0,
    this.overtimeWeeklyMaxMinutes = 0,
    this.breakdown = const BreakdownDto(),
    this.days = const [],
  });

  factory MyWeekDto.fromJson(Map<String, dynamic> json) => _$MyWeekDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MyWeekDtoToJson(this);

  /// DateOnly of the Monday and the Sunday.
  final String from;
  final String to;
  final int workedMinutes;

  /// Legal weekly maximum (42 h in Colombia).
  final int weeklyCapMinutes;
  final int scheduledMinutes;
  final int remainingMinutes;
  final int approvedOvertimeMinutes;
  final int overtimeWeeklyMaxMinutes;
  final BreakdownDto breakdown;
  final List<WeekDayDto> days;

  /// DateOnly of the period close.
  final String provisionalUntil;
}

@JsonSerializable()
class BreakdownDto {
  const BreakdownDto({
    this.ordinaryDay = 0,
    this.ordinaryNight = 0,
    this.overtimeDay = 0,
    this.overtimeNight = 0,
    this.sundayHoliday = 0,
    this.total = 0,
  });

  factory BreakdownDto.fromJson(Map<String, dynamic> json) => _$BreakdownDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BreakdownDtoToJson(this);

  final int ordinaryDay;
  final int ordinaryNight;
  final int overtimeDay;
  final int overtimeNight;
  final int sundayHoliday;
  final int total;
}

@JsonSerializable()
class WeekDayDto {
  const WeekDayDto({
    required this.date,
    required this.planKind,
    this.planLabel,
    this.scheduledMinutes = 0,
    this.workedMinutes = 0,
    this.isToday = false,
    this.inProgress = false,
  });

  factory WeekDayDto.fromJson(Map<String, dynamic> json) => _$WeekDayDtoFromJson(json);
  Map<String, dynamic> toJson() => _$WeekDayDtoToJson(this);

  final String date;
  @JsonKey(unknownEnumValue: DayKind.unknown)
  final DayKind planKind;
  final String? planLabel;
  final int scheduledMinutes;
  final int workedMinutes;
  final bool isToday;
  final bool inProgress;
}
