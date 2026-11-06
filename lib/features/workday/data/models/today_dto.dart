import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'today_dto.g.dart';

/// `GET /me/today`: everything the phone needs to decide what to show.
@JsonSerializable()
class TodayDto {
  const TodayDto({
    required this.serverTime,
    required this.date,
    required this.timeZoneId,
    required this.memberName,
    required this.plan,
    required this.policy,
    required this.settings,
    this.branchName,
    this.window,
    this.workday,
    this.absence,
    this.nextShift,
    this.supervisorName,
    this.device = const DeviceStatusDto(),
    this.overtimeUntil,
    this.autoCloseAt,
  });

  factory TodayDto.fromJson(Map<String, dynamic> json) => _$TodayDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TodayDtoToJson(this);

  final DateTime serverTime;

  /// DateOnly `yyyy-MM-dd` in the branch time zone.
  final String date;
  final String timeZoneId;
  final String memberName;
  final String? branchName;
  final DayPlanDto plan;
  final StartWindowDto? window;
  final WorkdayDto? workday;
  final AbsenceInfoDto? absence;
  final NextShiftDto? nextShift;
  final PolicyStatusDto policy;
  final ClientSettingsDto settings;
  final String? supervisorName;

  /// Device control (MobiControl) of this member.
  final DeviceStatusDto device;

  /// End of the approved overtime of today (TimeOnly `HH:mm:ss`).
  final String? overtimeUntil;

  /// When the server closes the workday automatically: end of the shift (or of the approved
  /// overtime) plus the grace minutes.
  final DateTime? autoCloseAt;

  /// Cached snapshot of a previous day, moved to [newDate]: the plan of the new day is unknown
  /// (it is assumed to be a working day; the server has the last word) and only a workday still
  /// open carries over (the server closes forgotten ones).
  TodayDto carriedTo(String newDate) => TodayDto(
    serverTime: serverTime,
    date: newDate,
    timeZoneId: timeZoneId,
    memberName: memberName,
    branchName: branchName,
    plan: const DayPlanDto(kind: DayKind.shift),
    workday: workday?.isOpen == true ? workday : null,
    nextShift: nextShift,
    policy: policy,
    settings: settings,
    supervisorName: supervisorName,
    device: device,
  );
}

@JsonSerializable()
class DayPlanDto {
  const DayPlanDto({
    required this.kind,
    this.start,
    this.end,
    this.lunchMinutes = 0,
    this.scheduledMinutes = 0,
    this.label,
    this.templateName,
    this.dayLetters,
  });

  factory DayPlanDto.fromJson(Map<String, dynamic> json) => _$DayPlanDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DayPlanDtoToJson(this);

  @JsonKey(unknownEnumValue: DayKind.unknown)
  final DayKind kind;

  /// TimeOnly `HH:mm:ss`.
  final String? start;
  final String? end;
  final int lunchMinutes;
  final int scheduledMinutes;
  final String? label;
  final String? templateName;
  final String? dayLetters;
}

@JsonSerializable()
class StartWindowDto {
  const StartWindowDto({
    required this.opensAt,
    required this.shiftStart,
    required this.shiftEnd,
    required this.canStartNow,
    this.blockedReason,
  });

  factory StartWindowDto.fromJson(Map<String, dynamic> json) => _$StartWindowDtoFromJson(json);
  Map<String, dynamic> toJson() => _$StartWindowDtoToJson(this);

  final DateTime opensAt;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final bool canStartNow;
  final String? blockedReason;
}

@JsonSerializable()
class RequirementsDto {
  const RequirementsDto({this.photo = false, this.signature = false, this.observationAlways = false});

  factory RequirementsDto.fromJson(Map<String, dynamic> json) => _$RequirementsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RequirementsDtoToJson(this);

  final bool photo;
  final bool signature;
  final bool observationAlways;
}

@JsonSerializable()
class CurrentActivityDto {
  const CurrentActivityDto({
    required this.id,
    required this.activityTypeId,
    required this.name,
    required this.color,
    required this.timeClass,
    required this.startedAt,
    required this.status,
    required this.requirements,
    this.workOrderNumber,
    this.siteName,
    this.workedSeconds = 0,
    this.pausedSeconds = 0,
    this.pausedSince,
    this.startGeofence = GeofenceStatus.notApplicable,
    this.startAccuracy,
  });

  factory CurrentActivityDto.fromJson(Map<String, dynamic> json) => _$CurrentActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentActivityDtoToJson(this);

  final String id;
  final String activityTypeId;
  final String name;
  final String color;
  final TimeClass timeClass;
  final String? workOrderNumber;
  final String? siteName;
  final DateTime startedAt;
  @JsonKey(unknownEnumValue: ActivityStatus.unknown)
  final ActivityStatus status;

  /// Worked seconds (pauses excluded) as of `TodayDto.serverTime`.
  final int workedSeconds;
  final int pausedSeconds;
  final DateTime? pausedSince;
  @JsonKey(unknownEnumValue: GeofenceStatus.unknown)
  final GeofenceStatus startGeofence;
  final double? startAccuracy;
  final RequirementsDto requirements;
}

@JsonSerializable()
class DaySummaryDto {
  const DaySummaryDto({
    this.activityCount = 0,
    this.productiveMinutes = 0,
    this.paidNonProductiveMinutes = 0,
    this.unproductiveMinutes = 0,
    this.idleMinutes = 0,
    this.withoutActivityMinutes = 0,
    this.pausedMinutes = 0,
    this.elapsedMinutes = 0,
    this.byCategory = const [],
  });

  factory DaySummaryDto.fromJson(Map<String, dynamic> json) => _$DaySummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DaySummaryDtoToJson(this);

