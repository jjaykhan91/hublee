// dart run tools/build_surah_info.dart [--out assets/quran]
//
// Downloads chapter info (short_text + text) for all 114 surahs
// from the quran.com API and saves to surah_info.json.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

const api = 'https://api.quran.com/api/v4';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'out',
      defaultsTo: 'assets/quran',
      help: 'Output directory for assets.',
    );
  final opts = parser.parse(args);

  final outDir = Directory(opts['out'] as String);
  if (!await outDir.exists()) await outDir.create(recursive: true);

  final dio = Dio(
    BaseOptions(
      baseUrl: api,
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final results = <Map<String, dynamic>>[];

  for (int id = 1; id <= 114; id++) {
    try {
      final res = await dio.get(
        '/chapters/$id/info',
        queryParameters: {'language': 'en'},
      );
      if (res.statusCode != 200) {
        stderr.writeln('chapter $id info: HTTP ${res.statusCode}');
        results.add({'id': id, 'short_text': '', 'text': '', 'source': ''});
        continue;
      }

      final info = res.data['chapter_info'] as Map<String, dynamic>;
      results.add({
        'id': id,
        'short_text': (info['short_text'] as String?) ?? '',
        'text': (info['text'] as String?) ?? '',
        'source': (info['source'] as String?) ?? '',
      });
      stdout.writeln('  $id/114');
    } catch (e) {
      stderr.writeln('chapter $id info: $e');
      results.add({'id': id, 'short_text': '', 'text': '', 'source': ''});
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  final outFile = File(p.join(outDir.path, 'surah_info.json'));
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(results),
  );
  stdout.writeln('Saved ${outFile.path} (${results.length} surahs)');
}
