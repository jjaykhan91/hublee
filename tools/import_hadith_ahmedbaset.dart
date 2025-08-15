// dart run tools/import_hadith_ahmedbaset.dart --file tools/utils/by_book/the_9_books/bukhari.json --out assets/hadith --collection bukhari --title "Sahih al-Bukhari"
// Repeat for other files (muslim, abudawud, …)
//
// Also supports folder mode (old behavior):
// dart run tools/import_hadith_ahmedbaset.dart --in tools/utils/db --out assets/hadith --collection bukhari --title "Sahih al-Bukhari" --mode books
//
// Output (per collection):
//   assets/hadith/<collection>/index.json
//   assets/hadith/<collection>/books/<n>.json
//   assets/hadith/<collection>/_meta.json

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('file', help: 'Single JSON file (e.g., by_book/the_9_books/bukhari.json).')
    ..addOption('in', help: 'Directory root that contains <collection>/<books|chapters> JSONs.')
    ..addOption('out', defaultsTo: 'assets/hadith', help: 'Output root.')
    ..addOption('collection', help: 'Collection id (e.g., bukhari, muslim).', mandatory: true)
    ..addOption('title', help: 'Human title for the collection.', mandatory: true)
    ..addOption('mode', defaultsTo: 'books', allowed: ['books', 'chapters'],
        help: 'Only used with --in. "books" (flat) or "chapters" (grouped).')
    ..addFlag('minify', defaultsTo: false, help: 'Compact JSON output.');

  final o = parser.parse(args);
  final singleFile = o['file'] as String?;
  final inputRoot = o['in'] as String?;
  final outRoot = Directory(o['out'] as String);
  final collection = (o['collection'] as String).trim();
  final title = (o['title'] as String).trim();
  final mode = (o['mode'] as String);
  final minify = o['minify'] as bool;

  String toJson(Object o) =>
      minify ? jsonEncode(o) : const JsonEncoder.withIndent('  ').convert(o);

  outRoot.createSync(recursive: true);
  final outBooksDir = Directory(p.join(outRoot.path, collection, 'books'));
  outBooksDir.createSync(recursive: true);

  final booksIndex = <Map<String, dynamic>>[];
  int totalHadith = 0;

  if (singleFile != null) {
    // --- Single by_book file (e.g., the_9_books/bukhari.json) ---
    final f = File(singleFile);
    if (!f.existsSync()) {
      stderr.writeln('❌ File not found: ${f.path}');
      exit(1);
    }
    final raw = jsonDecode(await f.readAsString());

    // That file usually looks like: [{"Book":1,"Chapter":"…","Text":"…","Text_Ar":"…","Hadith":1}, ...]
    final list = _unwrapArray(raw);
    final map = <String, List<Map<String, dynamic>>>{}; // bookNo -> hadith list

    for (final h in list) {
      final bookNo = _getStr(h, ['bookNumber','Book','book','bk']).trim();
      if (bookNo.isEmpty) continue;
      (map[bookNo] ??= []).add(h.cast<String, dynamic>());
    }

    for (final entry in map.entries.toList()..sort((a, b) => (int.tryParse(a.key) ?? 0).compareTo(int.tryParse(b.key) ?? 0))) {
      final bookNo = entry.key;
      final normalized = _normalizeFlatBook(collection, bookNo, entry.value);
      final hadithCount = (normalized['chapters'] as List)
          .fold<int>(0, (s, c) => s + ((c['hadiths'] as List).length));
      totalHadith += hadithCount;

      booksIndex.add({
        'bookNumber': bookNo,
        'hadithCount': hadithCount,
        'bookName': normalized['bookName'] ?? 'Book $bookNo',
      });

      final outFile = File(p.join(outBooksDir.path, '$bookNo.json'));
      await outFile.writeAsString(toJson(normalized));
      stdout.writeln('✔ $collection/books/$bookNo.json  ($hadithCount hadith)');
    }
  } else {
    // --- Folder mode (older flow) ---
    if (inputRoot == null) {
      stderr.writeln('❌ Provide either --file or --in.');
      exit(1);
    }
    final root = Directory(inputRoot);
    if (!root.existsSync()) {
      stderr.writeln('❌ Input root not found: ${root.path}');
      exit(1);
    }
    final collectionDir = Directory(p.join(root.path, collection, mode));
    if (!collectionDir.existsSync()) {
      stderr.writeln('❌ Not found: ${collectionDir.path}');
      exit(1);
    }

    final files = collectionDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final f in files) {
      final name = p.basenameWithoutExtension(f.path);
      final bookNo = _extractLastInt(name);
      if (bookNo == null) {
        stderr.writeln('⚠️  Skip ${f.path} (no numeric book number)');
        continue;
      }
      final raw = jsonDecode(await f.readAsString());
      final normalized = (mode == 'books')
          ? _normalizeFlatBook(collection, bookNo, _unwrapArray(raw))
          : _normalizeChapterStructuredBook(collection, bookNo, raw);

      final hadithCount = (normalized['chapters'] as List)
          .fold<int>(0, (s, c) => s + ((c['hadiths'] as List).length));
      totalHadith += hadithCount;

      booksIndex.add({
        'bookNumber': bookNo,
        'hadithCount': hadithCount,
        'bookName': normalized['bookName'] ?? 'Book $bookNo',
      });

      final outFile = File(p.join(outBooksDir.path, '$bookNo.json'));
      await outFile.writeAsString(toJson(normalized));
      stdout.writeln('✔ $collection/books/$bookNo.json  ($hadithCount hadith)');
    }
  }

  // index.json
  final idx = File(p.join(outRoot.path, collection, 'index.json'));
  await idx.writeAsString(toJson(booksIndex));
  stdout.writeln('✔ $collection/index.json (${booksIndex.length} books)');

  // _meta.json
  final meta = {
    'id': collection,
    'title': title,
    'totalBooks': booksIndex.length,
    'totalHadith': totalHadith,
  };
  final metaFile = File(p.join(outRoot.path, collection, '_meta.json'));
  await metaFile.writeAsString(toJson(meta));
  stdout.writeln('✔ $collection/_meta.json');
}

