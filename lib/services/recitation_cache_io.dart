/// File-backed recitation cache for VM platforms.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'recitation_cache.dart';

/// Application-support directory cache, or [root] in tests.
class FileRecitationCache implements RecitationCache {
  FileRecitationCache({Directory? root}) : _rootOverride = root;

  final Directory? _rootOverride;
  Future<String>? _basePathFuture;

  Future<String> _basePath() {
    final override = _rootOverride;
    if (override != null) return Future.value(override.path);
    return _basePathFuture ??= getApplicationSupportDirectory().then(
      (dir) => '${dir.path}/recitation',
    );
  }

  Future<Directory> _surahDir(
    String reciterId,
    int surahId, {
    required bool create,
  }) async {
    final dir = Directory(
      '${await _basePath()}/$reciterId/${surahId.toString().padLeft(3, '0')}',
    );
    if (create && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _file(Directory dir, int ayah) {
    return File('${dir.path}/${ayah.toString().padLeft(3, '0')}.mp3');
  }

  @override
  Future<String?> pathIfPresent({
    required String reciterId,
    required int surahId,
    required int ayah,
  }) async {
    final dir = await _surahDir(reciterId, surahId, create: false);
    if (!await dir.exists()) return null;
    final file = _file(dir, ayah);
    if (await file.exists()) return file.path;
    return null;
  }

  @override
  Future<void> write({
    required String reciterId,
    required int surahId,
    required int ayah,
    required List<int> bytes,
  }) async {
    final file = _file(await _surahDir(reciterId, surahId, create: true), ayah);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<void> deleteSurah({
    required String reciterId,
    required int surahId,
  }) async {
    final dir = await _surahDir(reciterId, surahId, create: false);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<Set<int>> downloadedAyahs({
    required String reciterId,
    required int surahId,
  }) async {
    final dir = await _surahDir(reciterId, surahId, create: false);
    if (!await dir.exists()) return {};
    final ayahs = <int>{};
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.mp3')) continue;
      final value = int.tryParse(name.substring(0, name.length - 4));
      if (value != null) ayahs.add(value);
    }
    return ayahs;
  }
}

/// Returns a file cache under the app support directory.
RecitationCache createPlatformRecitationCache() => FileRecitationCache();
