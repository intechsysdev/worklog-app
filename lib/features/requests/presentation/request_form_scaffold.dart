import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../data/request_models.dart';
import '../domain/request_forms.dart';
import 'requests_controller.dart';
import 'requests_screen.dart';

/// Common frame of the three request forms: header, scrollable body, server error and the
/// "Enviar solicitud" button. Submitting is online; without network a clear message is shown.
class RequestFormScaffold extends ConsumerStatefulWidget {
  const RequestFormScaffold({
    super.key,
    required this.title,
    required this.intro,
    required this.children,
    required this.onSubmit,
  });

  final String title;
  final String intro;
  final List<Widget> children;

  /// Validates and sends. Returns null when the local validation failed (errors on screen).
  final Future<RequestDto?> Function() onSubmit;

  @override
  ConsumerState<RequestFormScaffold> createState() => _RequestFormScaffoldState();
}

class _RequestFormScaffoldState extends ConsumerState<RequestFormScaffold> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await widget.onSubmit();
      if (created == null || !mounted) return;
      ref.read(requestsControllerProvider.notifier).added(created);
      showMessage(context, 'Solicitud enviada. Tu supervisor la revisará.');
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(Routes.requests);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.isNetwork ? requestsOfflineMessage : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackHeader(title: widget.title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  Text(widget.intro, style: c.textTheme.bodyMedium?.copyWith(height: 20 / 14)),
                  const SizedBox(height: 16),
                  ...widget.children,
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    InfoBanner(icon: Icons.error_outline, child: Text(_error!)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 16),
              child: PrimaryButton(
                label: 'Enviar solicitud',
                icon: Icons.send_rounded,
                loading: _busy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the system time picker in 24 h format.
Future<HourMinute?> pickTime(BuildContext context, HourMinute? initial) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial?.hour ?? 7, minute: initial?.minute ?? 0),
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
  return picked == null ? null : HourMinute(picked.hour, picked.minute);
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial, {DateTime? first, DateTime? last}) => showDatePicker(
  context: context,
  initialDate: initial,
  firstDate: first ?? initial.subtract(const Duration(days: 60)),
  lastDate: last ?? initial.add(const Duration(days: 90)),
);

String dateLabel(DateTime? date) => date == null ? 'Elegir fecha' : Fmt.longDate(date);
