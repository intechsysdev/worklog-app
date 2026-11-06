import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Small key-value store on SQLite for caches (`today`, catalog) and preferences.
abstract interface class KvStore {
  Future<String?> get(String key);
  Future<void> set(String key, String? value);
}

extension KvStoreJson on KvStore {
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic>? value) => set(key, value == null ? null : jsonEncode(value));

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final raw = await get(key);
    return raw == null ? fallback : raw == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());

  Future<DateTime?> getDate(String key) async {
    final raw = await get(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setDate(String key, DateTime? value) => set(key, value?.toUtc().toIso8601String());
}

/// Keys used by the app.
abstract final class KvKeys {
  static const today = 'cache.today';
  static const todayReceivedAt = 'cache.today.receivedAt';
  static const clockOffsetMs = 'clock.offsetMs';
  static const activityOptions = 'cache.activityOptions';
  static const timelinePrefix = 'cache.timeline.';
  static const profile = 'cache.me';
  static const policyAcceptedVersion = 'policy.acceptedVersion';
  static const deviceReviewed = 'device.reviewed';
  static const allowMobileData = 'sync.allowMobileData';
  static const lastSyncAt = 'sync.lastSyncAt';
  static const lastSyncError = 'sync.lastError';
  static const offlineSince = 'sync.offlineSince';
}

class SqliteKvStore implements KvStore {
  SqliteKvStore(this._db);

  final Database _db;

  @override
  Future<String?> get(String key) async {
    final rows = await _db.query('kv', columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await _db.delete('kv', where: 'key = ?', whereArgs: [key]);
    } else {
      await _db.insert('kv', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

class MemoryKvStore implements KvStore {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

final kvStoreProvider = Provider<KvStore>((ref) => SqliteKvStore(ref.watch(appDatabaseProvider).db));
