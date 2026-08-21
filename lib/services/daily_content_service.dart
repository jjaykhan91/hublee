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
  static Future<DailyVerse> loadVerseOfTheDay() async {
    final today = _today;
    if (_cachedVerse != null && _cachedDay == today) {
      return _cachedVerse!;
    }

    final rawJson = await rootBundle.loadString(
      AssetPaths.kfgqpcQuranMushafSmartV8,
    );
    final List<dynamic> allAyahs = json.decode(rawJson);

    // Pick a deterministic random ayah from the full Quran.
    final rng = Random(today);
    final row = allAyahs[rng.nextInt(allAyahs.length)];
    final surahId = row['sura_no'] as int;
    final ayahNum = row['aya_no'] as int;
    final surahName = (row['sura_name_en'] as String).trim();
    final arabic = (row['aya_text'] as String?) ?? '';

    // Load the English translation for this ayah.
    String english = '';
    try {
      final enJson = await rootBundle.loadString(
        AssetPaths.quranClearQuran(surahId),
      );
      final enMap = json.decode(enJson) as Map<String, dynamic>;
      english = (enMap['$ayahNum'] as String?) ?? '';
    } catch (_) {
      // Translation may not be available; leave empty.
    }

    _cachedVerse = DailyVerse(
      surahId: surahId,
      ayah: ayahNum,
      surahName: surahName,
      arabic: arabic,
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

    // Load Nawawi 40 as the daily hadith source.
    const path = 'assets/hadith/forties/nawawi40.json';
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
