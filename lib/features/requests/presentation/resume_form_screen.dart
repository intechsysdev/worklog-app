import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/common.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/requests_api.dart';
import '../domain/request_forms.dart';
import 'request_form_scaffold.dart';

/// "Reinicio de actividades": the workday of today is closed and the user needs to keep working.
/// When the supervisor approves it, "Reanudar jornada" appears on the closed day.
class ResumeFormScreen extends ConsumerStatefulWidget {
  const ResumeFormScreen({super.key});

  @override
  ConsumerState<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends ConsumerState<ResumeFormScreen> {
  final _reason = TextEditingController();
  FormErrors _errors = const {};

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RequestFormScaffold(
      title: 'Reinicio de actividades',
      intro:
          'Pide volver a trabajar hoy después de haber cerrado la jornada. Cuando tu supervisor lo apruebe '
          'podrás reanudarla desde aquí; el tiempo que estuvo cerrada no cuenta como trabajado.',
      onSubmit: () async {
        final errors = ResumeForm(reason: _reason.text).validate();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) return null;
        final created = await ref.read(requestsApiProvider).submitResume(reason: _reason.text.trim());
        // The closed day shows "solicitud enviada" at once.
        await ref.read(todayControllerProvider.notifier).refresh();
        return created;
      },
      children: [
        AppTextArea(
          controller: _reason,
          label: 'Motivo',
          optional: false,
          hint: 'Ej.: cerré por error y debo terminar la visita.',
          errorText: _errors['reason'],
        ),
      ],
    );
  }
}
