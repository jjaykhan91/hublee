/// Tests for [QuranChaptersRepository] and chapter list.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/quran_arabic_repository.dart';
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

  group('QuranArabicRepository', () {
    setUp(QuranArabicRepository.resetCache);

    test('loadAllEmlaey returns every surah in one pass', () async {
      final all = await const QuranArabicRepository().loadAllEmlaey();
      expect(all.length, 114);
      expect(all[1]!['1'], isNotEmpty);
      expect(all[114]!.length, 6);
      // Cached: a later per-surah load must not miss ayahs.
      final fatiha = await const QuranArabicRepository().loadArabicSurah(
        1,
        useGlyphText: false,
      );
      expect(fatiha['1'], all[1]!['1']);
    });
  });
}
