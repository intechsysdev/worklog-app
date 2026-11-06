/// Mutable state of the demo backend, persisted as JSON on the phone.
library;

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String).toUtc();
String? _iso(DateTime? v) => v?.toUtc().toIso8601String();

enum DemoScenario {
  normal('Normal'),
  vacation('Sin turno hoy (vacaciones)'),
  kioskShared('Kiosco · dispositivo compartido'),
  kioskAssigned('Kiosco · dispositivo asignado'),
  shiftEnd('Aviso de fin de turno');

  const DemoScenario(this.label);

  final String label;

  static DemoScenario parse(String? v) => DemoScenario.values.firstWhere((s) => s.name == v, orElse: () => normal);
}

class MockPause {
  MockPause(this.start, [this.end]);

  factory MockPause.fromJson(Map<String, dynamic> j) => MockPause(_date(j['start'])!, _date(j['end']));

  DateTime start;
  DateTime? end;

  Map<String, dynamic> toJson() => {'start': _iso(start), 'end': _iso(end)};
}

class MockActivity {
  MockActivity({
    required this.id,
    required this.typeId,
    required this.startedAt,
    this.workOrderId,
    this.endedAt,
    List<MockPause>? pauses,
    this.outcome,
    this.observation,
    this.photoCount = 0,
    this.hasSignature = false,
    this.autoFinished = false,
    this.geofence = 'NotApplicable',
    this.accuracy,
  }) : pauses = pauses ?? [];

  factory MockActivity.fromJson(Map<String, dynamic> j) => MockActivity(
    id: j['id'] as String,
    typeId: j['typeId'] as String,
    workOrderId: j['workOrderId'] as String?,
    startedAt: _date(j['startedAt'])!,
    endedAt: _date(j['endedAt']),
    pauses: [for (final p in j['pauses'] as List? ?? const []) MockPause.fromJson(Map<String, dynamic>.from(p as Map))],
    outcome: j['outcome'] as String?,
    observation: j['observation'] as String?,
    photoCount: j['photoCount'] as int? ?? 0,
    hasSignature: j['hasSignature'] as bool? ?? false,
    autoFinished: j['autoFinished'] as bool? ?? false,
    geofence: j['geofence'] as String? ?? 'NotApplicable',
    accuracy: (j['accuracy'] as num?)?.toDouble(),
  );

  final String id;
  final String typeId;
  final String? workOrderId;
  DateTime startedAt;
  DateTime? endedAt;
  final List<MockPause> pauses;
  String? outcome;
  String? observation;
  int photoCount;
  bool hasSignature;
  bool autoFinished;
  String geofence;
  double? accuracy;

  bool get isOpen => endedAt == null;
  bool get isPaused => pauses.isNotEmpty && pauses.last.end == null;

  int pausedSeconds(DateTime now) =>
      pauses.fold(0, (s, p) => s + ((p.end ?? endedAt ?? now).difference(p.start).inSeconds).clamp(0, 1 << 31));

  int spanSeconds(DateTime now) => (endedAt ?? now).difference(startedAt).inSeconds.clamp(0, 1 << 31);

  int workedSeconds(DateTime now) => (spanSeconds(now) - pausedSeconds(now)).clamp(0, 1 << 31);

  Map<String, dynamic> toJson() => {
    'id': id,
    'typeId': typeId,
    'workOrderId': workOrderId,
    'startedAt': _iso(startedAt),
    'endedAt': _iso(endedAt),
    'pauses': [for (final p in pauses) p.toJson()],
    'outcome': outcome,
    'observation': observation,
    'photoCount': photoCount,
    'hasSignature': hasSignature,
    'autoFinished': autoFinished,
    'geofence': geofence,
    'accuracy': accuracy,
  };
}

class MockWorkday {
  MockWorkday({
    required this.id,
    required this.date,
    required this.startedAt,
    this.endedAt,
    this.status = 'Open',
    this.closeKind,
    this.note,
    this.startAdjusted = false,
    this.lateMinutes = 0,
    this.startGeofence = 'NoLocation',
    this.endGeofence = 'NoLocation',
    List<MockActivity>? activities,
  }) : activities = activities ?? [];

  factory MockWorkday.fromJson(Map<String, dynamic> j) => MockWorkday(
    id: j['id'] as String,
    date: j['date'] as String,
    startedAt: _date(j['startedAt'])!,
    endedAt: _date(j['endedAt']),
    status: j['status'] as String? ?? 'Open',
    closeKind: j['closeKind'] as String?,
    note: j['note'] as String?,
    startAdjusted: j['startAdjusted'] as bool? ?? false,
    lateMinutes: j['lateMinutes'] as int? ?? 0,
    startGeofence: j['startGeofence'] as String? ?? 'NoLocation',
    endGeofence: j['endGeofence'] as String? ?? 'NoLocation',
    activities: [
      for (final a in j['activities'] as List? ?? const []) MockActivity.fromJson(Map<String, dynamic>.from(a as Map)),
    ],
  );

  final String id;

  /// DateOnly of the workday (local).
  final String date;
  DateTime startedAt;
  DateTime? endedAt;
  String status;
  String? closeKind;
  String? note;
  bool startAdjusted;
  int lateMinutes;
  String startGeofence;
  String endGeofence;
  final List<MockActivity> activities;

