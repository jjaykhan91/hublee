import 'package:flutter/foundation.dart';

/// Minimal chapter metadata used across the app.
@immutable
class ChapterMeta {
  /// Surah number (1–114).
  final int id;

  /// English name (e.g., "Al-Fatiha").
  final String nameSimple;

  /// Arabic name (e.g., "الفاتحة").
  final String nameArabic;

  /// Number of ayat in the surah.
  final int versesCount;

  const ChapterMeta({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
  });

  @override
  String toString() =>
      'ChapterMeta(id: $id, name: $nameSimple/$nameArabic, verses: $versesCount)';
}
