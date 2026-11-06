import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../sync/domain/queued_event.dart';
import '../../sync/presentation/sync_controller.dart';
import '../data/models/enums.dart';
import '../data/models/timeline_dto.dart';
import '../domain/day_projection.dart';
import 'widgets/workday_widgets.dart';
import 'workday_providers.dart';

/// "Mi día": distribution bar and timeline (most recent first).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final day = ref.watch(dayViewProvider).value;
    final timeline = ref.watch(timelineProvider);
    final pending = ref.watch(syncControllerProvider.select((s) => s.pendingEvents));
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();
    final workday = day?.workday;
    final date = Fmt.dateOnly(day?.today.date) ?? now.toLocal();

    final subtitle = [
      Fmt.longDate(date),
      if (workday != null)
        '${Fmt.time(workday.startedAt)} – ${workday.isOpen ? 'en curso' : (workday.endedAt == null ? '' : Fmt.time(workday.endedAt!))}',
    ].join(' · ');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 20, kScreenPadding, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Mi día',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: c.inkMuted)),
                  const SizedBox(height: 10),
                  SegmentedTabs(
                    labels: const ['Día', 'Semana'],
                    index: 0,
                    onChanged: (i) {
                      if (i == 1) context.push(Routes.week);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.primary,
                onRefresh: () async {
                  await ref.read(todayControllerProvider.notifier).refresh();
                  ref.invalidate(timelineProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                  children: [
                    _DistributionCard(timeline: timeline.value, workday: workday, now: now),
                    const SizedBox(height: 14),
                    for (final e in pending.reversed) _PendingTile(event: e),
                    ...timeline.when(
                      loading: () => [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                      error: (error, _) => [
                        StateMessage(
                          message: ApiException.from(error).message,
                          actionLabel: 'Reintentar',
                          onAction: () => ref.invalidate(timelineProvider),
                        ),
                      ],
                      data: (t) {
                        final entries = t?.entries ?? const <TimelineEntryDto>[];
                        if (entries.isEmpty && pending.isEmpty) {
                          return [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                t == null
                                    ? 'Sin conexión: el historial se mostrará al sincronizar.'
                                    : 'Aún no hay registros hoy.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: c.inkMuted),
                              ),
                            ),
                          ];
                        }
                        return [for (final e in entries) _EntryTile(entry: e, now: now)];
                      },
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      radius: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '¿Algo quedó mal registrado? Los ajustes los aprueba tu supervisor.',
                              style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkStrong),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => context.push(Routes.adjustmentRequest),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, kTouchTarget),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              foregroundColor: c.primary,
                              side: BorderSide(color: c.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Solicitar ajuste', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNav(current: NavTab.history, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.timeline, required this.workday, required this.now});

  final TimelineDto? timeline;
  final WorkdayView? workday;
  final DateTime now;

  DateTime? _at(String? time) {
    final date = Fmt.dateOnly(timeline?.date);
    if (date == null || time == null || time.length < 5) return null;
    final h = int.tryParse(time.substring(0, 2));
    final m = int.tryParse(time.substring(3, 5));
    if (h == null || m == null) return null;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final segments = [...?timeline?.segments]..sort((a, b) => a.start.compareTo(b.start));
    final localNow = now.toLocal();
    final shiftStart = _at(timeline?.shiftStart);
    final shiftEnd = _at(timeline?.shiftEnd);
    final rangeStart = shiftStart ?? (segments.isEmpty ? localNow : segments.first.start.toLocal());
    final lastEnd = segments.isEmpty ? rangeStart : (segments.last.end?.toLocal() ?? localNow);
    final rangeEnd = shiftEnd != null && shiftEnd.isAfter(lastEnd) ? shiftEnd : lastEnd;

    final parts = <(int, Color)>[];
    var cursor = rangeStart;
    for (final s in segments) {
      final start = s.start.toLocal();
      final end = s.end?.toLocal() ?? localNow;
      final gap = start.difference(cursor).inMinutes;
      if (gap > 0) parts.add((gap, c.surfaceMuted));
      final minutes = end.difference(start).inMinutes;
      final color = s.kind == SegmentKind.idle
          ? c.idle
          : s.end == null
          ? c.brandRed
          : parseHexColor(s.color);
      parts.add((minutes < 1 ? 1 : minutes, color));
      if (end.isAfter(cursor)) cursor = end;
    }
    final tail = rangeEnd.difference(cursor).inMinutes;
    if (tail > 0) parts.add((tail, c.surfaceMuted));

    final mid = rangeStart.add(rangeEnd.difference(rangeStart) ~/ 2);
    final s = workday?.summary;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DistributionBar(
            parts: parts,
            semanticsLabel: s == null
                ? 'Sin registros'
                : 'Distribución del día: productivo ${Fmt.minutes(s.productiveMinutes)}, traslado ${Fmt.minutes(s.paidNonProductiveMinutes)}, sin actividad ${Fmt.minutes(s.withoutActivityMinutes)}',
          ),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: TextStyle(fontSize: 12, color: c.inkMuted),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(Fmt.time(rangeStart)), Text(Fmt.time(mid)), Text(Fmt.time(rangeEnd))],
            ),
          ),
          if (s != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final p in categoryParts(s, c))
                  LegendItem(color: p.color, label: '${p.label} ${Fmt.minutes(p.minutes)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.now});

  final TimelineEntryDto entry;
  final DateTime now;

  static String _geofence(GeofenceStatus status) => switch (status) {
    GeofenceStatus.inside => 'dentro de geocerca',
    GeofenceStatus.outside => 'fuera de geocerca',
    GeofenceStatus.unknown => 'geocerca sin validar',
    GeofenceStatus.noLocation => 'sin ubicación',
    GeofenceStatus.notApplicable => '',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final e = entry;
    final range = '${Fmt.time(e.start)} – ${e.running || e.end == null ? 'ahora' : Fmt.time(e.end!)}';
    final (String duration, String meta, Color color) = switch (e.kind) {
      'start' || 'close' => (
        Fmt.time(e.start),
        [e.siteName, _geofence(e.geofence)].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        c.ink,
      ),
      'idle' => (Fmt.minutes(e.minutes), range, c.idle),
      _ => (
        e.running ? 'En curso' : Fmt.minutes(e.minutes),
        [
          range,
          if (e.running) ...[?e.siteName, ?e.workOrderNumber],
          ?e.outcomeLabel,
          if (e.photoCount > 0) e.photoCount == 1 ? '1 foto' : '${e.photoCount} fotos',
          if (e.hasSignature) 'firma',
          if (e.autoFinished) 'finalizada automáticamente',
        ].join(' · '),
        e.running ? c.brandRed : parseHexColor(e.color),
      ),
    };
    return _TimelineRow(title: e.title, duration: duration, meta: meta, color: color);
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.event});

  final QueuedEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return _TimelineRow(
      title: [event.title, event.meta.activityName].whereType<String>().join(' · '),
      duration: Fmt.time(event.event.occurredAt),
      meta: 'Pendiente de sincronizar',
      color: c.borderInput,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.title, required this.duration, required this.meta, required this.color});

  final String title;
  final String duration;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(child: Container(width: 2, color: c.borderCard)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkStrong),
                      ),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: TextStyle(fontSize: 13, color: c.inkMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