  bool get isOpen => status == 'Open';

  MockActivity? get current {
    for (final a in activities.reversed) {
      if (a.isOpen) return a;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'startedAt': _iso(startedAt),
    'endedAt': _iso(endedAt),
    'status': status,
    'closeKind': closeKind,
    'note': note,
    'startAdjusted': startAdjusted,
    'lateMinutes': lateMinutes,
    'startGeofence': startGeofence,
    'endGeofence': endGeofence,
    'activities': [for (final a in activities) a.toJson()],
  };
}

/// Shift of a day (instants), fixed once computed so the window does not move.
class MockShift {
  MockShift(this.start, this.end, {this.label = 'Campo L–V', this.lunchMinutes = 60, this.autoCloseAt});

  factory MockShift.fromJson(Map<String, dynamic> j) => MockShift(
    _date(j['start'])!,
    _date(j['end'])!,
    label: j['label'] as String? ?? 'Campo L–V',
    lunchMinutes: j['lunchMinutes'] as int? ?? 60,
    autoCloseAt: _date(j['autoCloseAt']),
  );

  final DateTime start;
  final DateTime end;
  final String label;
  final int lunchMinutes;

  /// Explicit automatic close (scenario "Aviso de fin de turno").
  final DateTime? autoCloseAt;

  Map<String, dynamic> toJson() => {
    'start': _iso(start),
    'end': _iso(end),
    'label': label,
    'lunchMinutes': lunchMinutes,
    'autoCloseAt': _iso(autoCloseAt),
  };
}

class MockState {
  MockState({
    this.scenario = DemoScenario.normal,
    this.offline = false,
    this.policyAccepted = false,
    this.policyAcceptedAt,
    this.email = 'andres.mora@intechsys.co',
    this.siteLat,
    this.siteLng,
    this.locationSamples = 0,
    Map<String, MockShift>? shifts,
    List<MockWorkday>? workdays,
    Map<String, Map<String, dynamic>>? processed,
    List<Map<String, dynamic>>? requests,
    Map<String, Map<String, dynamic>>? evidences,
    Map<String, String>? orderStatus,
  }) : shifts = shifts ?? {},
       workdays = workdays ?? [],
       processed = processed ?? {},
       requests = requests ?? [],
       evidences = evidences ?? {},
       orderStatus = orderStatus ?? {};

  factory MockState.fromJson(Map<String, dynamic> j) => MockState(
    scenario: DemoScenario.parse(j['scenario'] as String?),
    offline: j['offline'] as bool? ?? false,
    policyAccepted: j['policyAccepted'] as bool? ?? false,
    policyAcceptedAt: _date(j['policyAcceptedAt']),
    email: j['email'] as String? ?? 'andres.mora@intechsys.co',
    siteLat: (j['siteLat'] as num?)?.toDouble(),
    siteLng: (j['siteLng'] as num?)?.toDouble(),
    locationSamples: j['locationSamples'] as int? ?? 0,
    shifts: {
      for (final e in (j['shifts'] as Map? ?? const {}).entries)
        e.key as String: MockShift.fromJson(Map<String, dynamic>.from(e.value as Map)),
    },
    workdays: [
      for (final w in j['workdays'] as List? ?? const []) MockWorkday.fromJson(Map<String, dynamic>.from(w as Map)),
    ],
    processed: {
      for (final e in (j['processed'] as Map? ?? const {}).entries)
        e.key as String: Map<String, dynamic>.from(e.value as Map),
    },
    requests: [for (final r in j['requests'] as List? ?? const []) Map<String, dynamic>.from(r as Map)],
    evidences: {
      for (final e in (j['evidences'] as Map? ?? const {}).entries)
        e.key as String: Map<String, dynamic>.from(e.value as Map),
    },
    orderStatus: Map<String, String>.from(j['orderStatus'] as Map? ?? const {}),
  );

  DemoScenario scenario;

  /// "Simular sin conexión": the adapter answers as if there were no network.
  bool offline;
  bool policyAccepted;
  DateTime? policyAcceptedAt;
  String email;

  /// Center of every site: the first location received (so the geofence says "Dentro").
  double? siteLat;
  double? siteLng;
  int locationSamples;

  /// Shift per local date `yyyy-MM-dd`.
  final Map<String, MockShift> shifts;
  final List<MockWorkday> workdays;

  /// Answers already given per clientEventId (idempotency).
  final Map<String, Map<String, dynamic>> processed;

  /// RequestDto JSON.
  final List<Map<String, dynamic>> requests;

  /// EvidenceDto JSON per clientId.
  final Map<String, Map<String, dynamic>> evidences;

  /// Status of the work orders (by id): Open, InProgress, Completed…
  final Map<String, String> orderStatus;

  Map<String, dynamic> toJson() => {
    'scenario': scenario.name,
    'offline': offline,
    'policyAccepted': policyAccepted,
    'policyAcceptedAt': _iso(policyAcceptedAt),
    'email': email,
    'siteLat': siteLat,
    'siteLng': siteLng,
    'locationSamples': locationSamples,
    'shifts': {for (final e in shifts.entries) e.key: e.value.toJson()},
    'workdays': [for (final w in workdays) w.toJson()],
    'processed': processed,
    'requests': requests,
    'evidences': evidences,
    'orderStatus': orderStatus,
  };
}
