import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../workday/domain/day_projection.dart';
import '../../workday/presentation/start_workday_view.dart';
import '../../workday/presentation/widgets/workday_widgets.dart';
import '../../workday/presentation/workday_commands.dart';

/// Readable name of an app of the MobiControl profile (`com.microsoft.outlook` → `Outlook`).
String appLabel(String app) {
  final raw = app.contains('.') && !app.contains(' ') ? app.split('.').last : app;
  if (raw.isEmpty) return app;
  return raw[0].toUpperCase() + raw.substring(1);
}

/// Dark bar of the managed device: "Dispositivo compartido · sesión de …" / "En jornada · …".
class KioskBar extends StatelessWidget {
  const KioskBar({super.key, required this.label, this.open = false});

  final String label;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Container(
      color: c.ink,
      padding: const EdgeInsets.symmetric(horizontal: kScreenPadding, vertical: 10),
      child: Row(
        children: [
          Icon(open ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Administrado por MobiControl',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.borderInput),
          ),
        ],
      ),
    );
  }
}

/// "Kiosco fuera de jornada": device with app control and workday not started. The corporate
/// apps stay locked until the workday starts; then the server asks MobiControl to enable them.
class KioskView extends ConsumerStatefulWidget {
  const KioskView({super.key, required this.day});

  final DayView day;

  @override
  ConsumerState<KioskView> createState() => _KioskViewState();
}

class _KioskViewState extends ConsumerState<KioskView> {
  bool _sending = false;

  Future<void> _start() async {
    setState(() => _sending = true);
    try {
      final handle = await ref.read(workdayCommandsProvider).startWorkday();
      if (!mounted) return;
      // A 403 `device.unreachable` (MobiControl does not answer) comes back as a rejection.
      await reportCommand(
        ScaffoldMessenger.of(context),
        handle,
        accepted: 'MobiControl aplicó el perfil «En jornada».',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final day = widget.day;
    final today = day.today;
    final device = today.device;
    final (initials, name) = memberIdentity(day);
    final firstName = name.split(' ').first;
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();
    final gate = StartGate.evaluate(day, now);
    final early = !gate.allowed && today.window != null && now.isBefore(today.window!.opensAt);
    final date = Fmt.dateOnly(today.date) ?? now.toLocal();
    final apps = device.corporateApps.isEmpty
        ? const ['Correo', 'Órdenes de trabajo', 'Inventario', 'Chat del equipo']
        : device.corporateApps.map(appLabel).toList();
    final always = device.alwaysAvailableApps.isEmpty
        ? 'Teléfono para emergencias y WorkLog'
        : device.alwaysAvailableApps.map(appLabel).join(', ');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KioskBar(
              label: device.isShared
                  ? 'Dispositivo compartido · sesión de $name'
                  : 'Fuera de jornada · solo WorkLog y teléfono',
            ),
            BrandHeader(initials: initials, name: name, onAvatar: () => context.push(Routes.profile)),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Hola${firstName.isEmpty ? '' : ', $firstName'}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              Fmt.longDate(date),
                              if (today.plan.start != null)
                                'Turno ${Fmt.timeOnly(today.plan.start)} – ${Fmt.timeOnly(today.plan.end)}',
                            ].join(' · '),
                            style: TextStyle(fontSize: 15, color: c.inkMuted),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Apps de trabajo',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                                      ),
                                    ),
                                    StatusChip(
                                      label: _sending ? 'Habilitando' : 'Bloqueadas',
                                      background: c.surfaceMuted,
                                      foreground: c.inkStrong,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                  children: [for (var i = 0; i < apps.length; i++) _LockedApp(name: apps[i], index: i)],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Se habilitan cuando inicias tu jornada. Fuera de tu turno el dispositivo solo muestra WorkLog y el teléfono.',
                                  style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: c.successBg, shape: BoxShape.circle),
                                  child: Icon(Icons.phone_outlined, size: 18, color: c.successFg),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Siempre disponibles',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(always, style: TextStyle(fontSize: 13, color: c.inkMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 16),
                          if (_sending) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                'Habilitando tus apps de trabajo…',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: c.inkStrong),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          PrimaryButton(
                            label: 'Iniciar jornada',
                            height: 64,
                            fontSize: 18,
                            loading: _sending,
                            mutedWhenDisabled: true,
                            onPressed: gate.allowed ? _start : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gate.allowed
                                ? 'Al iniciar, WorkLog pide a MobiControl que habilite tus apps de trabajo.'
                                : gate.reason ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                          ),
                          if (early)
                            TertiaryButton(
                              label: 'Pedir autorización al supervisor',
                              onPressed: () => context.push(Routes.shiftChangeRequest),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedApp extends StatelessWidget {
  const _LockedApp({required this.name, required this.index});

  final String name;
  final int index;

  static const _colors = [Color(0xFF3C3C3B), Color(0xFF751326), Color(0xFF5A5958), Color(0xFFAF1839)];

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Semantics(
      label: '$name, bloqueada',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 0.45,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _colors[index % _colors.length],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 15 / 12, color: c.inkStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
