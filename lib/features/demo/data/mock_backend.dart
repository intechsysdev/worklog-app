import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import 'mock_catalog.dart';
import 'mock_state.dart';

/// Where the demo state is saved between launches.
abstract interface class MockStore {
  Future<String?> load();
  Future<void> save(String json);
}

class MemoryMockStore implements MockStore {
  String? value;

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String json) async => value = json;
}

/// HTTP answer of the demo backend.
class MockResponse {
  const MockResponse(this.status, [this.body]);

  final int status;
  final Object? body;
}

/// WorkLog API (and the ONE login) running on the phone, for the demo APK.
///
/// It answers every endpoint the app uses with the shapes of `docs/openapi.v1.json` and applies
/// the main rules of the real API: start window (15 min early, 5 min tolerance), one open
/// activity (starting another auto-finishes it), photo/signature/observation to finish,
/// idempotency by `clientEventId`, automatic close, week hours and requests that the
/// "supervisor" approves after 2 minutes.
///
/// The shift follows the real clock so the flow can always be tried: 07:00–16:00 on a weekday
/// inside that range; otherwise an 8 h shift that started 10 minutes ago.
class MockBackend {
  MockBackend({required this._store, DateTime Function()? now, MockState? state})
    : _clock = now ?? DateTime.now,
      state = state ?? MockState();

  static Future<MockBackend> load(MockStore store, {DateTime Function()? now}) async {
    final backend = MockBackend(store: store, now: now);
    final raw = await store.load();
    if (raw != null) {
      try {
        backend.state = MockState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return backend;
      } on Object {
        // Corrupted: start over.
      }
    }
    backend._seed();
    await backend._save();
    return backend;
  }

  static const _uuid = Uuid();
  static const approvalDelay = Duration(minutes: 2);
  static const earlyStartMinutes = 15;
  static const lateToleranceMinutes = 5;
  static const graceMinutes = 10;
  static const geofenceRadiusMeters = 150.0;

  final MockStore _store;
  final DateTime Function() _clock;
  MockState state;

  /// Local time of the phone.
  DateTime get _now => _clock().toLocal();

  bool get offline => state.offline;
  DemoScenario get scenario => state.scenario;

  // ── Demo controls ──────────────────────────────────────────────────────

  Future<void> setOffline(bool value) async {
    state.offline = value;
    await _save();
  }

  /// Changes the scenario and starts today over.
  Future<void> setScenario(DemoScenario scenario) async {
    final today = _dateOf(_now);
    state
      ..scenario = scenario
      ..workdays.removeWhere((w) => w.date == today || w.isOpen)
      ..shifts.remove(today)
      ..orderStatus.clear();
    if (scenario == DemoScenario.shiftEnd) _seedShiftEnd();
    await _save();
  }

  /// "Reiniciar datos de demostración".
  Future<void> reset() async {
    final email = state.email;
    final accepted = state.policyAccepted;
    _seed();
    state
      ..email = email
      ..policyAccepted = accepted
      ..policyAcceptedAt = accepted ? _now.toUtc() : null;
    await _save();
  }

  Future<void> _save() => _store.save(jsonEncode(state.toJson()));

  // ── Router ─────────────────────────────────────────────────────────────

  /// Answers a request. [body] is the decoded JSON (or the form fields of a multipart).
  MockResponse handle(String method, String path, {Map<String, String> query = const {}, Object? body}) {
    final p = path.replaceFirst(RegExp(r'^/api/v1'), '');
    final json = body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{};
    final now = _now;
    _tick(now);

    MockResponse result;
    final evidence = RegExp(r'^/me/workday/activities/([^/]+)/evidences$').firstMatch(p);
    final cancel = RegExp(r'^/me/requests/([^/]+)/cancel$').firstMatch(p);
    switch ((method, p)) {
      case ('POST', '/auth/login'):
      case ('POST', '/sso/token'):
        result = _login(json['email'] as String? ?? state.email);
      case ('POST', '/auth/refresh'):
        result = _login(state.email);
      case ('POST', '/auth/logout'):
        result = const MockResponse(204);
      case ('GET', '/me/tenants'):
        result = const MockResponse(200, [
          {
            'tenantId': MockCatalog.tenantId,
            'name': MockCatalog.tenantName,
            'slug': 'intechsys',
            'role': 'Member',
            'canAdministrate': false,
          },
        ]);
      case ('GET', '/me'):
        result = MockResponse(200, _me());
      case ('GET', '/me/privacy-policy'):
        result = MockResponse(200, _policy());
      case ('POST', '/me/privacy-policy/accept'):
        state
          ..policyAccepted = true
          ..policyAcceptedAt = now.toUtc();
        result = MockResponse(200, _policy());
      case ('GET', '/me/today'):
        result = MockResponse(200, today(now));
      case ('GET', '/me/timeline'):
        result = MockResponse(200, _timeline(query['date'] ?? _dateOf(now), now));
      case ('GET', '/me/workday/activity-options'):
        result = MockResponse(200, _options(now));
      case ('POST', '/me/workday/sync'):
        result = _sync(json['events'] as List? ?? const [], now);
      case ('POST', '/me/workday/locations'):
        result = _locations(json['samples'] as List? ?? const []);
      case ('GET', '/me/week'):
        result = MockResponse(200, week(query['date'] ?? _dateOf(now), now));
      case ('GET', '/me/requests'):
        result = _listRequests(query['status']);
      case ('POST', '/me/requests/adjustment'):
        result = _adjustment(json, now);
      case ('POST', '/me/requests/overtime'):
        result = _overtime(json, now);
      case ('POST', '/me/requests/shift-change'):
        result = _shiftChange(json, now);
      case ('POST', _) when cancel != null:
        result = _cancel(cancel.group(1)!, now);
      case ('POST', _) when evidence != null:
        result = _evidence(evidence.group(1)!, json, now);
      default:
        result = _problem(404, 'not_found', 'No existe $method $p en el modo demostración.');
    }
    if (method != 'GET' || p == '/me/today') unawaited(_save());
    return result;
  }

  // ── Auth and profile ───────────────────────────────────────────────────