  final int activityCount;
  final int productiveMinutes;
  final int paidNonProductiveMinutes;
  final int unproductiveMinutes;
  final int idleMinutes;

  /// Unproductive activities plus gaps between activities ("Sin actividad").
  final int withoutActivityMinutes;
  final int pausedMinutes;
  final int elapsedMinutes;

  /// Minutes per activity category, for the legends.
  final List<CategoryMinutesDto> byCategory;

  /// Hours that count for the day (lunch and pauses excluded).
  int get workedMinutes => productiveMinutes + paidNonProductiveMinutes + withoutActivityMinutes;

  DaySummaryDto copyWith({int? activityCount}) => DaySummaryDto(
    activityCount: activityCount ?? this.activityCount,
    productiveMinutes: productiveMinutes,
    paidNonProductiveMinutes: paidNonProductiveMinutes,
    unproductiveMinutes: unproductiveMinutes,
    idleMinutes: idleMinutes,
    withoutActivityMinutes: withoutActivityMinutes,
    pausedMinutes: pausedMinutes,
    elapsedMinutes: elapsedMinutes,
    byCategory: byCategory,
  );
}

@JsonSerializable()
class WorkdayDto {
  const WorkdayDto({
    required this.id,
    required this.date,
    required this.status,
    required this.startedAt,
    required this.summary,
    this.endedAt,
    this.startAdjusted = false,
    this.lateMinutes = 0,
    this.startGeofence = GeofenceStatus.notApplicable,
    this.startSiteName,
    this.closeKind,
    this.note,
    this.current,
  });

  factory WorkdayDto.fromJson(Map<String, dynamic> json) => _$WorkdayDtoFromJson(json);
  Map<String, dynamic> toJson() => _$WorkdayDtoToJson(this);

  final String id;
  final String date;
  @JsonKey(unknownEnumValue: WorkdayStatus.unknown)
  final WorkdayStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool startAdjusted;
  final int lateMinutes;
  @JsonKey(unknownEnumValue: GeofenceStatus.unknown)
  final GeofenceStatus startGeofence;
  final String? startSiteName;
  final CloseKind? closeKind;
  final String? note;
  final CurrentActivityDto? current;
  final DaySummaryDto summary;

  bool get isOpen => status == WorkdayStatus.open;
}

@JsonSerializable()
class AbsenceInfoDto {
  const AbsenceInfoDto({required this.label, required this.from, required this.to, this.approvedBy});

  factory AbsenceInfoDto.fromJson(Map<String, dynamic> json) => _$AbsenceInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AbsenceInfoDtoToJson(this);

  final String label;
  final String from;
  final String to;
  final String? approvedBy;
}

/// Device control of the member (MobiControl). With control, the workday opens and hides the
/// corporate apps and the shift end warnings follow [warningMinutes].
@JsonSerializable()
class DeviceStatusDto {
  const DeviceStatusDto({
    this.controlEnabled = false,
    this.isShared = false,
    this.deviceModel,
    this.warningMinutes = const [],
    this.logoutSharedOnClose = false,
    this.corporateApps = const [],
    this.alwaysAvailableApps = const [],
  });

  factory DeviceStatusDto.fromJson(Map<String, dynamic> json) => _$DeviceStatusDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceStatusDtoToJson(this);

  final bool controlEnabled;
  final bool isShared;
  final String? deviceModel;
  final List<int> warningMinutes;
  final bool logoutSharedOnClose;
  final List<String> corporateApps;
  final List<String> alwaysAvailableApps;
}

/// Minutes of a category in the day ("Productivo", "Traslado"…).
@JsonSerializable()
class CategoryMinutesDto {
  const CategoryMinutesDto({required this.name, required this.color, required this.timeClass, this.minutes = 0});

  factory CategoryMinutesDto.fromJson(Map<String, dynamic> json) => _$CategoryMinutesDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryMinutesDtoToJson(this);

  final String name;
  final String color;
  final TimeClass timeClass;
  final int minutes;
}

@JsonSerializable()
class NextShiftDto {
  const NextShiftDto({
    required this.date,
    required this.start,
    required this.end,
    this.templateName,
    this.notes = const [],
  });

  factory NextShiftDto.fromJson(Map<String, dynamic> json) => _$NextShiftDtoFromJson(json);
  Map<String, dynamic> toJson() => _$NextShiftDtoToJson(this);

  final String date;
  final String start;
  final String end;
  final String? templateName;
  final List<String> notes;
}

@JsonSerializable()
class PolicyStatusDto {
  const PolicyStatusDto({this.currentVersion, this.accepted = false, this.effectiveFrom});

  factory PolicyStatusDto.fromJson(Map<String, dynamic> json) => _$PolicyStatusDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PolicyStatusDtoToJson(this);

  final String? currentVersion;
  final bool accepted;
  final String? effectiveFrom;
}

/// Parameters the phone needs to sample and warn without asking the server.
@JsonSerializable()
class ClientSettingsDto {
  const ClientSettingsDto({
    this.samplingMinutes = 15,
    this.minGpsAccuracyMeters = 50,
    this.inactivityAlertMinutes = 20,
    this.shiftEndWarningMinutes = 15,
    this.maxPauseMinutes = 30,
    this.autoCloseGraceMinutes = 10,
  });

  factory ClientSettingsDto.fromJson(Map<String, dynamic> json) => _$ClientSettingsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ClientSettingsDtoToJson(this);

  final int samplingMinutes;
  final int minGpsAccuracyMeters;
  final int inactivityAlertMinutes;
  final int shiftEndWarningMinutes;
  final int maxPauseMinutes;
  final int autoCloseGraceMinutes;
}
