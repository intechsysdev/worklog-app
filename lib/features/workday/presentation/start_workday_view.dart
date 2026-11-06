import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock/server_clock.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/format/formatters.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../domain/day_projection.dart';
import 'widgets/workday_widgets.dart';
import 'workday_commands.dart';

/// GPS availability for the "GPS activo" chip.
final locationAvailabilityProvider = FutureProvider.autoDispose<LocationAvailability>(
  (ref) => ref.watch(locationServiceProvider).availability(),
);

/// Whether the workday can be started now, and why not.
class StartGate {
  const StartGate(this.allowed, [this.reason]);

  final bool allowed;
  final String? reason;

  static StartGate evaluate(DayView day, DateTime now) {
    if (day.stale) return const StartGate(true);
    final window = day.today.window;
    if (window == null) return const StartGate(false, 'No tienes turno hoy.');
    if (now.isBefore(window.opensAt)) {
      return StartGate(
        false,
        'Tu turno empieza a las ${Fmt.time(window.shiftStart)}. Puedes iniciar desde las ${Fmt.time(window.opensAt)}.',
      );
    }
    if (!now.isBefore(window.shiftEnd)) {
      return StartGate(false, window.blockedReason ?? 'Tu turno de hoy ya terminó.');
    }
    return const StartGate(true);
  }
}

/// "Inicio de jornada".
class StartWorkdayView extends ConsumerStatefulWidget {
  const StartWorkdayView({super.key, required this.day});

  final DayView day;

  @override
  ConsumerState<StartWorkdayView> createState() => _StartWorkdayViewState();
}

class _StartWorkdayViewState extends ConsumerState<StartWorkdayView> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final handle = await ref.read(workdayCommandsProvider).startWorkday();
      if (!mounted) return;
      await reportCommand(ScaffoldMessenger.of(context), handle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final day = widget.day;
    final today = day.today;
    final plan = today.plan;
    final (initials, name) = memberIdentity(day);
    final firstName = name.split(' ').first;
    final date = Fmt.dateOnly(today.date) ?? DateTime.now();
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();
    final gate = StartGate.evaluate(day, now);
    final online = ref.watch(networkProvider).value?.isOnline ?? true;
    final gps = ref.watch(locationAvailabilityProvider).value;

    final details = [
      Fmt.dayLetters(plan.dayLetters),
      if (plan.lunchMinutes > 0) 'almuerzo ${Fmt.minutes(plan.lunchMinutes)}',
      ?today.branchName,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BrandHeader(initials: initials, name: name, onAvatar: () => context.push(Routes.profile)),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(kScreenPadding, 8, kScreenPadding, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${Fmt.greeting(now)}${firstName.isEmpty ? '' : ', $firstName'}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(Fmt.longDate(date), style: TextStyle(fontSize: 15, color: c.inkMuted)),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.schedule_rounded, size: 20, color: c.primary),
                                    const SizedBox(width: 10),
                                    const SectionLabel('Turno de hoy'),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  day.stale
                                      ? 'Sin confirmar'
                                      : '${Fmt.timeOnly(plan.start)} – ${Fmt.timeOnly(plan.end)}',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: c.ink),
                                ),
                                if (details.isNotEmpty && !day.stale) ...[
                                  const SizedBox(height: 14),
                                  Text(details, style: TextStyle(fontSize: 14, color: c.inkMuted)),
                                ],
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    gps == LocationAvailability.ready
                                        ? StatusChip.success('GPS activo', icon: Icons.place_outlined)
                                        : StatusChip.warning('GPS inactivo', icon: Icons.location_off_outlined),
                                    online
                                        ? StatusChip.success('Conectado', icon: Icons.wifi_rounded)
                                        : StatusChip.warning('Sin conexión', icon: Icons.wifi_off_rounded),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (day.stale) ...[
                            const SizedBox(height: 12),
                            const InfoBanner(
                              child: Text(
                                'Sin conexión: no pudimos confirmar tu turno de hoy. Puedes iniciar la jornada y el servidor la validará al sincronizar.',
                              ),
                            ),
                          ],
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Fmt.time(now),
                                      style: TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1.28,
                                        height: 1,
                                        color: c.ink,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Hora del servidor', style: TextStyle(fontSize: 14, color: c.inkMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          PrimaryButton(
                            label: _busy ? 'Obteniendo ubicación…' : 'Iniciar jornada',
                            icon: Icons.play_arrow_rounded,
                            height: 64,
                            fontSize: 18,
                            loading: _busy,
                            mutedWhenDisabled: true,
                            onPressed: gate.allowed ? _start : null,
                          ),
                          if (!gate.allowed && gate.reason != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              gate.reason!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, height: 18 / 13, color: c.warningFg),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.shield_outlined, size: 16, color: c.inkMuted),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu ubicación solo se registra durante la jornada laboral, según la política de tratamiento de datos que aceptaste.',
                                  style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
