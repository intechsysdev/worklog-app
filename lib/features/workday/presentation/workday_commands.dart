import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/location/location_service.dart';
import '../../sync/data/models/sync_models.dart';
import '../../sync/data/sync_providers.dart';
import '../../sync/domain/queued_event.dart';
import '../../sync/domain/queued_file.dart';
import '../../sync/presentation/sync_controller.dart';
import '../data/evidence_storage.dart';
import '../data/models/activity_options_dto.dart';
import '../data/models/enums.dart';
import '../domain/day_projection.dart';

/// What the user picked in "Nueva actividad".
class ActivityChoice {
  const ActivityChoice({
    required this.activityTypeId,
    required this.title,
    this.workOrderId,
    this.workOrderNumber,
    this.siteName,
    this.catalog,
  });

  factory ActivityChoice.assigned(AssignedOptionDto order, CatalogOptionDto? catalog) => ActivityChoice(
    activityTypeId: order.activityTypeId,
    title: order.title,
    workOrderId: order.workOrderId,
    workOrderNumber: order.number,
    siteName: order.siteName,
    catalog: catalog,
  );

  factory ActivityChoice.catalog(CatalogOptionDto catalog) =>
      ActivityChoice(activityTypeId: catalog.activityTypeId, title: catalog.title, catalog: catalog);

  final String activityTypeId;
  final String title;
  final String? workOrderId;
  final String? workOrderNumber;
  final String? siteName;
  final CatalogOptionDto? catalog;
}

/// A photo taken in "Finalizar actividad".
class CapturedPhoto {
  const CapturedPhoto({required this.path, required this.capturedAt});

  final String path;
  final DateTime capturedAt;
}

/// Result of a user action: always saved on the phone; [result] is the server answer when it
/// arrived in time.
class CommandResult {
  const CommandResult({required this.clientEventId, this.result});

  final String clientEventId;
  final SyncEventResultDto? result;

  bool get rejected => result?.outcome == SyncOutcome.rejected;
  bool get adjusted => result?.outcome == SyncOutcome.adjusted;

  /// Still in the queue (no connection or slow server).
  bool get queued => result == null;
}

/// Returned as soon as the action is saved on the phone (the UI already shows it); [answer]
/// completes when the server answers or after [WorkdayCommands.answerTimeout].
class CommandHandle {
  const CommandHandle(this.clientEventId, this.answer);

  final String clientEventId;
  final Future<CommandResult> answer;
}

/// User actions on the workday. Each one is written to the local queue first (with its own
/// UUID and the real time, corrected with the server delta), the optimistic state updates at
/// once and the sync starts in the background.
class WorkdayCommands {
  WorkdayCommands(this._ref);

  static const _uuid = Uuid();

  /// How long an action waits for the server answer before reporting "saved on the phone".
  static const answerTimeout = Duration(seconds: 8);

  final Ref _ref;

  DateTime _now() => _ref.read(serverClockProvider).now();

  Future<LocationFix?> captureLocation({Duration timeout = const Duration(seconds: 6)}) =>
      _ref.read(locationServiceProvider).current(timeout: timeout);

  Future<CommandHandle> startWorkday({LocationFix? location}) async {
    final fix = location ?? await captureLocation();
    return _submit(
      SyncEventDto(
        clientEventId: _uuid.v7(),
        kind: SyncEventKind.workdayStart,
        occurredAt: _now(),
        workdayId: _uuid.v7(),
        location: fix?.toInput(),
      ),
      const EventMeta(),
    );
  }

  Future<CommandHandle> startActivity(ActivityChoice choice, {LocationFix? location}) async {
    final fix = location ?? await captureLocation();
    final catalog = choice.catalog;
    return _submit(
      SyncEventDto(
        clientEventId: _uuid.v7(),
        kind: SyncEventKind.activityStart,
        occurredAt: _now(),
        activityId: _uuid.v7(),
        activityTypeId: choice.activityTypeId,
        workOrderId: choice.workOrderId,
        location: fix?.toInput(),
      ),
      EventMeta(
        activityName: choice.title,
        activityColor: catalog?.color,
        timeClass: switch (catalog?.timeClass) {
          TimeClass.productive => 'Productive',
          TimeClass.paidNonProductive => 'PaidNonProductive',
          TimeClass.unproductive => 'Unproductive',
          null => null,
        },
        workOrderNumber: choice.workOrderNumber,
        siteName: choice.siteName,
        requiresPhoto: catalog?.requiresPhoto ?? false,
        requiresSignature: catalog?.requiresSignature ?? false,
        observationAlways: catalog?.observation == ObservationPolicy.always,
      ),
    );
  }

