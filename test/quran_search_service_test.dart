/// Unit tests for [QuranSearchService] Arabic field selection.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/models.dart';
import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/services/quran_search_service.dart';
import 'package:hublee/services/search_match.dart';
import 'package:hublee/ui/surah_reader_page.dart';
import 'package:hublee/services/settings_controller.dart';

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
    return {'1': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'};
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

  @override
  Future<int> mushafAyahCount() async => 1;

  @override
  Future<MushafAyah> loadMushafAyahAt(int index) async {
    return const MushafAyah(
      surahId: 1,
      ayah: 1,
      surahName: 'Al-Fatiha',
      glyphText: 'x',
    );
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

class _RankArabicRepo implements QuranArabicRepository {
  @override
  Future<Map<String, String>> loadArabicSurah(
    int surahId, {
    bool useGlyphText = true,
  }) async => {'1': 'ا', '2': 'ا'};

  @override
  Future<Map<int, Map<String, String>>> loadAllEmlaey() async => {
    1: {'1': 'ا', '2': 'ا'},
  };

  @override
  Future<Map<String, String>> loadUthmaniStandard(int surahId) async => {
    '1': 'ا',
    '2': 'ا',
  };

  @override
  Future<int> mushafAyahCount() async => 2;

  @override
  Future<MushafAyah> loadMushafAyahAt(int index) async {
    return MushafAyah(
      surahId: 1,
      ayah: index + 1,
      surahName: 'Al-Fatiha',
      glyphText: 'ا',
    );
  }
}

class _RankChaptersRepo implements QuranChaptersRepository {
  @override
  Future<List<ChapterMeta>> loadChapters() async => const [
    ChapterMeta(
      id: 1,
      nameSimple: 'Al-Fatiha',
      nameArabic: 'الفاتحة',
      versesCount: 2,
    ),
  ];
}

class _RankTranslationRepo implements QuranTranslationRepository {
  @override
  Future<Map<String, String>> loadClearQuran(int surahId) async => {
    '1': 'prefix qqzzwordish',
    '2': 'a qqzzword here',
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

    final result = await service.search('بسم');

    expect(arabicRepo.lastUseGlyphText, isFalse);
    expect(result.hits, hasLength(1));
    expect(result.hits.single.surahId, 1);
    expect(result.hits.single.ayah, 1);
  });

  test('folded Arabic query matches wasla and tashkeel', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );

    final result = await service.search('الله');
    expect(result.hits, hasLength(1));
    expect(result.hits.single.ayah, 1);
  });

  test('English search still matches', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );

    final result = await service.search('Merciful');
    expect(result.hits, hasLength(1));
    expect(result.hits.single.snippet, contains('Merciful'));
  });

  test('PUA-only strings do not drive matches when emlaey is used', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );

    // Query that only exists in the stub's glyph corpus.
    final result = await service.search('\uE000\uE001');
    expect(result.hits, isEmpty);
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
    expect((await service.search('   ')).hits, isEmpty);
  });

  test('1:1 jumps to the verse even without a text match', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );
    final result = await service.search('1:1');
    expect(result.hits, hasLength(1));
    expect(result.hits.single.surahId, 1);
    expect(result.hits.single.ayah, 1);
    expect(result.hits.single.arabicSnippet, isNotNull);
    expect(result.invalidJumpHint, isNull);
  });

  test('1:99 is rejected against versesCount', () async {
    final service = QuranSearchService(
      chaptersRepo: _StubChaptersRepo(),
      arabicRepo: _RecordingArabicRepo(),
      translationRepo: _StubTranslationRepo(),
    );
    final result = await service.search('1:99');
    expect(result.hits, isEmpty);
    expect(result.invalidJumpHint, contains('Al-Fatiha'));
    expect(result.invalidJumpHint, contains('1:99'));
  });

  test('exact English word ranks above a substring', () async {
    expect(englishExactWordMatch('a qqzzword here', 'qqzzword'), isTrue);
    expect(englishExactWordMatch('prefix qqzzwordish', 'qqzzword'), isFalse);

    final service = QuranSearchService(
      chaptersRepo: _RankChaptersRepo(),
      arabicRepo: _RankArabicRepo(),
      translationRepo: _RankTranslationRepo(),
    );
    final result = await service.search('qqzzword');
    expect(result.totalCount, 2);
    expect(result.hits.map((h) => h.ayah).toList(), [2, 1]);
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
    expect(arabicHits.hits.single.arabicSnippet, contains('ٱللَّهِ'));
  });

  test('glyph column is skipped when tajweed is on', () {
    expect(
      surahReaderNeedsGlyphColumn(
        tajweedEnabled: true,
        wordByWordEnabled: false,
        font: ArabicFontOption.uthmanic,
      ),
      isFalse,
    );
    expect(
      surahReaderNeedsGlyphColumn(
        tajweedEnabled: false,
        wordByWordEnabled: false,
        font: ArabicFontOption.uthmanic,
      ),
      isTrue,
    );
    expect(
      surahReaderNeedsGlyphColumn(
        tajweedEnabled: false,
        wordByWordEnabled: true,
        font: ArabicFontOption.uthmanic,
      ),
      isFalse,
    );
  });
}
