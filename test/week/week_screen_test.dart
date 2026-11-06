import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/clock/server_clock.dart';
import 'package:worklog_mobile/core/theme/app_theme.dart';
import 'package:worklog_mobile/features/week/data/week_models.dart';
import 'package:worklog_mobile/features/week/presentation/week_screen.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';

MyWeekDto sampleWeek() => const MyWeekDto(
  from: '2026-10-26',
  to: '2026-11-01',
  provisionalUntil: '2026-11-15',
  workedMinutes: 1880,
  weeklyCapMinutes: 2520,
  scheduledMinutes: 2400,
  remainingMinutes: 520,
  overtimeWeeklyMaxMinutes: 720,
  breakdown: BreakdownDto(ordinaryDay: 1880, total: 1880),
  days: [
    WeekDayDto(date: '2026-10-26', planKind: DayKind.shift, scheduledMinutes: 480, workedMinutes: 480),
    WeekDayDto(date: '2026-10-27', planKind: DayKind.shift, scheduledMinutes: 480, workedMinutes: 500),
    WeekDayDto(date: '2026-10-28', planKind: DayKind.shift, scheduledMinutes: 480, workedMinutes: 470),
    WeekDayDto(
      date: '2026-10-29',
      planKind: DayKind.shift,
      scheduledMinutes: 480,
      workedMinutes: 430,
      isToday: true,
      inProgress: true,
    ),
    WeekDayDto(date: '2026-10-30', planKind: DayKind.shift, scheduledMinutes: 480),
    WeekDayDto(date: '2026-10-31', planKind: DayKind.rest, planLabel: 'Descanso'),
    WeekDayDto(date: '2026-11-01', planKind: DayKind.rest, planLabel: 'Descanso'),
  ],
);

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverClockProvider.overrideWithValue(ServerClock(deviceNow: () => DateTime.utc(2026, 10, 29, 19))),
          weekProvider.overrideWith((ref, date) async => sampleWeek()),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Mi semana: total against the legal cap, bars per working day and breakdown', (tester) async {
    await pump(tester, const WeekScreen());

    expect(find.text('Mi semana'), findsOneWidget);
    expect(find.text('Lunes 26 a viernes 30 de octubre'), findsOneWidget);
    expect(find.text('31 h 20 m'), findsWidgets);
    expect(find.text('de 42 h legales'), findsOneWidget);
    expect(find.text('Programadas: 40 h'), findsOneWidget);
    expect(find.text('Te faltan 8 h 40 m'), findsOneWidget);

    // Five working days: rest days without hours are left out.
    for (final label in ['8:00', '8:20', '7:50', '7:10', '—']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Lun 26'), findsOneWidget);
    expect(find.text('Vie 30'), findsOneWidget);
    expect(find.text('Sáb 31'), findsNothing);

    expect(find.text('Ordinarias diurnas'), findsOneWidget);
    expect(find.text('Horas extra aprobadas'), findsOneWidget);
    expect(find.text('0 de 12'), findsOneWidget);
    expect(find.text('Dominical o festivo'), findsOneWidget);
    expect(find.text('Cifras provisionales hasta el cierre del periodo, el 15 de noviembre.'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
  });

  test('labels of the bars and of the range', () {
    expect(WeekView.barLabel(0), '—');
    expect(WeekView.barLabel(430), '7:10');
    expect(WeekView.rangeLabel(sampleWeek()), 'Lunes 26 a viernes 30 de octubre');
    expect(WeekView.visibleDays(sampleWeek()), hasLength(5));
  });
}
