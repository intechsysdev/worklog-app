import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/requests_api.dart';
import '../domain/request_forms.dart';
import 'request_form_scaffold.dart';

/// "Cambio de turno": 1 to 7 days with other hours, or as day off.
class ShiftChangeFormScreen extends ConsumerStatefulWidget {
  const ShiftChangeFormScreen({super.key});

  @override
  ConsumerState<ShiftChangeFormScreen> createState() => _ShiftChangeFormScreenState();
}

class _ShiftChangeFormScreenState extends ConsumerState<ShiftChangeFormScreen> {
  final _reason = TextEditingController();
  late final DateTime _today;
  late List<ShiftDayDraft> _days;
  FormErrors _errors = const {};

  @override
  void initState() {
    super.initState();
    final now = ref.read(serverClockProvider).now().toLocal();
    _today = DateTime(now.year, now.month, now.day);
    final plan = ref.read(dayViewProvider).value?.today.plan;
    _days = [
      ShiftDayDraft(
        date: _today.add(const Duration(days: 1)),
        start: HourMinute.tryParse(plan?.start) ?? const HourMinute(7, 0),
        end: HourMinute.tryParse(plan?.end) ?? const HourMinute(16, 0),
        lunchMinutes: plan?.lunchMinutes ?? 60,
      ),
    ];
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _set(int i, ShiftDayDraft day) => setState(() => _days = [..._days]..[i] = day);

  ShiftDayDraft _copy(
    ShiftDayDraft d, {
    DateTime? date,
    bool? dayOff,
    HourMinute? start,
    HourMinute? end,
    int? lunch,
  }) => ShiftDayDraft(
    date: date ?? d.date,
    dayOff: dayOff ?? d.dayOff,
    start: start ?? d.start,
    end: end ?? d.end,
    lunchMinutes: lunch ?? d.lunchMinutes,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return RequestFormScaffold(
      title: 'Cambio de turno',
      intro:
          'Propón otro horario (o un día libre) para hoy o días futuros. Tu supervisor lo aprueba antes de aplicarlo.',
      onSubmit: () async {
        final form = ShiftChangeForm(days: _days, reason: _reason.text, today: _today);
        final errors = form.validate();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) return null;
        return ref
            .read(requestsApiProvider)
            .submitShiftChange(days: [for (final d in _days) d.toDto(Fmt.isoDate)], reason: _reason.text.trim());
      },
      children: [
        for (var i = 0; i < _days.length; i++) ...[
          _DayCard(
            day: _days[i],
            error: _errors['day$i'],
            canRemove: _days.length > 1,
            onRemove: () => setState(() => _days = [..._days]..removeAt(i)),
            onDate: () async {
              final picked = await pickDate(
                context,
                _days[i].date,
                first: _today,
                last: _today.add(const Duration(days: 120)),
              );
              if (picked != null) _set(i, _copy(_days[i], date: picked));
            },
            onDayOff: (v) => _set(i, _copy(_days[i], dayOff: v)),
            onStart: () async {
              final t = await pickTime(context, _days[i].start);
              if (t != null) _set(i, _copy(_days[i], start: t));
            },
            onEnd: () async {
              final t = await pickTime(context, _days[i].end);
              if (t != null) _set(i, _copy(_days[i], end: t));
            },
            onLunch: (m) => _set(i, _copy(_days[i], lunch: m)),
          ),
          const SizedBox(height: 10),
        ],
        if (_errors['days'] != null) Text(_errors['days']!, style: TextStyle(fontSize: 13, color: c.primaryDark)),
        if (_days.length < 7)
          TertiaryButton(
            label: 'Agregar otro día',
            icon: Icons.add_rounded,
            onPressed: () {
              final last = _days.last;
              setState(() => _days = [..._days, _copy(last, date: last.date.add(const Duration(days: 1)))]);
            },
          ),
        const SizedBox(height: 8),
        AppTextArea(
          controller: _reason,
          label: 'Motivo',
          optional: false,
          hint: 'Ej.: cita médica en la mañana.',
          errorText: _errors['reason'],
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.error,
    required this.canRemove,
    required this.onRemove,
    required this.onDate,
    required this.onDayOff,
    required this.onStart,
    required this.onEnd,
    required this.onLunch,
  });

  final ShiftDayDraft day;
  final String? error;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onDate;
  final ValueChanged<bool> onDayOff;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ValueChanged<int> onLunch;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: error == null ? null : c.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: PickerField(
                  label: 'Día',
                  value: Fmt.longDate(day.date),
                  icon: Icons.calendar_today_outlined,
                  onTap: onDate,
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Quitar día',
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline_rounded, color: c.inkMuted),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Día libre', style: TextStyle(fontSize: 14, color: c.ink)),
            value: day.dayOff,
            onChanged: onDayOff,
          ),
          if (!day.dayOff) ...[
            Row(
              children: [
                Expanded(
                  child: PickerField(label: 'Entrada', value: day.start?.label, placeholder: 'HH:mm', onTap: onStart),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PickerField(label: 'Salida', value: day.end?.label, placeholder: 'HH:mm', onTap: onEnd),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const FieldLabel('Almuerzo'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [0, 30, 60, 90])
                  ChoiceChip(
                    label: Text(m == 0 ? 'Sin almuerzo' : Fmt.minutes(m)),
                    selected: day.lunchMinutes == m,
                    onSelected: (_) => onLunch(m),
                    selectedColor: c.primary,
                    labelStyle: TextStyle(color: day.lunchMinutes == m ? Colors.white : c.inkStrong),
                    showCheckmark: false,
                  ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(fontSize: 13, color: c.primaryDark)),
          ],
        ],
      ),
    );
  }
}
