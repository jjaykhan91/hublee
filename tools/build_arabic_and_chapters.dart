// dart run tools/build_arabic_and_chapters.dart --out assets/quran [--minify]
// By default writes PRETTY-PRINTED JSON. Add --minify to write compact JSON.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

const api = 'https://api.quran.com/api/v4';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('out', defaultsTo: 'assets/quran', help: 'Output directory for assets.')
    ..addFlag('minify',
        defaultsTo: false,
        negatable: true,
        help: 'Write compact JSON (no indentation). Default is pretty-printed.');
  final opts = parser.parse(args);

  final outDir = Directory(opts['out'] as String);
  final minify = opts['minify'] as bool;

  if (!await outDir.exists()) await outDir.create(recursive: true);

  String toJson(Object value) =>
      minify ? jsonEncode(value) : const JsonEncoder.withIndent('  ').convert(value);

  final dio = Dio(BaseOptions(
    baseUrl: api,
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  // 1) Chapters
  stdout.writeln('📖 Fetching chapters…');
  final chaptersRes = await dio.get('/chapters', queryParameters: {'language': 'en'});
  if (chaptersRes.statusCode != 200) {
    stderr.writeln('chapters: HTTP ${chaptersRes.statusCode}');
    exit(1);
  }
  final chapters = (chaptersRes.data['chapters'] as List).map((c) => {
        'id': c['id'],
        'name_simple': c['name_simple'],
        'name_arabic': c['name_arabic'],
        'revelation_place': c['revelation_place'],
        'verses_count': c['verses_count'],
      }).toList();

  final chaptersPath = p.join(outDir.path, 'chapters.min.json'); // keep filename for app
  await File(chaptersPath).writeAsString(toJson(chapters));
  stdout.writeln('✔ $chaptersPath');

  // 2) Arabic Uthmani per-surah shards
  final arDir = Directory(p.join(outDir.path, 'ar'));
  if (!await arDir.exists()) await arDir.create(recursive: true);

  for (int s = 1; s <= 114; s++) {
    final map = await _getArabicBySurah(dio, s);
    final filePath = p.join(arDir.path, '$s.json');
    await File(filePath).writeAsString(toJson(map));
    stdout.writeln('✔ ar/$s.json (${map.length} ayat)');
    await Future.delayed(const Duration(milliseconds: 80)); // be polite
  }

  stdout.writeln('✅ Arabic & chapters built to ${outDir.path}');
}

Future<Map<String, String>> _getArabicBySurah(Dio dio, int surah) async {
  final result = <String, String>{};
  int page = 1;
  while (true) {
    final r = await dio.get('/verses/by_chapter/$surah', queryParameters: {
      'page': page,
      'per_page': 50,
      'fields': 'text_uthmani',
      'language': 'en',
    });
    if (r.statusCode != 200) {
      throw Exception('verses $surah p$page: HTTP ${r.statusCode}');
    }
    final verses = (r.data['verses'] as List).cast<Map<String, dynamic>>();
    for (final v in verses) {
      final verseNum = (v['verse_number'] as num).toInt();
      final ar = (v['text_uthmani'] ??
                  v['text_indopak'] ??
                  v['text_arabic'] ??
                  '')
          .toString();
      result['$verseNum'] = ar;
    }
    final meta = (r.data['pagination'] ?? r.data['meta']) as Map<String, dynamic>?;
    final next = meta?['next_page'];
    if (next == null) break;
    page = next is int ? next : int.tryParse(next.toString()) ?? (page + 1);
  }
  return result;
}
