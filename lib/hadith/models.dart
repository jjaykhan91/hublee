import 'package:flutter/foundation.dart';

@immutable
class HadithBook {
  final String title;
  final List<Chapter> chapters;
  final List<Hadith> hadiths;

  const HadithBook({
    required this.title,
    required this.chapters,
    required this.hadiths,
  });
}

@immutable
class Chapter {
  final int? bookId;
  final int? id;
  final String? arabic;
  final String? english;

  const Chapter({this.bookId, this.id, this.arabic, this.english});

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        bookId: _toInt(j['bookId']),
        id: _toInt(j['id']),
        arabic: j['arabic'] as String?,
        english: j['english'] as String?,
      );
}

@immutable
class Hadith {
  final int? id;
  final int? idInBook;
  final int? chapterId;
  final int? bookId;
  final String? arabic;
  final String? english;  // may come from { text, narrator } object
  final String? narrator;

  const Hadith({
    this.id,
    this.idInBook,
    this.chapterId,
    this.bookId,
    this.arabic,
    this.english,
    this.narrator,
  });

  factory Hadith.fromJson(Map<String, dynamic> j) {
    final en = j['english'];
    String? english;
    String? narrator;

    if (en is String) {
      english = en;
    } else if (en is Map<String, dynamic>) {
      english = en['text'] as String?;
      narrator = (en['narrator'] ?? j['narrator']) as String?;
    }

    return Hadith(
      id: _toInt(j['id']),
      idInBook: _toInt(j['idInBook']),
      chapterId: _toInt(j['chapterId']),
      bookId: _toInt(j['bookId']),
      arabic: j['arabic'] as String?,
      english: english,
      narrator: narrator,
    );
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
