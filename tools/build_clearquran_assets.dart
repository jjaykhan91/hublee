// dart run tools/build_clearquran_assets.dart [--minify]
// Reads assets/quran/translations/TheClearQuran_MK_2018.json
// and writes decoded per-surah files to assets/quran/en.clearquran/.

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

String _decodeHtmlEntities(String s) {
  if (s.isEmpty) return s;

  // 1) named entities (minimal set commonly seen)
  const named = {
    'amp': '&',
    'quot': '"',
    'apos': "'",
    'lt': '<',
    'gt': '>',
    'nbsp': ' ', // just in case
  };
  s = s.replaceAllMapped(RegExp(r'&([a-zA-Z]+);'), (m) {
    final k = m.group(1)!.toLowerCase();
    return named[k] ?? m.group(0)!;
  });

  // 2) numeric decimal: &#1234;
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });

  // 3) numeric hex: &#x1F4A9;
  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });

  return s;
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('minify',
        defaultsTo: false,
        help: 'Write compact JSON (default pretty).');
  final opts = parser.parse(args);
  final minify = opts['minify'] as bool;

  final inputPath = 'assets/quran/translations/TheClearQuran_MK_2018.json';
  final outputDir = Directory('assets/quran/en.clearquran');

  String toJson(Object value) =>
      minify ? jsonEncode(value) : const JsonEncoder.withIndent('  ').convert(value);

  if (!await outputDir.exists()) await outputDir.create(recursive: true);

  final src = File(inputPath);
  if (!await src.exists()) {
    stderr.writeln('❌ Input not found: $inputPath');
    exit(1);
  }

  final root = jsonDecode(await src.readAsString());
  if (root is! Map<String, dynamic>) {
    stderr.writeln('❌ Unexpected JSON shape in $inputPath');
    exit(1);
  }

  int written = 0;
  for (var s = 1; s <= 114; s++) {
    final key = '$s';
    final surah = root[key];
    if (surah is! Map) {
      stderr.writeln('⚠️ Missing surah $s in source; skipping.');
      continue;
    }
    final ayahs = surah['Ayahs'];
    if (ayahs is! Map) {
      stderr.writeln('⚠️ Surah $s missing "Ayahs"; skipping.');
      continue;
    }

    final out = <String, String>{};
    ayahs.forEach((k, v) {
      if (v is Map && v.containsKey('Mustafa Khattab 2018')) {
        var text = (v['Mustafa Khattab 2018'] ?? '').toString();
        text = text.replaceAll(RegExp(r'</?i>'), ''); // strip italics tags
        text = _decodeHtmlEntities(text).trim();      // ← decode entities
        if (text.isNotEmpty) out[k.toString()] = text;
      }
    });

    final file = File(p.join(outputDir.path, '$s.json'));
    await file.writeAsString(toJson(out));
    stdout.writeln('✔ en.clearquran/$s.json (${out.length} ayat)');
    written++;
  }

  stdout.writeln('✅ Done: $written files → ${outputDir.path}');
}
