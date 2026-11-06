import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../workday/data/models/today_dto.dart';
import '../../workday/presentation/workday_providers.dart';
import '../domain/alert_schedule.dart';

/// Texts of the shift end notice, by device kind (AvisoCierre.dc.html).
class ShiftEndTexts {
  ShiftEndTexts(this.today, this.minutes);

  final TodayDto today;

  /// Minutes left to the automatic close; 0 once it happened.
  final int minutes;

  DeviceStatusDto get device => today.device;
  bool get shared => device.controlEnabled && device.isShared;
  bool get controlled => device.controlEnabled;
  bool get done => minutes <= 0;

  DateTime? get close => autoCloseOf(today);

  String get shiftEnd {
    final overtime = today.overtimeUntil;
    if (overtime != null) return Fmt.timeOnly(overtime);
    final end = today.window?.shiftEnd;
    return end == null ? '—' : Fmt.time(end);
  }

  String get title {
    if (done) {
      if (!controlled) return 'Jornada cerrada automáticamente';
      return shared ? 'Sesión cerrada' : 'Apps de trabajo ocultas';
    }
    if (!controlled) return 'Tu jornada se cerrará en $minutes min';
    return shared ? 'Tu sesión se cerrará en $minutes min' : 'Tus apps se ocultarán en $minutes min';
  }

  String get subtitle => today.overtimeUntil != null
      ? 'Tus horas extra aprobadas terminan a las $shiftEnd'
      : 'Tu turno termina a las $shiftEnd';

  String get body {
    if (done) {
      const pending = 'Tu jornada quedó pendiente de cierre para que tu supervisor la revise.';
      if (!controlled) return '$pending Si saliste a otra hora, solicita un ajuste.';
      return shared
          ? '$pending El dispositivo vuelve a la pantalla de ingreso de Shared Device.'
          : '$pending El dispositivo volvió al kiosco «Fuera de jornada».';
    }
    final what = !controlled
        ? 'se cerrarán la actividad abierta y la jornada'
        : shared
        ? 'tu sesión en este dispositivo se cerrará'
        : 'tus apps de trabajo se ocultarán';
    final grace = today.settings.autoCloseGraceMinutes;
    final at = close == null ? '' : 'A las ${Fmt.time(close!)}';
    return '$at${grace > 0 ? ', después de los $grace minutos de gracia' : ''}, $what. '
        'Guarda tu trabajo y cierra tu jornada para registrar la hora real de salida.';
  }

  String get foot => done
      ? (controlled ? 'MobiControl aplicó el cambio. Queda en Auditoría.' : 'El cierre automático queda en Auditoría.')
      : 'Aviso enviado por WorkLog${controlled ? ' y por MobiControl' : ''}. '
            'Si tienes horas extra autorizadas, el cierre se corre hasta su fin.';
}

/// Round badge with the minutes left (amber at 15, soft red at 5 or less, grey when closed).
class NoticeBadge extends StatelessWidget {
  const NoticeBadge({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final (bg, fg) = minutes <= 0
        ? (c.surfaceMuted, c.inkStrong)
        : minutes <= 5
        ? (c.pinkSoft, c.primaryDark)
        : (c.warningBg, c.warningFg);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        minutes <= 0 ? '✓' : '$minutes',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/// "Aviso de fin de turno": bottom sheet over the current activity.
class ShiftEndNoticeSheet extends ConsumerWidget {
  const ShiftEndNoticeSheet({super.key, required this.minutes, this.embedded = false});

  final int minutes;

  /// Rendered as a page (preview) instead of a modal sheet.
  final bool embedded;

  static Future<void> show(BuildContext context, {required int minutes}) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ShiftEndNoticeSheet(minutes: minutes),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final today = ref.watch(dayViewProvider).value?.today;
    if (today == null) return const SizedBox.shrink();
    final t = ShiftEndTexts(today, minutes);

    void leave(String route) {
      final router = GoRouter.of(context);
      if (!embedded) Navigator.of(context).pop();
      router.push(route);
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: t.title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kScreenPadding, 12, kScreenPadding, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!embedded)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: c.borderInput, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            Row(
              children: [
                NoticeBadge(minutes: minutes),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 26 / 21, color: c.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(t.subtitle, style: TextStyle(fontSize: 14, color: c.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t.body,
              style: TextStyle(fontSize: 15, height: 22 / 15, color: c.inkStrong),
            ),
            const SizedBox(height: 14),
            if (!t.done) ...[
              PrimaryButton(
                label: 'Cerrar jornada ahora',
                radius: AppRadii.button,
                onPressed: () => leave(Routes.closeWorkday),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Pedir horas extra al supervisor',
                fontSize: 16,
                foreground: c.inkStrong,
                onPressed: () => leave(Routes.overtimeRequest),
              ),
              TertiaryButton(
                label: 'Entendido, seguir trabajando',
                height: 44,
                onPressed: () => embedded ? Navigator.of(context).maybePop() : Navigator.of(context).pop(),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              t.foot,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 17 / 12, color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// State of a workday the server closed automatically (PendingReview): "Sesión cerrada" /
/// "Apps de trabajo ocultas".
class AutoClosedCard extends StatelessWidget {
  const AutoClosedCard({super.key, required this.today});

  final TodayDto today;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final t = ShiftEndTexts(today, 0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NoticeBadge(minutes: 0),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.body,
            style: TextStyle(fontSize: 14, height: 20 / 14, color: c.inkStrong),
          ),
          const SizedBox(height: 8),
          Text(t.foot, style: TextStyle(fontSize: 12, color: c.inkMuted)),
        ],
      ),
    );
  }
}
