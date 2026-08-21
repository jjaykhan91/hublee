// Builds the per-surah word-by-word English gloss assets.
//
//   dart run tools/build_word_by_word.dart [--minify]
//
// Input is the flat `"surah:ayah:word" -> "gloss"` dataset in tools/data.
// Output is one file per surah under assets/quran/en.wordbyword/, holding a
// gloss array per ayah:
//
//   { "1": ["In (the) name", "(of) Allah", ...], "2": [...] }
//
// The point of doing this at build time rather than in the app is alignment.
// The source data numbers words from 1 and counts the ayah-number marker as a
// trailing word, while our Arabic text also carries waqf signs and rosettes as
// separate tokens. Reconciling that in the reader would mean guessing on every
// frame. Instead this tool proves the two agree for all 6236 ayahs and writes
// arrays whose length equals the reader's own word count — so the reader just
// indexes. If a future data refresh breaks that, the build fails here.
//
// Attribution: the gloss text derives from "The Glorious Qur'an: Word-for-Word
// Translation to Facilitate Learning of Qur'anic Arabic" by Dr. Shehnaz Shaikh
// and Ms. Kausar Khatri, as distributed by the Quranic Arabic Corpus and QUL.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:hublee/quran/arabic_word_segmenter.dart';

/// Ayahs where our segmentation legitimately differs from the gloss data.
/// Keyed by `surah:ayah`; the value lists gloss indices (0-based) after which
/// a continuation marker is inserted.
///
/// 37:130 — the name Elijah is written as two tokens (إِلْ يَاسِينَ) but glossed
/// once, so the second token continues the first rather than standing alone.
const _continuationAfter = <String, List<int>>{
  '37:130': [2],
};

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'input',
      defaultsTo: 'tools/data/english-wbw-translation.json',
      help: 'Flat "s:a:w" -> gloss JSON source.',
    )
    ..addOption(
      'arabic',
      defaultsTo: 'assets/quran/ar',
      help: 'Directory of per-surah standard Uthmani text.',
    )
    ..addOption(
      'out',
      defaultsTo: 'assets/quran/en.wordbyword',
      help: 'Output directory for per-surah gloss files.',
    )
    ..addFlag(
      'minify',
      defaultsTo: true,
      negatable: true,
      help: 'Write compact JSON. These are data assets, so default is on.',
    );
  final opts = parser.parse(args);

  final inputFile = File(opts['input'] as String);
  if (!inputFile.existsSync()) {
    stderr.writeln('Source not found: ${inputFile.path}');
    exit(1);
  }

  final source =
      json.decode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  print('Loaded ${source.length} word entries from ${inputFile.path}');

  // Collapse "s:a:w" -> gloss into surah -> ayah -> ordered gloss list.
  final byAyah = <String, List<String?>>{};
  for (final entry in source.entries) {
    final parts = entry.key.split(':');
    if (parts.length != 3) {
      stderr.writeln('Malformed key: ${entry.key}');
      exit(1);
    }
    final ayahKey = '${parts[0]}:${parts[1]}';
    final position = int.parse(parts[2]);
    final list = byAyah.putIfAbsent(ayahKey, () => <String?>[]);
    while (list.length < position) {
      list.add(null);
    }
    list[position - 1] = entry.value?.toString().trim();
  }

  final outDir = Directory(opts['out'] as String);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final minify = opts['minify'] as bool;
  String encode(Object value) => minify
      ? jsonEncode(value)
      : const JsonEncoder.withIndent('  ').convert(value);

  final failures = <String>[];
  var totalAyahs = 0;
  var totalWords = 0;

  for (var surah = 1; surah <= 114; surah++) {
    final arabicFile = File(p.join(opts['arabic'] as String, '$surah.json'));
    if (!arabicFile.existsSync()) {
      failures.add('missing Arabic source for surah $surah');
      continue;
    }
    final arabic =
        json.decode(arabicFile.readAsStringSync()) as Map<String, dynamic>;

    final surahOut = <String, List<String>>{};

    for (final ayahEntry in arabic.entries) {
      final ayahNumber = ayahEntry.key;
      final ayahKey = '$surah:$ayahNumber';
      final text = ayahEntry.value.toString().trim();

      final raw = byAyah[ayahKey];
      if (raw == null) {
        failures.add('$ayahKey: no gloss data');
        continue;
      }
      // A blank position is intentional in the source: the word's meaning is
      // carried by the preceding gloss, as in بَعْدَ مَا -> "after what". Keep it
      // as an empty string so the reader can group the two into one phrase.
      final glosses = raw.map((g) => g ?? '').toList();
      if (glosses.isEmpty || glosses.first.isEmpty) {
        failures.add('$ayahKey: first word has no gloss to continue from');
        continue;
      }

      // The final position is the ayah-number marker, e.g. "(255)".
      final expectedMarker = '($ayahNumber)';
      if (glosses.last != expectedMarker) {
        failures.add(
          '$ayahKey: expected trailing marker "$expectedMarker", '
          'got "${glosses.last}"',
        );
        continue;
      }
      glosses.removeLast();

      for (final index in _continuationAfter[ayahKey] ?? const <int>[]) {
        if (index >= glosses.length) {
          failures.add('$ayahKey: continuation index $index out of range');
          continue;
        }
        glosses.insert(index + 1, '');
      }

      final words = segmentArabicWords(text);

      // Word ranges must tile the ayah, or the reader cannot map a character
      // offset (and therefore a tajweed cluster) to exactly one word.
      if (words.isNotEmpty &&
          (words.first.start != 0 || words.last.end != text.length)) {
        failures.add('$ayahKey: word ranges do not cover the text');
        continue;
      }

      if (words.length != glosses.length) {
        failures.add(
          '$ayahKey: ${words.length} words but ${glosses.length} glosses '
          '(${words.map((w) => w.text).take(4).join(" ")}…)',
        );
        continue;
      }

      surahOut[ayahNumber] = glosses;
      totalAyahs++;
      totalWords += glosses.length;
    }

    final outPath = p.join(outDir.path, '$surah.json');
    File(outPath).writeAsStringSync(encode(surahOut));
  }

  if (failures.isNotEmpty) {
    stderr.writeln('\n${failures.length} alignment failure(s):');
    for (final failure in failures.take(40)) {
      stderr.writeln('  $failure');
    }
    if (failures.length > 40) {
      stderr.writeln('  … and ${failures.length - 40} more');
    }
    stderr.writeln(
      '\nRefusing to ship misaligned glosses. Either fix the source data or '
      'add a documented entry to _continuationAfter.',
    );
    exit(1);
  }

  print('Aligned $totalAyahs ayahs / $totalWords words across 114 surahs');
  print('Wrote ${outDir.path}/1.json … 114.json');
}
