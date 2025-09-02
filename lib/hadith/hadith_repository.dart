import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'models.dart';

class HadithRepository {
  const HadithRepository();

  // ---------- Load a single book ----------
  Future<HadithBook> loadBook(String collectionId, String bookFile) async {
    final path = AssetPaths.hadith(collectionId, bookFile);
    final raw = await rootBundle.loadString(path);
    final root = json.decode(raw);

    if (root is! Map<String, dynamic>) {
      throw const FormatException('Expected top-level Map for hadith book JSON.');
    }

    // Title from english.title -> metadata.english.title -> filename
    String? title;
    final en1 = root['english'];
    if (en1 is Map<String, dynamic>) title = en1['title'] as String?;
    if (title == null) {
      final meta = root['metadata'];
      if (meta is Map<String, dynamic>) {
        final metaEn = meta['english'];
        if (metaEn is Map<String, dynamic>) title = metaEn['title'] as String?;
      }
    }
    title ??= _titleFromFileName(bookFile);

    // ✅ make the types explicit so we don’t end up with List<dynamic>
    final List<Chapter> chapters = (root['chapters'] is List ? root['chapters'] : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map<Chapter>(Chapter.fromJson)
        .toList(growable: false);

    final List<Hadith> hadiths = (root['hadiths'] is List ? root['hadiths'] : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map<Hadith>(Hadith.fromJson)
        .toList(growable: false);

    return HadithBook(title: title, chapters: chapters, hadiths: hadiths);
  }

  String _titleFromFileName(String file) {
    final base = file.split('/').last.split('.').first;
    return base.replaceAll('_', ' ').replaceFirstMapped(
      RegExp(r'^\w'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }
}

// ---------- Lightweight list metadata + loaders ----------
class HadithCollectionMeta {
  final String id;     // e.g., 'forties'
  final String title;  // e.g., 'Forties'
  final int? count;
  const HadithCollectionMeta({required this.id, required this.title, this.count});
}

class HadithBookMeta {
  final String file;   // 'nawawi40.json'
  final String title;  // display title from index.json (bookName/title)
  final int? length;
  const HadithBookMeta({required this.file, required this.title, this.length});
}

extension HadithRepositoryLists on HadithRepository {
  Future<List<HadithCollectionMeta>> loadCollections() async {
    final known = <HadithCollectionMeta>[
      const HadithCollectionMeta(id: 'forties', title: 'Forties'),
      const HadithCollectionMeta(id: 'the_9_books', title: 'The Nine Books'),
      const HadithCollectionMeta(id: 'other_books', title: 'Other Books'),
    ];
    final out = <HadithCollectionMeta>[];
    for (final c in known) {
      try {
        final books = await loadBooksForCollection(c.id);
        out.add(HadithCollectionMeta(id: c.id, title: c.title, count: books.length));
      } catch (_) {
        out.add(c);
      }
    }
    return out;
  }

  /// Reads `assets/hadith/<collectionId>/index.json` and returns the books.
  /// Supports your shape:
  /// [ { "id": 10, "file": "nawawi40.json", "bookName": "...", "length": 42 }, ... ]
  Future<List<HadithBookMeta>> loadBooksForCollection(String collectionId) async {
    final path = 'assets/hadith/$collectionId/index.json';
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw);

    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final arr = decoded['books'] ?? decoded['items'];
      if (arr is List) {
        list = arr;
      } else {
        return decoded.entries
            .where((e) => e.value is String)
            .map((e) => HadithBookMeta(file: e.key.toString(), title: e.value as String))
            .toList(growable: false);
      }
    } else {
      throw const FormatException('Unsupported index.json shape');
    }

    return list.whereType<Map<String, dynamic>>().map<HadithBookMeta>((m) {
      final file = (m['file'] ?? m['path'] ?? m['name']).toString();
      final title = (m['bookName'] ?? m['title'] ?? m['english'] ?? m['label'] ?? m['name'] ?? file).toString();
      final length = _toInt(m['length']);
      return HadithBookMeta(file: file, title: title, length: length);
    }).toList(growable: false);
  }
}

// ---------- Search ----------
class HadithSearchHit {
  final String collectionId;
  final String bookFile;
  final String? bookTitle;
  final int hadithIndex; // 0-based
  final String? snippet;
  const HadithSearchHit({
    required this.collectionId,
    required this.bookFile,
    required this.hadithIndex,
    this.bookTitle,
    this.snippet,
  });
}

extension HadithSearch on HadithRepository {
  Future<List<HadithSearchHit>> searchHadith(String query, {int limit = 100}) async {
    final qLower = query.toLowerCase();
    final hits = <HadithSearchHit>[];

    final collections = await loadCollections();
    for (final c in collections) {
      late final List<HadithBookMeta> books;
      try {
        books = await loadBooksForCollection(c.id);
      } catch (_) {
        continue;
      }

      for (final b in books) {
        HadithBook book;
        try {
          book = await loadBook(c.id, b.file);
        } catch (_) {
          continue;
        }

        for (var i = 0; i < book.hadiths.length; i++) {
          final h = book.hadiths[i];
          final en = (h.english ?? '').toLowerCase();
          final ar = (h.arabic ?? '');
          if (!(en.contains(qLower) || ar.contains(query))) continue;

          String? snippet;
          if (en.isNotEmpty) {
            final idx = en.indexOf(qLower);
            if (idx >= 0) {
              final start = (idx - 40).clamp(0, en.length);
              final end = (idx + qLower.length + 60).clamp(0, en.length);
              snippet = (h.english ?? '').substring(start, end).trim();
              if (start > 0) snippet = '…$snippet';
              if (end < en.length) snippet = '$snippet…';
            } else {
              snippet = h.english;
            }
          }

          hits.add(HadithSearchHit(
            collectionId: c.id,
            bookFile: b.file,
            bookTitle: book.title.isNotEmpty ? book.title : b.title,
            hadithIndex: i,
            snippet: snippet,
          ));

          if (hits.length >= limit) return hits;
        }
      }
    }
    return hits;
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
