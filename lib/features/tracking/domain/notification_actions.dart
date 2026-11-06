import 'package:uuid/uuid.dart';

import '../../../core/storage/kv_store.dart';
import '../../sync/data/models/sync_models.dart';
import '../../sync/domain/queue_stores.dart';
import '../../sync/domain/queued_event.dart';
import '../../workday/data/models/enums.dart';
import 'tracker_status.dart';

/// What a notification button did.
class NotificationActionResult {
  const NotificationActionResult({this.event, this.openRoute, this.status});

  /// Event written to the queue, if any.
  final SyncEventDto? event;

  /// Screen the app must open (finish with evidence).
  final String? openRoute;

  /// Status to show in the notification right away.
  final TrackerStatus? status;
}

/// Handles "Pausar", "Reanudar" and "Finalizar" pressed in the fixed notification. Runs in the
/// service isolate, so it writes straight to the SQLite queue (the app may not be running); the
/// sync sends it later like any other action.
///
/// "Finalizar" is queued as "Completada" only when the activity asks for nothing else; with
/// photo, signature or mandatory observation it opens the "Finalizar actividad" screen.
class NotificationActions {
  NotificationActions({required this._queue, required this._kv, DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _uuid = Uuid();
  static const finishRoute = '/actividad/finalizar';

  final EventQueueStore _queue;
  final KvStore _kv;
  final DateTime Function() _now;

  Future<NotificationActionResult> handle(String button, TrackerStatus status, {LocationInputDto? location}) async {
    final activityId = status.activityId;
    if (activityId == null) return const NotificationActionResult();

    // Same clock as the app: device time corrected with the last measured server delta.
    final offset = int.tryParse(await _kv.get(KvKeys.clockOffsetMs) ?? '') ?? 0;
    final at = _now().toUtc().add(Duration(milliseconds: offset));
    final meta = EventMeta(activityName: status.activityName, workOrderNumber: status.workOrderNumber);

    switch (button) {
      case TrackerButton.pause:
      case TrackerButton.resume:
        final pause = button == TrackerButton.pause;
        if (pause == status.paused) return NotificationActionResult(status: status);
        final event = SyncEventDto(
          clientEventId: _uuid.v7(),
          kind: pause ? SyncEventKind.activityPause : SyncEventKind.activityResume,
          occurredAt: at,
          activityId: activityId,
          location: location,
        );
        await _queue.enqueue(event, meta);
        return NotificationActionResult(event: event, status: status.withPaused(pause, at));

      case TrackerButton.finish:
        if (status.finishNeedsScreen) return const NotificationActionResult(openRoute: finishRoute);
        final event = SyncEventDto(
          clientEventId: _uuid.v7(),
          kind: SyncEventKind.activityFinish,
          occurredAt: at,
          activityId: activityId,
          outcome: ActivityOutcome.completed,
          photoCount: 0,
          hasSignature: false,
          location: location,
        );
        await _queue.enqueue(
          event,
          EventMeta(
            activityName: status.activityName,
            workOrderNumber: status.workOrderNumber,
            outcomeLabel: 'Completada',
          ),
        );
        return NotificationActionResult(
          event: event,
          status: TrackerStatus(workdayStartedAt: status.workdayStartedAt, samplingMinutes: status.samplingMinutes),
        );
    }
    return NotificationActionResult(status: status);
  }
}
