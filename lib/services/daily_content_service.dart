/// Provides deterministic "verse of the day" and "hadith of the day"
/// content based on the current date.
///
/// Uses a date-based seed so the same verse/hadith is shown all day,
/// but changes each day. Caches loaded content for the session.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';

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

/// Service that picks and loads daily content.
class DailyContentService {
  DailyContentService._();

  static DailyVerse? _cachedVerse;
  static DailyHadith? _cachedHadith;
  static int? _cachedDay;

  static int get _today => DateTime.now().difference(DateTime(2024)).inDays;

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

  /// Clears the session cache. Tests only.
  @visibleForTesting
  static void resetCache() {
    _cachedVerse = null;
    _cachedHadith = null;
    _cachedDay = null;
  }
}
