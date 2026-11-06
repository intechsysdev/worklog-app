import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../demo/presentation/demo_widgets.dart';
import '../../onboarding/data/device_info.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../requests/data/request_models.dart';
import '../../requests/presentation/requests_controller.dart';
import '../../sync/presentation/sync_controller.dart';
import '../../workday/presentation/widgets/workday_widgets.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/profile_api.dart';

/// "Mi perfil y ajustes".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(syncControllerProvider);
    final count = pending.pendingEvents.length + pending.pendingFiles.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: Text(
          count == 0
              ? 'Tendrás que ingresar de nuevo para registrar tu jornada.'
              : 'Tienes $count registros sin enviar. Si cierras sesión se borran del teléfono y no llegarán al servidor. Conéctate y sincroniza antes de salir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.wl.primaryDark),
            child: Text(count == 0 ? 'Cerrar sesión' : 'Cerrar sesión igual'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authControllerProvider.notifier).signOut();
  }

  void _help(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ayuda y soporte'),
      content: const Text(
        'Si algo no funciona en el teléfono (permisos, GPS, conexión), comunícate con soporte TI. Si un registro quedó mal, habla con tu supervisor.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wl;
    final config = ref.watch(appConfigProvider);
    final me = ref.watch(profileProvider).value;
    final day = ref.watch(dayViewProvider).value;
    final device = ref.watch(deviceInfoProvider).value;
    final sync = ref.watch(syncControllerProvider);
    final onboarding = ref.watch(onboardingProvider);
    final session = ref.watch(authRepositoryProvider).session;

    final name = me?.fullName ?? day?.today.memberName ?? session?.displayName ?? session?.email ?? '';
    final role = [me?.roleName ?? 'Usuario móvil', ?(me?.branchName ?? day?.today.branchName)].join(' · ');
    final plan = day?.today.plan;
    final pending = sync.pendingEvents.length + sync.pendingFiles.length;
    final policyVersion = onboarding.policy?.version ?? me?.policyVersion;
    final pendingRequests =
        ref.watch(requestsControllerProvider).value?.where((r) => r.status == RequestStatus.pending).length ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 20, kScreenPadding, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Mi perfil',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                    ),
                  ),
                  if (context.canPop())
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close_rounded, color: c.ink),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AvatarButton(initials: name.isEmpty ? '?' : Fmt.initials(name), onTap: null, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(role, style: TextStyle(fontSize: 13, color: c.inkStrong)),
                              if ((me?.supervisorName ?? day?.today.supervisorName) != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Supervisor: ${me?.supervisorName ?? day!.today.supervisorName}',
                                  style: TextStyle(fontSize: 13, color: c.inkMuted),
                                ),
                              ],
                              if (session?.tenantName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Empresa: ${session!.tenantName}',
                                  style: TextStyle(fontSize: 13, color: c.inkMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    label: 'Mi horario',
                    title: plan?.start != null
                        ? '${plan!.templateName ?? plan.label ?? 'Turno'} · ${Fmt.timeOnly(plan.start)} – ${Fmt.timeOnly(plan.end)}'
                        : 'Hoy sin turno',
                    subtitle: plan?.start != null
                        ? [
                            if (plan!.lunchMinutes > 0) 'Almuerzo ${Fmt.minutes(plan.lunchMinutes)}',
                            if (plan.scheduledMinutes > 0) '${Fmt.minutes(plan.scheduledMinutes)} programadas hoy',
                          ].join(' · ')
                        : (day?.today.nextShift == null
                              ? null
                              : 'Próximo turno: ${Fmt.longDate(Fmt.dateOnly(day!.today.nextShift!.date)!)}'),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    label: 'Mi dispositivo',
                    title:
                        me?.deviceModel ??
                        day?.today.device.deviceModel ??
                        (device == null ? 'Dispositivo' : '${device.model} · ${device.os}'),
                    subtitle: day?.today.device.controlEnabled ?? false
                        ? 'Administrado por SOTI MobiControl · ${day!.today.device.isShared ? 'dispositivo compartido' : 'asignado a ti'}'
                        : 'Administrado por SOTI MobiControl',
                    action: LinkButton(
                      label: 'Ver revisión del dispositivo',
                      onPressed: () => context.push(Routes.deviceReview),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _MenuRow(
                          title: 'Mis solicitudes',
                          trailing: pendingRequests == 0
                              ? null
                              : _badge(c, pendingRequests == 1 ? '1 pendiente' : '$pendingRequests pendientes'),
                          onTap: () => context.push(Routes.requests),
                        ),
                        _MenuRow(title: 'Mi semana', onTap: () => context.push(Routes.week)),
                        _MenuRow(
                          title: 'Sincronización',
                          trailing: Text(
                            pending == 0 ? 'Todo enviado' : '$pending pendientes',
                            style: TextStyle(fontSize: 13, color: pending == 0 ? c.successFg : c.warningFg),
                          ),
                          onTap: () => context.push(Routes.pending),
                        ),
                        _MenuRow(
                          title: 'Política de datos',
                          trailing: Text(
                            onboarding.policyAccepted ? 'v${policyVersion ?? '1.0'} aceptada' : 'Pendiente',
                            style: TextStyle(fontSize: 13, color: c.inkMuted),
                          ),
                          onTap: () => context.push(Routes.policyView),
                        ),
                        _MenuRow(title: 'Ayuda y soporte', last: !config.isDevelopment, onTap: () => _help(context)),
                        if (config.isDevelopment) ...[
                          _MenuRow(title: 'Vista previa: kiosco', onTap: () => context.push(Routes.kiosk)),
                          _MenuRow(
                            title: 'Vista previa: aviso de fin de turno',
                            last: true,
                            onTap: () => context.push(Routes.shiftEndNotice),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (config.isMock) ...[const SizedBox(height: 14), const DemoPanel()],
                  const SizedBox(height: 20),
                  SecondaryButton(
                    label: 'Cerrar sesión',
                    foreground: c.primary,
                    onPressed: () => _signOut(context, ref),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WorkLog ${config.appVersion} · INTECHSYS ONE${config.isDevelopment ? ' · modo desarrollo' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.inkMuted),
                  ),
                ],
              ),
            ),
            AppBottomNav(current: null, onSelect: (tab) => onNavTab(context, ref, tab)),
          ],
        ),
      ),
    );
  }

  static Widget _badge(WlColors c, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(AppRadii.pill)),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.warningFg),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.title, this.subtitle, this.action});

  final String label;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(fontSize: 13, color: c.inkMuted)),
          ],
          ?action,
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, required this.onTap, this.trailing, this.last = false});

  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, color: c.ink)),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
            Icon(Icons.chevron_right_rounded, size: 20, color: c.iconSubtle),
          ],
        ),
      ),
    );
  }
}
