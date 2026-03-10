/// Data models for the Quran module.
library;

import 'package:flutter/foundation.dart';

/// Lightweight metadata for a single Quran chapter (surah).
///
/// Used in surah lists, search results, bookmarks, and grouping
/// views (Juz, Makki/Madani, revelation order). Does NOT contain
/// the actual ayah text — that comes from the repositories.
@immutable
class ChapterMeta {
  /// Surah number (1-114).
  final int id;

  /// English transliteration (e.g. "Al-Fatiha").
  final String nameSimple;

  /// English meaning/translation of the surah name (e.g. "The Opener").
  /// From Quran.com; null if not loaded.
  final String? nameTranslated;

  /// Arabic script name (e.g. "الفاتحة"). From source data; may be unvowelled.
  final String nameArabic;

  /// Arabic name with full tashkeel (e.g. "الْفَاتِحَة") for display; null if not loaded.
  final String? nameArabicVowelled;

  /// Total number of ayat in this surah.
  final int versesCount;

  /// "Meccan" or "Medinan" — where the surah was revealed.
  final String revelationType;

  /// Chronological revelation order (1-114).
  final int revelationOrder;

  /// First juz this surah appears in (1-30).
  final int startJuz;

  /// Last juz this surah appears in (1-30).
  final int endJuz;

  const ChapterMeta({
    required this.id,
    required this.nameSimple,
    this.nameTranslated,
    required this.nameArabic,
    this.nameArabicVowelled,
    required this.versesCount,
    this.revelationType = 'Meccan',
    this.revelationOrder = 0,
    this.startJuz = 1,
    this.endJuz = 1,
  });

  /// Whether this surah was revealed in Mecca.
  bool get isMeccan => revelationType == 'Meccan';

  /// Whether this surah was revealed in Medina.
  bool get isMedinan => revelationType == 'Medinan';

  @override
  String toString() => 'ChapterMeta(id: $id, name: $nameSimple/$nameArabic, '
      'verses: $versesCount, $revelationType, juz: $startJuz-$endJuz)';
}
