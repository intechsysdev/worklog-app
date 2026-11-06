import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'mock_backend.dart';

/// Saves the demo state in a JSON file of the app folder (it survives restarts and the sign
/// out, which wipes the SQLite database).
class FileMockStore implements MockStore {
  Future<File> _file() async => File(p.join((await getApplicationSupportDirectory()).path, 'worklog_demo.json'));

  @override
  Future<String?> load() async {
    final file = await _file();
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> save(String json) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}

/// Dio adapter that answers on the phone with [MockBackend], so the demo APK works without any
/// server. With "Simular sin conexión" it fails like a phone without signal.
class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._backend, {this.latency = const Duration(milliseconds: 250)});

  final MockBackend _backend;
  final Duration latency;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (_backend.offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'Modo demostración: sin conexión simulada.');
    }

    final response = _backend.handle(
      options.method.toUpperCase(),
      options.uri.path,
      query: options.uri.queryParameters,
      body: _body(options.data),
    );
    final text = response.body == null ? '' : jsonEncode(response.body);
    return ResponseBody.fromString(
      text,
      response.status,
      headers: {
        Headers.contentTypeHeader: [response.status >= 400 ? 'application/problem+json' : Headers.jsonContentType],
      },
    );
  }

  static Object? _body(Object? data) {
    if (data is FormData) {
      return {for (final f in data.fields) f.key: f.value, for (final f in data.files) 'size': f.value.length};
    }
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    return data;
  }

  @override
  void close({bool force = false}) {}
}
