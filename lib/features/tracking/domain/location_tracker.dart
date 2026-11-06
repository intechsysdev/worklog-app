import 'tracker_status.dart';

enum TrackerEventType {
  /// New location samples are in the local store: send them.
  samplesStored,

  /// The notification queued an event: reload the queue and sync.
  eventQueued,

  /// The notification asks to open a screen.
  openRoute,
}

class TrackerEvent {
  const TrackerEvent(this.type, [this.route]);

  final TrackerEventType type;
  final String? route;
}

/// Location sampling (every `settings.samplingMinutes`) while the workday is open.
///
/// - Android: foreground service with the fixed notification, which keeps sampling with the app
///   in background and offers Pausar/Finalizar.
/// - Other platforms (and tests): a timer while the app is in memory.
abstract interface class LocationTracker {
  bool get isRunning;

  Stream<TrackerEvent> get events;

  Future<void> start(TrackerStatus status);

  /// The activity changed (started, paused, finished): refresh the notification.
  Future<void> update(TrackerStatus status);

  Future<void> stop();
}
