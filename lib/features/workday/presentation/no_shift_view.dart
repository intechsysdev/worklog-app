import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../data/models/enums.dart';
import '../domain/day_projection.dart';
import 'widgets/workday_widgets.dart';

/// "Sin turno hoy": absence, holiday, rest or no schedule. The start button stays disabled and no
/// location is recorded.
class NoShiftView extends StatelessWidget {
  const NoShiftView({super.key, required this.day});

  final DayView day;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final today = day.today;
    final (initials, name) = memberIdentity(day);
    final date = Fmt.dateOnly(today.date) ?? DateTime.now();
    final absence = today.absence;
    final next = today.nextShift;
    final nextDate = Fmt.dateOnly(next?.date);

    final (section, title, body, icon) = switch (today.plan.kind) {
      DayKind.absence => (
        'Novedad',
        absence?.label ?? today.plan.label ?? 'Novedad',
        [
          _range(absence?.from, absence?.to),
          if (absence?.approvedBy != null) 'Aprobadas por ${absence!.approvedBy}.',
        ].where((s) => s.isNotEmpty).join(' '),
        Icons.beach_access_outlined,
      ),
      DayKind.holiday => (
        'Festivo',
        today.plan.label ?? 'Día festivo',
        'Hoy no hay turno programado.',
        Icons.event_outlined,
      ),
      DayKind.rest => ('Descanso', 'Día de descanso', 'Según tu horario, hoy descansas.', Icons.weekend_outlined),
      _ => (
        'Sin horario',
        'Sin turno asignado',
        'No tienes horario asignado para hoy. Habla con tu supervisor.',
        Icons.event_busy_outlined,
      ),
    };

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
                          Text('Hoy no tienes turno', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(Fmt.longDate(date), style: TextStyle(fontSize: 15, color: c.inkMuted)),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(color: c.warningBg, shape: BoxShape.circle),
                                      child: Icon(icon, size: 20, color: c.warningFg),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SectionLabel(section),
                                          const SizedBox(height: 2),
                                          Text(
                                            title,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    body,
                                    style: TextStyle(fontSize: 14, height: 20 / 14, color: c.inkStrong),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (next != null && nextDate != null) ...[
                            const SizedBox(height: 16),
                            AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu próximo turno',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.inkMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    Fmt.longDate(nextDate),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      '${Fmt.timeOnly(next.start)} – ${Fmt.timeOnly(next.end)}',
                                      ?today.branchName,
                                    ].join(' · '),
                                    style: TextStyle(fontSize: 14, color: c.inkStrong),
                                  ),
                                  for (final note in next.notes) ...[
                                    const SizedBox(height: 6),
                                    Text(note, style: TextStyle(fontSize: 13, color: c.inkMuted)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          const SizedBox(height: 24),
                          const PrimaryButton(
                            label: 'Iniciar jornada',
                            icon: Icons.play_arrow_rounded,
                            height: 64,
                            fontSize: 18,
                            mutedWhenDisabled: true,
                            onPressed: null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No puedes iniciar jornada en días sin turno. No se registra tu ubicación.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                          ),
                          const SizedBox(height: 8),
                          TertiaryButton(
                            label: '¿Es un error? Solicitar cambio de turno',
                            onPressed: () => context.push(Routes.shiftChangeRequest),
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

  static String _range(String? from, String? to) {
    final a = Fmt.dateOnly(from);
    final b = Fmt.dateOnly(to);
    if (a == null || b == null) return '';
    if (a == b) return '${Fmt.longDate(a)}.';
    return 'Del ${Fmt.weekday(a)} ${a.day} al ${Fmt.weekday(b)} ${b.day} de ${Fmt.longDate(b).split(' de ').last}.';
  }
}
