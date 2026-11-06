import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/alert_schedule.dart';

/// Shows the scheduled local alerts (inactivity, pause, shift end).
abstract interface class AlertNotifier {
  /// Replaces every scheduled alert with [alerts].
  Future<void> reschedule(List<ScheduledAlert> alerts);

  Future<void> cancelAll();
}

/// `flutter_local_notifications` with inexact alarms (no SCHEDULE_EXACT_ALARM permission):
/// Android may deliver them a few minutes late in Doze, which is acceptable for these warnings.
class LocalAlertNotifier implements AlertNotifier {
  LocalAlertNotifier([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'worklog_alerts';
  static const channelName = 'Avisos de la jornada';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final Set<int> _scheduled = {};

  Future<bool> _init() async {
    if (_ready) return true;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
    return true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Inactividad, pausa excedida y fin de turno.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  @override
  Future<void> reschedule(List<ScheduledAlert> alerts) async {
    if (!await _init()) return;
    final keep = alerts.map((a) => a.id).toSet();
    for (final id in _scheduled.difference(keep)) {
      await _plugin.cancel(id: id);
    }
    _scheduled
      ..clear()
      ..addAll(keep);
    for (final alert in alerts) {
      try {
        await _plugin.zonedSchedule(
          id: alert.id,
          scheduledDate: tz.TZDateTime.from(alert.at.toUtc(), tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: alert.title,
          body: alert.body,
          payload: alert.kind.name,
        );
      } on Exception {
        // Notifications disabled by the user or by the device policy: nothing else to do.
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _init()) return;
    // Only our ids: the foreground service notification belongs to the service.
    await _plugin.cancelAllPendingNotifications();
    for (final id in {..._scheduled, AlertPlanner.inactivityId, AlertPlanner.pauseId}) {
      await _plugin.cancel(id: id);
    }
    _scheduled.clear();
  }
}

final alertNotifierProvider = Provider<AlertNotifier>((ref) => LocalAlertNotifier());
