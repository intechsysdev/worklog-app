import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/domain/queued_event.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';
import 'package:worklog_mobile/features/workday/domain/day_projection.dart';

import '../support/fakes.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 29, 12, 3);
  var seq = 0;

  QueuedEvent queued(
    String kind,
    DateTime at, {
    String? workdayId,
    String? activityId,
    QueueStatus status = QueueStatus.pending,
    EventMeta meta = const EventMeta(),
  }) => QueuedEvent(
    seq: ++seq,
    event: SyncEventDto(
      clientEventId: 'e$seq',
      kind: kind,
      occurredAt: at,
      workdayId: workdayId,
      activityId: activityId,
      activityTypeId: kind == SyncEventKind.activityStart ? 'type-1' : null,
    ),
    meta: meta,
    status: status,
    createdAt: at,
  );

  test('without pending events the server state is shown as is', () {
    final view = DayProjection.build(sampleToday(), const []);
    expect(view.mode, HomeMode.start);
    expect(view.workday, isNull);
  });

  test('a day without shift shows the no-shift mode', () {
    expect(DayProjection.build(sampleToday(kind: DayKind.absence), const []).mode, HomeMode.noShift);
  });

  test('queued start, activity and pause build the optimistic state', () {
    final events = [
      queued(SyncEventKind.workdayStart, t0, workdayId: 'w1'),
      queued(
        SyncEventKind.activityStart,
        t0.add(const Duration(minutes: 9)),
        activityId: 'a1',
        meta: const EventMeta(activityName: 'Instalación de equipo', workOrderNumber: 'OT-1042', requiresPhoto: true),
      ),
      queued(SyncEventKind.activityPause, t0.add(const Duration(minutes: 39)), activityId: 'a1'),
    ];

    final view = DayProjection.build(sampleToday(), events);

    expect(view.mode, HomeMode.active);
    expect(view.pendingCount, 3);
    expect(view.workday!.id, 'w1');
    expect(view.workday!.optimistic, isTrue);
    final current = view.current!;
    expect(current.name, 'Instalación de equipo');
    expect(current.place, 'OT-1042');
    expect(current.paused, isTrue);
    expect(current.requirements.photo, isTrue);
    // 30 minutes worked, the clock stops while paused.
    expect(current.worked(t0.add(const Duration(hours: 2))), const Duration(minutes: 30));
    expect(view.workday!.summary.activityCount, 1);
  });

  test('rejected events are left out; finish and close clear the activity', () {
    final events = [
      queued(SyncEventKind.workdayStart, t0, workdayId: 'w1'),
      queued(
        SyncEventKind.activityStart,
        t0.add(const Duration(minutes: 1)),
        activityId: 'bad',
        status: QueueStatus.rejected,
      ),
      queued(SyncEventKind.activityStart, t0.add(const Duration(minutes: 2)), activityId: 'a2'),
      queued(SyncEventKind.activityFinish, t0.add(const Duration(minutes: 30)), activityId: 'a2'),
    ];

    var view = DayProjection.build(sampleToday(), events);
    expect(view.mode, HomeMode.active);
    expect(view.current, isNull);
    expect(view.workday!.summary.activityCount, 1);

    view = DayProjection.build(sampleToday(), [
      ...events,
      queued(SyncEventKind.workdayClose, t0.add(const Duration(hours: 8))),
    ]);
    expect(view.mode, HomeMode.closed);
  });

  test('the server snapshot keeps the stopwatch running from serverTime', () {
    final serverTime = DateTime.utc(2026, 10, 29, 13);
    final today = sampleToday(
      serverTime: serverTime,
      workday: WorkdayDto(
        id: 'w1',
        date: '2026-10-29',
        status: WorkdayStatus.open,
        startedAt: t0,
        summary: const DaySummaryDto(activityCount: 1),
        current: CurrentActivityDto(
          id: 'a1',
          activityTypeId: 't1',
          name: 'Mantenimiento preventivo',
          color: '#AF1839',
          timeClass: TimeClass.productive,
          startedAt: t0,
          status: ActivityStatus.running,
          workedSeconds: 600,
          requirements: const RequirementsDto(),
        ),
      ),
    );

    final view = DayProjection.build(today, const []);
    expect(view.current!.worked(serverTime.add(const Duration(minutes: 5))), const Duration(minutes: 15));
    expect(view.current!.optimistic, isFalse);
  });
}
