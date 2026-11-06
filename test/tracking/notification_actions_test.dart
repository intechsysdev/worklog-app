import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/storage/app_database.dart';
import 'package:worklog_mobile/core/storage/kv_store.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/data/sqlite_queue_stores.dart';
import 'package:worklog_mobile/features/tracking/domain/notification_actions.dart';
import 'package:worklog_mobile/features/tracking/domain/tracker_status.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';

import '../support/fakes.dart';

void main() {
  final device = DateTime.utc(2026, 10, 29, 15);
  late AppDatabase database;
  late SqliteEventQueueStore queue;
  late SqliteKvStore kv;
  late NotificationActions actions;

  final status = TrackerStatus(
    workdayStartedAt: DateTime.utc(2026, 10, 29, 12, 3),
    samplingMinutes: 15,
    activityId: 'a1',
    activityName: 'Mantenimiento preventivo',
    place: 'Bodega Sur · OT-1043',
    workOrderNumber: 'OT-1043',
    activityStartedAt: DateTime.utc(2026, 10, 29, 14, 45),
    baseWorkedSeconds: 600,
    runningSince: DateTime.utc(2026, 10, 29, 14, 55),
  );

  setUp(() async {
    database = await openTestDatabase();
    queue = SqliteEventQueueStore(database.db);
    kv = SqliteKvStore(database.db);
    // The server clock is 30 s ahead of the phone.
    await kv.set(KvKeys.clockOffsetMs, '30000');
    actions = NotificationActions(queue: queue, kv: kv, now: () => device);
  });

  tearDown(() => database.close());

  test('"Pausar" queues the pause with the server time and pauses the stopwatch', () async {
    final result = await actions.handle(TrackerButton.pause, status);

    final pending = await queue.pending();
    expect(pending.single.event.kind, SyncEventKind.activityPause);
    expect(pending.single.event.activityId, 'a1');
    expect(pending.single.event.occurredAt, device.add(const Duration(seconds: 30)));
    expect(result.status!.paused, isTrue);
    // 10 min before + 5 min 30 s since 14:55.
    expect(result.status!.baseWorkedSeconds, 600 + 330);
  });

  test('"Finalizar" without requirements queues it as Completada', () async {
    final result = await actions.handle(TrackerButton.finish, status);

    final event = (await queue.pending()).single.event;
    expect(event.kind, SyncEventKind.activityFinish);
    expect(event.outcome, ActivityOutcome.completed);
    expect(result.status!.hasActivity, isFalse);
    expect(result.openRoute, isNull);
  });

  test('"Finalizar" with photo, signature or observation opens the screen instead', () async {
    final needsEvidence = TrackerStatus.fromJson({...status.toJson(), 'finishNeedsScreen': true});
    final result = await actions.handle(TrackerButton.finish, needsEvidence);

    expect(await queue.pendingCount(), 0);
    expect(result.openRoute, NotificationActions.finishRoute);
  });

  test('pressing "Pausar" on a paused activity does nothing', () async {
    final paused = status.withPaused(true, device);
    await actions.handle(TrackerButton.pause, paused);
    expect(await queue.pendingCount(), 0);
  });

  test('fixed notification content', () {
    final running = TrackerNotification.of(status, DateTime.utc(2026, 10, 29, 15, 37));
    expect(running.title, 'INTECHSYS ONE · Jornada activa');
    expect(running.text, startsWith('Mantenimiento preventivo · En curso 00:52'));
    expect(running.buttons.map((b) => b.$2), ['Pausar', 'Finalizar']);

    final paused = TrackerNotification.of(status.withPaused(true, device), DateTime.utc(2026, 10, 29, 16));
    expect(paused.buttons.first.$1, TrackerButton.resume);

    final idle = TrackerNotification.of(
      TrackerStatus(workdayStartedAt: status.workdayStartedAt, samplingMinutes: 15),
      device,
    );
    expect(idle.text, startsWith('Sin actividad en curso'));
    expect(idle.buttons, isEmpty);
  });

  test('status survives the JSON round trip between isolates', () {
    final decoded = TrackerStatus.decode(status.encode())!;
    expect(decoded.activityName, status.activityName);
    expect(decoded.worked(device), status.worked(device));
  });
}
