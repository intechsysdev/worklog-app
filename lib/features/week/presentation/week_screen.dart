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
import '../../requests/data/requests_api.dart';
import '../../workday/data/models/enums.dart';
import '../../workday/presentation/widgets/workday_widgets.dart';
import '../data/week_models.dart';

/// `GET /me/week?date` for the week containing the date (`yyyy-MM-dd`).
final weekProvider = FutureProvider.autoDispose.family<MyWeekDto, String>(
  (ref, date) => ref.watch(requestsApiProvider).week(date),
);

/// "Mi semana".
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = ref.read(serverClockProvider).now().toLocal();
  }

  void _move(int weeks) => setState(() => _anchor = _anchor.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final today = ref.read(serverClockProvider).now().toLocal();
    final week = ref.watch(weekProvider(Fmt.isoDate(_anchor)));
    final isCurrent = Fmt.isoDate(_anchor) == Fmt.isoDate(today) || _sameWeek(_anchor, today);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 20, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Mi semana',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week.value == null ? ' ' : WeekView.rangeLabel(week.value!),
                          style: TextStyle(fontSize: 14, color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Semana anterior',
                    onPressed: () => _move(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: c.ink),
                  ),
                  IconButton(
                    tooltip: 'Semana siguiente',
                    onPressed: isCurrent ? null : () => _move(1),
                    icon: Icon(Icons.chevron_right_rounded, color: isCurrent ? c.borderInput : c.ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 8),
              child: SegmentedTabs(
                labels: const ['Día', 'Semana'],
                index: 1,
                onChanged: (i) {
                  if (i == 0) context.go(Routes.history);
                },
              ),
            ),
            Expanded(
              child: week.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => StateMessage(
                  icon: Icons.cloud_off_outlined,
                  message: ApiException.from(error).isNetwork
                      ? 'Sin conexión. Mi semana se calcula en el servidor: conéctate para verla.'
                      : ApiException.from(error).message,
                  actionLabel: 'Reintentar',
                  onAction: () => ref.invalidate(weekProvider(Fmt.isoDate(_anchor))),
                ),
                data: (data) => RefreshIndicator(
                  color: c.primary,
                  onRefresh: () => ref.refresh(weekProvider(Fmt.isoDate(_anchor)).future),
                  child: WeekView(week: data),
                ),
              ),
            ),
            AppBottomNav(current: NavTab.history, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }

  static bool _sameWeek(DateTime a, DateTime b) {
    DateTime monday(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return monday(a) == monday(b);
  }
}

/// Body of "Mi semana" (separated for the widget tests).
class WeekView extends StatelessWidget {
  const WeekView({super.key, required this.week});

  final MyWeekDto week;

  /// Days shown in the bars: working days and any day with hours.
  static List<WeekDayDto> visibleDays(MyWeekDto week) {
    final days = week.days
        .where((d) => d.planKind.isWorkingDay || d.workedMinutes > 0 || d.scheduledMinutes > 0)
        .toList();
    return days.isEmpty ? week.days : days;
  }

  /// `Lunes 26 a viernes 30 de octubre`.
  static String rangeLabel(MyWeekDto week) {
    final days = visibleDays(week);
    final first = Fmt.dateOnly(days.isEmpty ? week.from : days.first.date);
    final last = Fmt.dateOnly(days.isEmpty ? week.to : days.last.date);
    if (first == null || last == null) return '';
    final firstText = Fmt.longDate(first).split(' de ').first;
    return '$firstText a ${Fmt.weekday(last)} ${last.day} de ${Fmt.longDate(last).split(' de ').last}';
  }

  /// `8:00`, `7:10`, `—`.
  static String barLabel(int minutes) =>
      minutes <= 0 ? '—' : '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  static String hours(int minutes) => minutes % 60 == 0 ? '${minutes ~/ 60}' : Fmt.minutes(minutes);

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final cap = week.weeklyCapMinutes <= 0 ? 1 : week.weeklyCapMinutes;
    final days = visibleDays(week);
    final maxMinutes = days.fold<int>(540, (m, d) => d.workedMinutes > m ? d.workedMinutes : m);
    final until = Fmt.dateOnly(week.provisionalUntil);
    final b = week.breakdown;

