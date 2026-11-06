import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/features/alerts/domain/alert_schedule.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';
import 'package:worklog_mobile/features/workday/domain/day_projection.dart';

import '../support/fakes.dart';

void main() {
  final started = DateTime.utc(2026, 10, 29, 12, 3);
  // Shift 07:00–16:00 Bogotá = 12:00–21:00 UTC; automatic close 16:10.
  final autoClose = DateTime.utc(2026, 10, 29, 21, 10);

  TodayDto today({
    CurrentActivityDto? current,
    DeviceStatusDto device = const DeviceStatusDto(),
    DateTime? autoCloseAt,
    WorkdayStatus status = WorkdayStatus.open,
  }) {
    final base = sampleToday(
      workday: WorkdayDto(
        id: 'w1',
        date: '2026-10-29',
        status: status,
        startedAt: started,
        summary: const DaySummaryDto(),
        current: current,
      ),
    );
    return TodayDto(
      serverTime: base.serverTime,
      date: base.date,
      timeZoneId: base.timeZoneId,
      memberName: base.memberName,
      plan: base.plan,
      window: base.window,
      workday: base.workday,
      policy: base.policy,
      settings: const ClientSettingsDto(),
      device: device,
      autoCloseAt: autoCloseAt,
    );
  }

  CurrentActivityDto activity({bool paused = false, DateTime? pausedSince}) => CurrentActivityDto(
    id: 'a1',
    activityTypeId: 't1',
    name: 'Mantenimiento preventivo',
    color: '#AF1839',
    timeClass: TimeClass.productive,
    startedAt: started.add(const Duration(minutes: 10)),
    status: paused ? ActivityStatus.paused : ActivityStatus.running,
    pausedSince: pausedSince,
    requirements: const RequirementsDto(),
  );

  DayView view(TodayDto t) => DayProjection.build(t, const []);

  test('without an open workday nothing is scheduled', () {
    final closed = view(today(status: WorkdayStatus.closed));
    expect(AlertPlanner.plan(day: closed, now: started), isEmpty);
    expect(AlertPlanner.plan(day: view(sampleToday()), now: started), isEmpty);
  });

  test('inactivity: inactivityAlertMinutes after the activity ended', () {
    final idleSince = DateTime.utc(2026, 10, 29, 14, 40);
    final alerts = AlertPlanner.plan(day: view(today()), now: idleSince, idleSince: idleSince);
    final inactivity = alerts.singleWhere((a) => a.kind == AlertKind.inactivity);
    expect(inactivity.at, DateTime.utc(2026, 10, 29, 15));
    expect(inactivity.title, 'Llevas 20 minutos sin actividad');
    expect(inactivity.id, AlertPlanner.inactivityId);
  });

  test('inactivity counts from the start of the workday when nothing was done yet', () {
    final alerts = AlertPlanner.plan(day: view(today()), now: started);
    expect(alerts.firstWhere((a) => a.kind == AlertKind.inactivity).at, started.add(const Duration(minutes: 20)));
  });

  test('a running activity cancels the inactivity alert', () {
    final alerts = AlertPlanner.plan(
      day: view(today(current: activity())),
      now: started,
    );
    expect(alerts.where((a) => a.kind == AlertKind.inactivity), isEmpty);
    expect(alerts.where((a) => a.kind == AlertKind.pauseExceeded), isEmpty);
  });

  test('pause exceeded: maxPauseMinutes after the pause started', () {
    final pausedSince = DateTime.utc(2026, 10, 29, 17);
    final alerts = AlertPlanner.plan(
      day: view(today(current: activity(paused: true, pausedSince: pausedSince))),
      now: pausedSince.add(const Duration(minutes: 5)),
    );
    final pause = alerts.singleWhere((a) => a.kind == AlertKind.pauseExceeded);
    expect(pause.at, DateTime.utc(2026, 10, 29, 17, 30));
    expect(pause.body, contains('Mantenimiento preventivo'));
  });

  test('shift end without device control: shiftEndWarningMinutes before autoCloseAt', () {
    final alerts = AlertPlanner.plan(
      day: view(today(current: activity(), autoCloseAt: autoClose)),
      now: started,
    );
    final shiftEnd = alerts.where((a) => a.kind == AlertKind.shiftEnd).toList();
    expect(shiftEnd.map((a) => a.at), [DateTime.utc(2026, 10, 29, 20, 55)]);
    expect(shiftEnd.single.title, 'Tu turno termina en 15 minutos');
  });

  test('shift end with MobiControl: one alert per warningMinutes, ordered in time', () {
    final alerts = AlertPlanner.plan(
      day: view(
        today(
          current: activity(),
          autoCloseAt: autoClose,
          device: const DeviceStatusDto(controlEnabled: true, warningMinutes: [5, 15]),
        ),
      ),
      now: started,
    );
    final shiftEnd = alerts.where((a) => a.kind == AlertKind.shiftEnd).toList();
    expect(shiftEnd.map((a) => a.minutesBefore), [15, 5]);
    expect(shiftEnd.map((a) => a.at), [DateTime.utc(2026, 10, 29, 20, 55), DateTime.utc(2026, 10, 29, 21, 5)]);
    expect(shiftEnd.map((a) => a.id).toSet(), hasLength(2));
  });

  test('without autoCloseAt the close is the shift end plus the grace', () {
    expect(autoCloseOf(today()), DateTime.utc(2026, 10, 29, 21, 10));
  });

  test('alerts already in the past are not scheduled', () {
    final late = DateTime.utc(2026, 10, 29, 21);
    final alerts = AlertPlanner.plan(
      day: view(
        today(
          current: activity(),
          autoCloseAt: autoClose,
          device: const DeviceStatusDto(controlEnabled: true, warningMinutes: [15, 5]),
        ),
      ),
      now: late,
    );
    expect(alerts.map((a) => a.minutesBefore), [5]);
  });

  test('due shift warning: the most urgent one reached, 0 after the close', () {
    final day = view(
      today(
        current: activity(),
        autoCloseAt: autoClose,
        device: const DeviceStatusDto(controlEnabled: true, warningMinutes: [15, 5]),
      ),
    );
    expect(AlertPlanner.dueShiftWarning(day: day, now: DateTime.utc(2026, 10, 29, 20, 50)), isNull);
    expect(AlertPlanner.dueShiftWarning(day: day, now: DateTime.utc(2026, 10, 29, 20, 56)), 15);
    expect(AlertPlanner.dueShiftWarning(day: day, now: DateTime.utc(2026, 10, 29, 21, 6)), 5);
    expect(AlertPlanner.dueShiftWarning(day: day, now: DateTime.utc(2026, 10, 29, 21, 11)), 0);
  });
}
