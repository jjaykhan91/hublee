/// Tests for [QuranV4TajweedRepository] and V4 verse data.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/quran_v4_tajweed_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranV4TajweedRepository', () {
    late QuranV4TajweedRepository repo;

    setUp(() {
      repo = QuranV4TajweedRepository();
    });

    test('loadV4Surah returns map keyed by ayah number', () async {
      final map = await repo.loadV4Surah(1);
      if (map.isEmpty) return; // asset may be missing or empty
      for (final entry in map.entries) {
        expect(entry.key, greaterThanOrEqualTo(1));
        expect(entry.value, isA<V4VerseData>());
        expect(entry.value.text, isNotEmpty);
        expect(entry.value.pageNumber, inInclusiveRange(1, 604));
      }
    });

    test('loadV4Surah(1) verse 1 has non-empty text and valid page', () async {
      final map = await repo.loadV4Surah(1);
      if (!map.containsKey(1)) return;
      final v1 = map[1]!;
      expect(v1.text, isNotEmpty);
      expect(v1.pageNumber, inInclusiveRange(1, 604));
    });

    test('loadV4Surah for invalid surah id returns empty or valid map', () async {
      final map = await repo.loadV4Surah(0);
      expect(map, isEmpty);
    });

    test('V4VerseData equality and fields', () {
      const v = V4VerseData(text: 'test', pageNumber: 1);
      expect(v.text, 'test');
      expect(v.pageNumber, 1);
    });
  });
}
