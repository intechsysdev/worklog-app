import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/network/http_clients.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/kv_store.dart';
import '../../workday/data/today_repository.dart';
import '../../workday/data/workday_api.dart';
import '../domain/queue_stores.dart';
import '../domain/sync_service.dart';
import 'sqlite_queue_stores.dart';

final workdayApiProvider = Provider<WorkdayApi>((ref) => WorkdayApi(ref.watch(worklogDioProvider)));

final eventQueueStoreProvider = Provider<EventQueueStore>(
  (ref) => SqliteEventQueueStore(ref.watch(appDatabaseProvider).db),
);

final fileQueueStoreProvider = Provider<FileQueueStore>(
  (ref) => SqliteFileQueueStore(ref.watch(appDatabaseProvider).db),
);

final locationSampleStoreProvider = Provider<LocationSampleStore>(
  (ref) => SqliteLocationSampleStore(ref.watch(appDatabaseProvider).db),
);

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  final repository = TodayRepository(
    api: ref.watch(workdayApiProvider),
    kv: ref.watch(kvStoreProvider),
    clock: ref.watch(serverClockProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final today = ref.watch(todayRepositoryProvider);
  return SyncService(
    events: ref.watch(eventQueueStoreProvider),
    files: ref.watch(fileQueueStoreProvider),
    locations: ref.watch(locationSampleStoreProvider),
    api: ref.watch(workdayApiProvider),
    kv: ref.watch(kvStoreProvider),
    onToday: today.save,
  );
});
