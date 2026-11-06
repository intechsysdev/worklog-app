// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyWeekDto _$MyWeekDtoFromJson(Map<String, dynamic> json) => MyWeekDto(
  from: json['from'] as String,
  to: json['to'] as String,
  provisionalUntil: json['provisionalUntil'] as String,
  workedMinutes: (json['workedMinutes'] as num?)?.toInt() ?? 0,
  weeklyCapMinutes: (json['weeklyCapMinutes'] as num?)?.toInt() ?? 0,
  scheduledMinutes: (json['scheduledMinutes'] as num?)?.toInt() ?? 0,
  remainingMinutes: (json['remainingMinutes'] as num?)?.toInt() ?? 0,
  approvedOvertimeMinutes: (json['approvedOvertimeMinutes'] as num?)?.toInt() ?? 0,
  overtimeWeeklyMaxMinutes: (json['overtimeWeeklyMaxMinutes'] as num?)?.toInt() ?? 0,
  breakdown: json['breakdown'] == null
      ? const BreakdownDto()
      : BreakdownDto.fromJson(json['breakdown'] as Map<String, dynamic>),
  days:
      (json['days'] as List<dynamic>?)?.map((e) => WeekDayDto.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
);

Map<String, dynamic> _$MyWeekDtoToJson(MyWeekDto instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'workedMinutes': instance.workedMinutes,
  'weeklyCapMinutes': instance.weeklyCapMinutes,
  'scheduledMinutes': instance.scheduledMinutes,
  'remainingMinutes': instance.remainingMinutes,
  'approvedOvertimeMinutes': instance.approvedOvertimeMinutes,
  'overtimeWeeklyMaxMinutes': instance.overtimeWeeklyMaxMinutes,
  'breakdown': instance.breakdown.toJson(),
  'days': instance.days.map((e) => e.toJson()).toList(),
  'provisionalUntil': instance.provisionalUntil,
};

BreakdownDto _$BreakdownDtoFromJson(Map<String, dynamic> json) => BreakdownDto(
  ordinaryDay: (json['ordinaryDay'] as num?)?.toInt() ?? 0,
  ordinaryNight: (json['ordinaryNight'] as num?)?.toInt() ?? 0,
  overtimeDay: (json['overtimeDay'] as num?)?.toInt() ?? 0,
  overtimeNight: (json['overtimeNight'] as num?)?.toInt() ?? 0,
  sundayHoliday: (json['sundayHoliday'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BreakdownDtoToJson(BreakdownDto instance) => <String, dynamic>{
  'ordinaryDay': instance.ordinaryDay,
  'ordinaryNight': instance.ordinaryNight,
  'overtimeDay': instance.overtimeDay,
  'overtimeNight': instance.overtimeNight,
  'sundayHoliday': instance.sundayHoliday,
  'total': instance.total,
};

WeekDayDto _$WeekDayDtoFromJson(Map<String, dynamic> json) => WeekDayDto(
  date: json['date'] as String,
  planKind: $enumDecode(_$DayKindEnumMap, json['planKind'], unknownValue: DayKind.unknown),
  planLabel: json['planLabel'] as String?,
  scheduledMinutes: (json['scheduledMinutes'] as num?)?.toInt() ?? 0,
  workedMinutes: (json['workedMinutes'] as num?)?.toInt() ?? 0,
  isToday: json['isToday'] as bool? ?? false,
  inProgress: json['inProgress'] as bool? ?? false,
);

Map<String, dynamic> _$WeekDayDtoToJson(WeekDayDto instance) => <String, dynamic>{
  'date': instance.date,
  'planKind': _$DayKindEnumMap[instance.planKind]!,
  'planLabel': ?instance.planLabel,
  'scheduledMinutes': instance.scheduledMinutes,
  'workedMinutes': instance.workedMinutes,
  'isToday': instance.isToday,
  'inProgress': instance.inProgress,
};

const _$DayKindEnumMap = {
  DayKind.shift: 'Shift',
  DayKind.absence: 'Absence',
  DayKind.override: 'Override',
  DayKind.holiday: 'Holiday',
  DayKind.rest: 'Rest',
  DayKind.unscheduled: 'Unscheduled',
  DayKind.unknown: 'Unknown',
};
