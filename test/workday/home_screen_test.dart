import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/clock/server_clock.dart';
import 'package:worklog_mobile/core/connectivity/connectivity_service.dart';
import 'package:worklog_mobile/core/format/formatters.dart';
import 'package:worklog_mobile/core/location/location_service.dart';
import 'package:worklog_mobile/core/theme/app_theme.dart';
import 'package:worklog_mobile/features/sync/domain/sync_ports.dart';
import 'package:worklog_mobile/features/sync/presentation/sync_controller.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';
import 'package:worklog_mobile/features/workday/presentation/home_screen.dart';
import 'package:worklog_mobile/features/workday/presentation/workday_commands.dart';
import 'package:worklog_mobile/features/workday/presentation/workday_providers.dart';

import '../support/fakes.dart';

class _FakeToday extends TodayController {
  _FakeToday(this.today);

  final TodayDto today;

  @override
  Future<TodayDto> build() async => today;

  @override
  Future<void> refresh() async {}
}

/// The server answers a different schedule than the cached one (changed in the panel).
class _ChangingToday extends TodayController {
  _ChangingToday(this.cached, this.fromServer);

  final TodayDto cached;
  final TodayDto fromServer;
  int refreshes = 0;

  @override
  Future<TodayDto> build() async => cached;

  @override
  Future<void> refresh() async {
    refreshes++;
    state = AsyncData(fromServer);
  }
}

/// Shift moved to 09:00 (14:00 UTC): at 07:02 it cannot start yet.
StartWindowDto _movedWindow() => StartWindowDto(
  opensAt: DateTime.utc(2026, 10, 29, 13, 45),
  shiftStart: DateTime.utc(2026, 10, 29, 14),
  shiftEnd: DateTime.utc(2026, 10, 29, 23),
  canStartNow: false,
);

class _FakeSync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(loaded: true, network: NetworkKind.wifi);
}

class _FakeLocation implements LocationService {
  @override
  Future<LocationAvailability> availability() async => LocationAvailability.ready;

  @override
  Future<LocationFix?> current({Duration timeout = const Duration(seconds: 8)}) async => null;
}

class _FakeConnectivity implements ConnectivityService {
  @override
  Future<NetworkKind> current() async => NetworkKind.wifi;

  @override
  Stream<NetworkKind> changes() => const Stream.empty();
}

/// Starts requested through the fake commands (reset for each test).
var starts = 0;

class _RecordingCommands extends WorkdayCommands {
  _RecordingCommands(super.ref);

  @override
  Future<CommandHandle> startWorkday({LocationFix? location}) async {
    starts++;
    return CommandHandle('e1', Future.value(const CommandResult(clientEventId: 'e1')));
  }
}

