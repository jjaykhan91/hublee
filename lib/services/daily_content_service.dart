/// Provides deterministic daily verse, hadith, words, and dhikr
/// based on the current date.
///
/// Uses a date-based seed so the same verse/hadith is shown all day,
/// but changes each day. Caches loaded content for the session.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import '../guidance/everyday_dhikr.dart';
import '../quran/arabic_word_segmenter.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/word_by_word_repository.dart';
import 'msa_dictionary_service.dart';

/// Verse of the day result.
class DailyVerse {
  final int surahId;
  final int ayah;
  final String surahName;
  final String arabic;
  final String english;

  const DailyVerse({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.arabic,
    required this.english,
  });
}

/// Hadith of the day result.
class DailyHadith {
  final String bookTitle;
  final String arabic;
  final String english;
  final String? narrator;
  final String collectionId;
  final String bookFile;
  final int hadithIndex;

  const DailyHadith({
    required this.bookTitle,
    required this.arabic,
    required this.english,
    this.narrator,
    this.collectionId = 'forties',
    this.bookFile = 'nawawi40.json',
    this.hadithIndex = 0,
  });
}

/// A Quranic word (or short phrase) and its word-by-word gloss.
class DailyQuranWord {
  const DailyQuranWord({
    required this.arabic,
    required this.gloss,
    required this.surahId,
    required this.ayah,
    required this.surahName,
  });

  final String arabic;
  final String gloss;
  final int surahId;
  final int ayah;
  final String surahName;
}

/// A Modern Standard Arabic dictionary headword.
class DailyArabicWord {
  const DailyArabicWord({
    required this.arabic,
    required this.english,
    required this.pos,
  });

  final String arabic;
  final String english;
  final String pos;
}

/// Service that picks and loads daily content.
class DailyContentService {
  DailyContentService._();

  static DailyVerse? _cachedVerse;
  static DailyHadith? _cachedHadith;
  static DailyQuranWord? _cachedQuranWord;
  static DailyArabicWord? _cachedArabicWord;
  static int? _cachedDay;

  static int get _today => DateTime.now().difference(DateTime(2024)).inDays;

  /// Calendar-day index used by widgets to skip a repeat decode.
  static int get dayIndex => _today;

  /// Returns the verse of the day, loading from assets if needed.
  ///
  /// Arabic comes from the shared mushaf decode in
  /// [QuranArabicRepository] so Home does not parse the 4.3 MB file
  /// a second time after search warmup.
  static Future<DailyVerse> loadVerseOfTheDay({
    QuranArabicRepository arabicRepo = const QuranArabicRepository(),
    QuranTranslationRepository translationRepo =
        const QuranTranslationRepository(),
  }) async {
    final today = _today;
    if (_cachedVerse != null && _cachedDay == today) {
      return _cachedVerse!;
    }

    final count = await arabicRepo.mushafAyahCount();
    final rng = Random(today);
    final picked = await arabicRepo.loadMushafAyahAt(rng.nextInt(count));

    var english = '';
    try {
      final enMap = await translationRepo.loadClearQuran(picked.surahId);
      english = enMap['${picked.ayah}'] ?? '';
    } catch (_) {
      // Translation may not be available; leave empty.
    }

    _cachedVerse = DailyVerse(
      surahId: picked.surahId,
      ayah: picked.ayah,
      surahName: picked.surahName,
      arabic: picked.glyphText,
      english: english,
    );
    _cachedDay = today;
    return _cachedVerse!;
  }

  /// Returns the hadith of the day from Nawawi 40 collection.
  static Future<DailyHadith> loadHadithOfTheDay() async {
    final today = _today;
    if (_cachedHadith != null && _cachedDay == today) {
      return _cachedHadith!;
    }

    final path = AssetPaths.hadith('forties', 'nawawi40.json');
    String rawJson;
    try {
      rawJson = await rootBundle.loadString(path);
    } catch (_) {
      _cachedHadith = const DailyHadith(
        bookTitle: 'Nawawi 40',
        arabic: '',
        english: 'Could not load hadith of the day.',
      );
      return _cachedHadith!;
    }

    final root = json.decode(rawJson) as Map<String, dynamic>;
    final hadiths = (root['hadiths'] as List?) ?? [];

    if (hadiths.isEmpty) {
      _cachedHadith = const DailyHadith(
        bookTitle: 'Nawawi 40',
        arabic: '',
        english: 'No hadiths available.',
      );
      return _cachedHadith!;
    }

    // Pick a deterministic random hadith.
    final rng = Random(today + 7777); // Different seed than verse
    final hadithIndex = rng.nextInt(hadiths.length);
    final hadith = hadiths[hadithIndex];

    String? english;
    String? narrator;
    final englishField = hadith['english'];
    if (englishField is String) {
      english = englishField;
    } else if (englishField is Map<String, dynamic>) {
      english = englishField['text'] as String?;
      narrator = (englishField['narrator'] ?? hadith['narrator']) as String?;
    }

    // Resolve book title.
    String bookTitle = 'Nawawi 40';
    final englishMeta = root['english'];
    if (englishMeta is Map<String, dynamic>) {
      bookTitle = (englishMeta['title'] as String?) ?? bookTitle;
    }

    _cachedHadith = DailyHadith(
      bookTitle: bookTitle,
      arabic: (hadith['arabic'] as String?) ?? '',
      english: english ?? '',
      narrator: narrator,
      collectionId: 'forties',
      bookFile: 'nawawi40.json',
      hadithIndex: hadithIndex,
    );
    _cachedDay = today;
    return _cachedHadith!;
  }

