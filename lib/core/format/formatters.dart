/// Spanish formatting helpers used across the UI. Kept dependency-free so they behave the same
/// in tests and on any device locale.
abstract final class Fmt {
  static const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// `Jueves 29 de octubre`.
  static String longDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    return '${_capitalize(weekday)} ${date.day} de ${_months[date.month - 1]}';
  }

  /// `29 oct`.
  static String shortDate(DateTime date) => '${date.day} ${_months[date.month - 1].substring(0, 3)}';

  /// `jueves`.
  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

  /// `07:03` in local time.
  static String time(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// `07:00` from an API TimeOnly (`07:00:00`).
  static String timeOnly(String? value) {
    if (value == null || value.length < 5) return '--:--';
    return value.substring(0, 5);
  }

  /// `01:23:45` stopwatch.
  static String stopwatch(Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  /// `1 h 28 m`, `7 m`, `2 h`, `0 m`.
  static String minutes(int totalMinutes) {
    final total = totalMinutes < 0 ? 0 : totalMinutes;
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '$m m';
    if (m == 0) return '$h h';
    return '$h h $m m';
  }

  static String duration(Duration d) => minutes(d.inMinutes);

  /// `1,8 MB`, `120 KB`.
  static String fileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    final kb = (bytes / 1024).ceil();
    return '$kb KB';
  }

  /// `6 m` accuracy.
  static String meters(double? value) => value == null ? '—' : '${value.round()} m';

  /// `AM` from `Andrés Mora`.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// `Buenos días`, `Buenas tardes`, `Buenas noches`.
  static String greeting(DateTime now) {
    final hour = now.toLocal().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  /// `Lunes a viernes` from day letters `LMXJV`.
  static String dayLetters(String? letters) {
    if (letters == null || letters.isEmpty) return '';
    const names = {
      'L': 'lunes',
      'M': 'martes',
      'X': 'miércoles',
      'J': 'jueves',
      'V': 'viernes',
      'S': 'sábado',
      'D': 'domingo',
    };
    const order = 'LMXJVSD';
    if (letters == 'LMXJV') return 'Lunes a viernes';
    if (letters == 'LMXJVS') return 'Lunes a sábado';
    if (letters == order) return 'Todos los días';
    final list = letters.split('').where(names.containsKey).map((l) => names[l]!).toList();
    if (list.isEmpty) return '';
    final text = list.length == 1 ? list.first : '${list.sublist(0, list.length - 1).join(', ')} y ${list.last}';
    return _capitalize(text);
  }

  /// Parses an API DateOnly (`yyyy-MM-dd`) as a local calendar date.
  static DateTime? dateOnly(String? value) {
    if (value == null) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// `yyyy-MM-dd`.
  static String isoDate(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
