import 'dart:async';

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
import '../data/models/today_dto.dart';
import '../domain/day_projection.dart';
import 'activity_view.dart';
import 'no_shift_view.dart';
import 'start_workday_view.dart';
import 'widgets/workday_widgets.dart';
import 'workday_commands.dart';
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

/// The workday of today is already closed. With "reinicio de actividades" approved by the
/// supervisor it can be resumed from here.
class DayClosedView extends ConsumerStatefulWidget {
  const DayClosedView({super.key, required this.day});

  final DayView day;

  @override
  ConsumerState<DayClosedView> createState() => _DayClosedViewState();
}

class _DayClosedViewState extends ConsumerState<DayClosedView> {
  bool _busy = false;
  Timer? _refreshTimer;

  /// The supervisor approves from the panel while this screen is open: the day is asked again
  /// on showing it and every minute, so "Reanudar jornada" appears without leaving the app.
  static const _refreshEvery = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
    _refreshTimer = Timer.periodic(_refreshEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(todayControllerProvider.notifier).refresh();

  /// "Reanudar jornada": a start of the workday; the server opens the closed one again.
  Future<void> _resume() async {
    setState(() => _busy = true);
    try {
      final handle = await ref.read(workdayCommandsProvider).startWorkday();
      if (!mounted) return;
      await reportCommand(ScaffoldMessenger.of(context), handle, accepted: 'Jornada reanudada.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final day = widget.day;
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
              child: RefreshIndicator(
                color: c.primary,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                    if (!workday.optimistic && !day.stale && day.today.resume != null) ...[
                      _ResumeSection(resume: day.today.resume!, busy: _busy, onResume: _resume),
                      const SizedBox(height: 12),
                    ],
                    SecondaryButton(
                      label: 'Ver mi día',
                      icon: Icons.format_list_bulleted_rounded,
                      onPressed: () => context.go(Routes.history),
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNav(current: NavTab.workday, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }
}

/// "Reinicio de actividades" on the closed day: ask for it, wait for the supervisor or resume.
class _ResumeSection extends StatelessWidget {
  const _ResumeSection({required this.resume, required this.busy, required this.onResume});

  final ResumeDto resume;
  final bool busy;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    Widget ask(String label) => SecondaryButton(
      label: label,
      icon: Icons.play_circle_outline_rounded,
      onPressed: () => context.push(Routes.resumeRequest),
    );
    final comment = resume.resolverComment?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (resume.state) {
        ResumeState.approved when resume.canResumeNow => [
          const InfoBanner(
            tone: BannerTone.success,
            icon: Icons.check_circle_outline,
            child: Text('Tu supervisor aprobó el reinicio de actividades. Ya puedes seguir trabajando.'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Reanudar jornada', icon: Icons.play_arrow_rounded, loading: busy, onPressed: onResume),
        ],
        ResumeState.approved => [
          InfoBanner(
            child: Text(
              resume.blockedReason ?? 'Tu turno de hoy ya terminó. Solicita horas extra para seguir trabajando.',
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Solicitar horas extra',
            icon: Icons.more_time_rounded,
            onPressed: () => context.push(Routes.overtimeRequest),
          ),
        ],
        ResumeState.pending => [
          const InfoBanner(
            tone: BannerTone.neutral,
            icon: Icons.hourglass_empty_rounded,
            child: Text(
              'Solicitud de reinicio de actividades enviada. Cuando tu supervisor la apruebe podrás reanudar la jornada aquí.',
            ),
          ),
        ],
        ResumeState.rejected => [
          InfoBanner(
            child: Text(
              comment == null || comment.isEmpty
                  ? 'Tu supervisor no aprobó el reinicio de actividades.'
                  : 'Tu supervisor no aprobó el reinicio de actividades: $comment',
            ),
          ),
          const SizedBox(height: 12),
          ask('Solicitar de nuevo el reinicio'),
        ],
        ResumeState.none || ResumeState.unknown => [ask('Solicitar reinicio de actividades')],
      },
    );
  }
}
