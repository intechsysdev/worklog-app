import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/clock/server_clock.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/headers.dart';
import '../../data/models/enums.dart';
import '../../data/models/today_dto.dart';
import '../../domain/day_projection.dart';
import '../workday_commands.dart';
import '../workday_providers.dart';

/// Text that re-renders every second with the server time.
class ServerTimeText extends ConsumerWidget {
  const ServerTimeText({super.key, required this.builder, this.style, this.textAlign});

  final String Function(DateTime now) builder;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();
    return Text(builder(now), style: style, textAlign: textAlign);
  }
}

/// Waits for the server answer of an action and shows it. The messenger is captured before
/// navigating, so the message survives the screen change.
Future<CommandResult> reportCommand(ScaffoldMessengerState messenger, CommandHandle handle, {String? accepted}) async {
  final result = await handle.answer;
  final r = result.result;
  final String? message;
  if (result.queued) {
    message = 'Sin conexión con el servidor: quedó guardado en el teléfono y se enviará solo.';
  } else if (result.rejected) {
    message = r?.message ?? 'El servidor rechazó el registro.';
  } else if (result.adjusted) {
    message = r?.message ?? 'El servidor ajustó el registro.';
  } else {
    message = accepted;
  }
  if (message != null && messenger.mounted) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: result.rejected ? 8 : 4),
        ),
      );
  }
  return result;
}

/// Bottom navigation behaviour: "Jornada" opens "Cerrar jornada" while the workday is open and
/// "Inicio de jornada" otherwise.
void onNavTab(BuildContext context, WidgetRef ref, NavTab tab) {
  switch (tab) {
    case NavTab.activity:
      context.go(Routes.home);
    case NavTab.history:
      context.go(Routes.history);
    case NavTab.workday:
      final mode = ref.read(dayViewProvider).value?.mode;
      if (mode == HomeMode.active) {
        context.push(Routes.closeWorkday);
      } else {
        context.go(Routes.home);
      }
  }
}

/// Initials and display name of the signed-in technician.
(String initials, String name) memberIdentity(DayView? day) {
  final name = day?.today.memberName ?? '';
  return (name.isEmpty ? '?' : Fmt.initials(name), name);
}

/// A slice of the day for the bars and legends.
class TimePart {
  const TimePart(this.label, this.minutes, this.color);

  final String label;
  final int minutes;
  final Color color;
}

/// Minutes per category (`summary.byCategory`), plus "Sin actividad" (unproductive categories
/// and gaps). Without the per-category data, falls back to Productivo / Traslado.
List<TimePart> categoryParts(DaySummaryDto s, WlColors c) {
  final parts = s.byCategory.isNotEmpty
      ? [
          for (final cat in s.byCategory)
            if (cat.timeClass != TimeClass.unproductive && cat.minutes > 0)
              TimePart(cat.name, cat.minutes, parseHexColor(cat.color)),
        ]
      : [
          TimePart('Productivo', s.productiveMinutes, c.primary),
          if (s.paidNonProductiveMinutes > 0) TimePart('Traslado', s.paidNonProductiveMinutes, c.travel),
        ];
  if (parts.isEmpty) parts.add(TimePart('Productivo', 0, c.primary));
  return [...parts, TimePart('Sin actividad', s.withoutActivityMinutes, c.idle)];
}

/// Three tiles of "Resumen del día".
class DaySummaryTiles extends StatelessWidget {
  const DaySummaryTiles({super.key, required this.workday});

  final WorkdayView workday;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final s = workday.summary;
    Widget tile(String value, String label, {Color? color, double size = 20}) => Expanded(
      child: AppCard(
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color ?? c.ink),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: c.inkMuted)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Resumen del día'),
        const SizedBox(height: 10),
        Row(
          children: [
            tile('${s.activityCount}', 'Actividades'),
            const SizedBox(width: 10),
            tile(Fmt.minutes(s.productiveMinutes), 'Productivo', size: 19),
            const SizedBox(width: 10),
            tile(Fmt.minutes(s.withoutActivityMinutes), 'Sin actividad', color: c.warningFg),
          ],
        ),
      ],
    );
  }
}
