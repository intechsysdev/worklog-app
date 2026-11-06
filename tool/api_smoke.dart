// Smoke test of the app's data layer against a running WorkLog API (development auth).
//
//   dart run tool/api_smoke.dart http://localhost:5290 tecnico@intechsys.dev <tenantId>
//
// Uses the same models and `WorkdayApi` as the app: accepts the policy, syncs a full day
// (start, activity, pause, resume, finish, close), resends the batch to check idempotency,
// uploads a signature and a location sample, and reads the timeline.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_mobile/features/requests/data/request_models.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/domain/queued_file.dart';
import 'package:worklog_mobile/features/week/data/week_models.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';
import 'package:worklog_mobile/features/workday/data/workday_api.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    print('Uso: dart run tool/api_smoke.dart <apiUrl> <correo> <tenantId>');
    exit(64);
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: '${args[0]}/api/v1',
      headers: {'Authorization': 'Bearer dev:${args[1]}', 'X-Tenant-Id': args[2], 'X-Client': 'mobile'},
    ),
  );
  final api = WorkdayApi(dio);

  final policy = (await dio.get<Map<String, dynamic>>('/me/privacy-policy')).data!;
  if (policy['accepted'] != true) {
    await dio.post<void>('/me/privacy-policy/accept', data: {'version': policy['version']});
    print('Política ${policy['version']} aceptada');
  }

  final today = await api.today();
  print('today: ${today.plan.kind.name} ${today.plan.start}-${today.plan.end}, workday=${today.workday?.status.name}');
  final options = await api.activityOptions();
  print(
    'options: ${options.assigned.length} OT, ${options.catalog.length} catálogo, ${options.outcomes.length} resultados',
  );

  if (today.workday != null) {
    print('La jornada de hoy ya existe (${today.workday!.status.name}): se omite el ciclo del día.');
  } else {
    await _day(api, today.date, options.catalog.first.activityTypeId, options.catalog.first.requiresPhoto);
  }
  await _phase2(dio);
}

Future<void> _day(WorkdayApi api, String date, String activityTypeId, bool requiresPhoto) async {
  const uuid = Uuid();
  final now = DateTime.now().toUtc();
  final location = LocationInputDto(latitude: 4.7110, longitude: -74.0721, accuracy: 8, capturedAt: now);
  final workdayId = uuid.v7();
  final activityId = uuid.v7();
  SyncEventDto event(String kind, int second, {Map<String, Object?> extra = const {}}) => SyncEventDto(
    clientEventId: uuid.v7(),
    kind: kind,
    occurredAt: now.add(Duration(seconds: second)),
    workdayId: kind == SyncEventKind.workdayStart ? workdayId : null,
    activityId: kind.startsWith('activity.') ? activityId : null,
    activityTypeId: kind == SyncEventKind.activityStart ? activityTypeId : null,
    outcome: extra['outcome'] as ActivityOutcome?,
    observation: extra['observation'] as String?,
    photoCount: extra['photoCount'] as int?,
    hasSignature: extra['hasSignature'] as bool?,
    location: location,
  );

  final batch = [
    event(SyncEventKind.workdayStart, 0),
    event(SyncEventKind.activityStart, 1),
    event(SyncEventKind.activityPause, 2),
    event(SyncEventKind.activityResume, 3),
    event(
      SyncEventKind.activityFinish,
      4,
      extra: {
        'outcome': ActivityOutcome.completed,
        'photoCount': requiresPhoto ? 1 : 0,
        'hasSignature': true,
        'observation': 'Prueba de humo de la app',
      },
    ),
  ];
  print('payload: ${jsonEncode(batch.first.toJson())}');

  var result = await api.sync(batch);
  for (final r in result.results) {
    print('  ${r.clientEventId.substring(0, 8)} ${r.outcome.name} ${r.code ?? ''} ${r.message ?? ''}');
  }
  print(
    'today tras sync: workday=${result.today?.workday?.status.name}, actividades=${result.today?.workday?.summary.activityCount}',
  );

  result = await api.sync(batch);
  print('reintento idempotente: ${result.results.map((r) => r.outcome.name).join(', ')}');

  final png = File('${Directory.systemTemp.path}/wl_signature.png')
    ..writeAsBytesSync(
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='),
    );
  final file = QueuedFile(
    clientId: uuid.v7(),
    activityId: activityId,
    kind: EvidenceKind.signature,
    path: png.path,
    contentType: 'image/png',
    sizeBytes: png.lengthSync(),
    capturedAt: now,
    label: 'Firma del cliente',
    status: FileStatus.pending,
    createdAt: now,
  );
  await api.uploadEvidence(file);
  await api.uploadEvidence(file);
  print('evidencia subida dos veces con el mismo clientId (idempotente)');

  print('puntos guardados: ${await api.sendLocations([location])}');

  final close = await api.sync([
    SyncEventDto(
      clientEventId: uuid.v7(),
      kind: SyncEventKind.workdayClose,
      occurredAt: now.add(const Duration(seconds: 6)),
      note: 'Cierre desde la prueba',
      location: location,
    ),
  ]);
  print('cierre: ${close.results.single.outcome.name} → ${close.today?.workday?.status.name}');

  final timeline = await api.timeline(date);
  print('timeline: ${timeline.segments.length} segmentos, ${timeline.entries.map((e) => e.kind).join(' > ')}');
}

