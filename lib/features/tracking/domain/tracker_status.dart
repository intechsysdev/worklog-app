import 'dart:convert';

import '../../../core/format/formatters.dart';
import '../../workday/domain/day_projection.dart';

/// What the background service needs to know about the open workday: shared between the app
/// and the service isolate as JSON.
class TrackerStatus {
  const TrackerStatus({
    required this.workdayStartedAt,
    required this.samplingMinutes,
    this.activityId,
    this.activityName,
    this.place,
    this.activityStartedAt,
    this.paused = false,
    this.baseWorkedSeconds = 0,
    this.runningSince,
    this.finishNeedsScreen = false,
    this.workOrderNumber,
  });

  factory TrackerStatus.fromDay(DayView day) {
    final workday = day.workday!;
    final current = workday.current;
    final requirements = current?.requirements;
    return TrackerStatus(
      workdayStartedAt: workday.startedAt.toUtc(),
      samplingMinutes: day.today.settings.samplingMinutes < 1 ? 15 : day.today.settings.samplingMinutes,
      activityId: current?.id,
      activityName: current?.name,
      place: current == null || current.place.isEmpty ? null : current.place,
      workOrderNumber: current?.workOrderNumber,
      activityStartedAt: current?.startedAt.toUtc(),
      paused: current?.paused ?? false,
      baseWorkedSeconds: current?.baseWorkedSeconds ?? 0,
      runningSince: current?.runningSince?.toUtc(),
      finishNeedsScreen:
          requirements != null && (requirements.photo || requirements.signature || requirements.observationAlways),
    );
  }

  factory TrackerStatus.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null ? null : DateTime.parse(json[key] as String);
    return TrackerStatus(
      workdayStartedAt: date('workdayStartedAt')!,
      samplingMinutes: json['samplingMinutes'] as int? ?? 15,
      activityId: json['activityId'] as String?,
      activityName: json['activityName'] as String?,
      place: json['place'] as String?,
      workOrderNumber: json['workOrderNumber'] as String?,
      activityStartedAt: date('activityStartedAt'),
      paused: json['paused'] as bool? ?? false,
      baseWorkedSeconds: json['baseWorkedSeconds'] as int? ?? 0,
      runningSince: date('runningSince'),
      finishNeedsScreen: json['finishNeedsScreen'] as bool? ?? false,
    );
  }

  static TrackerStatus? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return TrackerStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  final DateTime workdayStartedAt;
  final int samplingMinutes;
  final String? activityId;
  final String? activityName;
  final String? place;
  final String? workOrderNumber;
  final DateTime? activityStartedAt;
  final bool paused;
  final int baseWorkedSeconds;
  final DateTime? runningSince;

  /// The activity asks for photo, signature or observation: "Finalizar" opens the screen.
  final bool finishNeedsScreen;

  bool get hasActivity => activityId != null;

  Duration worked(DateTime now) {
    var seconds = baseWorkedSeconds;
    if (!paused && runningSince != null && now.isAfter(runningSince!)) {
      seconds += now.difference(runningSince!).inSeconds;
    }
    return Duration(seconds: seconds);
  }

  /// After a pause or resume pressed in the notification (before the app recomputes it).
  TrackerStatus withPaused(bool value, DateTime at) => TrackerStatus(
    workdayStartedAt: workdayStartedAt,
    samplingMinutes: samplingMinutes,
    activityId: activityId,
    activityName: activityName,
    place: place,
    workOrderNumber: workOrderNumber,
    activityStartedAt: activityStartedAt,
    paused: value,
    baseWorkedSeconds: worked(at).inSeconds,
    runningSince: value ? null : at,
    finishNeedsScreen: finishNeedsScreen,
  );

  Map<String, dynamic> toJson() => {
    'workdayStartedAt': workdayStartedAt.toUtc().toIso8601String(),
    'samplingMinutes': samplingMinutes,
    'activityId': ?activityId,
    'activityName': ?activityName,
    'place': ?place,
    'workOrderNumber': ?workOrderNumber,
    'activityStartedAt': ?activityStartedAt?.toUtc().toIso8601String(),
    'paused': paused,
    'baseWorkedSeconds': baseWorkedSeconds,
    'runningSince': ?runningSince?.toUtc().toIso8601String(),
    'finishNeedsScreen': finishNeedsScreen,
  };

  String encode() => jsonEncode(toJson());
}

/// Ids of the notification buttons.
abstract final class TrackerButton {
  static const pause = 'pause';
  static const resume = 'resume';
  static const finish = 'finish';
}

/// Content of the fixed notification "INTECHSYS ONE · Jornada activa".
class TrackerNotification {
  const TrackerNotification({required this.title, required this.text, required this.buttons});

  /// Builds the notification for [status] at [now]. The stopwatch advances with each update of
  /// the service (every 30 s): Android notifications from Flutter cannot run a native chronometer.
  factory TrackerNotification.of(TrackerStatus status, DateTime now) {
    const title = 'INTECHSYS ONE · Jornada activa';
    if (!status.hasActivity) {
      return TrackerNotification(
        title: title,
        text: 'Sin actividad en curso · jornada desde las ${Fmt.time(status.workdayStartedAt)}',
        buttons: const [],
      );
    }
    final worked = status.worked(now);
    final h = worked.inHours.toString().padLeft(2, '0');
    final m = worked.inMinutes.remainder(60).toString().padLeft(2, '0');
    final state = status.paused ? 'En pausa' : 'En curso';
    final meta = [
      ?status.place,
      if (status.activityStartedAt != null) 'desde ${Fmt.time(status.activityStartedAt!)}',
    ].join(' · ');
    return TrackerNotification(
      title: title,
      text: '${status.activityName} · $state $h:$m${meta.isEmpty ? '' : '\n$meta'}',
      buttons: [
        status.paused ? (TrackerButton.resume, 'Reanudar') : (TrackerButton.pause, 'Pausar'),
        (TrackerButton.finish, 'Finalizar'),
      ],
    );
  }

  final String title;
  final String text;

  /// (id, label).
  final List<(String, String)> buttons;
}