    return ListView(
      padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      Fmt.minutes(week.workedMinutes),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.ink),
                    ),
                  ),
                  Text(
                    'de ${hours(week.weeklyCapMinutes)} h legales',
                    style: TextStyle(fontSize: 14, color: c.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                image: true,
                label:
                    '${Fmt.minutes(week.workedMinutes)} de ${Fmt.minutes(week.scheduledMinutes)} programadas y ${Fmt.minutes(week.weeklyCapMinutes)} de tope legal',
                child: SizedBox(
                  height: 20,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final worked = (week.workedMinutes / cap).clamp(0.0, 1.0);
                      final scheduled = (week.scheduledMinutes / cap).clamp(0.0, 1.0);
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                          ),
                          Container(
                            height: 12,
                            width: box.maxWidth * worked,
                            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(6)),
                          ),
                          Positioned(
                            left: (box.maxWidth * scheduled - 1).clamp(0, box.maxWidth - 2),
                            top: 0,
                            bottom: 0,
                            child: Container(width: 2, color: c.ink),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle.merge(
                style: TextStyle(fontSize: 12, color: c.inkMuted),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Programadas: ${Fmt.minutes(week.scheduledMinutes)}'),
                    Text(
                      week.remainingMinutes > 0
                          ? 'Te faltan ${Fmt.minutes(week.remainingMinutes)}'
                          : 'Programadas cumplidas',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Horas por día'),
              const SizedBox(height: 10),
              Semantics(
                image: true,
                label: days
                    .map((d) {
                      final date = Fmt.dateOnly(d.date)!;
                      return '${Fmt.weekday(date)} ${d.workedMinutes > 0 ? Fmt.minutes(d.workedMinutes) : 'sin registro'}${d.inProgress ? ' en curso' : ''}';
                    })
                    .join(', '),
                child: SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < days.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _DayBar(day: days[i], max: maxMinutes),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dayName(days[i]),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: days[i].isToday ? c.ink : c.inkMuted,
                          fontWeight: days[i].isToday ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _BreakdownRow(label: 'Ordinarias diurnas', value: Fmt.minutes(b.ordinaryDay)),
              _BreakdownRow(label: 'Ordinarias nocturnas', value: Fmt.minutes(b.ordinaryNight)),
              _BreakdownRow(
                label: 'Horas extra aprobadas',
                value: '${hours(week.approvedOvertimeMinutes)} de ${hours(week.overtimeWeeklyMaxMinutes)}',
              ),
              _BreakdownRow(label: 'Dominical o festivo', value: Fmt.minutes(b.sundayHoliday), last: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          until == null
              ? 'Cifras provisionales hasta el cierre del periodo.'
              : 'Cifras provisionales hasta el cierre del periodo, el ${until.day} de ${Fmt.longDate(until).split(' de ').last}.',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: c.inkMuted),
        ),
      ],
    );
  }

  static String _dayName(WeekDayDto day) {
    final date = Fmt.dateOnly(day.date)!;
    final name = Fmt.weekday(date);
    return '${name[0].toUpperCase()}${name.substring(1, 3)} ${date.day}';
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day, required this.max});

  final WeekDayDto day;
  final int max;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final height = day.workedMinutes <= 0 ? 6.0 : (day.workedMinutes / max * 120).clamp(6.0, 120.0);
    final color = day.workedMinutes <= 0
        ? c.surfaceMuted
        : day.inProgress
        ? c.brandRed
        : c.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          WeekView.barLabel(day.workedMinutes),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkStrong),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          constraints: const BoxConstraints(maxWidth: 40),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: c.ink)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
          ),
        ],
      ),
    );
  }
}
