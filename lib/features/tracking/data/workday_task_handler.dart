import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/kv_store.dart';
import '../../sync/data/models/sync_models.dart';
import '../../sync/data/sqlite_queue_stores.dart';
import '../domain/notification_actions.dart';
import '../domain/tracker_status.dart';

/// Keys shared between the app and the service isolate (SharedPreferences of the plugin).
abstract final class TrackerKeys {
  static const status = 'wl.tracker.status';
}

/// Messages from the service to the app.
abstract final class TrackerMessages {
  static const samples = 'samples';
  static const queued = 'queued';
  static const open = 'open';
}

/// Entry point of the service isolate.
@pragma('vm:entry-point')
void startWorkdayTask() {
  FlutterForegroundTask.setTaskHandler(WorkdayTaskHandler());
}

/// Runs in the foreground service (Android): refreshes the fixed notification, samples the
/// location every `samplingMinutes` (also with the app closed) and handles the notification
/// buttons. Everything is written to the same SQLite database; the app sends it when it syncs.
class WorkdayTaskHandler extends TaskHandler {
  AppDatabase? _db;
  DateTime? _lastSample;

  Future<AppDatabase> _database() async => _db ??= await AppDatabase.open();

  Future<TrackerStatus?> _status() async =>
      TrackerStatus.decode(await FlutterForegroundTask.getData<String>(key: TrackerKeys.status));

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _database();
    await _refresh();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_tick(timestamp));
  }

  Future<void> _tick(DateTime timestamp) async {
    final status = await _status();
    if (status == null) return;
    await _show(status);

    final due = _lastSample == null || timestamp.difference(_lastSample!).inMinutes >= status.samplingMinutes;
    if (!due) return;
    _lastSample = timestamp;
    final location = await _locate(const Duration(seconds: 20));
    if (location == null) return;
    await SqliteLocationSampleStore((await _database()).db).add(location);
    FlutterForegroundTask.sendDataToMain({'type': TrackerMessages.samples});
  }

  @override
  void onReceiveData(Object data) {
    unawaited(_refresh());
  }

  @override
  void onNotificationButtonPressed(String id) {
    unawaited(_press(id));
  }

  Future<void> _press(String id) async {
    final status = await _status();
    if (status == null) return;
    final db = await _database();
    final actions = NotificationActions(queue: SqliteEventQueueStore(db.db), kv: SqliteKvStore(db.db));
    final result = await actions.handle(id, status, location: await _locate(const Duration(seconds: 5)));

    if (result.status != null) {
      await FlutterForegroundTask.saveData(key: TrackerKeys.status, value: result.status!.encode());
      await _show(result.status!);
    }
    if (result.event != null) FlutterForegroundTask.sendDataToMain({'type': TrackerMessages.queued});
    if (result.openRoute != null) {
      FlutterForegroundTask.launchApp(result.openRoute);
      FlutterForegroundTask.sendDataToMain({'type': TrackerMessages.open, 'route': result.openRoute});
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/inicio');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _db?.close();
    _db = null;
  }

  Future<void> _refresh() async {
    final status = await _status();
    if (status != null) await _show(status);
  }

  Future<void> _show(TrackerStatus status) async {
    final content = TrackerNotification.of(status, DateTime.now().toUtc());
    await FlutterForegroundTask.updateService(
      notificationTitle: content.title,
      notificationText: content.text,
      notificationButtons: [for (final (id, text) in content.buttons) NotificationButton(id: id, text: text)],
    );
  }

  Future<LocationInputDto?> _locate(Duration timeout) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return LocationInputDto(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        capturedAt: p.timestamp.toUtc(),
      );
    } on Object {
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null
            ? null
            : LocationInputDto(
                latitude: last.latitude,
                longitude: last.longitude,
                accuracy: last.accuracy,
                capturedAt: last.timestamp.toUtc(),
              );
      } on Object {
        return null;
      }
    }
  }
}
