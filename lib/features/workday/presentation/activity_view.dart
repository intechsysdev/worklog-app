import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../kiosk/presentation/kiosk_view.dart';
import '../../sync/presentation/sync_controller.dart';
import '../data/models/enums.dart';
import '../domain/day_projection.dart';
import 'start_workday_view.dart';
import 'widgets/workday_widgets.dart';
import 'workday_commands.dart';

/// "Actividad en curso" (and the open workday without a current activity).
class ActiveWorkdayView extends ConsumerStatefulWidget {
  const ActiveWorkdayView({super.key, required this.day});

  final DayView day;

  @override
  ConsumerState<ActiveWorkdayView> createState() => _ActiveWorkdayViewState();
}

class _ActiveWorkdayViewState extends ConsumerState<ActiveWorkdayView> {
  bool _busy = false;

  Future<void> _togglePause(ActivityView activity) async {
    setState(() => _busy = true);
    try {
      final commands = ref.read(workdayCommandsProvider);
      final handle = activity.paused ? await commands.resume(activity) : await commands.pause(activity);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _busy = false);
      // Only the server corrections are worth a message here.
      final result = await handle.answer;
      if (result.rejected || result.adjusted) await reportCommand(messenger, handle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final day = widget.day;
    final workday = day.workday!;
    final current = workday.current;
    final shiftEnd = day.today.window?.shiftEnd;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (day.today.device.controlEnabled)
              const KioskBar(label: 'En jornada · apps de trabajo habilitadas', open: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 20, kScreenPadding, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jornada activa',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            'Desde ${Fmt.time(workday.startedAt)}',
                            if (shiftEnd != null && !day.stale) 'Turno hasta ${Fmt.time(shiftEnd)}',
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const _GpsBadge(),
                  const SizedBox(width: 6),
                  const _SyncBadge(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 8, kScreenPadding, 16),
                children: [
                  if (current != null)
                    _CurrentActivityCard(activity: current, busy: _busy, onTogglePause: () => _togglePause(current))
                  else
                    const _NoActivityCard(),
                  const SizedBox(height: 16),
                  DaySummaryTiles(workday: workday),
                ],
              ),
            ),
            AppBottomNav(current: NavTab.activity, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }
}

class _CurrentActivityCard extends ConsumerWidget {
  const _CurrentActivityCard({required this.activity, required this.busy, required this.onTogglePause});

  final ActivityView activity;
  final bool busy;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final paused = activity.paused;
    return AppCard(
      radius: AppRadii.activityCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: paused
                ? StatusChip(label: 'EN PAUSA', background: c.warningBg, foreground: c.warningFg, dot: c.warningDot)
                : StatusChip(label: 'EN CURSO', background: c.successBg, foreground: c.successFg, dot: c.successDot),
          ),
          const SizedBox(height: 16),
          Text(
            activity.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 30 / 24, color: c.ink),
          ),
          if (activity.place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(activity.place, style: TextStyle(fontSize: 14, color: c.inkMuted)),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Semantics(
                  label: 'Tiempo de la actividad',
                  child: ServerTimeText(
                    builder: (now) => Fmt.stopwatch(activity.worked(now)),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.52,
                      height: 1,
                      color: paused ? c.inkMuted : c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paused && activity.pausedSince != null
                      ? 'En pausa desde las ${Fmt.time(activity.pausedSince!)}'
                      : 'Iniciada a las ${Fmt.time(activity.startedAt)}',
                  style: TextStyle(fontSize: 13, color: c.inkMuted),
                ),
              ],
            ),
          ),
          _GeofenceBox(activity: activity),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: paused ? 'Reanudar' : 'Pausar',
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  fontSize: 16,
                  loading: busy,
                  onPressed: onTogglePause,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Finalizar',
                  icon: Icons.stop_rounded,
                  height: 52,
                  fontSize: 16,
                  radius: AppRadii.button,
                  onPressed: busy ? null : () => context.push(Routes.finishActivity),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TertiaryButton(
            label: 'Cambiar actividad',
            icon: Icons.swap_horiz_rounded,
            onPressed: () => context.push(Routes.selectActivity),
          ),
        ],
      ),
    );
  }
}

class _GeofenceBox extends StatelessWidget {
  const _GeofenceBox({required this.activity});

  final ActivityView activity;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final accuracy = activity.accuracy == null ? '' : ' · precisión ${Fmt.meters(activity.accuracy)}';
    final (text, ok) = switch (activity.geofence) {
      GeofenceStatus.inside => ('Dentro de la geocerca del sitio$accuracy', true),
      GeofenceStatus.outside => ('Fuera de la geocerca del sitio$accuracy', false),
      GeofenceStatus.notApplicable => ('Actividad sin geocerca de sitio$accuracy', true),
      GeofenceStatus.noLocation => ('Sin ubicación al iniciar la actividad', false),
      GeofenceStatus.unknown =>
        activity.optimistic
            ? ('Ubicación capturada$accuracy · se valida al sincronizar', true)
            : ('Precisión insuficiente para validar la geocerca$accuracy', false),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(12)),
      child: LocationLine(text: text, ok: ok),
    );
  }
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard();

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return AppCard(
      radius: AppRadii.activityCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: 'SIN ACTIVIDAD',
              background: c.warningBg,
              foreground: c.warningFg,
              dot: c.warningDot,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¿Qué vas a hacer ahora?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 30 / 24, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige una orden asignada o una actividad del catálogo. El tiempo sin actividad se reporta como «Sin actividad».',
            style: TextStyle(fontSize: 14, height: 20 / 14, color: c.inkMuted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Iniciar actividad',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.push(Routes.selectActivity),
          ),
          const SizedBox(height: 8),
          TertiaryButton(label: 'Cerrar jornada', onPressed: () => context.push(Routes.closeWorkday)),
        ],
      ),
    );
  }
}

class _GpsBadge extends ConsumerWidget {
  const _GpsBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final ready = ref.watch(locationAvailabilityProvider).value == LocationAvailability.ready;
    return Semantics(
      label: ready ? 'GPS activo' : 'GPS inactivo',
      child: Container(
        width: kTouchTarget,
        height: kTouchTarget,
        decoration: BoxDecoration(color: ready ? c.successBg : c.warningBg, shape: BoxShape.circle),
        child: Icon(
          ready ? Icons.place_outlined : Icons.location_off_outlined,
          size: 16,
          color: ready ? c.successFg : c.warningFg,
        ),
      ),
    );
  }
}

class _SyncBadge extends ConsumerWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final status = ref.watch(syncControllerProvider);
    final pending = status.pendingEvents.length + status.pendingFiles.length;
    final ok = pending == 0 && !status.hasRejected;
    final label = ok
        ? 'Todo sincronizado. Ver sincronización'
        : pending > 0
        ? '$pending pendientes de sincronizar. Ver sincronización'
        : 'Hay registros rechazados. Ver sincronización';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: ok ? c.successBg : c.warningBg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(Routes.pending),
          child: SizedBox(
            width: kTouchTarget,
            height: kTouchTarget,
            child: Center(
              child: ok
                  ? Icon(Icons.check_rounded, size: 18, color: c.successFg)
                  : pending > 0
                  ? Text(
                      pending > 99 ? '99+' : '$pending',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.warningFg),
                    )
                  : Icon(Icons.priority_high_rounded, size: 18, color: c.warningFg),
            ),
          ),
        ),
      ),
    );
  }
}
