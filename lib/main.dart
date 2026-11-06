import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/network/http_clients.dart';
import 'core/storage/app_database.dart';
import 'features/demo/data/mock_backend.dart';
import 'features/demo/data/mock_http_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Channel to receive the messages of the foreground service (notification buttons, samples).
  FlutterForegroundTask.initCommunicationPort();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final database = await AppDatabase.open();
  final config = AppConfig.fromEnvironment();
  // Demo APK: the API runs on the phone with mock data that survives restarts.
  final backend = config.isMock ? await MockBackend.load(FileMockStore()) : null;
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        appConfigProvider.overrideWithValue(config),
        mockBackendProvider.overrideWithValue(backend),
      ],
      child: const WorkLogApp(),
    ),
  );
}
