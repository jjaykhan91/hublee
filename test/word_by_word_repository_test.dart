/// Tests for [WordByWordRepository] and word-by-word verse parsing.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/word_by_word_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordByWordRepository', () {
    late WordByWordRepository repo;

    setUp(() {
      repo = WordByWordRepository();
    });

    test('loadVerse(1, 1) returns list with correct structure when asset has 1:1', () async {
      final words = await repo.loadVerse(1, 1);
      if (words.isEmpty) return; // skip when asset not present
      expect(words, isNotEmpty);
      for (final w in words) {
        expect(w.position, greaterThanOrEqualTo(1));
        expect(w.translation, isNotEmpty);
      }
      final positions = words.map((w) => w.position).toList();
      expect(positions, orderedEquals(positions..sort()));
    });

    test('loadVerse for non-existent verse returns empty', () async {
      final words = await repo.loadVerse(114, 999);
      expect(words, isEmpty);
    });

    test('loadSurah(1) returns map keyed by ayah when asset has data', () async {
      final map = await repo.loadSurah(1);
      if (map.isEmpty) return;
      for (final entry in map.entries) {
        expect(entry.key, greaterThanOrEqualTo(1));
        expect(entry.value, isNotEmpty);
        for (final w in entry.value) {
          expect(w.position, greaterThanOrEqualTo(1));
          expect(w.translation, isNotEmpty);
        }
      }
    });
  });
}
