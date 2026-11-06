import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database: the offline queue (events, files, location samples) and a small
/// key-value store for caches and preferences.
class AppDatabase {
  AppDatabase(this.db);

  static const fileName = 'worklog.db';
  static const version = 1;

  final Database db;

  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final location = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    final db = await dbFactory.openDatabase(
      location,
      options: OpenDatabaseOptions(version: version, onCreate: (db, _) => createSchema(db)),
    );
    return AppDatabase(db);
  }

  static Future<void> createSchema(Database db) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE events (
          seq INTEGER PRIMARY KEY AUTOINCREMENT,
          client_event_id TEXT NOT NULL UNIQUE,
          kind TEXT NOT NULL,
          occurred_at TEXT NOT NULL,
          payload TEXT NOT NULL,
          meta TEXT NOT NULL,
          status TEXT NOT NULL,
          code TEXT,
          message TEXT,
          result_id TEXT,
          attempts INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          synced_at TEXT
        )''')
      ..execute('CREATE INDEX ix_events_status ON events(status, seq)')
      ..execute('''
        CREATE TABLE files (
          client_id TEXT PRIMARY KEY,
          activity_id TEXT NOT NULL,
          kind TEXT NOT NULL,
          path TEXT NOT NULL,
          content_type TEXT NOT NULL,
          size_bytes INTEGER NOT NULL,
          captured_at TEXT NOT NULL,
          label TEXT NOT NULL,
          status TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          last_error TEXT,
          created_at TEXT NOT NULL,
          uploaded_at TEXT
        )''')
      ..execute('''
        CREATE TABLE location_samples (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL
        )''')
      ..execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await batch.commit(noResult: true);
  }

  /// Removes everything (sign out).
  Future<void> wipe() async {
    final batch = db.batch()
      ..delete('events')
      ..delete('files')
      ..delete('location_samples')
      ..delete('kv');
    await batch.commit(noResult: true);
  }

  Future<void> close() => db.close();
}

/// Opened in `main` and injected with an override.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden after opening the database.'),
);
