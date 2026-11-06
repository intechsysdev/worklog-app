import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../alerts/presentation/shift_end_notice.dart';
import '../../kiosk/presentation/kiosk_view.dart';
import '../data/models/enums.dart';
import '../domain/day_projection.dart';
import 'activity_view.dart';
import 'no_shift_view.dart';
import 'start_workday_view.dart';
import 'widgets/workday_widgets.dart';
import 'workday_providers.dart';

/// "Actividad" tab: start of the workday, day without shift, current activity or closed day.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(dayViewProvider);
    return day.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: StateMessage(
            icon: Icons.cloud_off_outlined,
            message: ApiException.from(error).isNetwork
                ? 'No pudimos cargar tu día. Conéctate a internet la primera vez para descargar tu turno.'
                : ApiException.from(error).message,
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(todayControllerProvider),
          ),
        ),
      ),
      data: (day) => switch (day.mode) {
        HomeMode.start => day.today.device.controlEnabled ? KioskView(day: day) : StartWorkdayView(day: day),
        HomeMode.noShift => NoShiftView(day: day),
        HomeMode.active => ActiveWorkdayView(day: day),
        HomeMode.closed => DayClosedView(day: day),
      },
    );
  }
}

/// The workday of today is already closed.
class DayClosedView extends ConsumerWidget {
  const DayClosedView({super.key, required this.day});

  final DayView day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final workday = day.workday!;
    final (initials, name) = memberIdentity(day);
    final date = Fmt.dateOnly(day.today.date) ?? DateTime.now();
    final s = workday.summary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (day.today.device.controlEnabled) const KioskBar(label: 'Fuera de jornada · solo WorkLog y teléfono'),
            BrandHeader(initials: initials, name: name, onAvatar: () => context.push(Routes.profile)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 8, kScreenPadding, 24),
                children: [
                  Text('Jornada cerrada', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(Fmt.longDate(date), style: TextStyle(fontSize: 15, color: c.inkMuted)),
                  const SizedBox(height: 16),
                  if (workday.status == WorkdayStatus.pendingReview) ...[
                    AutoClosedCard(today: day.today),
                    const SizedBox(height: 16),
                  ],
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Fmt.time(workday.startedAt)} → ${workday.endedAt == null ? '—' : Fmt.time(workday.endedAt!)}',
                          style: TextStyle(fontSize: 14, color: c.inkStrong),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Fmt.minutes(s.workedMinutes),
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        Text(
                          workday.status == WorkdayStatus.pendingReview
                              ? 'Pendiente de revisión del supervisor'
                              : 'Horas de la jornada · provisional',
                          style: TextStyle(fontSize: 13, color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DaySummaryTiles(workday: workday),
                  const SizedBox(height: 16),
                  if (workday.optimistic)
                    const InfoBanner(
                      tone: BannerTone.neutral,
                      child: Text('El cierre está guardado en el teléfono y se enviará al recuperar la conexión.'),
                    ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'Ver mi día',
                    icon: Icons.format_list_bulleted_rounded,
                    onPressed: () => context.go(Routes.history),
                  ),
                ],
              ),
            ),
            AppBottomNav(current: NavTab.workday, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }
}