  MockResponse _login(String email) {
    state.email = email.trim().isEmpty ? state.email : email.trim().toLowerCase();
    final expires = _now.toUtc().add(const Duration(hours: 8));
    return MockResponse(200, {
      'accessToken': 'demo.${_uuid.v4()}',
      'refreshToken': 'demo-refresh.${_uuid.v4()}',
      'expiresAt': expires.toIso8601String(),
      'expiresInSeconds': 8 * 3600,
      'user': {
        'id': MockCatalog.memberId,
        'email': state.email,
        'firstName': 'Andrés',
        'lastName': 'Mora',
        'fullName': MockCatalog.memberName,
        'isPlatformAdmin': false,
        'roles': const <String>[],
        'memberships': const <Object>[],
      },
    });
  }

  Map<String, dynamic> _me() => {
    'memberId': MockCatalog.memberId,
    'tenantId': MockCatalog.tenantId,
    'tenantName': MockCatalog.tenantName,
    'fullName': MockCatalog.memberName,
    'initials': 'AM',
    'email': state.email,
    'roleName': 'Usuario móvil',
    'roleKey': 'mobile',
    'usage': 'Mobile',
    'permissions': ['view_own', 'record_work'],
    'isPlatformAdmin': false,
    'branchName': MockCatalog.branchName,
    'workGroupName': 'Campo',
    'supervisorName': MockCatalog.supervisor,
    'deviceModel': MockCatalog.deviceModel,
    'policyVersion': state.policyAccepted ? '1.0' : null,
    'policyAcceptedAt': state.policyAcceptedAt?.toIso8601String(),
  };

  Map<String, dynamic> _policy() => {
    'version': '1.0',
    'effectiveFrom': '2026-01-01',
    'summary': MockCatalog.policySummary,
    'accepted': state.policyAccepted,
    'acceptedAt': state.policyAcceptedAt?.toIso8601String(),
  };

  // ── Plan of the day ────────────────────────────────────────────────────

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _dateOf(DateTime local) => '${local.year}-${_two(local.month)}-${_two(local.day)}';
  static DateTime _parseDate(String date) {
    final p = date.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static String _timeOnly(DateTime instant) {
    final l = instant.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}:00';
  }

