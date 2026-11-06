import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/network/api_exception.dart';
import 'package:worklog_mobile/features/demo/data/mock_backend.dart';
import 'package:worklog_mobile/features/demo/data/mock_catalog.dart';
import 'package:worklog_mobile/features/demo/data/mock_http_adapter.dart';
import 'package:worklog_mobile/features/demo/data/mock_state.dart';
import 'package:worklog_mobile/features/requests/data/request_models.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/week/data/week_models.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/workday_api.dart';

void main() {
  // Tuesday 3 November 2026, local time of the test machine.
  late DateTime clock;
  late MemoryMockStore store;
  late MockBackend backend;

  Future<void> boot(DateTime at) async {
    clock = at;
    store = MemoryMockStore();
    backend = await MockBackend.load(store, now: () => clock);
  }

  Map<String, dynamic> json(MockResponse r) => Map<String, dynamic>.from(r.body! as Map);

  Map<String, dynamic> today() => json(backend.handle('GET', '/api/v1/me/today'));

  Map<String, dynamic> location() => {
    'latitude': 4.7110,
    'longitude': -74.0721,
    'accuracy': 8,
    'capturedAt': clock.toUtc().toIso8601String(),
  };

  var n = 0;
  Map<String, dynamic> event(String kind, {Map<String, dynamic> extra = const {}, DateTime? at}) => {
    'clientEventId': 'e${++n}',
    'kind': kind,
    'occurredAt': (at ?? clock).toUtc().toIso8601String(),
    'location': location(),
    ...extra,
  };

  List<Map<String, dynamic>> sync(List<Map<String, dynamic>> events) {
    final body = json(backend.handle('POST', '/api/v1/me/workday/sync', body: {'events': events}));
    return [for (final r in body['results'] as List) Map<String, dynamic>.from(r as Map)];
  }

  group('shift adapted to the real clock', () {
    test('weekday inside 07:00–16:00: the regular shift', () async {
      await boot(DateTime(2026, 11, 3, 10));
      final plan = today()['plan'] as Map;
      expect(plan['kind'], 'Shift');
      expect(plan['start'], '07:00:00');
      expect(plan['end'], '16:00:00');
      expect((today()['window'] as Map)['canStartNow'], isTrue);
    });

    test('at night or on the weekend: 8 h starting 10 minutes ago, stable during the day', () async {
      await boot(DateTime(2026, 11, 7, 22, 30)); // Saturday
      var plan = today()['plan'] as Map;
      expect(plan['start'], '22:20:00');
      expect(plan['end'], '06:20:00');
      expect((today()['window'] as Map)['canStartNow'], isTrue);

      clock = clock.add(const Duration(minutes: 40));
      plan = today()['plan'] as Map;
      expect(plan['start'], '22:20:00', reason: 'the window must not move');
    });

    test('a weekday before 07:00 also adapts', () async {
      await boot(DateTime(2026, 11, 3, 6, 30));
      expect((today()['plan'] as Map)['start'], '06:20:00');
    });
  });

  test('full workday: start, activities with requirements, auto-finish and close', () async {
    await boot(DateTime(2026, 11, 3, 8));
    backend.handle('POST', '/api/v1/me/privacy-policy/accept', body: {'version': '1.0'});
    expect((today()['policy'] as Map)['accepted'], isTrue);

    var results = sync([
      event('workday.start', extra: {'workdayId': 'w1'}),
    ]);
    expect(results.single['outcome'], 'Accepted');
    expect((today()['workday'] as Map)['startGeofence'], 'Inside', reason: 'the site is centered on the phone');

    final order = MockCatalog.orders[0]; // OT-1042, Instalación de equipo (foto y firma)
    clock = clock.add(const Duration(minutes: 5));
    results = sync([
      event('activity.start', extra: {'activityId': 'a1', 'workOrderId': order.id}),
    ]);
    expect(results.single['outcome'], 'Accepted');
    final current = (today()['workday'] as Map)['current'] as Map;
    expect(current['name'], 'Instalación de equipo');
    expect(current['workOrderNumber'], 'OT-1042');
    expect(current['startGeofence'], 'Inside');
    expect((current['requirements'] as Map)['signature'], isTrue);

    clock = clock.add(const Duration(minutes: 30));
    results = sync([
      event('activity.pause', extra: {'activityId': 'a1'}),
    ]);
    clock = clock.add(const Duration(minutes: 10));
    results = sync([
      event('activity.resume', extra: {'activityId': 'a1'}),
      event(
        'activity.finish',
        extra: {'activityId': 'a1', 'outcome': 'Completed', 'photoCount': 0, 'hasSignature': true},
      ),
    ]);
    expect(results.last['outcome'], 'Rejected');
    expect(results.last['code'], 'activity.photo');

    results = sync([
      event(
        'activity.finish',
        extra: {'activityId': 'a1', 'outcome': 'Incomplete', 'photoCount': 1, 'hasSignature': true},
      ),
    ]);
    expect(results.single['code'], 'activity.observation', reason: 'Incompleta pide observación');

    results = sync([
      event(
        'activity.finish',
        extra: {'activityId': 'a1', 'outcome': 'Completed', 'photoCount': 1, 'hasSignature': true},
      ),
    ]);
    expect(results.single['outcome'], 'Accepted');

    // Starting another activity auto-finishes the open one.
    clock = clock.add(const Duration(minutes: 2));
    sync([
      event('activity.start', extra: {'activityId': 'a2', 'activityTypeId': MockCatalog.warranty.id}),
    ]);
    clock = clock.add(const Duration(minutes: 20));
    sync([
      event('activity.start', extra: {'activityId': 'a3', 'activityTypeId': MockCatalog.transfer.id}),
    ]);
    clock = clock.add(const Duration(minutes: 15));
    results = sync([
      event('workday.close', extra: {'note': 'Todo bien'}),
    ]);
    expect(results.single['outcome'], 'Accepted');

    final workday = today()['workday'] as Map;
    expect(workday['status'], 'Closed');
    final summary = workday['summary'] as Map;
    expect(summary['activityCount'], 3);
    final categories = {for (final c in summary['byCategory'] as List) (c as Map)['name']: c['minutes']};
    expect(categories['Productivo'], 30 + 20, reason: '40 min − 10 min de pausa + 20 min de garantía');
    expect(categories['Traslado'], 15);

    // The completed order leaves "Asignadas hoy".
    final options = json(backend.handle('GET', '/api/v1/me/workday/activity-options'));
    expect((options['assigned'] as List).map((o) => (o as Map)['number']), ['OT-1043', 'OT-1047']);
    expect((options['catalog'] as List), hasLength(8));

    final timeline = json(backend.handle('GET', '/api/v1/me/timeline', query: {'date': '2026-11-03'}));
    final kinds = [for (final e in timeline['entries'] as List) (e as Map)['kind']];
    expect(kinds.first, 'close');
    expect(kinds.last, 'start');
    expect(kinds.where((k) => k == 'activity'), hasLength(3));
  });

  test('idempotency: resending the same events repeats the answers without new effects', () async {
    await boot(DateTime(2026, 11, 3, 9));
    final batch = [
      event('workday.start', extra: {'workdayId': 'w1'}),
      event('activity.start', extra: {'activityId': 'a1', 'activityTypeId': MockCatalog.admin.id}),
      event('activity.finish', extra: {'activityId': 'a1', 'outcome': 'Completed', 'photoCount': 0}),
    ];
    final first = sync(batch);
    final second = sync(batch);
    expect(second, first);
    expect(((today()['workday'] as Map)['summary'] as Map)['activityCount'], 1);
    expect(backend.state.workdays.where((w) => w.date == '2026-11-03'), hasLength(1));
  });

  test('start window: too early online is rejected; queued offline is moved to the opening', () async {
    // At 07:00 the regular shift is fixed for the day; then the clock goes back to test the window.
    await boot(DateTime(2026, 11, 3, 7));
    today();
    clock = DateTime(2026, 11, 3, 6, 40); // still before 06:45
    var results = sync([
      event('workday.start', extra: {'workdayId': 'w1'}),
    ]);
    expect(results.single['code'], 'workday.too_early');

    clock = DateTime(2026, 11, 3, 6, 55);
    results = sync([
      event('workday.start', extra: {'workdayId': 'w2'}, at: DateTime(2026, 11, 3, 6, 41)),
    ]);
    expect(results.single['outcome'], 'Adjusted');
    expect(results.single['message'], contains('Se registró a las 06:45'));
  });

  test('late arrival beyond the 5 minute tolerance', () async {
    await boot(DateTime(2026, 11, 3, 7, 20));
    sync([
      event('workday.start', extra: {'workdayId': 'w1'}),
    ]);
    expect((today()['workday'] as Map)['lateMinutes'], 20);
  });

  group('scenarios', () {
    test('vacation: absence approved by the supervisor and start blocked', () async {
      await boot(DateTime(2026, 11, 3, 10));
      await backend.setScenario(DemoScenario.vacation);
      final t = today();
      expect((t['plan'] as Map)['kind'], 'Absence');
      expect((t['absence'] as Map)['approvedBy'], 'Laura Gómez');
      expect(t['window'], isNull);
      expect(
        sync([
          event('workday.start', extra: {'workdayId': 'w1'}),
        ]).single['code'],
        'workday.no_shift',
      );
    });

    test('kiosk shared and assigned', () async {
      await boot(DateTime(2026, 11, 3, 10));
      await backend.setScenario(DemoScenario.kioskShared);
      var device = today()['device'] as Map;
      expect(device['controlEnabled'], isTrue);
      expect(device['isShared'], isTrue);
      expect(device['warningMinutes'], [15, 5]);
      await backend.setScenario(DemoScenario.kioskAssigned);
      device = today()['device'] as Map;
      expect(device['isShared'], isFalse);
      expect((today()['device'] as Map)['corporateApps'], isNotEmpty);
    });

    test('shift end: open workday and automatic close in 16 minutes', () async {
      await boot(DateTime(2026, 11, 3, 15, 30));
      await backend.setScenario(DemoScenario.shiftEnd);
      final t = today();
      expect(DateTime.parse(t['autoCloseAt'] as String), clock.add(const Duration(minutes: 16)).toUtc());
      final workday = t['workday'] as Map;
      expect(workday['status'], 'Open');
      expect((workday['current'] as Map)['name'], 'Mantenimiento preventivo');

      clock = clock.add(const Duration(minutes: 17));
      final closed = today()['workday'] as Map;
      expect(closed['status'], 'PendingReview');
      expect(closed['closeKind'], 'Automatic');
    });
  });

  test('requests: created pending, approved by the supervisor after 2 minutes, cancel only pending', () async {
    await boot(DateTime(2026, 11, 3, 10));
    final created = backend.handle(
      'POST',
      '/api/v1/me/requests/overtime',
      body: {'date': '2026-11-03', 'from': '16:00:00', 'to': '17:30:00', 'reason': 'Cierre de obra'},
    );
    expect(created.status, 201);
    final id = json(created)['id'] as String;
    final shift = backend.handle(
      'POST',
      '/api/v1/me/requests/shift-change',
      body: {
        'days': [
          {'date': '2026-11-04', 'start': null, 'end': null, 'lunchMinutes': 0},
        ],
        'reason': 'Cita médica',
      },
    );
    final shiftId = json(shift)['id'] as String;
    expect(backend.handle('POST', '/api/v1/me/requests/$shiftId/cancel').status, 200);

    clock = clock.add(const Duration(minutes: 3));
    final list = json(backend.handle('GET', '/api/v1/me/requests'));
    final overtime = (list['items'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .firstWhere((r) => r['id'] == id);
    expect(overtime['status'], 'Approved');
    expect(overtime['resolverName'], 'Laura Gómez');
    expect(today()['overtimeUntil'], '17:30:00');
    expect(backend.handle('POST', '/api/v1/me/requests/$id/cancel').status, 409);

    final bad = backend.handle(
      'POST',
      '/api/v1/me/requests/overtime',
      body: {'date': '2026-11-03', 'from': '17:00:00', 'to': '16:00:00', 'reason': 'Al revés'},
    );
    expect(json(bad)['code'], 'request.overtime_range');
  });

  test('state survives a restart', () async {
    await boot(DateTime(2026, 11, 3, 10));
    sync([
      event('workday.start', extra: {'workdayId': 'w1'}),
    ]);
    await backend.setScenario(DemoScenario.normal);
    sync([
      event('workday.start', extra: {'workdayId': 'w9'}),
    ]);
    await Future<void>.delayed(Duration.zero);
    final reloaded = await MockBackend.load(store, now: () => clock);
    expect(reloaded.state.workdays.where((w) => w.isOpen).single.id, 'w9');
  });

  group('through dio with the app models', () {
    late WorkdayApi api;
    late Dio dio;

    setUp(() async {
      await boot(DateTime(2026, 11, 3, 10));
      dio = Dio(BaseOptions(baseUrl: 'https://demo.worklog.local/api/v1'))
        ..httpClientAdapter = MockHttpAdapter(backend, latency: Duration.zero);
      api = WorkdayApi(dio);
    });

    test('today, options, timeline, week and requests parse into the DTOs of the app', () async {
      final today = await api.today();
      expect(today.memberName, 'Andrés Mora');
      expect(today.supervisorName, 'Laura Gómez');
      expect(today.plan.kind, DayKind.shift);

      final options = await api.activityOptions();
      expect(options.assigned.map((o) => o.number), ['OT-1042', 'OT-1043', 'OT-1047']);
      expect(options.catalogFor(MockCatalog.installation.id)!.requiresSignature, isTrue);

      final result = await api.sync([
        SyncEventDto(clientEventId: 'x1', kind: SyncEventKind.workdayStart, occurredAt: clock.toUtc(), workdayId: 'w1'),
      ]);
      expect(result.results.single.outcome, SyncOutcome.accepted);
      expect(result.today!.workday!.isOpen, isTrue);

      final timeline = await api.timeline('2026-11-03');
      expect(timeline.entries.first.kind, anyOf('idle', 'start'));

      final week = MyWeekDto.fromJson((await dio.get<Map<String, dynamic>>('/me/week')).data!);
      expect(week.days, hasLength(7));
      expect(week.workedMinutes, greaterThan(8 * 60), reason: 'seeded days with hours');

      final requests = RequestPageDto.fromJson((await dio.get<Map<String, dynamic>>('/me/requests')).data!);
      expect(requests.items.map((r) => r.status), containsAll([RequestStatus.approved, RequestStatus.rejected]));
    });

    test('"Simular sin conexión" fails like a phone without signal', () async {
      await backend.setOffline(true);
      await expectLater(api.today(), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue)));
      await backend.setOffline(false);
      expect((await api.today()).memberName, 'Andrés Mora');
    });

    test('validation errors come back as ProblemDetails with their code', () async {
      await expectLater(
        dio.post<Map<String, dynamic>>('/me/requests/shift-change', data: {'days': <Object>[], 'reason': 'x'}),
        throwsA(isA<DioException>().having((e) => ApiException.fromDio(e).code, 'code', 'request.days')),
      );
    });
  });
}
