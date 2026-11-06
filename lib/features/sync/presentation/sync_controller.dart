import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/storage/kv_store.dart';
import '../data/sync_providers.dart';
import '../domain/queued_event.dart';
import '../domain/queued_file.dart';
import '../domain/sync_ports.dart';
import '../domain/sync_service.dart';

/// Everything the "Pendiente de sincronizar" screen and the sync badges need.
class SyncStatus {
  const SyncStatus({
    this.pendingEvents = const [],
    this.pendingFiles = const [],
    this.reviewed = const [],
    this.failedFiles = const [],
    this.lastSyncAt,
    this.offlineSince,
    this.lastError,
    this.syncing = false,
    this.allowMobileData = false,
    this.network = NetworkKind.none,
    this.loaded = false,
  });

  final List<QueuedEvent> pendingEvents;
  final List<QueuedFile> pendingFiles;

  /// Events the server rejected or adjusted.
  final List<QueuedEvent> reviewed;
  final List<QueuedFile> failedFiles;
  final DateTime? lastSyncAt;
  final DateTime? offlineSince;
  final String? lastError;
  final bool syncing;
  final bool allowMobileData;
  final NetworkKind network;
  final bool loaded;

  bool get hasPending => pendingEvents.isNotEmpty || pendingFiles.isNotEmpty;
  bool get allSent => !hasPending;
  bool get hasRejected => reviewed.any((e) => e.status == QueueStatus.rejected);

  /// Files that cannot go now because they wait for wifi.
  bool fileWaitsForWifi(QueuedFile file) => !network.isUnmetered && !allowMobileData;

  SyncStatus copyWith({
    List<QueuedEvent>? pendingEvents,
    List<QueuedFile>? pendingFiles,
    List<QueuedEvent>? reviewed,
    List<QueuedFile>? failedFiles,
    DateTime? lastSyncAt,
    DateTime? offlineSince,
    bool clearOfflineSince = false,
    String? lastError,
    bool clearLastError = false,
    bool? syncing,
    bool? allowMobileData,
    NetworkKind? network,
    bool? loaded,
  }) => SyncStatus(
    pendingEvents: pendingEvents ?? this.pendingEvents,
    pendingFiles: pendingFiles ?? this.pendingFiles,
    reviewed: reviewed ?? this.reviewed,
    failedFiles: failedFiles ?? this.failedFiles,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    offlineSince: clearOfflineSince ? null : (offlineSince ?? this.offlineSince),
    lastError: clearLastError ? null : (lastError ?? this.lastError),
    syncing: syncing ?? this.syncing,
    allowMobileData: allowMobileData ?? this.allowMobileData,
    network: network ?? this.network,
    loaded: loaded ?? this.loaded,
  );
}

/// Drives the synchronization: right after each action, when the network comes back, every
/// minute while something is pending, and with "Reintentar ahora".
class SyncController extends Notifier<SyncStatus> {
  static const retryEvery = Duration(minutes: 1);

  Timer? _timer;

  @override
  SyncStatus build() {
    ref.listen(networkProvider, (previous, next) {
      final kind = next.value;
      if (kind == null) return;
      final was = previous?.value ?? NetworkKind.none;
      state = state.copyWith(network: kind);
      if (kind.isOnline && (!was.isOnline || kind.isUnmetered != was.isUnmetered)) unawaited(run());
    });
    _timer = Timer.periodic(retryEvery, (_) {
      if (state.hasPending && !state.syncing) unawaited(run());
    });
    ref.onDispose(() => _timer?.cancel());
    unawaited(reload());
    return const SyncStatus();
  }

  SyncService get _service => ref.read(syncServiceProvider);

  /// Reads the queue and the sync bookkeeping from SQLite.
  Future<void> reload() async {
    final events = ref.read(eventQueueStoreProvider);
    final files = ref.read(fileQueueStoreProvider);
    final kv = ref.read(kvStoreProvider);
    final network = await ref.read(connectivityServiceProvider).current();
    final next = state.copyWith(
      pendingEvents: await events.pending(),
      pendingFiles: await files.pending(),
      reviewed: await events.reviewed(),
      failedFiles: await files.failed(),
      lastSyncAt: await kv.getDate(KvKeys.lastSyncAt),
      offlineSince: await kv.getDate(KvKeys.offlineSince),
      clearOfflineSince: await kv.get(KvKeys.offlineSince) == null,
      lastError: await kv.get(KvKeys.lastSyncError),
      clearLastError: await kv.get(KvKeys.lastSyncError) == null,
      allowMobileData: await kv.getBool(KvKeys.allowMobileData),
      network: network,
      loaded: true,
    );
    if (ref.mounted) state = next;
  }

  /// Sends events, location samples and (network permitting) files.
  Future<SyncReport> run() async {
    if (!ref.mounted) return SyncReport.idle;
    state = state.copyWith(syncing: true);
    try {
      final report = await _service.syncEvents();
      if (report.delivered) {
        await _service.syncLocations();
        final network = await ref.read(connectivityServiceProvider).current();
        await _service.syncFiles(network: network, allowMobileData: state.allowMobileData);
      }
      return report;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(syncing: false);
        await reload();
      }
    }
  }

  Future<void> setAllowMobileData(bool value) async {
    await ref.read(kvStoreProvider).setBool(KvKeys.allowMobileData, value);
    state = state.copyWith(allowMobileData: value);
    if (value) unawaited(run());
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);
