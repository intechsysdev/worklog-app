import '../data/models/sync_models.dart';
import 'queued_event.dart';
import 'queued_file.dart';

/// Local queue of user actions. Every action is written here first, then sent.
abstract interface class EventQueueStore {
  /// Saves the event as pending. Idempotent by `clientEventId`.
  Future<QueuedEvent> enqueue(SyncEventDto event, EventMeta meta, {DateTime? now});

  /// Pending events in local order (oldest first).
  Future<List<QueuedEvent>> pending({int? limit});

  /// Events the server rejected or adjusted, most recent first.
  Future<List<QueuedEvent>> reviewed({int limit = 20});

  Future<int> pendingCount();

  Future<void> markResult(
    String clientEventId,
    QueueStatus status, {
    String? code,
    String? message,
    String? resultId,
    required DateTime at,
  });

  /// Counts a failed delivery attempt for these events.
  Future<void> markAttempt(List<String> clientEventIds);

  /// Whether any event that touches [activityId] is still waiting.
  Future<bool> hasPendingFor(String activityId);

  /// Activities started on this phone that the server did not reject (id, start, name), oldest
  /// first. The timeline of the API has no activity ids, so the adjustment form maps its entries
  /// with these.
  Future<List<QueuedEvent>> startedActivities({DateTime? since});

  /// Removes confirmed events older than [before].
  Future<void> purgeConfirmed(DateTime before);
}

abstract interface class FileQueueStore {
  Future<void> enqueue(QueuedFile file);
  Future<List<QueuedFile>> pending();
  Future<List<QueuedFile>> failed({int limit = 20});
  Future<int> pendingCount();
  Future<void> markUploaded(String clientId, DateTime at);
  Future<void> markAttempt(String clientId, String? error);
  Future<void> markFailed(String clientId, String error);
}

abstract interface class LocationSampleStore {
  Future<void> add(LocationInputDto sample);
  Future<List<(int, LocationInputDto)>> take(int limit);
  Future<void> delete(List<int> ids);
  Future<int> count();
}
