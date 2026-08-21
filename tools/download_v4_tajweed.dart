// dart run tools/download_v4_tajweed.dart [--fonts-only] [--script-only]
//
// Downloads QPC V4 Tajweed assets for font-based tajweed (same approach as
// Quran.com). When both script and fonts are present, the app uses them
// instead of the software tajweed engine.
//
// NOTE: The GitHub repo "TarteelAI/quranic-universal-library" is the QUL
// *backend/CMS* — it is NOT where you download the script or fonts. The data
// comes from the QUL website and CDN. See docs/V4_TAJWEED_SOURCES.md.
//
// 1) V4 script JSON: Download manually from the QUL website:
//    https://qul.tarteel.ai/resources/quran-script/47
//    Click "Download json", then save as: assets/quran/qpc-v4.json
//    If that page/link doesn't work, use the app with software tajweed only
//    (no V4 script); see docs/V4_TAJWEED_SOURCES.md.
//
// 2) Fonts: This script downloads p1.ttf–p604.ttf from Tarteel's CDN
//    into assets/fonts/qpc_v4_tajweed/.
//
// Run from repo root: dart run tools/download_v4_tajweed.dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

const _fontBaseUrl =
    'https://static-cdn.tarteel.ai/qul/fonts/quran_fonts/v4-tajweed/ttf';
const _totalPages = 604;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'fonts-only',
      defaultsTo: false,
      help: 'Only download fonts (skip script reminder).',
    )
    ..addFlag(
      'script-only',
      defaultsTo: false,
      help: 'Only print script download instructions.',
    );
  final opts = parser.parse(args);

  if (opts['script-only'] as bool) {
    _printScriptInstructions();
    return;
  }

  if (!(opts['fonts-only'] as bool)) {
    _printScriptInstructions();
    stdout.writeln();
  }

  final projectRoot = _findProjectRoot();
  final fontDir = Directory(
    p.join(projectRoot, 'assets', 'fonts', 'qpc_v4_tajweed'),
  );
  if (!await fontDir.exists()) await fontDir.create(recursive: true);

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
    ),
  );

  stdout.writeln('Downloading QPC V4 Tajweed fonts (1–$_totalPages)...');
  var done = 0;
  for (var page = 1; page <= _totalPages; page++) {
    final name = 'p$page.ttf';
    final url = '$_fontBaseUrl/$name';
    final file = File(p.join(fontDir.path, name));
    if (await file.exists()) {
      done++;
      if (page % 100 == 0) stdout.writeln('  $page/$_totalPages (cached)');
      continue;
    }
    try {
      await dio.download(url, file.path);
      done++;
      if (page % 50 == 0 || page == _totalPages) {
        stdout.writeln('  $page/$_totalPages');
      }
    } catch (e) {
      stderr.writeln('Failed to download $name: $e');
    }
  }
  stdout.writeln('Done. $done/$_totalPages font files in ${fontDir.path}');
}

void _printScriptInstructions() {
  stdout.writeln('V4 Tajweed script (required for font-based tajweed):');
  stdout.writeln('  1. Open https://qul.tarteel.ai/resources/quran-script/47');
  stdout.writeln('  2. Click "Download json"');
  stdout.writeln('  3. Save as: assets/quran/qpc-v4.json');
  stdout.writeln('  4. Replace the placeholder file if it exists.');
  stdout.writeln('');
  stdout.writeln('If that link does not work: see docs/V4_TAJWEED_SOURCES.md.');
}

String _findProjectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}