  static String _hm(DateTime instant) {
    final l = instant.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  bool _isVacation(String date, DateTime now) {
    if (state.scenario != DemoScenario.vacation) return false;
    final d = _parseDate(date);
    final today = _parseDate(_dateOf(now));
    return !d.isBefore(today) && d.isBefore(today.add(const Duration(days: 11)));
  }

  /// Regular shift of a weekday: 07:00–16:00 with one hour of lunch.
  static MockShift _standard(DateTime day) =>
      MockShift(DateTime(day.year, day.month, day.day, 7).toUtc(), DateTime(day.year, day.month, day.day, 16).toUtc());

  /// Shift of [date]; null on rest days or vacations. Today's is fixed once computed.
  MockShift? shiftFor(String date, DateTime now) {
    if (_isVacation(date, now)) return null;
    final stored = state.shifts[date];
    if (stored != null) return stored;
    final day = _parseDate(date);
    final weekday = day.weekday <= DateTime.friday;
    if (date != _dateOf(now)) return weekday ? _standard(day) : null;

    final MockShift shift;
    final minutes = now.hour * 60 + now.minute;
    if (weekday && minutes >= 7 * 60 && minutes < 16 * 60) {
      shift = _standard(day);
    } else {
      // Outside the regular hours (night, weekend): an 8 h shift that started 10 minutes ago.
      final start = DateTime(now.year, now.month, now.day, now.hour, now.minute).subtract(const Duration(minutes: 10));
      shift = MockShift(
        start.toUtc(),
        start.add(const Duration(hours: 8)).toUtc(),
        label: 'Turno de demostración',
        lunchMinutes: 0,
      );
    }
    state.shifts[date] = shift;
    return shift;
  }

  Map<String, dynamic>? _approvedOvertime(String date) {
    for (final r in state.requests) {
      if (r['type'] == 'Overtime' && r['status'] == 'Approved' && r['date'] == date) return r;
    }
    return null;
  }

  /// Automatic close of the workday of [date]: end of the shift (or of the approved overtime)
  /// plus the grace minutes.
  DateTime? autoCloseFor(String date, DateTime now) {
    final shift = shiftFor(date, now);
    if (shift == null) return null;
    if (shift.autoCloseAt != null) return shift.autoCloseAt;
    var end = shift.end;
    final overtime = _approvedOvertime(date);
    if (overtime != null) {
      final to = (overtime['overtimeTo'] as String).split(':').map(int.parse).toList();
      final day = _parseDate(date);
      final otEnd = DateTime(day.year, day.month, day.day, to[0], to[1]).toUtc();
      if (otEnd.isAfter(end)) end = otEnd;
    }
    return end.add(const Duration(minutes: graceMinutes));
  }

  MockWorkday? _workdayOn(String date) {
    for (final w in state.workdays) {
      if (w.date == date) return w;
    }
    return null;
  }

  MockWorkday? get _open {
    for (final w in state.workdays) {
      if (w.isOpen) return w;
    }
    return null;
  }

  /// Automatic close and approval of requests, as the server's background jobs.
  void _tick(DateTime now) {
    final utc = now.toUtc();
    final open = _open;
    if (open != null) {
      final close = autoCloseFor(open.date, now);
      if (close != null && !utc.isBefore(close)) _close(open, close, status: 'PendingReview', kind: 'Automatic');
    }
    for (final r in state.requests) {
      if (r['status'] != 'Pending') continue;
      final sent = DateTime.parse(r['submittedAt'] as String);
      if (utc.difference(sent) >= approvalDelay) _approve(r, sent.add(approvalDelay));
    }
  }

  void _close(MockWorkday w, DateTime at, {required String status, required String kind, String? note}) {
    final current = w.current;
    if (current != null) _finishActivity(current, at, outcome: 'Completed', auto: true);
    w
      ..endedAt = at
      ..status = status
      ..closeKind = kind
      ..note = note ?? w.note;
  }

  void _finishActivity(MockActivity a, DateTime at, {required String outcome, bool auto = false}) {
    if (a.isPaused) a.pauses.last.end = at;
    a
      ..endedAt = at
      ..outcome = outcome
      ..autoFinished = auto;
    if (a.workOrderId != null) state.orderStatus[a.workOrderId!] = outcome;
  }

  // ── today ──────────────────────────────────────────────────────────────

  Map<String, dynamic> today(DateTime now) {
    final date = _dateOf(now);
    final shift = shiftFor(date, now);
    final vacation = _isVacation(date, now);
    final workday = _open ?? _workdayOn(date);
    final utc = now.toUtc();
    final device =
        state.scenario == DemoScenario.kioskShared ||
        state.scenario == DemoScenario.kioskAssigned ||
        state.scenario == DemoScenario.shiftEnd;

    Map<String, dynamic>? window;
    if (shift != null) {
      final opens = shift.start.subtract(const Duration(minutes: earlyStartMinutes));
      final early = utc.isBefore(opens);
      final over = !utc.isBefore(shift.end);
      window = {
        'opensAt': opens.toIso8601String(),
        'shiftStart': shift.start.toIso8601String(),
        'shiftEnd': shift.end.toIso8601String(),
        'canStartNow': workday == null && !early && !over,
        if (early)
          'blockedReason': 'Tu turno empieza a las ${_hm(shift.start)}. Puedes iniciar desde las ${_hm(opens)}.',
        if (over) 'blockedReason': 'Tu turno de hoy ya terminó.',
      };
    }

    final overtime = _approvedOvertime(date);
    final autoClose = autoCloseFor(date, now);
    final next = _nextShift(date, now);
    return {
      'serverTime': utc.toIso8601String(),
      'date': date,
      'timeZoneId': 'America/Bogota',
      'memberName': MockCatalog.memberName,
      'branchName': MockCatalog.branchName,
      'supervisorName': MockCatalog.supervisor,
      'plan': vacation
          ? {'kind': 'Absence', 'lunchMinutes': 0, 'scheduledMinutes': 0, 'label': 'Vacaciones'}
          : shift == null
          ? {'kind': 'Rest', 'lunchMinutes': 0, 'scheduledMinutes': 0, 'label': 'Descanso'}
          : {
              'kind': 'Shift',
              'start': _timeOnly(shift.start),
              'end': _timeOnly(shift.end),
              'lunchMinutes': shift.lunchMinutes,
              'scheduledMinutes': shift.end.difference(shift.start).inMinutes - shift.lunchMinutes,
              'label': shift.label,
              'templateName': shift.label,
              'dayLetters': 'LMXJV',
            },
      'window': ?window,
      if (workday != null) 'workday': _workdayDto(workday, now),
      if (vacation)
        'absence': {
          'label': 'Vacaciones',
          'from': date,
          'to': _dateOf(_parseDate(date).add(const Duration(days: 10))),
          'approvedBy': MockCatalog.supervisor,
        },
      'nextShift': ?next,
      'policy': {'currentVersion': '1.0', 'accepted': state.policyAccepted, 'effectiveFrom': '2026-01-01'},
      'settings': {
        'samplingMinutes': 15,
        'minGpsAccuracyMeters': 50,
        'inactivityAlertMinutes': 20,
        'shiftEndWarningMinutes': 15,
        'maxPauseMinutes': 30,
        'autoCloseGraceMinutes': graceMinutes,
      },
      'device': {
        'controlEnabled': device,
        'isShared': state.scenario == DemoScenario.kioskShared,
        'deviceModel': MockCatalog.deviceModel,
        'warningMinutes': device ? [15, 5] : <int>[],
        'logoutSharedOnClose': state.scenario == DemoScenario.kioskShared,
        'corporateApps': device ? MockCatalog.corporateApps : <String>[],
        'alwaysAvailableApps': MockCatalog.alwaysAvailableApps,
      },
      if (overtime != null) 'overtimeUntil': overtime['overtimeTo'],
      if (autoClose != null) 'autoCloseAt': autoClose.toIso8601String(),
    };
  }

  Map<String, dynamic>? _nextShift(String date, DateTime now) {
    var day = _parseDate(date).add(const Duration(days: 1));
    for (var i = 0; i < 30; i++, day = day.add(const Duration(days: 1))) {
      final d = _dateOf(day);
      if (_isVacation(d, now)) continue;
      if (day.weekday > DateTime.friday) continue;
      final s = _standard(day);
      return {
        'date': d,
        'start': _timeOnly(s.start),
        'end': _timeOnly(s.end),
        'templateName': 'Campo L–V',
        'notes': const <String>[],
      };
    }
    return null;
  }

  Map<String, dynamic> _workdayDto(MockWorkday w, DateTime now) {
    final current = w.current;
    return {
      'id': w.id,
      'date': w.date,
      'status': w.status,
      'startedAt': w.startedAt.toIso8601String(),
      if (w.endedAt != null) 'endedAt': w.endedAt!.toIso8601String(),
      'startAdjusted': w.startAdjusted,
      'lateMinutes': w.lateMinutes,
      'startGeofence': w.startGeofence,
      'startSiteName': MockCatalog.mainSite,
      'closeKind': ?w.closeKind,
      'note': ?w.note,
      if (current != null) 'current': _currentDto(current, now),
      'summary': summary(w, now),
    };
  }

  Map<String, dynamic> _currentDto(MockActivity a, DateTime now) {
    final type = MockCatalog.type(a.typeId)!;
    final order = MockCatalog.order(a.workOrderId);
    final utc = now.toUtc();
    return {
      'id': a.id,
      'activityTypeId': a.typeId,
      'name': type.name,
      'color': type.category.color,
      'timeClass': type.category.timeClass,
      'workOrderNumber': ?order?.number,
      'siteName': ?order?.site,
      'startedAt': a.startedAt.toIso8601String(),
      'status': a.isPaused ? 'Paused' : 'Running',
      'workedSeconds': a.workedSeconds(utc),
      'pausedSeconds': a.pausedSeconds(utc),
      if (a.isPaused) 'pausedSince': a.pauses.last.start.toIso8601String(),
      'startGeofence': a.geofence,
      'startAccuracy': ?a.accuracy,
      'requirements': {'photo': type.photo, 'signature': type.signature, 'observationAlways': type.observationAlways},
    };
  }

  /// DaySummaryDto, with the minutes per category.
  Map<String, dynamic> summary(MockWorkday w, DateTime now) {
    final end = w.endedAt ?? now.toUtc();
    final elapsed = end.difference(w.startedAt).inMinutes.clamp(0, 100000);
    final byCategory = <String, int>{};
    var productive = 0, paid = 0, unproductive = 0, spans = 0, paused = 0;
    for (final a in w.activities) {
      final type = MockCatalog.type(a.typeId)!;
      final minutes = a.workedSeconds(end) ~/ 60;
      spans += a.spanSeconds(end);
      paused += a.pausedSeconds(end);
      byCategory[type.category.name] = (byCategory[type.category.name] ?? 0) + minutes;
      switch (type.category.timeClass) {
        case 'Productive':
          productive += minutes;
        case 'PaidNonProductive':
          paid += minutes;
        default:
          unproductive += minutes;
      }
    }
    final idle = (elapsed - spans ~/ 60).clamp(0, 100000);
    return {
      'byCategory': [
        for (final c in MockCatalog.categories)
          if (byCategory.containsKey(c.name) || c == MockCatalog.productive)
            {'name': c.name, 'color': c.color, 'timeClass': c.timeClass, 'minutes': byCategory[c.name] ?? 0},
      ],
      'activityCount': w.activities.length,
      'productiveMinutes': productive,
      'paidNonProductiveMinutes': paid,
      'unproductiveMinutes': unproductive,
      'idleMinutes': idle,
      'withoutActivityMinutes': unproductive + idle,
      'pausedMinutes': paused ~/ 60,
      'elapsedMinutes': elapsed,
    };
  }

  /// Minutes that count for the day (as the app shows them).
  int workedMinutes(MockWorkday w, DateTime now) {
    final s = summary(w, now);
    return (s['productiveMinutes'] as int) +
        (s['paidNonProductiveMinutes'] as int) +
        (s['withoutActivityMinutes'] as int);
  }

  // ── timeline ───────────────────────────────────────────────────────────

  Map<String, dynamic> _timeline(String date, DateTime now) {
    final shift = shiftFor(date, now);
    final w = _workdayOn(date) ?? (_open?.date == date ? _open : null);
    final segments = <Map<String, dynamic>>[];
    final entries = <Map<String, dynamic>>[];
    if (w != null) {
      final utc = now.toUtc();
      entries.add({
        'kind': 'start',
        'title': 'Inicio de jornada',
        'start': w.startedAt.toIso8601String(),
        'minutes': 0,
        'color': '#1E1F1D',
        'running': false,
        'siteName': MockCatalog.mainSite,
        'autoFinished': false,
        'photoCount': 0,
        'hasSignature': false,
        'geofence': w.startGeofence,
      });
      var cursor = w.startedAt;
      void idle(DateTime until) {
        final minutes = until.difference(cursor).inMinutes;
        if (minutes < 1) return;
        final seg = {
          'kind': 'Idle',
          'start': cursor.toIso8601String(),
          'end': until.toIso8601String(),
          'minutes': minutes,
          'title': 'Sin actividad',
          'color': '#DA830B',
        };
        segments.add(seg);
        entries.add({
          'kind': 'idle',
          'title': 'Sin actividad',
          'start': cursor.toIso8601String(),
          'end': until.toIso8601String(),
          'minutes': minutes,
          'color': '#DA830B',
          'running': false,
          'autoFinished': false,
          'photoCount': 0,
          'hasSignature': false,
          'geofence': 'NotApplicable',
        });
      }

      final activities = [...w.activities]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      for (final a in activities) {
        idle(a.startedAt);
        final type = MockCatalog.type(a.typeId)!;
        final order = MockCatalog.order(a.workOrderId);
        final minutes = a.workedSeconds(utc) ~/ 60;
        segments.add({
          'kind': 'Activity',
          'start': a.startedAt.toIso8601String(),
          if (a.endedAt != null) 'end': a.endedAt!.toIso8601String(),
          'minutes': minutes,
          'title': type.name,
          'color': type.category.color,
          'timeClass': type.category.timeClass,
        });
        final label = MockCatalog.outcomes.where((o) => o.$1 == a.outcome).map((o) => o.$2).firstOrNull;
        entries.add({
          'kind': 'activity',
          'title': type.name,
          'start': a.startedAt.toIso8601String(),
          if (a.endedAt != null) 'end': a.endedAt!.toIso8601String(),
          'minutes': minutes,
          'color': type.category.color,
          'running': a.isOpen,
          'workOrderNumber': ?order?.number,
          'siteName': ?order?.site,
          'outcome': ?a.outcome,
          'outcomeLabel': ?label,
          'autoFinished': a.autoFinished,
          'photoCount': a.photoCount,
          'hasSignature': a.hasSignature,
          'geofence': a.geofence,
        });
        cursor = a.endedAt ?? utc;
        if (a.isOpen) break;
      }
      if (w.endedAt != null) {
        idle(w.endedAt!);
        entries.add({
          'kind': 'close',
          'title': w.closeKind == 'Automatic' ? 'Cierre automático' : 'Cierre de jornada',
          'start': w.endedAt!.toIso8601String(),
          'minutes': 0,
          'color': '#1E1F1D',
          'running': false,
          'autoFinished': false,
          'photoCount': 0,
          'hasSignature': false,
          'geofence': w.endGeofence,
        });
      } else if (w.current == null) {
        idle(utc);
      }
    }
    return {
      'date': date,
      if (shift != null) 'shiftStart': _timeOnly(shift.start),
      if (shift != null) 'shiftEnd': _timeOnly(shift.end),
      if (w != null) 'workday': _workdayDto(w, now),
      'segments': segments,
      'entries': entries.reversed.toList(),
    };
  }

  // ── activity options ───────────────────────────────────────────────────

  Map<String, dynamic> _options(DateTime now) {
    final shift = shiftFor(_dateOf(now), now);
    return {
      'assigned': [
        if (shift != null)
          for (final o in MockCatalog.orders)
            if (const {null, 'Open', 'InProgress'}.contains(state.orderStatus[o.id]))
              {
                'workOrderId': o.id,
                'number': o.number,
                'activityTypeId': o.typeId,
                'title': MockCatalog.type(o.typeId)!.name,
                'siteName': o.site,
                'scheduledTime': _timeOnly(shift.start.add(Duration(minutes: o.offsetMinutes))),
                'status': state.orderStatus[o.id] ?? 'Open',
              },
      ],
      'catalog': [
        for (final t in MockCatalog.types)
          {
            'activityTypeId': t.id,
            'title': t.name,
            'categoryName': t.category.name,
            'timeClass': t.category.timeClass,
            'color': t.category.color,
            'requiresPhoto': t.photo,
            'requiresSignature': t.signature,
            'observation': t.observationAlways ? 'Always' : 'Optional',
          },
      ],
      'outcomes': [
        for (final o in MockCatalog.outcomes)
          {'outcome': o.$1, 'label': o.$2, 'description': o.$3, 'requiresObservation': o.$4},
      ],
    };
  }

  // ── sync ───────────────────────────────────────────────────────────────

  MockResponse _sync(List<dynamic> raw, DateTime now) {
    if (raw.length > 200) return _problem(400, 'events', 'Se reciben máximo 200 eventos por envío.');
    final events = [for (final e in raw) Map<String, dynamic>.from(e as Map)];
    final ordered = [for (var i = 0; i < events.length; i++) (i, events[i])]
      ..sort((a, b) {
        final c = DateTime.parse(a.$2['occurredAt'] as String).compareTo(DateTime.parse(b.$2['occurredAt'] as String));
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    final results = <Map<String, dynamic>>[];
    for (final (_, e) in ordered) {
      final id = e['clientEventId'] as String;
      final previous = state.processed[id];
      if (previous != null) {
        results.add(previous);
        continue;
      }
      final result = _apply(e, now)..['clientEventId'] = id;
      state.processed[id] = result;
      results.add(result);
    }
    return MockResponse(200, {'results': results, 'today': today(now)});
  }

  Map<String, dynamic> _ok([String? resultId, String? message]) => {
    'outcome': message == null ? 'Accepted' : 'Adjusted',
    'message': ?message,
    'resultId': ?resultId,
  };

  Map<String, dynamic> _rejected(String code, String message) => {
    'outcome': 'Rejected',
    'code': code,
    'message': message,
  };

  Map<String, dynamic> _apply(Map<String, dynamic> e, DateTime now) {
    final utc = now.toUtc();
    var at = DateTime.parse(e['occurredAt'] as String).toUtc();
    if (at.isAfter(utc.add(const Duration(minutes: 2)))) {
      return _rejected('event.future', 'La hora del teléfono está adelantada. Revisa la fecha y hora automáticas.');
    }
    if (at.isAfter(utc)) at = utc;
    final queued = utc.difference(at) > const Duration(minutes: 2);
    final location = e['location'] is Map ? Map<String, dynamic>.from(e['location'] as Map) : null;

    switch (e['kind']) {
      case 'workday.start':
        final open = _open;
        if (open != null) {
          return open.id == e['workdayId']
              ? _ok(open.id)
              : _rejected('workday.already_open', 'Ya tienes una jornada abierta.');
        }
        final date = _dateOf(at.toLocal());
        if (_workdayOn(date) != null) {
          return _rejected(
            'workday.already_closed',
            'Ya cerraste la jornada de hoy. Si fue un error, solicita un ajuste.',
          );
        }
        final shift = shiftFor(date, now);
        if (shift == null) {
          return _rejected(
            'workday.no_shift',
            _isVacation(date, now)
                ? 'Hoy tienes vacaciones: no puedes iniciar jornada.'
                : 'Hoy no tienes turno: no puedes iniciar jornada.',
          );
        }
        final opens = shift.start.subtract(const Duration(minutes: earlyStartMinutes));
        var start = at;
        String? message;
        if (at.isBefore(opens)) {
          if (!queued) {
            return _rejected(
              'workday.too_early',
              'Tu turno empieza a las ${_hm(shift.start)}. Puedes iniciar desde las ${_hm(opens)}.',
            );
          }
          start = opens;
          message = 'Fuera de la ventana del turno (desde ${_hm(opens)}). Se registró a las ${_hm(opens)}.';
        }
        if (!start.isBefore(shift.end)) return _rejected('workday.shift_over', 'Tu turno de hoy ya terminó.');
        final late = start.difference(shift.start.add(const Duration(minutes: lateToleranceMinutes))).inMinutes;
        final workday = MockWorkday(
          id: e['workdayId'] as String? ?? _uuid.v4(),
          date: date,
          startedAt: start,
          startAdjusted: message != null,
          lateMinutes: late > 0 ? start.difference(shift.start).inMinutes : 0,
          startGeofence: _geofence(location),
        );
        state.workdays.add(workday);
        return _ok(workday.id, message);

      case 'workday.close':
        final open = _open;
        if (open == null) return _rejected('workday.not_open', 'No tienes una jornada abierta.');
        _close(open, at, status: 'Closed', kind: 'Manual', note: e['note'] as String?);
        open.endGeofence = _geofence(location);
        return _ok(open.id);

      case 'activity.start':
        final open = _open;
        if (open == null) return _rejected('workday.not_open', 'Inicia la jornada antes de registrar actividades.');
        final order = MockCatalog.order(e['workOrderId'] as String?);
        if (e['workOrderId'] != null && order == null) return _rejected('work_order.not_found', 'La OT no existe.');
        if (order != null && !const {null, 'Open', 'InProgress'}.contains(state.orderStatus[order.id])) {
          return _rejected('work_order.closed', 'La ${order.number} ya está cerrada.');
        }
        final type = MockCatalog.type(order?.typeId ?? e['activityTypeId'] as String?);
        if (type == null) return _rejected('activity.type', 'Elige la actividad.');
        final previous = open.current;
        if (previous != null) _finishActivity(previous, at, outcome: 'Completed', auto: true);
        final activity = MockActivity(
          id: e['activityId'] as String? ?? _uuid.v4(),
          typeId: type.id,
          workOrderId: order?.id,
          startedAt: at,
          geofence: order == null ? 'NotApplicable' : _geofence(location),
          accuracy: (location?['accuracy'] as num?)?.toDouble(),
        );
        open.activities.add(activity);
        if (order != null) state.orderStatus[order.id] = 'InProgress';
        return _ok(activity.id);

      case 'activity.pause':
      case 'activity.resume':
        final activity = _activityOf(e['activityId'] as String?);
        if (activity == null) return _rejected('activity.not_found', 'La actividad no pertenece a tu jornada abierta.');
        if (!activity.isOpen) return _rejected('activity.finished', 'La actividad ya terminó.');
        if (e['kind'] == 'activity.pause') {
          if (activity.isPaused) return _rejected('activity.not_running', 'La actividad ya está en pausa.');
          activity.pauses.add(MockPause(at));
        } else {
          if (!activity.isPaused) return _rejected('activity.not_paused', 'La actividad no está en pausa.');
          activity.pauses.last.end = at;
        }
        return _ok(activity.id);

      case 'activity.finish':
        final activity = _activityOf(e['activityId'] as String?);
        if (activity == null) return _rejected('activity.not_found', 'La actividad no pertenece a tu jornada abierta.');
        if (!activity.isOpen) return _ok(activity.id, 'La actividad ya estaba finalizada.');
        final type = MockCatalog.type(activity.typeId)!;
        final outcome = e['outcome'] as String? ?? 'Completed';
        final outcomeNeedsObservation = MockCatalog.outcomes.any((o) => o.$1 == outcome && o.$4);
        final observation = (e['observation'] as String?)?.trim() ?? '';
        if ((outcomeNeedsObservation || type.observationAlways) && observation.isEmpty) {
          return _rejected('activity.observation', 'Escribe la observación: es obligatoria con este resultado.');
        }
        if (type.photo && (e['photoCount'] as int? ?? 0) < 1) {
          return _rejected('activity.photo', '${type.name} exige al menos una foto.');
        }
        if (type.signature && e['hasSignature'] != true) {
          return _rejected('activity.signature', '${type.name} exige la firma del cliente.');
        }
        _finishActivity(activity, at, outcome: outcome);
        activity
          ..observation = observation.isEmpty ? null : observation
          ..photoCount = e['photoCount'] as int? ?? 0
          ..hasSignature = e['hasSignature'] == true;
        return _ok(activity.id);
    }
    return _rejected('event.kind', 'Tipo de evento desconocido: ${e['kind']}.');
  }

  MockActivity? _activityOf(String? id) {
    final open = _open;
    if (open == null || id == null) return null;
    for (final a in open.activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// "Inside" with the real location of the phone: the first reading becomes the site center.
  String _geofence(Map<String, dynamic>? location) {
    if (location == null) return 'NoLocation';
    final lat = (location['latitude'] as num).toDouble();
    final lng = (location['longitude'] as num).toDouble();
    final accuracy = (location['accuracy'] as num?)?.toDouble() ?? 0;
    if (state.siteLat == null) {
      state
        ..siteLat = lat
        ..siteLng = lng;
    }
    if (accuracy > 50) return 'Unknown';
    return _distance(lat, lng, state.siteLat!, state.siteLng!) <= geofenceRadiusMeters ? 'Inside' : 'Outside';
  }

  static double _distance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  MockResponse _locations(List<dynamic> samples) {
    if (_open == null) return const MockResponse(200, {'stored': 0});
    for (final s in samples) {
      final m = Map<String, dynamic>.from(s as Map);
      if (state.siteLat == null) {
        state
          ..siteLat = (m['latitude'] as num).toDouble()
          ..siteLng = (m['longitude'] as num).toDouble();
      }
    }
    state.locationSamples += samples.length;
    return MockResponse(200, {'stored': samples.length});
  }

  MockResponse _evidence(String activityId, Map<String, dynamic> form, DateTime now) {
    final clientId = form['clientId'] as String?;
    if (clientId == null) return _problem(400, 'clientId', 'Falta el identificador de la evidencia.');
    final existing = state.evidences[clientId];
    if (existing != null) return MockResponse(200, existing);
    final exists = state.workdays.any((w) => w.activities.any((a) => a.id == activityId));
    if (!exists) return _problem(404, 'activity.not_found', 'La actividad no pertenece a tus jornadas.');
    final dto = {
      'id': _uuid.v4(),
      'activityId': activityId,
      'kind': form['kind'] ?? 'Photo',
      'sizeBytes': form['size'] ?? 0,
      'capturedAt': form['capturedAt'] ?? now.toUtc().toIso8601String(),
    };
    state.evidences[clientId] = dto;
    return MockResponse(200, dto);
  }

  // ── week ───────────────────────────────────────────────────────────────

  Map<String, dynamic> week(String date, DateTime now) {
    final anchor = _parseDate(date);
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final today = _dateOf(now);
    final days = <Map<String, dynamic>>[];
    var worked = 0, scheduled = 0, overtime = 0;
    for (var i = 0; i < 7; i++) {
      final d = _dateOf(monday.add(Duration(days: i)));
      final shift = shiftFor(d, now);
      final w = _workdayOn(d);
      final minutes = w == null ? 0 : workedMinutes(w, now);
      final planned = shift == null ? 0 : shift.end.difference(shift.start).inMinutes - shift.lunchMinutes;
      worked += minutes;
      scheduled += planned;
      final ot = _approvedOvertime(d);
      if (ot != null) overtime += _minutesBetween(ot['overtimeFrom'] as String, ot['overtimeTo'] as String);
      days.add({
        'date': d,
        'planKind': _isVacation(d, now) ? 'Absence' : (shift == null ? 'Rest' : 'Shift'),
        'planLabel': _isVacation(d, now) ? 'Vacaciones' : (shift?.label ?? 'Descanso'),
        'scheduledMinutes': planned,
        'workedMinutes': minutes,
        'isToday': d == today,
        'inProgress': d == today && (w?.isOpen ?? false),
      });
    }
    final close = anchor.day <= 15
        ? DateTime(anchor.year, anchor.month + 1, 0)
        : DateTime(anchor.year, anchor.month + 1, 15);
    return {
      'from': _dateOf(monday),
      'to': _dateOf(monday.add(const Duration(days: 6))),
      'workedMinutes': worked,
      'weeklyCapMinutes': 2520,
      'scheduledMinutes': scheduled,
      'remainingMinutes': math.max(0, scheduled - worked),
      'approvedOvertimeMinutes': overtime,
      'overtimeWeeklyMaxMinutes': 720,
      'breakdown': {
        'ordinaryDay': worked,
        'ordinaryNight': 0,
        'overtimeDay': overtime,
        'overtimeNight': 0,
        'sundayHoliday': 0,
        'total': worked + overtime,
      },
      'days': days,
      'provisionalUntil': _dateOf(close),
    };
  }

  static int _minutesBetween(String from, String to) {
    int m(String t) {
      final p = t.split(':').map(int.parse).toList();
      return p[0] * 60 + p[1];
    }

    return m(to) - m(from);
  }

  // ── requests ───────────────────────────────────────────────────────────

  MockResponse _listRequests(String? status) {
    final items = [
      for (final r in state.requests.reversed)
        if (status == null || r['status'] == status) r,
    ];
    return MockResponse(200, {
      'items': items,
      'page': 1,
      'pageSize': 100,
      'totalCount': items.length,
      'totalPages': 1,
      'hasPrevious': false,
      'hasNext': false,
    });
  }

  String? _reasonError(Object? reason) {
    final text = (reason as String? ?? '').trim();
    return text.length < 5 || text.length > 500 ? 'El motivo debe tener entre 5 y 500 caracteres.' : null;
  }

  Map<String, dynamic> _newRequest(
    String type,
    String date,
    String title,
    String detail,
    String reason,
    DateTime now,
  ) => {
    'id': _uuid.v4(),
    'memberId': MockCatalog.memberId,
    'memberName': MockCatalog.memberName,
    'type': type,
    'status': 'Pending',
    'title': title,
    'detail': detail,
    'reason': reason.trim(),
    'date': date,
    'submittedAt': now.toUtc().toIso8601String(),
    'days': const <Object>[],
  };

  MockResponse _created(Map<String, dynamic> r) {
    state.requests.add(r);
    return MockResponse(201, r);
  }

  static const _targets = {
    'WorkdayStart': 'Inicio de jornada',
    'WorkdayEnd': 'Fin de jornada',
    'ActivityStart': 'Inicio',
    'ActivityEnd': 'Fin',
  };

  MockResponse _adjustment(Map<String, dynamic> j, DateTime now) {
    final workday = state.workdays.where((w) => w.id == j['workdayId']).firstOrNull;
    if (workday == null) return _problem(404, 'workday.not_found', 'La jornada no existe.');
    final target = j['target'] as String?;
    if (!_targets.containsKey(target)) return _problem(400, 'request.target', 'Elige qué quieres corregir.');
    final activity = workday.activities.where((a) => a.id == j['activityRecordId']).firstOrNull;
    if (target!.startsWith('Activity') && activity == null) {
      return _problem(400, 'request.activity', 'Elige la actividad a corregir.');
    }
    final reasonError = _reasonError(j['reason']);
    if (reasonError != null) return _problem(400, 'reason', reasonError);
    final proposed = DateTime.parse(j['proposedValue'] as String).toUtc();
    final original = switch (target) {
      'WorkdayStart' => workday.startedAt,
      'WorkdayEnd' => workday.endedAt,
      'ActivityStart' => activity!.startedAt,
      _ => activity!.endedAt,
    };
    if (original != null && _hm(original) == _hm(proposed)) {
      return _problem(400, 'request.same_value', 'La hora propuesta es igual a la registrada.');
    }
    final name = activity == null ? 'Jornada' : MockCatalog.type(activity.typeId)!.name;
    final day = _parseDate(workday.date);
    final r =
        _newRequest(
            'RecordAdjustment',
            workday.date,
            '$name · ${day.day} ${_month(day.month)}',
            '${_targets[target]} ${original == null ? '—' : _hm(original)} → ${_hm(proposed)}. ${(j['reason'] as String).trim()}',
            j['reason'] as String,
            now,
          )
          ..['workdayId'] = workday.id
          ..['activityRecordId'] = activity?.id
          ..['target'] = target
          ..['originalValue'] = original?.toIso8601String()
          ..['proposedValue'] = proposed.toIso8601String();
    return _created(r);
  }

  MockResponse _overtime(Map<String, dynamic> j, DateTime now) {
    final from = j['from'] as String?;
    final to = j['to'] as String?;
    if (j['date'] == null || from == null || to == null) {
      return _problem(400, 'request.malformed', 'Completa fecha y horas.');
    }
    final minutes = _minutesBetween(from, to);
    if (minutes <= 0) return _problem(400, 'request.overtime_range', 'La hora final debe ser posterior a la inicial.');
    if (minutes > 120) return _problem(400, 'overtime.daily_max', 'Supera el máximo de 2 h extra al día.');
    final reasonError = _reasonError(j['reason']);
    if (reasonError != null) return _problem(400, 'reason', reasonError);
    final date = j['date'] as String;
    final r =
        _newRequest(
            'Overtime',
            date,
            _longDate(_parseDate(date)),
            '${_duration(minutes)} · ${(j['reason'] as String).trim()}',
            j['reason'] as String,
            now,
          )
          ..['overtimeFrom'] = from
          ..['overtimeTo'] = to
          ..['authorizationReference'] = j['authorizationReference'];
    return _created(r);
  }

  MockResponse _shiftChange(Map<String, dynamic> j, DateTime now) {
    final days = [for (final d in j['days'] as List? ?? const []) Map<String, dynamic>.from(d as Map)];
    if (days.isEmpty || days.length > 7) return _problem(400, 'request.days', 'Propón entre 1 y 7 días.');
    final today = _dateOf(now);
    if (days.any((d) => (d['date'] as String).compareTo(today) < 0)) {
      return _problem(400, 'days', 'Los cambios de turno son para hoy o días futuros.');
    }
    if (days.map((d) => d['date']).toSet().length != days.length) {
      return _problem(400, 'request.days_repeated', 'Hay días repetidos.');
    }
    final reasonError = _reasonError(j['reason']);
    if (reasonError != null) return _problem(400, 'reason', reasonError);
    final first = days.first;
    final hours = first['start'] == null
        ? 'Día libre'
        : '${(first['start'] as String).substring(0, 5)} – ${(first['end'] as String).substring(0, 5)}';
    final r = _newRequest(
      'ShiftChange',
      first['date'] as String,
      '${_longDate(_parseDate(first['date'] as String))}${days.length > 1 ? ' y ${days.length - 1} más' : ''}',
      hours,
      j['reason'] as String,
      now,
    )..['days'] = days;
    return _created(r);
  }

  MockResponse _cancel(String id, DateTime now) {
    final r = state.requests.where((x) => x['id'] == id).firstOrNull;
    if (r == null) return _problem(404, 'request.not_found', 'La solicitud no existe.');
    if (r['status'] != 'Pending') return _problem(409, 'request.resolved', 'La solicitud ya fue resuelta.');
    r
      ..['status'] = 'Cancelled'
      ..['resolvedAt'] = now.toUtc().toIso8601String();
    return MockResponse(200, r);
  }

  /// The "supervisor" approves: adjustments are applied to the record.
  void _approve(Map<String, dynamic> r, DateTime at) {
    r
      ..['status'] = 'Approved'
      ..['resolverName'] = MockCatalog.supervisor
      ..['resolvedAt'] = at.toIso8601String();
    if (r['type'] != 'RecordAdjustment') return;
    final workday = state.workdays.where((w) => w.id == r['workdayId']).firstOrNull;
    final value = DateTime.parse(r['proposedValue'] as String).toUtc();
    if (workday == null) return;
    final activity = workday.activities.where((a) => a.id == r['activityRecordId']).firstOrNull;
    switch (r['target']) {
      case 'WorkdayStart':
        workday.startedAt = value;
      case 'WorkdayEnd':
        if (workday.endedAt != null) workday.endedAt = value;
      case 'ActivityStart':
        activity?.startedAt = value;
      case 'ActivityEnd':
        if (activity?.endedAt != null) activity!.endedAt = value;
    }
  }

  // ── seed ───────────────────────────────────────────────────────────────

  void _seed() {
    final now = _now;
    state = MockState();
    // The last four working days, worked.
    var day = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final seeded = <DateTime>[];
    while (seeded.length < 4) {
      if (day.weekday <= DateTime.friday) seeded.add(day);
      day = day.subtract(const Duration(days: 1));
    }
    for (var k = 0; k < seeded.length; k++) {
      state.workdays.add(_seedDay(seeded[k], k));
    }
    final last = seeded.last;
    state.requests.addAll([
      _newRequest(
          'Overtime',
          _dateOf(last),
          _longDate(last),
          '1 h 30 m · cierre de obra en Bodega Sur',
          'Cierre de obra en Bodega Sur',
          DateTime(last.year, last.month, last.day, 15, 20),
        )
        ..['status'] = 'Approved'
        ..['overtimeFrom'] = '16:00:00'
        ..['overtimeTo'] = '17:30:00'
        ..['resolverName'] = MockCatalog.supervisor
        ..['resolvedAt'] = DateTime(last.year, last.month, last.day, 15, 40).toUtc().toIso8601String(),
      () {
        var saturday = DateTime(now.year, now.month, now.day);
        while (saturday.weekday != DateTime.saturday) {
          saturday = saturday.add(const Duration(days: 1));
        }
        return _newRequest(
            'ShiftChange',
            _dateOf(saturday),
            _longDate(saturday),
            '07:00 – 11:00',
            'Recuperar horas de la semana',
            DateTime(seeded.first.year, seeded.first.month, seeded.first.day, 9, 30),
          )
          ..['status'] = 'Rejected'
          ..['resolverName'] = MockCatalog.supervisor
          ..['resolverComment'] = 'la sede está cerrada ese día'
          ..['resolvedAt'] = DateTime(
            seeded.first.year,
            seeded.first.month,
            seeded.first.day,
            11,
          ).toUtc().toIso8601String()
          ..['days'] = [
            {'date': _dateOf(saturday), 'start': '07:00:00', 'end': '11:00:00', 'lunchMinutes': 0},
          ];
      }(),
    ]);
  }

  MockWorkday _seedDay(DateTime day, int k) {
    DateTime t(int h, int m) => DateTime(day.year, day.month, day.day, h, m).toUtc();
    MockActivity a(MockActivityType type, DateTime from, DateTime to, {int photos = 0, bool signature = false}) =>
        MockActivity(
          id: _uuid.v4(),
          typeId: type.id,
          startedAt: from,
          endedAt: to,
          outcome: 'Completed',
          photoCount: photos,
          hasSignature: signature,
          geofence: 'Inside',
          accuracy: 8,
        );
    return MockWorkday(
      id: _uuid.v4(),
      date: _dateOf(day),
      startedAt: t(7, 2 + k),
      endedAt: t(16, 2 + k * 3),
      status: 'Closed',
      closeKind: 'Manual',
      startGeofence: 'Inside',
      endGeofence: 'Inside',
      activities: [
        a(MockCatalog.transfer, t(7, 5 + k), t(8, 5)),
        a(MockCatalog.installation, t(8, 12), t(11, 40 - k * 5), photos: 1, signature: true),
        a(MockCatalog.admin, t(13, 0), t(13, 50)),
        a(MockCatalog.maintenance, t(14, 0), t(15, 55 - k * 4), photos: 1),
      ],
    );
  }

  /// Scenario "Aviso de fin de turno": workday open with an activity and the automatic close
  /// 16 minutes from now, so the 15 and 5 minute warnings show up shortly.
  void _seedShiftEnd() {
    final now = _now;
    final date = _dateOf(now);
    final close = now.add(const Duration(minutes: 16)).toUtc();
    final end = close.subtract(const Duration(minutes: graceMinutes));
    final start = end.subtract(const Duration(hours: 8));
    state.shifts[date] = MockShift(start, end, label: 'Turno de demostración', lunchMinutes: 0, autoCloseAt: close);
    state.workdays.add(
      MockWorkday(
        id: _uuid.v4(),
        date: date,
        startedAt: start.add(const Duration(minutes: 3)),
        startGeofence: 'Inside',
        activities: [
          MockActivity(
            id: _uuid.v4(),
            typeId: MockCatalog.transfer.id,
            startedAt: start.add(const Duration(minutes: 5)),
            endedAt: start.add(const Duration(minutes: 65)),
            outcome: 'Completed',
          ),
          MockActivity(
            id: _uuid.v4(),
            typeId: MockCatalog.maintenance.id,
            workOrderId: MockCatalog.orders[1].id,
            startedAt: start.add(const Duration(minutes: 72)),
            geofence: 'Inside',
            accuracy: 7,
          ),
        ],
      ),
    );
    state.orderStatus[MockCatalog.orders[1].id] = 'InProgress';
  }

  // ── helpers ────────────────────────────────────────────────────────────

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  static String _month(int m) => _months[m - 1].substring(0, 3);
  static String _longDate(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} de ${_months[d.month - 1]}';
  static String _duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m m';
    return m == 0 ? '$h h' : '$h h $m m';
  }

  MockResponse _problem(int status, String code, String detail) => MockResponse(status, {
    'type': 'about:blank',
    'title': status == 404 ? 'No encontrado' : (status == 409 ? 'Conflicto' : 'Solicitud incorrecta'),
    'status': status,
    'detail': detail,
    'code': code,
  });
}