  /// A Quranic word for today, aligned with the word-by-word glossary.
  static Future<DailyQuranWord> loadQuranWordOfTheDay({
    QuranArabicRepository arabicRepo = const QuranArabicRepository(),
    WordByWordRepository wordByWordRepo = const WordByWordRepository(),
  }) async {
    final today = _today;
    if (_cachedQuranWord != null && _cachedDay == today) {
      return _cachedQuranWord!;
    }

    final count = await arabicRepo.mushafAyahCount();
    final rng = Random(today + 4242);

    Future<DailyQuranWord?> fromSurah({
      required int surahId,
      required String surahName,
      required int preferAyah,
    }) async {
      final uthmani = await arabicRepo.loadUthmaniStandard(surahId);
      final glossMap = await wordByWordRepo.loadSurah(surahId);
      final ayahs = [
        for (final key in uthmani.keys) int.tryParse(key),
      ].whereType<int>().toList()..sort();
      if (ayahs.isEmpty) return null;
      var origin = ayahs.indexOf(preferAyah);
      if (origin < 0) origin = rng.nextInt(ayahs.length);
      final n = ayahs.length < 12 ? ayahs.length : 12;
      for (var i = 0; i < n; i++) {
        final ayah = ayahs[(origin + i) % ayahs.length];
        final text = (uthmani['$ayah'] ?? '').trim();
        if (text.isEmpty) continue;
        final words = segmentArabicWords(text);
        if (words.isEmpty) continue;
        final glosses = glossMap[ayah];
        if (glosses == null || glosses.length != words.length) continue;
        final candidates = [
          for (var w = 0; w < glosses.length; w++)
            if (glosses[w].trim().isNotEmpty) w,
        ];
        if (candidates.isEmpty) continue;
        final index = candidates[rng.nextInt(candidates.length)];
        final phrase = glossPhraseAt(glosses, index);
        if (phrase == null) continue;
        final arabic = words
            .sublist(phrase.firstWord, phrase.lastWord + 1)
            .map((word) => word.text)
            .join(' ');
        return DailyQuranWord(
          arabic: arabic,
          gloss: phrase.gloss,
          surahId: surahId,
          ayah: ayah,
          surahName: surahName,
        );
      }
      return null;
    }

    DailyQuranWord? picked;
    for (var attempt = 0; attempt < 3 && picked == null; attempt++) {
      final row = await arabicRepo.loadMushafAyahAt(rng.nextInt(count));
      picked = await fromSurah(
        surahId: row.surahId,
        surahName: row.surahName,
        preferAyah: row.ayah,
      );
    }

    _cachedQuranWord =
        picked ??
        const DailyQuranWord(
          arabic: '\u0628\u0650\u0633\u0652\u0645\u0650',
          gloss: 'In (the) name',
          surahId: 1,
          ayah: 1,
          surahName: 'Al-Fatihah',
        );
    _cachedDay = today;
    return _cachedQuranWord!;
  }

  /// An MSA dictionary word for today.
  static Future<DailyArabicWord> loadArabicWordOfTheDay({
    MsaDictionaryService dictionary = const MsaDictionaryService(),
  }) async {
    final today = _today;
    if (_cachedArabicWord != null && _cachedDay == today) {
      return _cachedArabicWord!;
    }

    final entries = await dictionary.load();
    if (entries.isEmpty) {
      _cachedArabicWord = const DailyArabicWord(
        arabic: '',
        english: 'No dictionary entries.',
        pos: '',
      );
      _cachedDay = today;
      return _cachedArabicWord!;
    }

    final rng = Random(today + 9090);
    final entry = entries[rng.nextInt(entries.length)];
    _cachedArabicWord = DailyArabicWord(
      arabic: entry.arabic,
      english: entry.english,
      pos: entry.pos,
    );
    _cachedDay = today;
    return _cachedArabicWord!;
  }

  /// Standard Uthmani (not PUA glyphs) for widgets and other Unicode views.
  static Future<String> uthmaniFor(int surahId, int ayah) async {
    final map = await const QuranArabicRepository().loadUthmaniStandard(
      surahId,
    );
    return (map['$ayah'] ?? '').trim();
  }

  /// Today's short dhikr. Rotates through [everydayDhikrCatalog].
  static EverydayDhikr dhikrOfTheDay() => dhikrForDay(dayIndex);

  /// Picks the catalog entry for a calendar-day index. Tests only need [day].
  static EverydayDhikr dhikrForDay(int day) {
    final catalog = everydayDhikrCatalog;
    return catalog[day.abs() % catalog.length];
  }

  /// Clears the session cache. Tests only.
  @visibleForTesting
  static void resetCache() {
    _cachedVerse = null;
    _cachedHadith = null;
    _cachedQuranWord = null;
    _cachedArabicWord = null;
    _cachedDay = null;
  }
}
