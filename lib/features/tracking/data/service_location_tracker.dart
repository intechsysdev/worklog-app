import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../sync/data/sync_providers.dart';
import '../domain/location_tracker.dart';
import '../domain/tracker_status.dart';
import 'timer_location_tracker.dart';
import 'workday_task_handler.dart';

/// Android: foreground service (type `location`) with the fixed notification
/// "INTECHSYS ONE · Jornada activa". The service isolate samples and handles the buttons
/// ([WorkdayTaskHandler]); this side starts, updates and stops it and relays its messages.
class ServiceLocationTracker implements LocationTracker {
  ServiceLocationTracker() {
    FlutterForegroundTask.addTaskDataCallback(_onData);
  }

  static const _serviceId = 4242;
  static bool _initialized = false;

  final _events = StreamController<TrackerEvent>.broadcast();
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Stream<TrackerEvent> get events => _events.stream;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'worklog_workday',
        channelName: 'Jornada activa',
        channelDescription: 'Se muestra mientras tu jornada está abierta.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        // The notification is refreshed every 30 s; sampling uses `samplingMinutes`.
        eventAction: ForegroundTaskEventAction.repeat(30000),

        allowWifiLock: true,
      ),
    );
  }

  void _onData(Object data) {
    if (data is! Map || _events.isClosed) return;
    switch (data['type']) {
      case TrackerMessages.samples:
        _events.add(const TrackerEvent(TrackerEventType.samplesStored));
      case TrackerMessages.queued:
        _events.add(const TrackerEvent(TrackerEventType.eventQueued));
      case TrackerMessages.open:
        _events.add(TrackerEvent(TrackerEventType.openRoute, data['route'] as String?));
    }
  }

  @override
  Future<void> start(TrackerStatus status) async {
    _init();
    await FlutterForegroundTask.saveData(key: TrackerKeys.status, value: status.encode());
    final content = TrackerNotification.of(status, DateTime.now().toUtc());
    final buttons = [for (final (id, text) in content.buttons) NotificationButton(id: id, text: text)];
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: content.title,
        notificationText: content.text,
        notificationButtons: buttons,
      );
    } else {
      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: content.title,
        notificationText: content.text,
        notificationButtons: buttons,
        notificationInitialRoute: '/inicio',
        callback: startWorkdayTask,
      );
      if (result is ServiceRequestFailure) return;
    }
    _running = true;
  }

  @override
  Future<void> update(TrackerStatus status) async {
    if (!_running) return start(status);
    await FlutterForegroundTask.saveData(key: TrackerKeys.status, value: status.encode());
    FlutterForegroundTask.sendDataToTask('refresh');
  }

  @override
  Future<void> stop() async {
    _running = false;
    await FlutterForegroundTask.removeData(key: TrackerKeys.status);
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }

  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    _events.close();
  }
}

final locationTrackerProvider = Provider<LocationTracker>((ref) {
  if (Platform.isAndroid) {
    final tracker = ServiceLocationTracker();
    ref.onDispose(tracker.dispose);
    return tracker;
  }
  final tracker = TimerLocationTracker(ref.watch(locationServiceProvider), ref.watch(locationSampleStoreProvider));
  ref.onDispose(tracker.dispose);
  return tracker;
});