  Future<CommandHandle> pause(ActivityView activity) => _activityEvent(SyncEventKind.activityPause, activity);

  Future<CommandHandle> resume(ActivityView activity) => _activityEvent(SyncEventKind.activityResume, activity);

  Future<CommandHandle> _activityEvent(String kind, ActivityView activity) async {
    final fix = await captureLocation(timeout: const Duration(seconds: 4));
    return _submit(
      SyncEventDto(
        clientEventId: _uuid.v7(),
        kind: kind,
        occurredAt: _now(),
        activityId: activity.id,
        location: fix?.toInput(),
      ),
      EventMeta(activityName: activity.name, workOrderNumber: activity.workOrderNumber),
    );
  }

  Future<CommandHandle> finishActivity({
    required ActivityView activity,
    required ActivityOutcome outcome,
    required String outcomeLabel,
    String? observation,
    List<CapturedPhoto> photos = const [],
    Uint8List? signaturePng,
    DateTime? signedAt,
    LocationFix? location,
  }) async {
    final storage = _ref.read(evidenceStorageProvider);
    final files = _ref.read(fileQueueStoreProvider);
    final createdAt = DateTime.now().toUtc();

    // Files first: if the app dies right after, the event is not lost and neither are the photos.
    for (var i = 0; i < photos.length; i++) {
      final clientId = _uuid.v7();
      final (path, size) = await storage.keepPhoto(photos[i].path, clientId);
      await files.enqueue(
        QueuedFile(
          clientId: clientId,
          activityId: activity.id,
          kind: EvidenceKind.photo,
          path: path,
          contentType: path.endsWith('.png') ? 'image/png' : 'image/jpeg',
          sizeBytes: size,
          capturedAt: photos[i].capturedAt.toUtc(),
          label: 'Foto ${i + 1} de ${photos.length}',
          status: FileStatus.pending,
          createdAt: createdAt,
        ),
      );
    }
    if (signaturePng != null) {
      final clientId = _uuid.v7();
      final (path, size) = await storage.keepSignature(signaturePng, clientId);
      await files.enqueue(
        QueuedFile(
          clientId: clientId,
          activityId: activity.id,
          kind: EvidenceKind.signature,
          path: path,
          contentType: 'image/png',
          sizeBytes: size,
          capturedAt: (signedAt ?? _now()).toUtc(),
          label: 'Firma del cliente',
          status: FileStatus.pending,
          createdAt: createdAt,
        ),
      );
    }

    final text = observation?.trim();
    return _submit(
      SyncEventDto(
        clientEventId: _uuid.v7(),
        kind: SyncEventKind.activityFinish,
        occurredAt: _now(),
        activityId: activity.id,
        outcome: outcome,
        observation: text == null || text.isEmpty ? null : text,
        photoCount: photos.length,
        hasSignature: signaturePng != null,
        location: location?.toInput(),
      ),
      EventMeta(activityName: activity.name, workOrderNumber: activity.workOrderNumber, outcomeLabel: outcomeLabel),
    );
  }

  Future<CommandHandle> closeWorkday({String? note, LocationFix? location}) {
    final text = note?.trim();
    return _submit(
      SyncEventDto(
        clientEventId: _uuid.v7(),
        kind: SyncEventKind.workdayClose,
        occurredAt: _now(),
        note: text == null || text.isEmpty ? null : text,
        location: location?.toInput(),
      ),
      const EventMeta(),
    );
  }

  Future<CommandHandle> _submit(SyncEventDto event, EventMeta meta) async {
    await _ref.read(eventQueueStoreProvider).enqueue(event, meta);
    final sync = _ref.read(syncControllerProvider.notifier);
    await sync.reload();
    return CommandHandle(event.clientEventId, _answer(sync, event.clientEventId));
  }

  Future<CommandResult> _answer(SyncController sync, String clientEventId) async {
    try {
      final report = await sync.run().timeout(answerTimeout);
      return CommandResult(clientEventId: clientEventId, result: report.resultFor(clientEventId));
    } on TimeoutException {
      return CommandResult(clientEventId: clientEventId);
    }
  }
}

final workdayCommandsProvider = Provider<WorkdayCommands>(WorkdayCommands.new);
