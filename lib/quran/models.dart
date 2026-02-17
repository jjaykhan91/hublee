/// Data models for the Quran module.
library;

import 'package:flutter/foundation.dart';

/// Lightweight metadata for a single Quran chapter (surah).
///
/// Used in surah lists, search results, and bookmarks. Does NOT
/// contain the actual ayah text — that comes from the repositories.
@immutable
class ChapterMeta {
  /// Surah number (1–114).
  final int id;

  /// English transliteration (e.g. "Al-Fatiha").
  final String nameSimple;

  /// Arabic script name (e.g. "الفاتحة").
  final String nameArabic;

  /// Total number of ayat in this surah.
  final int versesCount;

  const ChapterMeta({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
  });

  @override
  String toString() => 'ChapterMeta(id: $id, name: $nameSimple/$nameArabic, '
      'verses: $versesCount)';
}
