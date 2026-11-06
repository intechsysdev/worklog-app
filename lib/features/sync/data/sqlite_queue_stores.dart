import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../workday/data/models/enums.dart';
import '../domain/queue_stores.dart';
import '../domain/queued_event.dart';
import '../domain/queued_file.dart';
import 'models/sync_models.dart';

String _iso(DateTime value) => value.toUtc().toIso8601String();

class SqliteEventQueueStore implements EventQueueStore {
  SqliteEventQueueStore(this._db);

  final Database _db;

  @override
  Future<QueuedEvent> enqueue(SyncEventDto event, EventMeta meta, {DateTime? now}) async {
    final createdAt = (now ?? DateTime.now()).toUtc();
    await _db.insert('events', {
      'client_event_id': event.clientEventId,
      'kind': event.kind,
      'occurred_at': _iso(event.occurredAt),
      'payload': jsonEncode(event.toJson()),
      'meta': jsonEncode(meta.toJson()),
      'status': QueueStatus.pending.name,
      'attempts': 0,
      'created_at': _iso(createdAt),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final rows = await _db.query('events', where: 'client_event_id = ?', whereArgs: [event.clientEventId]);
    return _map(rows.single);
  }

  @override
  Future<List<QueuedEvent>> pending({int? limit}) async {
    final rows = await _db.query(
      'events',
      where: 'status = ?',
      whereArgs: [QueueStatus.pending.name],
      orderBy: 'seq ASC',
      limit: limit,
    );
    return rows.map(_map).toList();
  }

  @override
  Future<List<QueuedEvent>> reviewed({int limit = 20}) async {
    final rows = await _db.query(
      'events',
      where: 'status IN (?, ?)',
      whereArgs: [QueueStatus.rejected.name, QueueStatus.adjusted.name],
      orderBy: 'seq DESC',
      limit: limit,
    );
    return rows.map(_map).toList();
  }

  @override
  Future<int> pendingCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS n FROM events WHERE status = ?', [QueueStatus.pending.name]);
    return (result.first['n'] as int?) ?? 0;
  }

  @override
  Future<void> markResult(
    String clientEventId,
    QueueStatus status, {
    String? code,
    String? message,
    String? resultId,
    required DateTime at,
  }) => _db.update(
    'events',
    {'status': status.name, 'code': code, 'message': message, 'result_id': resultId, 'synced_at': _iso(at)},
    where: 'client_event_id = ?',
    whereArgs: [clientEventId],
  );

  @override
  Future<void> markAttempt(List<String> clientEventIds) async {
    if (clientEventIds.isEmpty) return;
    final placeholders = List.filled(clientEventIds.length, '?').join(', ');
    await _db.rawUpdate(
      'UPDATE events SET attempts = attempts + 1 WHERE client_event_id IN ($placeholders)',
      clientEventIds,
    );
  }

  @override
  Future<bool> hasPendingFor(String activityId) async {
    final rows = await _db.query(
      'events',
      columns: ['seq'],
      where: 'status = ? AND payload LIKE ?',
      whereArgs: [QueueStatus.pending.name, '%"activityId":"$activityId"%'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<QueuedEvent>> startedActivities({DateTime? since}) async {
    final rows = await _db.query(
      'events',
      where: 'kind = ? AND status != ?${since == null ? '' : ' AND occurred_at >= ?'}',
      whereArgs: [SyncEventKind.activityStart, QueueStatus.rejected.name, if (since != null) _iso(since)],
      orderBy: 'seq ASC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<void> purgeConfirmed(DateTime before) => _db.delete(
    'events',
    where: 'status IN (?, ?) AND created_at < ?',
    whereArgs: [QueueStatus.accepted.name, QueueStatus.adjusted.name, _iso(before)],
  );

  QueuedEvent _map(Map<String, Object?> row) => QueuedEvent(
    seq: row['seq']! as int,
    event: SyncEventDto.fromJson(jsonDecode(row['payload']! as String) as Map<String, dynamic>),
    meta: EventMeta.fromJson(jsonDecode(row['meta']! as String) as Map<String, dynamic>),
    status: QueueStatus.parse(row['status']! as String),
    code: row['code'] as String?,
    message: row['message'] as String?,
    resultId: row['result_id'] as String?,
    attempts: row['attempts'] as int? ?? 0,
    createdAt: DateTime.parse(row['created_at']! as String),
    syncedAt: row['synced_at'] == null ? null : DateTime.parse(row['synced_at']! as String),
  );
}

class SqliteFileQueueStore implements FileQueueStore {
  SqliteFileQueueStore(this._db);

  final Database _db;

  @override
  Future<void> enqueue(QueuedFile file) => _db.insert('files', {
    'client_id': file.clientId,
    'activity_id': file.activityId,
    'kind': file.kind.wire,
    'path': file.path,
    'content_type': file.contentType,
    'size_bytes': file.sizeBytes,
    'captured_at': _iso(file.capturedAt),
    'label': file.label,
    'status': file.status.name,
    'attempts': file.attempts,
    'created_at': _iso(file.createdAt),
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  @override
  Future<List<QueuedFile>> pending() async {
    final rows = await _db.query(
      'files',
      where: 'status = ?',
      whereArgs: [FileStatus.pending.name],
      orderBy: 'created_at ASC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<List<QueuedFile>> failed({int limit = 20}) async {
    final rows = await _db.query(
      'files',
      where: 'status = ?',
      whereArgs: [FileStatus.failed.name],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_map).toList();
  }

  @override
  Future<int> pendingCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS n FROM files WHERE status = ?', [FileStatus.pending.name]);
    return (result.first['n'] as int?) ?? 0;
  }

  @override
  Future<void> markUploaded(String clientId, DateTime at) => _db.update(
    'files',
    {'status': FileStatus.uploaded.name, 'uploaded_at': _iso(at), 'last_error': null},
    where: 'client_id = ?',
    whereArgs: [clientId],
  );

  @override
  Future<void> markAttempt(String clientId, String? error) =>
      _db.rawUpdate('UPDATE files SET attempts = attempts + 1, last_error = ? WHERE client_id = ?', [error, clientId]);

  @override
  Future<void> markFailed(String clientId, String error) => _db.update(
    'files',
    {'status': FileStatus.failed.name, 'last_error': error},
    where: 'client_id = ?',
    whereArgs: [clientId],
  );

  QueuedFile _map(Map<String, Object?> row) => QueuedFile(
    clientId: row['client_id']! as String,
    activityId: row['activity_id']! as String,
    kind: row['kind'] == 'Signature' ? EvidenceKind.signature : EvidenceKind.photo,
    path: row['path']! as String,
    contentType: row['content_type']! as String,
    sizeBytes: row['size_bytes']! as int,
    capturedAt: DateTime.parse(row['captured_at']! as String),
    label: row['label']! as String,
    status: FileStatus.parse(row['status']! as String),
    attempts: row['attempts'] as int? ?? 0,
    lastError: row['last_error'] as String?,
    createdAt: DateTime.parse(row['created_at']! as String),
  );
}

class SqliteLocationSampleStore implements LocationSampleStore {
  SqliteLocationSampleStore(this._db);

  final Database _db;

  @override
  Future<void> add(LocationInputDto sample) =>
      _db.insert('location_samples', {'payload': jsonEncode(sample.toJson()), 'created_at': _iso(DateTime.now())});

  @override
  Future<List<(int, LocationInputDto)>> take(int limit) async {
    final rows = await _db.query('location_samples', orderBy: 'id ASC', limit: limit);
    return rows
        .map(
          (r) =>
              (r['id']! as int, LocationInputDto.fromJson(jsonDecode(r['payload']! as String) as Map<String, dynamic>)),
        )
        .toList();
  }

  @override
  Future<void> delete(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await _db.rawDelete('DELETE FROM location_samples WHERE id IN ($placeholders)', ids);
  }

  @override
  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS n FROM location_samples');
    return (result.first['n'] as int?) ?? 0;
  }
}
