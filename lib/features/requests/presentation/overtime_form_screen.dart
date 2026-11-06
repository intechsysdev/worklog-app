import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/requests_api.dart';
import '../domain/request_forms.dart';
import 'request_form_scaffold.dart';

/// "Horas extra": date, range and (optional) Mintrabajo authorization number.
class OvertimeFormScreen extends ConsumerStatefulWidget {
  const OvertimeFormScreen({super.key});

  @override
  ConsumerState<OvertimeFormScreen> createState() => _OvertimeFormScreenState();
}

class _OvertimeFormScreenState extends ConsumerState<OvertimeFormScreen> {
  final _reason = TextEditingController();
  final _authorization = TextEditingController();
  DateTime? _date;
  HourMinute? _from;
  HourMinute? _to;
  FormErrors _errors = const {};

  @override
  void initState() {
    super.initState();
    final now = ref.read(serverClockProvider).now().toLocal();
    _date = DateTime(now.year, now.month, now.day);
    // By default the extra hours start when the shift ends.
    final end = ref.read(dayViewProvider).value?.today.plan.end;
    _from = HourMinute.tryParse(end);
    if (_from != null && _from!.hour < 22) _to = HourMinute(_from!.hour + 1, _from!.minute);
  }

  @override
  void dispose() {
    _reason.dispose();
    _authorization.dispose();
    super.dispose();
  }

  OvertimeForm get _form => OvertimeForm(
    date: _date,
    from: _from,
    to: _to,
    authorizationReference: _authorization.text,
    reason: _reason.text,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final minutes = _form.minutes;
    return RequestFormScaffold(
      title: 'Horas extra',
      intro:
          'Pide autorización para trabajar después de tu turno. Si se aprueba, el cierre automático se corre hasta su fin.',
      onSubmit: () async {
        final form = _form;
        final errors = form.validate();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) return null;
        final auth = _authorization.text.trim();
        return ref
            .read(requestsApiProvider)
            .submitOvertime(
              date: Fmt.isoDate(form.date!),
              from: form.from!.wire,
              to: form.to!.wire,
              authorizationReference: auth.isEmpty ? null : auth,
              reason: _reason.text.trim(),
            );
      },
      children: [
        PickerField(
          label: 'Fecha',
          value: _date == null ? null : Fmt.longDate(_date!),
          icon: Icons.calendar_today_outlined,
          errorText: _errors['date'],
          onTap: () async {
            final picked = await pickDate(context, _date ?? DateTime.now());
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PickerField(
                label: 'Desde',
                value: _from?.label,
                placeholder: 'HH:mm',
                errorText: _errors['from'],
                onTap: () async {
                  final picked = await pickTime(context, _from);
                  if (picked != null) setState(() => _from = picked);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PickerField(
                label: 'Hasta',
                value: _to?.label,
                placeholder: 'HH:mm',
                errorText: _errors['to'],
                onTap: () async {
                  final picked = await pickTime(context, _to ?? _from);
                  if (picked != null) setState(() => _to = picked);
                },
              ),
            ),
          ],
        ),
        if (minutes > 0) ...[
          const SizedBox(height: 8),
          Text('Total: ${Fmt.minutes(minutes)}', style: TextStyle(fontSize: 13, color: c.inkMuted)),
        ],
        const SizedBox(height: 14),
        LabeledTextField(
          controller: _authorization,
          label: 'Autorización de Mintrabajo',
          labelHint: '(opcional)',
          hint: 'N.º de resolución',
          maxLength: 100,
          errorText: _errors['authorization'],
        ),
        const SizedBox(height: 14),
        AppTextArea(
          controller: _reason,
          label: 'Motivo',
          optional: false,
          hint: 'Ej.: cierre de obra en Bodega Sur.',
          errorText: _errors['reason'],
        ),
      ],
    );
  }
}
