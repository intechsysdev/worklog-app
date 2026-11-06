import '../../../core/format/formatters.dart';
import '../../workday/data/models/today_dto.dart';
import '../../workday/domain/day_projection.dart';

enum AlertKind { inactivity, pauseExceeded, shiftEnd }

/// A local notification to show at [at].
class ScheduledAlert {
  const ScheduledAlert({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    this.minutesBefore,
  });

  /// Stable id per kind (and per warning), so rescheduling replaces the previous one.
  final int id;
  final AlertKind kind;
  final DateTime at;
  final String title;
  final String body;

  /// For shift end warnings: minutes before the automatic close.
  final int? minutesBefore;

  @override
  String toString() => 'ScheduledAlert($kind, $at, $minutesBefore)';
}

/// When the shift ends for the warnings: the automatic close of the server, or the end of the
/// shift plus the grace minutes when the snapshot does not bring it.
DateTime? autoCloseOf(TodayDto today) {
  if (today.autoCloseAt != null) return today.autoCloseAt!.toUtc();
  final end = today.window?.shiftEnd;
  return end?.toUtc().add(Duration(minutes: today.settings.autoCloseGraceMinutes));
}

/// Minutes before the automatic close at which the user is warned: those of the device control
/// (MobiControl) or, without control, `settings.shiftEndWarningMinutes`.
List<int> shiftEndWarnings(TodayDto today) {
  final values = today.device.controlEnabled && today.device.warningMinutes.isNotEmpty
      ? today.device.warningMinutes
      : [today.settings.shiftEndWarningMinutes];
  return values.where((m) => m > 0).toSet().toList()..sort((a, b) => b.compareTo(a));
}

/// Local notifications of the day, recomputed every time a new `today` (or queue change) arrives:
/// - inactivity: `inactivityAlertMinutes` after the user was left without an open activity;
/// - pause exceeded: `maxPauseMinutes` after the pause started;
/// - shift end: each warning before the automatic close.
///
/// Only alerts in the future are returned. Nothing is scheduled without an open workday.
abstract final class AlertPlanner {
  static const inactivityId = 1001;
  static const pauseId = 1002;
  static const shiftEndBaseId = 1100;

  static List<ScheduledAlert> plan({required DayView day, required DateTime now, DateTime? idleSince}) {
    final workday = day.workday;
    if (workday == null || !workday.isOpen) return const [];
    final settings = day.today.settings;
    final alerts = <ScheduledAlert>[];
    final current = workday.current;

    if (current == null && settings.inactivityAlertMinutes > 0) {
      final since = idleSince ?? workday.startedAt;
      final minutes = settings.inactivityAlertMinutes;
      alerts.add(
        ScheduledAlert(
          id: inactivityId,
          kind: AlertKind.inactivity,
          at: since.toUtc().add(Duration(minutes: minutes)),
          title: 'Llevas $minutes minutos sin actividad',
          body: 'Inicia tu siguiente actividad para que el tiempo quede registrado.',
        ),
      );
    }

    if (current != null && current.paused && current.pausedSince != null && settings.maxPauseMinutes > 0) {
      final minutes = settings.maxPauseMinutes;
      alerts.add(
        ScheduledAlert(
          id: pauseId,
          kind: AlertKind.pauseExceeded,
          at: current.pausedSince!.toUtc().add(Duration(minutes: minutes)),
          title: 'La pausa ya pasó de $minutes minutos',
          body: 'Reanuda ${current.name} o finalízala si ya terminaste.',
        ),
      );
    }

    final close = autoCloseOf(day.today);
    if (close != null && !day.stale) {
      final shiftEnd = day.today.window?.shiftEnd ?? close;
      for (final minutes in shiftEndWarnings(day.today)) {
        alerts.add(
          ScheduledAlert(
            id: shiftEndBaseId + minutes,
            kind: AlertKind.shiftEnd,
            at: close.subtract(Duration(minutes: minutes)),
            minutesBefore: minutes,
            title: 'Tu turno termina en $minutes minutos',
            body:
                'Tu turno termina a las ${Fmt.time(shiftEnd)}. A las ${Fmt.time(close)} se cerrarán la actividad abierta y la jornada.',
          ),
        );
      }
    }

    final utcNow = now.toUtc();
    return alerts.where((a) => a.at.isAfter(utcNow)).toList()..sort((a, b) => a.at.compareTo(b.at));
  }

  /// Shift end warning that should be on screen now (the most urgent one already reached), or null.
  static int? dueShiftWarning({required DayView day, required DateTime now}) {
    final workday = day.workday;
    if (workday == null || !workday.isOpen || day.stale) return null;
    final close = autoCloseOf(day.today);
    if (close == null) return null;
    final utcNow = now.toUtc();
    if (!utcNow.isBefore(close)) return 0;
    int? due;
    for (final minutes in shiftEndWarnings(day.today)) {
      if (!utcNow.isBefore(close.subtract(Duration(minutes: minutes)))) {
        due = due == null || minutes < due ? minutes : due;
      }
    }
    return due;
  }
}
