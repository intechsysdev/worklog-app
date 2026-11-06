import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../requests/presentation/adjustment_form_screen.dart';
import '../domain/queued_event.dart';
import '../domain/queued_file.dart';
import 'sync_controller.dart';

/// "Pendiente de sincronizar": queue, server rejections, mobile data toggle and retry.
class PendingSyncScreen extends ConsumerStatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  ConsumerState<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends ConsumerState<PendingSyncScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncControllerProvider.notifier).reload());
  }

  Future<void> _retry() async {
    final report = await ref.read(syncControllerProvider.notifier).run();
    if (!mounted) return;
    showMessage(
      context,
      report.delivered
          ? (report.sent == 0 ? 'Todo está sincronizado.' : 'Se enviaron ${report.sent} registros.')
          : report.error!.message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final status = ref.watch(syncControllerProvider);
    final events = status.pendingEvents;
    final files = status.pendingFiles;
    final offline = !status.network.isOnline || status.offlineSince != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Pendiente de sincronizar'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  if (offline)
                    InfoBanner(
                      icon: Icons.cloud_off_outlined,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      radius: AppRadii.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.offlineSince != null
                                ? 'Sin conexión desde las ${Fmt.time(status.offlineSince!)}'
                                : 'Sin conexión',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tu trabajo está guardado en el teléfono. Se enviará solo cuando vuelva la señal.',
                          ),
                        ],
                      ),
                    )
                  else if (status.allSent)
                    const InfoBanner(
                      tone: BannerTone.success,
                      icon: Icons.check_circle_outline,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      radius: AppRadii.card,
                      child: Text('Todo enviado. No hay registros pendientes.'),
                    ),
                  const SizedBox(height: 14),
                  SectionLabel(_queueTitle(events.length, files.length)),
                  const SizedBox(height: 10),
                  if (events.isEmpty && files.isEmpty)
                    Text('No hay nada en cola.', style: TextStyle(fontSize: 14, color: c.inkMuted))
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final e in events)
                            _QueueRow(
                              time: Fmt.time(e.event.occurredAt),
                              title: e.title,
                              meta: e.subtitle,
                              state: e.attempts > 0 ? 'Reintentando' : 'En cola',
                            ),
                          for (final f in files)
                            _QueueRow(
                              time: Fmt.time(f.capturedAt),
                              title: f.label,
                              meta: [Fmt.fileSize(f.sizeBytes), ?f.lastError].join(' · '),
                              state: status.fileWaitsForWifi(f) ? 'Espera wifi' : 'En cola',
                            ),
                        ].withSeparators(c.divider),
                      ),
                    ),
                  for (final e in status.reviewed) ...[const SizedBox(height: 14), _ReviewedCard(event: e)],
                  for (final f in status.failedFiles) ...[const SizedBox(height: 14), _FailedFileCard(file: f)],
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    radius: AppRadii.button,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subir archivos con datos móviles',
                              style: TextStyle(fontSize: 14, color: c.ink),
                            ),
                          ),
                          Switch(
                            value: status.allowMobileData,
                            onChanged: (v) => ref.read(syncControllerProvider.notifier).setAllowMobileData(v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 16),
              child: Column(
                children: [
                  Text(
                    status.lastSyncAt == null
                        ? 'Aún no se ha sincronizado.'
                        : 'Última sincronización: ${_relativeDay(status.lastSyncAt!)} ${Fmt.time(status.lastSyncAt!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.inkMuted),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Reintentar ahora',
                    icon: Icons.refresh_rounded,
                    height: 56,
                    fontSize: 17,
                    foreground: c.primary,
                    borderColor: c.primary,
                    loading: status.syncing,
                    onPressed: _retry,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _queueTitle(int events, int files) {
    String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    return 'En cola · ${plural(events, 'evento', 'eventos')} y ${plural(files, 'archivo', 'archivos')}';
  }

  static String _relativeDay(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) return 'hoy';
    return Fmt.shortDate(local);
  }
}

extension on List<Widget> {
  List<Widget> withSeparators(Color color) => [
    for (var i = 0; i < length; i++) ...[if (i > 0) Divider(height: 1, color: color), this[i]],
  ];
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.time, required this.title, required this.meta, required this.state});

  final String time;
  final String title;
  final String meta;
  final String state;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.inkStrong,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta, style: TextStyle(fontSize: 12, color: c.inkMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ReviewedCard extends StatelessWidget {
  const _ReviewedCard({required this.event});

  final QueuedEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final rejected = event.status == QueueStatus.rejected;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: rejected ? c.primary : c.warningDot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            rejected ? 'Rechazado por el servidor' : 'Ajustado por el servidor',
            color: rejected ? c.primary : c.warningFg,
          ),
          const SizedBox(height: 6),
          Text(
            '${Fmt.time(event.event.occurredAt)} · ${event.title}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
          ),
          if (event.message != null) ...[
            const SizedBox(height: 6),
            Text(
              event.message!,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkStrong),
            ),
          ],
          const SizedBox(height: 2),
          LinkButton(
            label: 'Solicitar ajuste',
            onPressed: () => context.push(Routes.adjustmentRequest, extra: prefillForRejected(event)),
          ),
        ],
      ),
    );
  }
}

class _FailedFileCard extends StatelessWidget {
  const _FailedFileCard({required this.file});

  final QueuedFile file;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: c.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Archivo no enviado', color: c.primary),
          const SizedBox(height: 6),
          Text(
            '${Fmt.time(file.capturedAt)} · ${file.label}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
          ),
          if (file.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              file.lastError!,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkStrong),
            ),
          ],
        ],
      ),
    );
  }
}
