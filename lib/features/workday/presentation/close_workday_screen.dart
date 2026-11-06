import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock/server_clock.dart';
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
import 'workday_providers.dart';

/// "Cerrar jornada": provisional summary, day note and "Seguir trabajando".
class CloseWorkdayScreen extends ConsumerStatefulWidget {
  const CloseWorkdayScreen({super.key});

  @override
  ConsumerState<CloseWorkdayScreen> createState() => _CloseWorkdayScreenState();
}

class _CloseWorkdayScreenState extends ConsumerState<CloseWorkdayScreen> {
  final _note = TextEditingController();
  LocationFix? _location;
  bool _locating = true;
  bool _busy = false;
  DayView? _day;

  @override
  void initState() {
    super.initState();
    ref.read(locationServiceProvider).current().then((fix) {
      if (mounted) {
        setState(() {
          _location = fix;
          _locating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    setState(() => _busy = true);
    try {
      final handle = await ref.read(workdayCommandsProvider).closeWorkday(note: _note.text, location: _location);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go(Routes.history);
      await reportCommand(messenger, handle, accepted: 'Jornada cerrada.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    // Kept while saving: the optimistic state closes the workday as soon as it is queued.
    final day = _busy ? _day : ref.watch(dayViewProvider).value;
    _day = day;
    final workday = day?.workday;
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();

    if (day == null || workday == null || !workday.isOpen) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              BackHeader(title: 'Cerrar jornada'),
              Expanded(child: StateMessage(message: 'No tienes una jornada abierta.')),
            ],
          ),
        ),
      );
    }

    final s = workday.summary;
    final lunch = day.today.plan.lunchMinutes;
    final categories = categoryParts(s, c);
    final current = workday.current;
    final date = Fmt.dateOnly(day.today.date) ?? now.toLocal();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Cerrar jornada'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${Fmt.time(workday.startedAt)} → ${Fmt.time(now)}',
                                style: TextStyle(fontSize: 14, color: c.inkStrong),
                              ),
                            ),
                            Text(Fmt.longDate(date), style: TextStyle(fontSize: 14, color: c.inkMuted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Fmt.minutes(s.workedMinutes),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.34,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Horas de la jornada · provisional', style: TextStyle(fontSize: 13, color: c.inkMuted)),
                        const SizedBox(height: 12),
                        DistributionBar(
                          height: 12,
                          semanticsLabel: [
                            for (final p in categories) '${p.label} ${Fmt.minutes(p.minutes)}',
                            if (lunch > 0) 'almuerzo ${Fmt.minutes(lunch)}',
                          ].join(', '),
                          parts: [for (final p in categories) (p.minutes, p.color), (lunch, c.surfaceMuted)],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            for (final p in categories)
                              LegendItem(color: p.color, label: '${p.label} ${Fmt.minutes(p.minutes)}', fontSize: 13),
                            if (lunch > 0)
                              LegendItem(
                                color: c.surfaceMuted,
                                outlined: true,
                                label: 'Almuerzo ${Fmt.minutes(lunch)} (no cuenta)',
                                fontSize: 13,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (current != null) ...[
                    const SizedBox(height: 14),
                    InfoBanner(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Tienes '),
                            TextSpan(
                              text: current.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' en curso. Se finalizará como Completada a las ${Fmt.time(now)}.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  LocationLine(
                    busy: _locating,
                    ok: _location != null,
                    text: _locating
                        ? 'Obteniendo ubicación de cierre…'
                        : _location == null
                        ? 'Sin ubicación de cierre: el GPS no respondió.'
                        : 'Ubicación de cierre capturada · precisión ${Fmt.meters(_location!.accuracy)}',
                  ),
                  const SizedBox(height: 14),
                  AppTextArea(controller: _note, label: 'Nota del día', hint: 'Algo que tu supervisor deba saber'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 16),
              child: Column(
                children: [
                  PrimaryButton(label: 'Cerrar jornada', icon: Icons.logout_rounded, loading: _busy, onPressed: _close),
                  TertiaryButton(label: 'Seguir trabajando', onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