// ---------- helpers ----------

List<Map<String, dynamic>> _unwrapArray(dynamic raw) {
  if (raw is List) return raw.cast<Map<String, dynamic>>();
  if (raw is Map && raw['hadiths'] is List) return (raw['hadiths'] as List).cast<Map<String, dynamic>>();
  throw FormatException('Expected array or {"hadiths":[...]}. Got ${raw.runtimeType}');
}

String? _extractLastInt(String s) {
  final m = RegExp(r'(\d+)').allMatches(s).toList();
  if (m.isEmpty) return null;
  return int.parse(m.last.group(1)!).toString();
}

Map<String, dynamic> _normalizeFlatBook(String collection, String bookNo, List<Map<String, dynamic>> list) {
  // Group by any chapter-ish title. AhmedBaset files often use "Chapter"/"Chapter_En".
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  String bookName = '';

  for (final h in list) {
    final chapter = _getStr(h, ['chapterTitle','chapter','Chapter','chapter_en','Chapter_En','Chapter_Ar']).trim();
    final chapKey = chapter.isEmpty ? '—' : chapter;

    // Arabic/English field variants in that repo:
    final ar = _getStr(h, ['arabic','arabictext','Text_Ar','ar']).trim();
    final en = htmlUnescape(_getStr(h, ['english','text','Text','en']).trim());

    final hadithNo = _getStr(h, ['hadithNumber','hadithnumber','Hadith','n','no','number']).trim();
    final nameCandidate = _getStr(h, ['bookName','book_name']);
    if (bookName.isEmpty && nameCandidate.isNotEmpty) bookName = nameCandidate;

    (grouped[chapKey] ??= []).add({
      'hadithNumber': hadithNo,
      'arabic': ar,
      'english': en,
      'grades': h['grades'] ?? [],
      'reference': {'book': bookNo, 'hadith': hadithNo},
    });
  }

  final chapters = grouped.entries.map((e) => {
    'chapterTitle': e.key,
    'hadiths': e.value,
  }).toList();

  return {
    'collection': collection,
    'bookNumber': bookNo,
    'bookName': bookName.isNotEmpty ? bookName : 'Book $bookNo',
    'chapters': chapters,
  };
}

Map<String, dynamic> _normalizeChapterStructuredBook(String collection, String bookNo, dynamic raw) {
  // Fallback: pass-through with normalization (if you ever use by_chapter).
  List chaptersRaw = [];
  String bookName = '';

  if (raw is Map<String, dynamic>) {
    bookName = _getStr(raw, ['bookName','book_name','title','name']);
    chaptersRaw = (raw['chapters'] ?? raw['data'] ?? raw['chapter'] ?? const []) as List;
  } else if (raw is List) {
    chaptersRaw = raw;
  }

  final chapters = <Map<String, dynamic>>[];
  for (final c in chaptersRaw) {
    if (c is! Map) continue;
    final title = _getStr(c, ['chapterTitle','chapter','title','name','chapter_en']);
    final hadithList = (c['hadiths'] ?? c['hadith'] ?? c['data'] ?? c['items'] ?? c['list'] ?? const []) as List;

    final items = <Map<String, dynamic>>[];
    for (final h in hadithList) {
      if (h is! Map) continue;
      final ar = _getStr(h, ['arabic','arabictext','Text_Ar','ar']).trim();
      final en = htmlUnescape(_getStr(h, ['english','text','Text','en']).trim());
      final hadithNo = _getStr(h, ['hadithNumber','hadithnumber','Hadith','n','no','number']).trim();
      items.add({
        'hadithNumber': hadithNo,
        'arabic': ar,
        'english': en,
        'grades': h['grades'] ?? [],
        'reference': {'book': bookNo, 'hadith': hadithNo},
      });
    }

    chapters.add({'chapterTitle': title.isEmpty ? '—' : title, 'hadiths': items});
  }

  return {
    'collection': collection,
    'bookNumber': bookNo,
    'bookName': bookName.isNotEmpty ? bookName : 'Book $bookNo',
    'chapters': chapters,
  };
}

String _getStr(Map obj, List<String> keys, [String def = '']) {
  for (final k in keys) {
    if (obj.containsKey(k) && obj[k] != null) {
      final s = obj[k].toString();
      if (s.trim().isNotEmpty) return s;
    }
  }
  return def;
}

String htmlUnescape(String s) {
  if (s.isEmpty) return s;
  const named = {'amp':'&','quot':'"','apos':"'",'lt':'<','gt':'>','nbsp':' '};
  s = s.replaceAllMapped(RegExp(r'&([a-zA-Z]+);'), (m) => named[m.group(1)!.toLowerCase()] ?? m.group(0)!);
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  return s;
}
