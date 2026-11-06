import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/format/formatters.dart';
import 'package:worklog_mobile/features/requests/data/request_models.dart';
import 'package:worklog_mobile/features/requests/domain/adjustment_options.dart';
import 'package:worklog_mobile/features/requests/domain/request_forms.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/domain/queued_event.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/timeline_dto.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';
import 'package:worklog_mobile/features/workday/domain/day_projection.dart';

void main() {
  group('HourMinute', () {
    test('parses and formats', () {
      expect(HourMinute.tryParse('7:05')!.label, '07:05');
      expect(HourMinute.tryParse('16:00:00')!.wire, '16:00:00');
      expect(HourMinute.tryParse('24:00'), isNull);
      expect(HourMinute.tryParse('aa'), isNull);
    });
  });

  group('AdjustmentForm', () {
    final date = DateTime(2026, 10, 29);

    AdjustmentForm form({
      String? workdayId = 'w1',
      AdjustmentTarget? target = AdjustmentTarget.activityEnd,
      String? activity = 'a1',
      HourMinute? proposed = const HourMinute(9, 55),
      DateTime? original,
      String reason = 'Olvidé finalizar al salir del sitio.',
    }) => AdjustmentForm(
      workdayId: workdayId,
      date: date,
      target: target,
      activityRecordId: activity,
      proposed: proposed,
      original: original,
      reason: reason,
    );

    test('a complete form is valid and proposes the local time of the workday date', () {
      final f = form();
      expect(f.validate(), isEmpty);
      expect(f.proposedValue, DateTime(2026, 10, 29, 9, 55));
    });

    test('activity targets need the activity', () {
      expect(form(activity: null).validate().keys, contains('activity'));
      expect(form(target: AdjustmentTarget.workdayStart, activity: null).validate(), isEmpty);
    });

    test('target, hour, workday and reason are required', () {
      final errors = form(workdayId: null, target: null, proposed: null, reason: 'mal').validate();
      expect(errors.keys, containsAll(['workday', 'target', 'proposed', 'reason']));
    });

    test('the proposed hour must differ from the recorded one', () {
      final errors = form(original: DateTime(2026, 10, 29, 9, 55).toUtc()).validate();
      expect(errors['proposed'], 'La hora propuesta es igual a la registrada.');
    });
  });

  group('OvertimeForm', () {
    test('valid range', () {
      const f = OvertimeForm(
        date: null,
        from: HourMinute(16, 0),
        to: HourMinute(17, 30),
        reason: 'Cierre de obra en Bodega Sur',
      );
      expect(f.minutes, 90);
      expect(f.validate().keys, ['date']);
    });

    test('the end must be after the start', () {
      final f = OvertimeForm(
        date: DateTime(2026, 10, 23),
        from: const HourMinute(17, 0),
        to: const HourMinute(16, 0),
        reason: 'Cierre de obra',
      );
      expect(f.validate()['to'], 'La hora final debe ser posterior a la inicial.');
    });

    test('reason of at least 5 characters and authorization of at most 100', () {
      final f = OvertimeForm(
        date: DateTime(2026, 10, 23),
        from: const HourMinute(16, 0),
        to: const HourMinute(18, 0),
        authorizationReference: 'x' * 101,
        reason: 'ok',
      );
      expect(f.validate().keys, containsAll(['reason', 'authorization']));
    });
  });

  group('ShiftChangeForm', () {
    final today = DateTime(2026, 11, 3);

    test('hours or day off, today or later', () {
      final f = ShiftChangeForm(
        today: today,
        reason: 'Cita médica en la mañana',
        days: [
          ShiftDayDraft(date: today, start: const HourMinute(10, 0), end: const HourMinute(18, 0)),
          ShiftDayDraft(date: today.add(const Duration(days: 1)), dayOff: true),
        ],
      );
      expect(f.validate(), isEmpty);
      final dtos = f.days.map((d) => d.toDto(Fmt.isoDate)).toList();
      expect(dtos.first.toJson(), {'date': '2026-11-03', 'start': '10:00:00', 'end': '18:00:00', 'lunchMinutes': 60});
      expect(dtos.last.toJson(), {'date': '2026-11-04', 'start': null, 'end': null, 'lunchMinutes': 0});
      expect(dtos.last.isDayOff, isTrue);
    });

    test('past, repeated and inverted days are rejected', () {
      final f = ShiftChangeForm(
        today: today,
        reason: 'Cambio',
        days: [
          ShiftDayDraft(date: today.subtract(const Duration(days: 1)), dayOff: true),
          ShiftDayDraft(date: today, start: const HourMinute(18, 0), end: const HourMinute(10, 0)),
          ShiftDayDraft(date: today, start: const HourMinute(7, 0), end: const HourMinute(8, 0), lunchMinutes: 0),
          ShiftDayDraft(date: today.add(const Duration(days: 2))),
        ],
      );
      final errors = f.validate();
      expect(errors['day0'], 'Los cambios de turno son para hoy o días futuros.');
      expect(errors['day1'], 'La salida debe ser después de la entrada.');
      expect(errors['day2'], 'Este día está repetido.');
      expect(errors['day3'], 'Escribe la entrada y la salida, o marca el día como libre.');
    });

    test('between 1 and 7 days', () {
      final none = ShiftChangeForm(today: today, reason: 'Cambio de turno', days: const []);
      expect(none.validate().keys, ['days']);
      final eight = ShiftChangeForm(
        today: today,
        reason: 'Cambio de turno',
        days: [for (var i = 0; i < 8; i++) ShiftDayDraft(date: today.add(Duration(days: i)), dayOff: true)],
      );
      expect(eight.validate().keys, ['days']);
    });
  });

  group('adjustment options', () {
    final start = DateTime.utc(2026, 10, 29, 12, 3);
    final activityStart = DateTime.utc(2026, 10, 29, 13, 12);
    final workday = WorkdayView(
      id: 'w1',
      status: WorkdayStatus.closed,
      startedAt: start,
      endedAt: DateTime.utc(2026, 10, 29, 21),
      summary: const DaySummaryDto(),
    );
    final entries = [
      TimelineEntryDto(
        kind: 'activity',
        title: 'Instalación de equipo',
        start: activityStart,
        end: DateTime.utc(2026, 10, 29, 14, 40),
        color: '#AF1839',
      ),
      TimelineEntryDto(
        kind: 'activity',
        title: 'Registrada en otro teléfono',
        start: DateTime.utc(2026, 10, 29, 16),
        end: DateTime.utc(2026, 10, 29, 17),
        color: '#868787',
      ),
    ];
    final started = [
      QueuedEvent(
        seq: 1,
        event: SyncEventDto(
          clientEventId: 'e1',
          kind: SyncEventKind.activityStart,
          occurredAt: activityStart.add(const Duration(seconds: 20)),
          activityId: 'a1',
        ),
        meta: const EventMeta(activityName: 'Instalación de equipo'),
        status: QueueStatus.accepted,
        createdAt: activityStart,
      ),
    ];

    test('workday start and end plus the activities matched to this phone', () {
      final options = adjustmentOptions(workday: workday, entries: entries, startedActivities: started);
      expect(options.map((o) => o.label), [
        'Inicio de jornada',
        'Fin de jornada',
        'Inicio · Instalación de equipo',
        'Fin · Instalación de equipo',
      ]);
      expect(options[2].activityRecordId, 'a1');
      expect(options[2].target, AdjustmentTarget.activityStart);
      expect(options[3].original, DateTime.utc(2026, 10, 29, 14, 40));
    });

    test('no workday, no options', () {
      expect(adjustmentOptions(workday: null, entries: entries, startedActivities: started), isEmpty);
    });
  });
}