/// Phase 2: today.device / autoCloseAt, week and the three requests (sent and cancelled).
Future<void> _phase2(Dio dio) async {
  final today = (await dio.get<Map<String, dynamic>>('/me/today')).data!;
  final parsed = TodayDto.fromJson(today);
  print(
    'device: control=${parsed.device.controlEnabled}, compartido=${parsed.device.isShared}, '
    'avisos=${parsed.device.warningMinutes}, autoCloseAt=${parsed.autoCloseAt}, supervisor=${parsed.supervisorName}',
  );
  print('categorías: ${parsed.workday?.summary.byCategory.map((c) => '${c.name} ${c.minutes} m').join(', ')}');

  final week = MyWeekDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/me/week', queryParameters: {'date': parsed.date})).data!,
  );
  print(
    'semana ${week.from}..${week.to}: ${week.workedMinutes} de ${week.weeklyCapMinutes} min, '
    '${week.days.length} días, provisional hasta ${week.provisionalUntil}',
  );

  final created = <RequestDto>[];
  Future<void> submit(String label, String path, Map<String, dynamic> body) async {
    try {
      final r = RequestDto.fromJson((await dio.post<Map<String, dynamic>>(path, data: body)).data!);
      created.add(r);
      print('$label: ${r.status.label} · ${r.title} · ${r.detail}');
    } on DioException catch (e) {
      print('$label rechazada: ${e.response?.statusCode} ${e.response?.data}');
    }
  }

  final workday = parsed.workday;
  if (workday != null) {
    await submit('ajuste', '/me/requests/adjustment', {
      'workdayId': workday.id,
      'target': AdjustmentTarget.workdayStart.wire,
      'proposedValue': workday.startedAt.subtract(const Duration(minutes: 7)).toUtc().toIso8601String(),
      'reason': 'Prueba de humo: llegué antes',
    });
  }
  await submit('horas extra', '/me/requests/overtime', {
    'date': parsed.date,
    'from': '15:00:00',
    'to': '16:30:00',
    'reason': 'Prueba de humo: cierre de obra',
  });
  final tomorrow = DateTime.parse(parsed.date).add(const Duration(days: 1));
  final date =
      '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  await submit('cambio de turno', '/me/requests/shift-change', {
    'days': [
      const ShiftChangeDayDto(date: '', start: '08:00:00', end: '17:00:00', lunchMinutes: 60).toJson()..['date'] = date,
    ],
    'reason': 'Prueba de humo: cita médica',
  });

  final list = RequestPageDto.fromJson((await dio.get<Map<String, dynamic>>('/me/requests')).data!);
  print(
    'mis solicitudes: ${list.items.length} (${list.items.where((r) => r.status == RequestStatus.pending).length} pendientes)',
  );
  for (final r in created) {
    final cancelled = RequestDto.fromJson((await dio.post<Map<String, dynamic>>('/me/requests/${r.id}/cancel')).data!);
    print('cancelada: ${cancelled.type.label} → ${cancelled.status.label}');
  }
}
