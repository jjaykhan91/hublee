import 'package:flutter/foundation.dart';

@immutable
class ChapterMeta {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final String revelationPlace;
  final int versesCount;

  const ChapterMeta({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.revelationPlace,
    required this.versesCount,
  });

  factory ChapterMeta.fromJson(Map<String, dynamic> j) => ChapterMeta(
        id: j['id'] as int,
        nameSimple: j['name_simple'] as String,
        nameArabic: j['name_arabic'] as String,
        revelationPlace: j['revelation_place'] as String,
        versesCount: j['verses_count'] as int,
      );
}

@immutable
class Ayah {
  final int number; // 1-based
  final String? arabic;
  final String? english;

  const Ayah({required this.number, this.arabic, this.english});
}

@immutable
class Surah {
  final ChapterMeta meta;
  final List<Ayah> ayat;

  const Surah({required this.meta, required this.ayat});
}

@immutable
class QuranSearchHit {
  final int surahId;
  final int ayah; // 1-based
  final String surahName;
  final String? snippet;

  const QuranSearchHit({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    this.snippet,
  });
}
