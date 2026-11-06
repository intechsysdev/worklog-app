import '../data/request_models.dart';

/// Time of day `HH:mm`, as typed in the forms.
class HourMinute implements Comparable<HourMinute> {
  const HourMinute(this.hour, this.minute);

  factory HourMinute.fromDateTime(DateTime value) => HourMinute(value.hour, value.minute);

  /// Parses `7:05`, `07:05` or `07:05:00`. Returns null when invalid.
  static HourMinute? tryParse(String? text) {
    if (text == null) return null;
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*$').firstMatch(text);
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return null;
    return HourMinute(h, m);
  }

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  /// `HH:mm:ss` for the API (TimeOnly).
  String get wire => '${_two(hour)}:${_two(minute)}:00';

  String get label => '${_two(hour)}:${_two(minute)}';

  /// Local date-time on [date].
  DateTime on(DateTime date) => DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(HourMinute other) => totalMinutes.compareTo(other.totalMinutes);

  @override
  bool operator ==(Object other) => other is HourMinute && other.totalMinutes == totalMinutes;

  @override
  int get hashCode => totalMinutes;

  static String _two(int v) => v.toString().padLeft(2, '0');
}

/// Field errors of a form: key = field, value = Spanish message.
typedef FormErrors = Map<String, String>;

String? _reasonError(String reason) {
  final text = reason.trim();
  if (text.length < 5) return 'Cuenta el motivo (mínimo 5 caracteres).';
  if (text.length > 500) return 'El motivo admite máximo 500 caracteres.';
  return null;
}

/// "Ajuste de registro": a recorded time that should be different.
class AdjustmentForm {
  const AdjustmentForm({
    required this.workdayId,
    required this.date,
    required this.target,
    required this.proposed,
    required this.reason,
    this.activityRecordId,
    this.original,
  });

  final String? workdayId;

  /// Calendar date of the workday.
  final DateTime date;
  final AdjustmentTarget? target;
  final String? activityRecordId;
  final HourMinute? proposed;

  /// Time currently recorded, to avoid proposing the same value.
  final DateTime? original;
  final String reason;

  FormErrors validate() => {
    if (workdayId == null) 'workday': 'No hay una jornada registrada para ajustar.',
    if (target == null) 'target': 'Elige qué quieres corregir.',
    if (target != null && target!.isActivity && activityRecordId == null) 'activity': 'Elige la actividad a corregir.',
    if (proposed == null) 'proposed': 'Escribe la hora correcta (HH:mm).',
    if (proposed != null && original != null && proposed == HourMinute.fromDateTime(original!.toLocal()))
      'proposed': 'La hora propuesta es igual a la registrada.',
    'reason': ?_reasonError(reason),
  };

  /// Proposed instant (local time of the workday date).
  DateTime get proposedValue => proposed!.on(date);
}

/// "Horas extra": a range of extra hours on a date.
class OvertimeForm {
  const OvertimeForm({
    required this.date,
    required this.from,
    required this.to,
    required this.reason,
    this.authorizationReference = '',
  });

  final DateTime? date;
  final HourMinute? from;
  final HourMinute? to;
  final String authorizationReference;
  final String reason;

  int get minutes => from == null || to == null ? 0 : to!.totalMinutes - from!.totalMinutes;

  FormErrors validate() => {
    if (date == null) 'date': 'Elige la fecha.',
    if (from == null) 'from': 'Escribe la hora de inicio (HH:mm).',
    if (to == null) 'to': 'Escribe la hora final (HH:mm).',
    if (from != null && to != null && to!.compareTo(from!) <= 0) 'to': 'La hora final debe ser posterior a la inicial.',
    if (authorizationReference.trim().length > 100) 'authorization': 'Máximo 100 caracteres.',
    'reason': ?_reasonError(reason),
  };
}

/// One day of a shift change: hours, or day off.
class ShiftDayDraft {
  const ShiftDayDraft({required this.date, this.dayOff = false, this.start, this.end, this.lunchMinutes = 60});

  final DateTime date;
  final bool dayOff;
  final HourMinute? start;
  final HourMinute? end;
  final int lunchMinutes;

  ShiftChangeDayDto toDto(String Function(DateTime) isoDate) => ShiftChangeDayDto(
    date: isoDate(date),
    start: dayOff ? null : start?.wire,
    end: dayOff ? null : end?.wire,
    lunchMinutes: dayOff ? 0 : lunchMinutes,
  );
}

/// "Cambio de turno": between 1 and 7 days, today or later.
class ShiftChangeForm {
  const ShiftChangeForm({required this.days, required this.reason, required this.today});

  final List<ShiftDayDraft> days;
  final String reason;

  /// Today in the branch, to reject past days.
  final DateTime today;

  FormErrors validate() {
    final errors = <String, String>{};
    if (days.isEmpty || days.length > 7) errors['days'] = 'Propón entre 1 y 7 días.';
    final seen = <DateTime>{};
    final firstDay = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final key = DateTime(d.date.year, d.date.month, d.date.day);
      if (!seen.add(key)) errors['day$i'] = 'Este día está repetido.';
      if (key.isBefore(firstDay)) errors['day$i'] = 'Los cambios de turno son para hoy o días futuros.';
      if (!d.dayOff) {
        if (d.start == null || d.end == null) {
          errors['day$i'] = 'Escribe la entrada y la salida, o marca el día como libre.';
        } else if (d.end!.compareTo(d.start!) <= 0) {
          errors['day$i'] = 'La salida debe ser después de la entrada.';
        } else if (d.lunchMinutes < 0 || d.lunchMinutes >= d.end!.totalMinutes - d.start!.totalMinutes) {
          errors['day$i'] = 'El almuerzo no puede ocupar todo el turno.';
        }
      }
    }
    final reasonError = _reasonError(reason);
    if (reasonError != null) errors['reason'] = reasonError;
    return errors;
  }
}
