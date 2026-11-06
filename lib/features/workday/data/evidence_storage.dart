import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps photos and signatures in the app folder until they are uploaded (the camera writes to a
/// temporary folder the OS may clean).
class EvidenceStorage {
  EvidenceStorage({Future<Directory> Function()? baseDir}) : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  Future<Directory> _folder() async {
    final dir = Directory(p.join((await _baseDir()).path, 'evidences'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a picked photo. Returns the new path and its size.
  Future<(String, int)> keepPhoto(String sourcePath, String clientId) async {
    final ext = p.extension(sourcePath).toLowerCase() == '.png' ? '.png' : '.jpg';
    final target = p.join((await _folder()).path, '$clientId$ext');
    final copy = await File(sourcePath).copy(target);
    return (copy.path, await copy.length());
  }

  /// Writes the signature PNG.
  Future<(String, int)> keepSignature(Uint8List png, String clientId) async {
    final target = File(p.join((await _folder()).path, '$clientId.png'));
    await target.writeAsBytes(png, flush: true);
    return (target.path, png.length);
  }
}

final evidenceStorageProvider = Provider<EvidenceStorage>((ref) => EvidenceStorage());
