// Usage:
// dart run tools/build_hadith_indexes.dart \
//   --src tools/utils/by_book \
//   --out assets/hadith
//
// What it does:
// - Copies *.json books from --src/{collection} into --out/{collection}/books/
// - Writes an index.json for each collection
// - Writes collections.json and manifest.json under --out
//
// Your per-book JSON shape should match the sample you posted (id, metadata, chapters, hadiths).

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('src', help: 'Source folder with collections', defaultsTo: 'tools/utils/by_book')
    ..addOption('out', help: 'Assets output folder', defaultsTo: 'assets/hadith')
    ..addFlag('minify', help: 'Minify JSON output', defaultsTo: false)
    ..addFlag('clean', help: 'Clean OUT before building', defaultsTo: false);

  final o = parser.parse(args);
  final srcDir = Directory(o['src'] as String);
  final outDir = Directory(o['out'] as String);
  final minify = o['minify'] as bool;
  final clean = o['clean'] as bool;

  if (!srcDir.existsSync()) {
    stderr.writeln('❌ Source does not exist: ${srcDir.path}');
    exit(1);
  }

  if (clean && outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  final enc = minify ? const JsonEncoder() : const JsonEncoder.withIndent('  ');
  final collectionsSummary = <Map<String, dynamic>>[];

  // Walk top-level collections in src
  for (final coll in srcDir.listSync().whereType<Directory>()) {
    final collId = p.basename(coll.path); // e.g. forties, other_books, the_9_books
    final srcBooks = coll
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (srcBooks.isEmpty) continue;

    // out: <out>/<collection>/books
    final dstBooksDir = Directory(p.join(outDir.path, collId, 'books'));
    dstBooksDir.createSync(recursive: true);

    final index = <Map<String, dynamic>>[];
    var totalHadithInCollection = 0;

    for (final f in srcBooks) {
      // Copy the raw file as-is into books/
      final dstFile = File(p.join(dstBooksDir.path, p.basename(f.path)));
      await f.copy(dstFile.path);

      // Parse enough fields to build index
      try {
        final j = jsonDecode(await File(f.path).readAsString()) as Map<String, dynamic>;

        final bookId = (j['id'] as num?)?.toInt() ??
            int.tryParse(p.basenameWithoutExtension(f.path)) ??
            0;

        final metadata = (j['metadata'] as Map?) ?? {};
        final ar = (metadata['arabic'] as Map?) ?? {};
        final en = (metadata['english'] as Map?) ?? {};
        final enTitle = (en['title'] ?? '').toString();
        final arTitle = (ar['title'] ?? '').toString();
        final length = (metadata['length'] as num?)?.toInt() ??
            ((j['hadiths'] as List?)?.length ?? 0);

        totalHadithInCollection += length;

        index.add({
          'id': bookId,
          'file': p.basename(dstFile.path),
          'bookName': enTitle.isNotEmpty ? enTitle : (arTitle.isNotEmpty ? arTitle : p.basenameWithoutExtension(dstFile.path)),
          'length': length,
        });
      } catch (e) {
        stderr.writeln('⚠️  Failed to parse ${f.path}: $e');
      }
    }

    // Write index.json for this collection
    final indexFile = File(p.join(outDir.path, collId, 'index.json'));
    await indexFile.writeAsString(enc.convert(index));
    stdout.writeln('✔ $collId/index.json  (${index.length} books, $totalHadithInCollection hadith)');

    collectionsSummary.add({
      'id': collId,
      'title': _friendly(collId),
      'totalBooks': index.length,
      'totalHadith': totalHadithInCollection,
    });
  }

  // collections.json
  final collectionsJson = File(p.join(outDir.path, 'collections.json'));
  await collectionsJson.writeAsString(enc.convert(collectionsSummary));
  stdout.writeln('✔ collections.json (${collectionsSummary.length} collections)');

  // manifest.json
  final manifest = {
    'version': 1,
    'collections_path': 'assets/hadith/collections.json',
    'collection_path': 'assets/hadith/{collection}/index.json',
    'book_path': 'assets/hadith/{collection}/books/{file}',
  };
  final manifestJson = File(p.join(outDir.path, 'manifest.json'));
  await manifestJson.writeAsString(enc.convert(manifest));
  stdout.writeln('✔ manifest.json');

  stdout.writeln('✅ Done. Make sure pubspec.yaml includes assets/hadith/** as shown earlier.');
}

String _friendly(String id) => id
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
