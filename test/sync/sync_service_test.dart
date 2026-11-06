import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_mobile/core/storage/app_database.dart';
import 'package:worklog_mobile/core/storage/kv_store.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/data/sqlite_queue_stores.dart';
import 'package:worklog_mobile/features/sync/domain/queued_event.dart';
import 'package:worklog_mobile/features/sync/domain/queued_file.dart';
import 'package:worklog_mobile/features/sync/domain/sync_ports.dart';
import 'package:worklog_mobile/features/sync/domain/sync_service.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';

import '../support/fakes.dart';

void main() {
  const uuid = Uuid();
  late AppDatabase database;
  late SqliteEventQueueStore events;
  late SqliteFileQueueStore files;
  late SqliteLocationSampleStore locations;
  late SqliteKvStore kv;
  late FakeSyncApi api;
  late List<TodayDto> received;
  late SyncService sync;

  final t0 = DateTime.utc(2026, 10, 29, 12, 3);

  SyncEventDto event(String kind, {required DateTime at, String? workdayId, String? activityId}) => SyncEventDto(
    clientEventId: uuid.v4(),
    kind: kind,
    occurredAt: at,
    workdayId: workdayId,
    activityId: activityId,
    activityTypeId: kind == SyncEventKind.activityStart ? uuid.v4() : null,
  );

  setUp(() async {
    database = await openTestDatabase();
    events = SqliteEventQueueStore(database.db);
    files = SqliteFileQueueStore(database.db);
    locations = SqliteLocationSampleStore(database.db);
    kv = SqliteKvStore(database.db);
    api = FakeSyncApi()..today = sampleToday();
    received = [];
    sync = SyncService(
      events: events,
      files: files,
      locations: locations,
      api: api,
      kv: kv,
      onToday: (today) async => received.add(today),
      now: () => t0.add(const Duration(minutes: 10)),
    );
  });

  tearDown(() => database.close());

  group('event queue', () {
    test('enqueue is idempotent by clientEventId and keeps the local order', () async {
      final workdayId = uuid.v4();
      final start = event(SyncEventKind.workdayStart, at: t0, workdayId: workdayId);
      final activity = event(
        SyncEventKind.activityStart,
        at: t0.add(const Duration(minutes: 2)),
        activityId: uuid.v4(),
      );

      await events.enqueue(start, const EventMeta());
      await events.enqueue(activity, const EventMeta(activityName: 'Instalación de equipo'));
      await events.enqueue(start, const EventMeta());

      final pending = await events.pending();
      expect(pending.map((e) => e.clientEventId), [start.clientEventId, activity.clientEventId]);
      expect(pending.last.meta.activityName, 'Instalación de equipo');
      expect(await events.pendingCount(), 2);
    });
  });

  group('SyncService', () {
    test('sends pending events in the order the user did them and reconciles with today', () async {
      final workdayId = uuid.v4();
      final activityId = uuid.v4();
      final queued = [
        event(SyncEventKind.workdayStart, at: t0, workdayId: workdayId),
        event(SyncEventKind.activityStart, at: t0.add(const Duration(minutes: 5)), activityId: activityId),
        event(SyncEventKind.activityPause, at: t0.add(const Duration(minutes: 9)), activityId: activityId),
      ];
      for (final e in queued) {
        await events.enqueue(e, const EventMeta());
      }

      final report = await sync.syncEvents();

      expect(report.delivered, isTrue);
      expect(report.sent, 3);
      expect(api.batches, hasLength(1));
      expect(api.batches.single.map((e) => e.clientEventId), queued.map((e) => e.clientEventId));
      expect(await events.pendingCount(), 0);
      expect(received, hasLength(1));
      expect(await kv.getDate(KvKeys.lastSyncAt), isNotNull);
    });

    test('a failed delivery keeps the events and the retry is idempotent', () async {
      final workdayId = uuid.v4();
      final start = event(SyncEventKind.workdayStart, at: t0, workdayId: workdayId);
      await events.enqueue(start, const EventMeta());

      // 1) No network: nothing reaches the server.
      api.failNext.add(networkDown);
      var report = await sync.syncEvents();
      expect(report.delivered, isFalse);
      expect(report.error!.isNetwork, isTrue);
      expect((await events.pending()).single.attempts, 1);
      expect(await kv.getDate(KvKeys.offlineSince), isNotNull);

      // 2) The server applies the batch but the answer is lost.
      api.loseNextResponse = true;
      report = await sync.syncEvents();
      expect(report.delivered, isFalse);
      expect(await events.pendingCount(), 1);

      // 3) "Reintentar ahora": same clientEventId, the server replays its answer.
      report = await sync.syncEvents();
      expect(report.delivered, isTrue);
      expect(api.batches.map((b) => b.single.clientEventId).toSet(), {start.clientEventId});
      expect(api.effects[start.clientEventId], 1, reason: 'the server must apply the event only once');
      expect(await events.pendingCount(), 0);
      expect(await kv.getDate(KvKeys.offlineSince), isNull);
    });

    test('a rejected event is marked with its reason, is not resent and does not block the rest', () async {
      final workdayId = uuid.v4();
      final activityId = uuid.v4();
      final start = event(SyncEventKind.workdayStart, at: t0, workdayId: workdayId);
      final activity = event(
        SyncEventKind.activityStart,
        at: t0.add(const Duration(minutes: 1)),
        activityId: activityId,
      );
      final pause = event(SyncEventKind.activityPause, at: t0.add(const Duration(minutes: 2)), activityId: activityId);
      for (final e in [start, activity, pause]) {
        await events.enqueue(e, const EventMeta());
      }
      api.scripted[activity.clientEventId] = SyncEventResultDto(
        clientEventId: activity.clientEventId,
        outcome: SyncOutcome.rejected,
        code: 'activity.inactive',
        message: 'La actividad ya no está en el catálogo.',
      );

      final report = await sync.syncEvents();

      expect(report.resultFor(activity.clientEventId)!.outcome, SyncOutcome.rejected);
      expect(report.resultFor(pause.clientEventId)!.outcome, SyncOutcome.accepted);
      final reviewed = await events.reviewed();
      expect(reviewed.single.clientEventId, activity.clientEventId);
      expect(reviewed.single.status, QueueStatus.rejected);
      expect(reviewed.single.code, 'activity.inactive');
      expect(reviewed.single.message, 'La actividad ya no está en el catálogo.');

      await sync.syncEvents();
      expect(api.batches, hasLength(1), reason: 'nothing pending: no second batch');
    });

    test('an adjusted event keeps the server message', () async {
      final start = event(SyncEventKind.workdayStart, at: t0, workdayId: uuid.v4());
      await events.enqueue(start, const EventMeta());
      api.scripted[start.clientEventId] = SyncEventResultDto(
        clientEventId: start.clientEventId,
        outcome: SyncOutcome.adjusted,
        message: 'Fuera de la ventana del turno (desde 06:45). Se registró a las 06:45.',
      );

      await sync.syncEvents();

      final reviewed = await events.reviewed();
      expect(reviewed.single.status, QueueStatus.adjusted);
      expect(reviewed.single.message, contains('Se registró a las 06:45'));
    });

    test('events queued while a sync is running go in a second pass', () async {
      final activityId = uuid.v4();
      final first = event(SyncEventKind.activityPause, at: t0, activityId: activityId);
      final second = event(
        SyncEventKind.activityResume,
        at: t0.add(const Duration(minutes: 3)),
        activityId: activityId,
      );
      await events.enqueue(first, const EventMeta());

      late Future<SyncReport> concurrent;
      api.duringSync = () async {
        await events.enqueue(second, const EventMeta());
        concurrent = sync.syncEvents();
      };

      final report = await sync.syncEvents();
      await concurrent;

      expect(api.batches.map((b) => b.map((e) => e.clientEventId).toList()), [
        [first.clientEventId],
        [second.clientEventId],
      ]);
      expect(report.sent, 2);
      expect(await events.pendingCount(), 0);
    });

    test('large queues are sent in batches', () async {
      final small = SyncService(
        events: events,
        files: files,
        locations: locations,
        api: api,
        kv: kv,
        onToday: (_) async {},
        batchSize: 2,
      );
      final activityId = uuid.v4();
      for (var i = 0; i < 5; i++) {
        await events.enqueue(
          event(
            SyncEventKind.activityPause,
            at: t0.add(Duration(minutes: i)),
            activityId: activityId,
          ),
          const EventMeta(),
        );
      }

      final report = await small.syncEvents();

      expect(api.batches.map((b) => b.length), [2, 2, 1]);
      expect(report.sent, 5);
    });
  });

  group('file queue', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('worklog_test'));
    tearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    Future<QueuedFile> queueFile(String activityId) async {
      final path = '${temp.path}/${uuid.v4()}.jpg';
      File(path).writeAsBytesSync(List.filled(1024, 1));
      final file = QueuedFile(
        clientId: uuid.v4(),
        activityId: activityId,
        kind: EvidenceKind.photo,
        path: path,
        contentType: 'image/jpeg',
        sizeBytes: 1024,
        capturedAt: t0,
        label: 'Foto 1 de 1',
        status: FileStatus.pending,
        createdAt: t0,
      );
      await files.enqueue(file);
      return file;
    }

    test('files wait for wifi unless mobile data is allowed', () async {
      final file = await queueFile(uuid.v4());

      expect(await sync.syncFiles(network: NetworkKind.mobile, allowMobileData: false), 0);
      expect(await sync.syncFiles(network: NetworkKind.none, allowMobileData: true), 0);
      expect(await files.pendingCount(), 1);

      expect(await sync.syncFiles(network: NetworkKind.mobile, allowMobileData: true), 1);
      expect(api.uploads.single.clientId, file.clientId);
      expect(await files.pendingCount(), 0);
      expect(File(file.path).existsSync(), isFalse, reason: 'uploaded files are removed from the phone');
    });

    test('a file waits until the events of its activity are synchronized', () async {
      final activityId = uuid.v4();
      await events.enqueue(event(SyncEventKind.activityStart, at: t0, activityId: activityId), const EventMeta());
      await queueFile(activityId);

      expect(await sync.syncFiles(network: NetworkKind.wifi, allowMobileData: false), 0);

      await sync.syncEvents();
      expect(await sync.syncFiles(network: NetworkKind.wifi, allowMobileData: false), 1);
    });

    test('a network error stops the upload and keeps the file', () async {
      await queueFile(uuid.v4());
      api.uploadError = networkDown;

      expect(await sync.syncFiles(network: NetworkKind.wifi, allowMobileData: false), 0);
      final pending = await files.pending();
      expect(pending.single.attempts, 1);
      expect(pending.single.lastError, isNotNull);
    });
  });

  test('location samples are flushed and removed', () async {
    for (var i = 0; i < 3; i++) {
      await locations.add(
        LocationInputDto(latitude: 4.7, longitude: -74.04, accuracy: 8, capturedAt: t0.add(Duration(minutes: 15 * i))),
      );
    }

    expect(await sync.syncLocations(), 3);
    expect(await locations.count(), 0);
    expect(api.locationBatches.single, hasLength(3));
  });
}
