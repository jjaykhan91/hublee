/// Tests for [QuranChaptersRepository] and chapter list.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/models.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranChaptersRepository', () {
    test('loadChapters returns 114 chapters with valid metadata', () async {
      final repo = const QuranChaptersRepository();
      final chapters = await repo.loadChapters();
      expect(chapters.length, 114);
      for (var i = 0; i < chapters.length; i++) {
        final c = chapters[i];
        expect(c.id, inInclusiveRange(1, 114));
        expect(c.nameSimple, isNotEmpty);
        expect(c.nameArabic, isNotEmpty);
        expect(c.versesCount, greaterThan(0));
        expect(c.revelationType, anyOf('Meccan', 'Medinan'));
        if (i > 0) {
          expect(c.id, greaterThan(chapters[i - 1].id));
        }
      }
    });

    test('first chapter is Al-Fatiha with 7 verses', () async {
      final repo = const QuranChaptersRepository();
      final chapters = await repo.loadChapters();
      expect(chapters.first.id, 1);
      expect(chapters.first.versesCount, 7);
      expect(chapters.first.nameSimple, isNotEmpty);
    });

    test('last chapter is An-Nas with 6 verses', () async {
      final repo = const QuranChaptersRepository();
      final chapters = await repo.loadChapters();
      expect(chapters.last.id, 114);
      expect(chapters.last.versesCount, 6);
    });
  });
}
