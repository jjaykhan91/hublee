/// Unit tests for [QuranSearchService] Arabic field selection.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/models.dart';
import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/services/quran_search_service.dart';

/// Records which [useGlyphText] flag was requested and returns fixtures.
class _RecordingArabicRepo implements QuranArabicRepository {
  bool? lastUseGlyphText;
  int loadCount = 0;
  int uthmaniLoadCount = 0;

  @override
  Future<Map<String, String>> loadArabicSurah(
    int surahId, {
    bool useGlyphText = true,
  }) async {
    loadCount++;
    lastUseGlyphText = useGlyphText;
    if (useGlyphText) {
      // PUA-looking private-use junk — must NOT be what search indexes.
      return {'1': '\uE000\uE001\uE002'};
    }
    return {'1': 'بسم الله الرحمن الرحيم'};
  }

  @override
  Future<Map<int, Map<String, String>>> loadAllEmlaey() async {
    return {1: await loadArabicSurah(1, useGlyphText: false)};
  }

  @override
  Future<Map<String, String>> loadUthmaniStandard(int surahId) async {
    uthmaniLoadCount++;
    return {'1': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'};
  }
}

class _StubChaptersRepo implements QuranChaptersRepository {
  @override
  Future<List<ChapterMeta>> loadChapters() async => const [
    ChapterMeta(
      id: 1,
      nameSimple: 'Al-Fatiha',
      nameArabic: 'الفاتحة',
      versesCount: 1,
    ),
  ];
}

class _StubTranslationRepo implements QuranTranslationRepository {
  @override
  Future<Map<String, String>> loadClearQuran(int surahId) async => {
    '1': 'In the name of Allah, the Entirely Merciful, the Especially Merciful',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(QuranSearchService.resetCache);

  test('Arabic search indexes emlaey, not PUA glyph text', () async {
    final arabicRepo = _RecordingArabicRepo();
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: arabicRepo,
      translationRepo: _StubTranslationRepo(),
    );

    final hits = await service.search('بسم');

    expect(arabicRepo.lastUseGlyphText, isFalse);
    expect(hits, hasLength(1));
    expect(hits.single.surahId, 1);
    expect(hits.single.ayah, 1);
  });

  test('English search still matches', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );

    final hits = await service.search('Merciful');
    expect(hits, hasLength(1));
    expect(hits.single.snippet, contains('Merciful'));
  });

  test('PUA-only strings do not drive matches when emlaey is used', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );

    // Query that only exists in the stub's glyph corpus.
    final hits = await service.search('\uE000\uE001');
    expect(hits, isEmpty);
  });

  test('second search reuses the session index', () async {
    final arabicRepo = _RecordingArabicRepo();
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: arabicRepo,
      translationRepo: _StubTranslationRepo(),
    );

    await service.search('Merciful');
    expect(arabicRepo.loadCount, 1);

    await service.search('Allah');
    expect(arabicRepo.loadCount, 1);
  });

  test('empty query returns no hits', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );
    expect(await service.search('   '), isEmpty);
  });

  test('1:1 jumps to the verse even without a text match', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );
    final hits = await service.search('1:1');
    expect(hits, hasLength(1));
    expect(hits.single.surahId, 1);
    expect(hits.single.ayah, 1);
    expect(hits.single.arabicSnippet, isNotNull);
  });

  test('index skips uthmani until a hit needs an Arabic snippet', () async {
    final arabicRepo = _RecordingArabicRepo();
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: arabicRepo,
      translationRepo: _StubTranslationRepo(),
    );

    await service.warmIndex();
    expect(arabicRepo.uthmaniLoadCount, 0);

    await service.search('Merciful');
    expect(arabicRepo.uthmaniLoadCount, 0);

    final arabicHits = await service.search('بسم');
    expect(arabicRepo.uthmaniLoadCount, 1);
    expect(arabicHits.single.arabicSnippet, contains('ٱللَّهِ'));
  });
}
