import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_clients.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/kv_store.dart';
import '../../requests/presentation/requests_controller.dart';
import '../../sync/presentation/sync_controller.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/mock_state.dart';

class DemoStatus {
  const DemoStatus({required this.scenario, required this.offline});

  final DemoScenario scenario;
  final bool offline;
}

/// Controls of the demo APK (Perfil): scenario, "Simular sin conexión" and reset.
class DemoController extends Notifier<DemoStatus?> {
  @override
  DemoStatus? build() {
    final backend = ref.watch(mockBackendProvider);
    return backend == null ? null : DemoStatus(scenario: backend.scenario, offline: backend.offline);
  }

  Future<void> setOffline(bool value) async {
    final backend = ref.read(mockBackendProvider);
    if (backend == null) return;
    await backend.setOffline(value);
    state = DemoStatus(scenario: backend.scenario, offline: value);
    if (!value) unawaited(ref.read(syncControllerProvider.notifier).run());
  }

  /// Starts today over with another scenario.
  Future<void> setScenario(DemoScenario scenario) async {
    final backend = ref.read(mockBackendProvider);
    if (backend == null) return;
    await backend.setScenario(scenario);
    await _resetLocal();
    state = DemoStatus(scenario: scenario, offline: backend.offline);
  }

  /// "Reiniciar datos de demostración".
  Future<void> reset() async {
    final backend = ref.read(mockBackendProvider);
    if (backend == null) return;
    await backend.reset();
    await _resetLocal();
    state = DemoStatus(scenario: backend.scenario, offline: backend.offline);
  }

  /// The local queue and caches belong to the previous data: they are cleared (session,
  /// policy acceptance and preferences stay).
  Future<void> _resetLocal() async {
    final db = ref.read(appDatabaseProvider).db;
    final batch = db.batch()
      ..delete('events')
      ..delete('files')
      ..delete('location_samples')
      ..delete(
        'kv',
        where: "key LIKE 'cache.%' OR key IN (?, ?, ?)",
        whereArgs: [KvKeys.lastSyncAt, KvKeys.lastSyncError, KvKeys.offlineSince],
      );
    await batch.commit(noResult: true);
    ref
      ..invalidate(todayControllerProvider)
      ..invalidate(activityOptionsProvider)
      ..invalidate(timelineProvider)
      ..invalidate(syncControllerProvider)
      ..invalidate(requestsControllerProvider);
  }
}

final demoControllerProvider = NotifierProvider<DemoController, DemoStatus?>(DemoController.new);