void main() {
  setUp(() => starts = 0);

  Future<void> pumpHome(
    WidgetTester tester,
    TodayDto today,
    DateTime now, {
    TodayController Function()? controller,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayControllerProvider.overrideWith(controller ?? () => _FakeToday(today)),
          syncControllerProvider.overrideWith(_FakeSync.new),
          serverClockProvider.overrideWithValue(ServerClock(deviceNow: () => now)),
          locationServiceProvider.overrideWithValue(_FakeLocation()),
          connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
          workdayCommandsProvider.overrideWith(_RecordingCommands.new),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Unmount so the per-second ticker stops before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('day with shift and open window: shows the shift and starts the workday', (tester) async {
    final now = DateTime.utc(2026, 10, 29, 12, 2);
    await pumpHome(tester, sampleToday(serverTime: now), now);

    expect(find.text('Buenos días, Andrés'), findsOneWidget);
    expect(find.text('Jueves 29 de octubre'), findsOneWidget);
    expect(find.text('07:00 – 16:00'), findsOneWidget);
    expect(find.text('Hora del servidor'), findsOneWidget);
    expect(find.text(Fmt.time(now)), findsOneWidget);
    expect(find.text('GPS activo'), findsOneWidget);
    expect(find.text('Conectado'), findsOneWidget);

    await tester.tap(find.text('Iniciar jornada'));
    await tester.pump();
    expect(starts, 1);

    await unmount(tester);
  });

  testWidgets('before the window opens the start button is disabled and says when it opens', (tester) async {
    final now = DateTime.utc(2026, 10, 29, 11);
    final today = sampleToday(serverTime: now);
    await pumpHome(tester, today, now);

    expect(find.textContaining('Puedes iniciar desde las ${Fmt.time(today.window!.opensAt)}'), findsOneWidget);
    await tester.tap(find.text('Iniciar jornada'));
    await tester.pump();
    expect(starts, 0);

    await unmount(tester);
  });

  testWidgets('the schedule changed in the panel: the screen shows the new window, not the cached one', (tester) async {
    final now = DateTime.utc(2026, 10, 29, 12, 2);
    final cached = sampleToday(serverTime: now);
    final moved = sampleToday(serverTime: now, window: _movedWindow());
    await pumpHome(tester, cached, now, controller: () => _ChangingToday(cached, moved));
    await tester.pump();

    expect(find.textContaining('Puedes iniciar desde las ${Fmt.time(moved.window!.opensAt)}'), findsOneWidget);
    expect(find.text('Actualizar horario'), findsOneWidget);
    await tester.tap(find.text('Iniciar jornada'));
    await tester.pump();
    expect(starts, 0);

    await unmount(tester);
  });

  testWidgets('pressing start asks the schedule first and starts when the new one allows it', (tester) async {
    final now = DateTime.utc(2026, 10, 29, 12, 2);
    final blockedInCache = sampleToday(serverTime: now, window: _movedWindow());
    final openNow = sampleToday(serverTime: now);
    late _ChangingToday controller;
    await pumpHome(tester, blockedInCache, now, controller: () => controller = _ChangingToday(blockedInCache, openNow));
    await tester.pump();

    expect(controller.refreshes, greaterThan(0));
    await tester.tap(find.text('Iniciar jornada'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(starts, 1);

    await unmount(tester);
  });

  testWidgets('day without shift shows the absence and blocks the start', (tester) async {
    final now = DateTime.utc(2026, 11, 3, 13);
    final today = TodayDto(
      serverTime: now,
      date: '2026-11-03',
      timeZoneId: 'America/Bogota',
      memberName: 'Andrés Mora',
      branchName: 'Sede Bogotá Norte',
      plan: const DayPlanDto(kind: DayKind.absence, label: 'Vacaciones'),
      absence: const AbsenceInfoDto(label: 'Vacaciones', from: '2026-11-03', to: '2026-11-13'),
      nextShift: const NextShiftDto(
        date: '2026-11-17',
        start: '07:00:00',
        end: '16:00:00',
        notes: ['El lunes 16 es festivo.'],
      ),
      policy: const PolicyStatusDto(currentVersion: '1.0', accepted: true),
      settings: const ClientSettingsDto(),
    );
    await pumpHome(tester, today, now);

    expect(find.text('Hoy no tienes turno'), findsOneWidget);
    expect(find.text('Vacaciones'), findsOneWidget);
    expect(find.text('Del martes 3 al viernes 13 de noviembre.'), findsOneWidget);
    expect(find.text('Martes 17 de noviembre'), findsOneWidget);
    expect(find.text('El lunes 16 es festivo.'), findsOneWidget);
    expect(find.textContaining('No puedes iniciar jornada en días sin turno'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('open workday shows the current activity with its stopwatch', (tester) async {
    final now = DateTime.utc(2026, 10, 29, 14, 35, 45);
    final started = DateTime.utc(2026, 10, 29, 13, 12);
    final today = sampleToday(
      serverTime: now,
      workday: WorkdayDto(
        id: 'w1',
        date: '2026-10-29',
        status: WorkdayStatus.open,
        startedAt: DateTime.utc(2026, 10, 29, 12, 3),
        summary: const DaySummaryDto(activityCount: 3, productiveMinutes: 151, withoutActivityMinutes: 7),
        current: CurrentActivityDto(
          id: 'a1',
          activityTypeId: 't1',
          name: 'Instalación de equipo',
          color: '#AF1839',
          timeClass: TimeClass.productive,
          workOrderNumber: 'OT-1042',
          siteName: 'Almacén Norte',
          startedAt: started,
          status: ActivityStatus.running,
          workedSeconds: 5025,
          startGeofence: GeofenceStatus.inside,
          startAccuracy: 6,
          requirements: const RequirementsDto(),
        ),
      ),
    );
    await pumpHome(tester, today, now);

    expect(find.text('Jornada activa'), findsOneWidget);
    expect(find.text('EN CURSO'), findsOneWidget);
    expect(find.text('Instalación de equipo'), findsOneWidget);
    expect(find.text('Almacén Norte · OT-1042'), findsOneWidget);
    expect(find.text('01:23:45'), findsOneWidget);
    expect(find.text('Dentro de la geocerca del sitio · precisión 6 m'), findsOneWidget);
    expect(find.text('2 h 31 m'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('Cambiar actividad'), findsOneWidget);

    await unmount(tester);
  });
}
