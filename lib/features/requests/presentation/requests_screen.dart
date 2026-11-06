import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../data/request_models.dart';
import 'requests_controller.dart';

/// "Mis solicitudes": Todas / Pendientes / Resueltas, cancel and "Nueva solicitud".
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  RequestsTab _tab = RequestsTab.all;

  Future<void> _cancel(RequestDto request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la solicitud?'),
        content: Text('${request.type.label} · ${request.title}. Tu supervisor ya no la verá como pendiente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar solicitud')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(requestsControllerProvider.notifier).cancel(request.id);
      if (mounted) showMessage(context, 'Solicitud cancelada.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.isNetwork ? requestsOfflineMessage : e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(requestsControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Mis solicitudes'),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 0),
              child: SegmentedTabs(
                labels: const ['Todas', 'Pendientes', 'Resueltas'],
                index: _tab.index,
                onChanged: (i) => setState(() => _tab = RequestsTab.values[i]),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: requests.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => StateMessage(
                  icon: Icons.cloud_off_outlined,
                  message: ApiException.from(error).isNetwork
                      ? requestsOfflineMessage
                      : ApiException.from(error).message,
                  actionLabel: 'Reintentar',
                  onAction: () => ref.invalidate(requestsControllerProvider),
                ),
                data: (all) => RefreshIndicator(
                  color: context.wl.primary,
                  onRefresh: () => ref.read(requestsControllerProvider.notifier).refresh(),
                  child: RequestList(requests: filterRequests(all, _tab), onCancel: _cancel),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 10, kScreenPadding, 16),
              child: PrimaryButton(
                label: 'Nueva solicitud',
                icon: Icons.add_rounded,
                onPressed: () => showNewRequestSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const requestsOfflineMessage =
    'Sin conexión. Las solicitudes se envían en línea porque tu supervisor y el servidor las validan al momento. Conéctate e inténtalo de nuevo.';

/// Chooser of the three request kinds.
Future<void> showNewRequestSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  builder: (sheet) {
    final c = sheet.wl;
    Widget option(IconData icon, String title, String detail, String route) => ListTile(
      minTileHeight: 64,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.pinkSoft, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: c.primary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
      ),
      subtitle: Text(detail, style: TextStyle(fontSize: 13, color: c.inkMuted)),
      onTap: () {
        Navigator.of(sheet).pop();
        context.push(route);
      },
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Nueva solicitud',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
            ),
          ),
          option(
            Icons.edit_calendar_outlined,
            'Ajuste de registro',
            'Una hora de inicio o fin que quedó mal.',
            Routes.adjustmentRequest,
          ),
          option(Icons.more_time_rounded, 'Horas extra', 'Trabajo después del turno.', Routes.overtimeRequest),
          option(
            Icons.swap_calls_rounded,
            'Cambio de turno',
            'Otro horario o un día libre.',
            Routes.shiftChangeRequest,
          ),
        ],
      ),
    );
  },
);

/// List of request cards (separated for the widget tests).
class RequestList extends StatelessWidget {
  const RequestList({super.key, required this.requests, required this.onCancel});

  final List<RequestDto> requests;
  final ValueChanged<RequestDto> onCancel;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Text(
            'No hay solicitudes aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.wl.inkMuted),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => RequestCard(request: requests[i], onCancel: () => onCancel(requests[i])),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onCancel});

  final RequestDto request;
  final VoidCallback onCancel;

  /// `Enviada hoy 10:05`, `Aprobada por Laura Gómez el 23 oct`, `Rechazada: …`.
  static String metaOf(RequestDto r, DateTime now) {
    final sent = r.submittedAt.toLocal();
    final local = now.toLocal();
    final sameDay = sent.year == local.year && sent.month == local.month && sent.day == local.day;
    final when = sameDay ? 'hoy ${Fmt.time(sent)}' : '${Fmt.shortDate(sent)} ${Fmt.time(sent)}';
    final resolved = r.resolvedAt == null ? '' : ' el ${Fmt.shortDate(r.resolvedAt!.toLocal())}';
    return switch (r.status) {
      RequestStatus.pending => 'Enviada $when',
      RequestStatus.approved => 'Aprobada${r.resolverName == null ? '' : ' por ${r.resolverName}'}$resolved',
      RequestStatus.rejected =>
        r.resolverComment == null || r.resolverComment!.isEmpty
            ? 'Rechazada${r.resolverName == null ? '' : ' por ${r.resolverName}'}$resolved'
            : 'Rechazada: ${r.resolverComment}',
      RequestStatus.cancelled => 'Cancelada por ti$resolved',
      RequestStatus.unknown => 'Enviada $when',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final r = request;
    final (bg, fg, dot) = switch (r.status) {
      RequestStatus.pending => (c.warningBg, c.warningFg, c.warningDot),
      RequestStatus.approved => (c.successBg, c.successFg, c.successDot),
      _ => (c.surfaceMuted, c.inkStrong, c.inkMuted),
    };
    final detail = r.detail.isNotEmpty ? r.detail : r.reason;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(r.type.label)),
              StatusChip(
                label: r.status.label,
                background: bg,
                foreground: fg,
                dot: dot,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: TextStyle(fontSize: 14, color: c.inkStrong)),
          ],
          const SizedBox(height: 6),
          Text(metaOf(r, DateTime.now()), style: TextStyle(fontSize: 13, color: c.inkMuted)),
          if (r.status == RequestStatus.pending) LinkButton(label: 'Cancelar solicitud', onPressed: onCancel),
        ],
      ),
    );
  }
}
