// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodayDto _$TodayDtoFromJson(Map<String, dynamic> json) => TodayDto(
  serverTime: DateTime.parse(json['serverTime'] as String),
  date: json['date'] as String,
  timeZoneId: json['timeZoneId'] as String,
  memberName: json['memberName'] as String,
  plan: DayPlanDto.fromJson(json['plan'] as Map<String, dynamic>),
  policy: PolicyStatusDto.fromJson(json['policy'] as Map<String, dynamic>),
  settings: ClientSettingsDto.fromJson(json['settings'] as Map<String, dynamic>),
  branchName: json['branchName'] as String?,
  window: json['window'] == null ? null : StartWindowDto.fromJson(json['window'] as Map<String, dynamic>),
  workday: json['workday'] == null ? null : WorkdayDto.fromJson(json['workday'] as Map<String, dynamic>),
  absence: json['absence'] == null ? null : AbsenceInfoDto.fromJson(json['absence'] as Map<String, dynamic>),
  nextShift: json['nextShift'] == null ? null : NextShiftDto.fromJson(json['nextShift'] as Map<String, dynamic>),
  supervisorName: json['supervisorName'] as String?,
  device: json['device'] == null
      ? const DeviceStatusDto()
      : DeviceStatusDto.fromJson(json['device'] as Map<String, dynamic>),
  overtimeUntil: json['overtimeUntil'] as String?,
  autoCloseAt: json['autoCloseAt'] == null ? null : DateTime.parse(json['autoCloseAt'] as String),
);

Map<String, dynamic> _$TodayDtoToJson(TodayDto instance) => <String, dynamic>{
  'serverTime': instance.serverTime.toIso8601String(),
  'date': instance.date,
  'timeZoneId': instance.timeZoneId,
  'memberName': instance.memberName,
  'branchName': ?instance.branchName,
  'plan': instance.plan.toJson(),
  'window': ?instance.window?.toJson(),
  'workday': ?instance.workday?.toJson(),
  'absence': ?instance.absence?.toJson(),
  'nextShift': ?instance.nextShift?.toJson(),
  'policy': instance.policy.toJson(),
  'settings': instance.settings.toJson(),
  'supervisorName': ?instance.supervisorName,
  'device': instance.device.toJson(),
  'overtimeUntil': ?instance.overtimeUntil,
  'autoCloseAt': ?instance.autoCloseAt?.toIso8601String(),
};

DayPlanDto _$DayPlanDtoFromJson(Map<String, dynamic> json) => DayPlanDto(
  kind: $enumDecode(_$DayKindEnumMap, json['kind'], unknownValue: DayKind.unknown),
  start: json['start'] as String?,
  end: json['end'] as String?,
  lunchMinutes: (json['lunchMinutes'] as num?)?.toInt() ?? 0,
  scheduledMinutes: (json['scheduledMinutes'] as num?)?.toInt() ?? 0,
  label: json['label'] as String?,
  templateName: json['templateName'] as String?,
  dayLetters: json['dayLetters'] as String?,
);

