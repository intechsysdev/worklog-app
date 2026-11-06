import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklog_mobile/core/network/api_exception.dart';
import 'package:worklog_mobile/core/storage/app_database.dart';
import 'package:worklog_mobile/features/sync/data/models/sync_models.dart';
import 'package:worklog_mobile/features/sync/domain/queued_file.dart';
import 'package:worklog_mobile/features/sync/domain/sync_ports.dart';
import 'package:worklog_mobile/features/workday/data/models/enums.dart';
import 'package:worklog_mobile/features/workday/data/models/today_dto.dart';

/// In-memory SQLite database with the app schema.
Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
}

TodayDto sampleToday({
  DateTime? serverTime,
  DayKind kind = DayKind.shift,
  WorkdayDto? workday,
  StartWindowDto? window,
}) {
  final now = serverTime ?? DateTime.utc(2026, 10, 29, 12, 2);
  return TodayDto(
    serverTime: now,
    date: '2026-10-29',
    timeZoneId: 'America/Bogota',
    memberName: 'Andrés Mora',
    branchName: 'Sede Bogotá Norte',
    plan: DayPlanDto(
      kind: kind,
      start: kind.isWorkingDay ? '07:00:00' : null,
      end: kind.isWorkingDay ? '16:00:00' : null,
      lunchMinutes: 60,
      scheduledMinutes: 480,
      label: kind.isWorkingDay ? 'Campo L-V' : 'Vacaciones',
      templateName: 'Campo L-V',
      dayLetters: 'LMXJV',
    ),
    window:
        window ??
        (kind.isWorkingDay
            ? StartWindowDto(
                opensAt: DateTime.utc(2026, 10, 29, 11, 45),
                shiftStart: DateTime.utc(2026, 10, 29, 12),
                shiftEnd: DateTime.utc(2026, 10, 29, 21),
                canStartNow: true,
              )
            : null),
    workday: workday,
    policy: const PolicyStatusDto(currentVersion: '1.0', accepted: true, effectiveFrom: '2026-01-01'),
    settings: const ClientSettingsDto(),
  );
}

/// Scriptable fake of the server side of the sync.
class FakeSyncApi implements SyncApi {
  final List<List<SyncEventDto>> batches = [];
  final List<QueuedFile> uploads = [];
  final List<List<LocationInputDto>> locationBatches = [];

  /// Errors thrown by the next calls to [sync], in order.
  final List<Object> failNext = [];

  /// Outcome per clientEventId; accepted when absent.
  final Map<String, SyncEventResultDto> scripted = {};

  /// Ids the server "already processed": a retry answers the same outcome without new effects.
  final Map<String, SyncEventResultDto> processed = {};

  /// How many times each event produced an effect on the "server".
  final Map<String, int> effects = {};

  Object? uploadError;
  TodayDto? today;

  /// The server applies the batch but the answer never reaches the phone.
  bool loseNextResponse = false;

  /// Runs while a batch is "in flight", to simulate actions during a sync.
  Future<void> Function()? duringSync;

  @override
  Future<SyncBatchResultDto> sync(List<SyncEventDto> events) async {
    batches.add(List.of(events));
    if (failNext.isNotEmpty) throw failNext.removeAt(0);
    final hook = duringSync;
    duringSync = null;
    if (hook != null) await hook();
    if (loseNextResponse) {
      loseNextResponse = false;
      await _apply(events);
      throw networkDown;
    }
    return _apply(events);
  }

  Future<SyncBatchResultDto> _apply(List<SyncEventDto> events) async {
    final results = <SyncEventResultDto>[];
    for (final e in events) {
      final previous = processed[e.clientEventId];
      if (previous != null) {
        results.add(previous);
        continue;
      }
      final result =
          scripted[e.clientEventId] ??
          SyncEventResultDto(
            clientEventId: e.clientEventId,
            outcome: SyncOutcome.accepted,
            resultId: e.activityId ?? e.workdayId,
          );
      processed[e.clientEventId] = result;
      if (result.outcome != SyncOutcome.rejected) effects[e.clientEventId] = (effects[e.clientEventId] ?? 0) + 1;
      results.add(result);
    }
    return SyncBatchResultDto(results: results, today: today);
  }

  @override
  Future<int> sendLocations(List<LocationInputDto> samples) async {
    locationBatches.add(samples);
    return samples.length;
  }

  @override
  Future<void> uploadEvidence(QueuedFile file) async {
    if (uploadError != null) throw uploadError!;
    uploads.add(file);
  }
}

const networkDown = ApiException(message: 'Sin conexión', isNetwork: true);
