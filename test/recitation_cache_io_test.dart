/// Tests that the file recitation cache does not create folders on read.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/recitation_cache_io.dart';

void main() {
  test('pathIfPresent does not create empty folders', () async {
    final root = await Directory.systemTemp.createTemp('hublee_recitation');
    addTearDown(() => root.delete(recursive: true));
    final cache = FileRecitationCache(root: root);

    expect(
      await cache.pathIfPresent(reciterId: 'alafasy', surahId: 1, ayah: 1),
      isNull,
    );
    expect(root.listSync(), isEmpty);

    await cache.write(
      reciterId: 'alafasy',
      surahId: 1,
      ayah: 1,
      bytes: [1, 2, 3],
    );
    expect(
      await cache.pathIfPresent(reciterId: 'alafasy', surahId: 1, ayah: 1),
      isNotNull,
    );
    expect(await cache.downloadedAyahs(reciterId: 'alafasy', surahId: 1), {1});
  });
}