Map<String, dynamic> _$DayPlanDtoToJson(DayPlanDto instance) => <String, dynamic>{
  'kind': _$DayKindEnumMap[instance.kind]!,
  'start': ?instance.start,
  'end': ?instance.end,
  'lunchMinutes': instance.lunchMinutes,
  'scheduledMinutes': instance.scheduledMinutes,
  'label': ?instance.label,
  'templateName': ?instance.templateName,
  'dayLetters': ?instance.dayLetters,
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

StartWindowDto _$StartWindowDtoFromJson(Map<String, dynamic> json) => StartWindowDto(
  opensAt: DateTime.parse(json['opensAt'] as String),
  shiftStart: DateTime.parse(json['shiftStart'] as String),
  shiftEnd: DateTime.parse(json['shiftEnd'] as String),
  canStartNow: json['canStartNow'] as bool,
  blockedReason: json['blockedReason'] as String?,
);

Map<String, dynamic> _$StartWindowDtoToJson(StartWindowDto instance) => <String, dynamic>{
  'opensAt': instance.opensAt.toIso8601String(),
  'shiftStart': instance.shiftStart.toIso8601String(),
  'shiftEnd': instance.shiftEnd.toIso8601String(),
  'canStartNow': instance.canStartNow,
  'blockedReason': ?instance.blockedReason,
};

RequirementsDto _$RequirementsDtoFromJson(Map<String, dynamic> json) => RequirementsDto(
  photo: json['photo'] as bool? ?? false,
  signature: json['signature'] as bool? ?? false,
  observationAlways: json['observationAlways'] as bool? ?? false,
);

Map<String, dynamic> _$RequirementsDtoToJson(RequirementsDto instance) => <String, dynamic>{
  'photo': instance.photo,
  'signature': instance.signature,
  'observationAlways': instance.observationAlways,
};

CurrentActivityDto _$CurrentActivityDtoFromJson(Map<String, dynamic> json) => CurrentActivityDto(
  id: json['id'] as String,
  activityTypeId: json['activityTypeId'] as String,
  name: json['name'] as String,
  color: json['color'] as String,
  timeClass: $enumDecode(_$TimeClassEnumMap, json['timeClass']),
  startedAt: DateTime.parse(json['startedAt'] as String),
  status: $enumDecode(_$ActivityStatusEnumMap, json['status'], unknownValue: ActivityStatus.unknown),
  requirements: RequirementsDto.fromJson(json['requirements'] as Map<String, dynamic>),
  workOrderNumber: json['workOrderNumber'] as String?,
  siteName: json['siteName'] as String?,
  workedSeconds: (json['workedSeconds'] as num?)?.toInt() ?? 0,
  pausedSeconds: (json['pausedSeconds'] as num?)?.toInt() ?? 0,
  pausedSince: json['pausedSince'] == null ? null : DateTime.parse(json['pausedSince'] as String),
  startGeofence:
      $enumDecodeNullable(_$GeofenceStatusEnumMap, json['startGeofence'], unknownValue: GeofenceStatus.unknown) ??
      GeofenceStatus.notApplicable,
  startAccuracy: (json['startAccuracy'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CurrentActivityDtoToJson(CurrentActivityDto instance) => <String, dynamic>{
  'id': instance.id,
  'activityTypeId': instance.activityTypeId,
  'name': instance.name,
  'color': instance.color,
  'timeClass': _$TimeClassEnumMap[instance.timeClass]!,
  'workOrderNumber': ?instance.workOrderNumber,
  'siteName': ?instance.siteName,
  'startedAt': instance.startedAt.toIso8601String(),
  'status': _$ActivityStatusEnumMap[instance.status]!,
  'workedSeconds': instance.workedSeconds,
  'pausedSeconds': instance.pausedSeconds,
  'pausedSince': ?instance.pausedSince?.toIso8601String(),
  'startGeofence': _$GeofenceStatusEnumMap[instance.startGeofence]!,
  'startAccuracy': ?instance.startAccuracy,
  'requirements': instance.requirements.toJson(),
};

const _$TimeClassEnumMap = {
  TimeClass.productive: 'Productive',
  TimeClass.paidNonProductive: 'PaidNonProductive',
  TimeClass.unproductive: 'Unproductive',
};

const _$ActivityStatusEnumMap = {
  ActivityStatus.running: 'Running',
  ActivityStatus.paused: 'Paused',
  ActivityStatus.finished: 'Finished',
  ActivityStatus.unknown: 'Unknown',
};

const _$GeofenceStatusEnumMap = {
  GeofenceStatus.notApplicable: 'NotApplicable',
  GeofenceStatus.inside: 'Inside',
  GeofenceStatus.outside: 'Outside',
  GeofenceStatus.unknown: 'Unknown',
  GeofenceStatus.noLocation: 'NoLocation',
};

DaySummaryDto _$DaySummaryDtoFromJson(Map<String, dynamic> json) => DaySummaryDto(
  activityCount: (json['activityCount'] as num?)?.toInt() ?? 0,
  productiveMinutes: (json['productiveMinutes'] as num?)?.toInt() ?? 0,
  paidNonProductiveMinutes: (json['paidNonProductiveMinutes'] as num?)?.toInt() ?? 0,
  unproductiveMinutes: (json['unproductiveMinutes'] as num?)?.toInt() ?? 0,
  idleMinutes: (json['idleMinutes'] as num?)?.toInt() ?? 0,
  withoutActivityMinutes: (json['withoutActivityMinutes'] as num?)?.toInt() ?? 0,
  pausedMinutes: (json['pausedMinutes'] as num?)?.toInt() ?? 0,
  elapsedMinutes: (json['elapsedMinutes'] as num?)?.toInt() ?? 0,
  byCategory:
      (json['byCategory'] as List<dynamic>?)
          ?.map((e) => CategoryMinutesDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DaySummaryDtoToJson(DaySummaryDto instance) => <String, dynamic>{
  'activityCount': instance.activityCount,
  'productiveMinutes': instance.productiveMinutes,
  'paidNonProductiveMinutes': instance.paidNonProductiveMinutes,
  'unproductiveMinutes': instance.unproductiveMinutes,
  'idleMinutes': instance.idleMinutes,
  'withoutActivityMinutes': instance.withoutActivityMinutes,
  'pausedMinutes': instance.pausedMinutes,
  'elapsedMinutes': instance.elapsedMinutes,
  'byCategory': instance.byCategory.map((e) => e.toJson()).toList(),
};

WorkdayDto _$WorkdayDtoFromJson(Map<String, dynamic> json) => WorkdayDto(
  id: json['id'] as String,
  date: json['date'] as String,
  status: $enumDecode(_$WorkdayStatusEnumMap, json['status'], unknownValue: WorkdayStatus.unknown),
  startedAt: DateTime.parse(json['startedAt'] as String),
  summary: DaySummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
  endedAt: json['endedAt'] == null ? null : DateTime.parse(json['endedAt'] as String),
  startAdjusted: json['startAdjusted'] as bool? ?? false,
  lateMinutes: (json['lateMinutes'] as num?)?.toInt() ?? 0,
  startGeofence:
      $enumDecodeNullable(_$GeofenceStatusEnumMap, json['startGeofence'], unknownValue: GeofenceStatus.unknown) ??
      GeofenceStatus.notApplicable,
  startSiteName: json['startSiteName'] as String?,
  closeKind: $enumDecodeNullable(_$CloseKindEnumMap, json['closeKind']),
  note: json['note'] as String?,
  current: json['current'] == null ? null : CurrentActivityDto.fromJson(json['current'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WorkdayDtoToJson(WorkdayDto instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date,
  'status': _$WorkdayStatusEnumMap[instance.status]!,
  'startedAt': instance.startedAt.toIso8601String(),
  'endedAt': ?instance.endedAt?.toIso8601String(),
  'startAdjusted': instance.startAdjusted,
  'lateMinutes': instance.lateMinutes,
  'startGeofence': _$GeofenceStatusEnumMap[instance.startGeofence]!,
  'startSiteName': ?instance.startSiteName,
  'closeKind': ?_$CloseKindEnumMap[instance.closeKind],
  'note': ?instance.note,
  'current': ?instance.current?.toJson(),
  'summary': instance.summary.toJson(),
};

const _$WorkdayStatusEnumMap = {
  WorkdayStatus.open: 'Open',
  WorkdayStatus.closed: 'Closed',
  WorkdayStatus.pendingReview: 'PendingReview',
  WorkdayStatus.unknown: 'Unknown',
};

const _$CloseKindEnumMap = {CloseKind.manual: 'Manual', CloseKind.automatic: 'Automatic'};

AbsenceInfoDto _$AbsenceInfoDtoFromJson(Map<String, dynamic> json) => AbsenceInfoDto(
  label: json['label'] as String,
  from: json['from'] as String,
  to: json['to'] as String,
  approvedBy: json['approvedBy'] as String?,
);

Map<String, dynamic> _$AbsenceInfoDtoToJson(AbsenceInfoDto instance) => <String, dynamic>{
  'label': instance.label,
  'from': instance.from,
  'to': instance.to,
  'approvedBy': ?instance.approvedBy,
};

DeviceStatusDto _$DeviceStatusDtoFromJson(Map<String, dynamic> json) => DeviceStatusDto(
  controlEnabled: json['controlEnabled'] as bool? ?? false,
  isShared: json['isShared'] as bool? ?? false,
  deviceModel: json['deviceModel'] as String?,
  warningMinutes: (json['warningMinutes'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [],
  logoutSharedOnClose: json['logoutSharedOnClose'] as bool? ?? false,
  corporateApps: (json['corporateApps'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  alwaysAvailableApps: (json['alwaysAvailableApps'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
);

Map<String, dynamic> _$DeviceStatusDtoToJson(DeviceStatusDto instance) => <String, dynamic>{
  'controlEnabled': instance.controlEnabled,
  'isShared': instance.isShared,
  'deviceModel': ?instance.deviceModel,
  'warningMinutes': instance.warningMinutes,
  'logoutSharedOnClose': instance.logoutSharedOnClose,
  'corporateApps': instance.corporateApps,
  'alwaysAvailableApps': instance.alwaysAvailableApps,
};

CategoryMinutesDto _$CategoryMinutesDtoFromJson(Map<String, dynamic> json) => CategoryMinutesDto(
  name: json['name'] as String,
  color: json['color'] as String,
  timeClass: $enumDecode(_$TimeClassEnumMap, json['timeClass']),
  minutes: (json['minutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CategoryMinutesDtoToJson(CategoryMinutesDto instance) => <String, dynamic>{
  'name': instance.name,
  'color': instance.color,
  'timeClass': _$TimeClassEnumMap[instance.timeClass]!,
  'minutes': instance.minutes,
};

NextShiftDto _$NextShiftDtoFromJson(Map<String, dynamic> json) => NextShiftDto(
  date: json['date'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  templateName: json['templateName'] as String?,
  notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
);

Map<String, dynamic> _$NextShiftDtoToJson(NextShiftDto instance) => <String, dynamic>{
  'date': instance.date,
  'start': instance.start,
  'end': instance.end,
  'templateName': ?instance.templateName,
  'notes': instance.notes,
};

PolicyStatusDto _$PolicyStatusDtoFromJson(Map<String, dynamic> json) => PolicyStatusDto(
  currentVersion: json['currentVersion'] as String?,
  accepted: json['accepted'] as bool? ?? false,
  effectiveFrom: json['effectiveFrom'] as String?,
);

Map<String, dynamic> _$PolicyStatusDtoToJson(PolicyStatusDto instance) => <String, dynamic>{
  'currentVersion': ?instance.currentVersion,
  'accepted': instance.accepted,
  'effectiveFrom': ?instance.effectiveFrom,
};

ClientSettingsDto _$ClientSettingsDtoFromJson(Map<String, dynamic> json) => ClientSettingsDto(
  samplingMinutes: (json['samplingMinutes'] as num?)?.toInt() ?? 15,
  minGpsAccuracyMeters: (json['minGpsAccuracyMeters'] as num?)?.toInt() ?? 50,
  inactivityAlertMinutes: (json['inactivityAlertMinutes'] as num?)?.toInt() ?? 20,
  shiftEndWarningMinutes: (json['shiftEndWarningMinutes'] as num?)?.toInt() ?? 15,
  maxPauseMinutes: (json['maxPauseMinutes'] as num?)?.toInt() ?? 30,
  autoCloseGraceMinutes: (json['autoCloseGraceMinutes'] as num?)?.toInt() ?? 10,
);

Map<String, dynamic> _$ClientSettingsDtoToJson(ClientSettingsDto instance) => <String, dynamic>{
  'samplingMinutes': instance.samplingMinutes,
  'minGpsAccuracyMeters': instance.minGpsAccuracyMeters,
  'inactivityAlertMinutes': instance.inactivityAlertMinutes,
  'shiftEndWarningMinutes': instance.shiftEndWarningMinutes,
  'maxPauseMinutes': instance.maxPauseMinutes,
  'autoCloseGraceMinutes': instance.autoCloseGraceMinutes,
};
