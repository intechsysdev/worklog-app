import 'dart:async';
import 'dart:io';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/kv_store.dart';
import '../../workday/data/models/enums.dart';
import '../../workday/data/models/today_dto.dart';
import '../data/models/sync_models.dart';
import 'queue_stores.dart';
import 'queued_event.dart';
import 'sync_ports.dart';

/// Outcome of one pass of the synchronization.
class SyncReport {
  const SyncReport({this.sent = 0, this.results = const [], this.error, this.filesUploaded = 0});

  static const idle = SyncReport();

  final int sent;
  final List<SyncEventResultDto> results;

  /// Why the events could not be delivered (they stay in the queue).
  final ApiException? error;
  final int filesUploaded;

  bool get delivered => error == null;

  SyncEventResultDto? resultFor(String clientEventId) {
    for (final r in results) {
      if (r.clientEventId == clientEventId) return r;
    }
    return null;
  }
}

/// Sends the local queue to `POST /me/workday/sync` in the order the user did things.
///
/// - One pass at a time; a call during a pass schedules another one right after.
/// - Retrying is safe: the server de-duplicates by `clientEventId` and answers the same outcome.
/// - A rejected event is marked and never resent; the following events are still processed.
/// - The `today` of the answer replaces the cached state (reconciliation of the optimistic UI).
class SyncService {
  SyncService({
    required this._events,
    required this._files,
    required this._locations,
    required this._api,
    required this._kv,
    required this._onToday,
    DateTime Function()? now,
    this.batchSize = 200,
    this.locationBatchSize = 200,
    this.maxFileAttempts = 20,
  }) : _now = now ?? DateTime.now;

  final EventQueueStore _events;
  final FileQueueStore _files;
  final LocationSampleStore _locations;
  final SyncApi _api;
  final KvStore _kv;
  final Future<void> Function(TodayDto today) _onToday;
  final DateTime Function() _now;
  final int batchSize;
  final int locationBatchSize;
  final int maxFileAttempts;

  Future<SyncReport>? _running;
  bool _again = false;

  bool get isRunning => _running != null;

  /// Sends pending events. Safe to call any time.
  Future<SyncReport> syncEvents() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final future = _loop().whenComplete(() => _running = null);
    _running = future;
    return future;
  }

  Future<SyncReport> _loop() async {
    var report = await _pass();
    while (_again && report.delivered) {
      _again = false;
      final next = await _pass();
      report = SyncReport(
        sent: report.sent + next.sent,
        results: [...report.results, ...next.results],
        error: next.error,
      );
    }
    _again = false;
    return report;
  }

  Future<SyncReport> _pass() async {
    var sent = 0;
    final results = <SyncEventResultDto>[];

    while (true) {
      final batch = await _events.pending(limit: batchSize);
      if (batch.isEmpty) break;

      final SyncBatchResultDto response;
      try {
        response = await _api.sync(batch.map((e) => e.event).toList());
      } on Object catch (error) {
        final failure = ApiException.from(error);
        await _events.markAttempt(batch.map((e) => e.clientEventId).toList());
        await _recordFailure(failure);
        return SyncReport(sent: sent, results: results, error: failure);
      }

      final at = _now().toUtc();
      final byId = {for (final r in response.results) r.clientEventId: r};
      final unanswered = <String>[];
      for (final event in batch) {
        final result = byId[event.clientEventId];
        if (result == null) {
          unanswered.add(event.clientEventId);
          continue;
        }
        await _events.markResult(
          event.clientEventId,
          switch (result.outcome) {
            SyncOutcome.accepted => QueueStatus.accepted,
            SyncOutcome.adjusted => QueueStatus.adjusted,
            SyncOutcome.rejected => QueueStatus.rejected,
          },
          code: result.code,
          message: result.message,
          resultId: result.resultId,
          at: at,
        );
        results.add(result);
      }
      await _events.markAttempt(unanswered);
      sent += batch.length - unanswered.length;

      if (response.today != null) await _onToday(response.today!);
      await _recordSuccess(at);

      // Events the server did not answer stay pending; avoid a hot loop on them.
      if (unanswered.isNotEmpty || batch.length < batchSize) break;
    }

    if (sent == 0 && results.isEmpty) await _recordSuccess(_now().toUtc());
    return SyncReport(sent: sent, results: results);
  }

  /// Sends the periodic location samples. Outside the workday the server discards them.
  Future<int> syncLocations() async {
    var stored = 0;
    while (true) {
      final batch = await _locations.take(locationBatchSize);
      if (batch.isEmpty) return stored;
      try {
        stored += await _api.sendLocations(batch.map((b) => b.$2).toList());
      } on Object catch (error) {
        final failure = ApiException.from(error);
        // A business rejection would repeat forever: drop the batch.
        if (failure.isTransient || failure.isUnauthorized) return stored;
      }
      await _locations.delete(batch.map((b) => b.$1).toList());
      if (batch.length < locationBatchSize) return stored;
    }
  }

  /// Uploads photos and signatures when the network allows it.
  ///
  /// By default only on wifi; with [allowMobileData] also on mobile data. A file whose activity
  /// has not reached the server yet waits for the next pass.
  Future<int> syncFiles({required NetworkKind network, required bool allowMobileData}) async {
    if (!network.isOnline) return 0;
    if (!network.isUnmetered && !allowMobileData) return 0;

    var uploaded = 0;
    for (final file in await _files.pending()) {
      if (await _events.hasPendingFor(file.activityId)) continue;
      try {
        await _api.uploadEvidence(file);
        await _files.markUploaded(file.clientId, _now().toUtc());
        uploaded++;
        _deleteQuietly(file.path);
      } on Object catch (error) {
        final failure = ApiException.from(error);
        if (failure.isTransient) {
          await _files.markAttempt(file.clientId, failure.message);
          break;
        }
        if (failure.code == 'evidence.missing' ||
            failure.code == 'evidence.size' ||
            failure.code == 'evidence.type' ||
            file.attempts + 1 >= maxFileAttempts) {
          await _files.markFailed(file.clientId, failure.message);
        } else {
          // 404: the activity is not on the server yet (or was rejected); try again later.
          await _files.markAttempt(file.clientId, failure.message);
        }
      }
    }
    return uploaded;
  }

  Future<void> _recordSuccess(DateTime at) async {
    await _kv.setDate(KvKeys.lastSyncAt, at);
    await _kv.set(KvKeys.lastSyncError, null);
    await _kv.set(KvKeys.offlineSince, null);
  }

  Future<void> _recordFailure(ApiException failure) async {
    await _kv.set(KvKeys.lastSyncError, failure.message);
    if (failure.isNetwork && await _kv.get(KvKeys.offlineSince) == null) {
      await _kv.setDate(KvKeys.offlineSince, _now().toUtc());
    }
  }

  void _deleteQuietly(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Not critical: the file is already on the server.
    }
  }
}
