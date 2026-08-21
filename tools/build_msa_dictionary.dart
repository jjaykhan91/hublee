// Builds assets/arabic/msa_dictionary.json
//
//   dart run tools/build_msa_dictionary.dart
//
// Merges a bundled newspaper/MSA core with Wiktionary Arabic entries
// streamed from kaikki.org (CC-BY-SA 3.0 / GFDL). The core ships even
// if the download fails, so the Modern Arabic dictionary never depends
// on the network at runtime.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const _wiktionaryUrl =
    'https://kaikki.org/dictionary/Arabic/kaikki.org-dictionary-Arabic.jsonl';

const _skipPos = {
  'character',
  'suffix',
  'prefix',
  'infix',
  'circumfix',
  'punct',
  'symbol',
  'name',
};

final _arabicLetter = RegExp(r'[\u0600-\u06FF]');
final _dialectTag = RegExp(
  r'egypt|egyptian|moroccan|levantine|dialect',
  caseSensitive: false,
);

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'core-only',
      help: 'Skip the Wiktionary download and emit the core list.',
    );
  final parsed = parser.parse(args);
  final coreOnly = parsed['core-only'] as bool;
  final root = Directory.current.path;
  final corePath = p.join(root, 'tools', 'data', 'msa_core.json');
  final outPath = p.join(root, 'assets', 'arabic', 'msa_dictionary.json');

  final coreRaw = jsonDecode(await File(corePath).readAsString());
  final coreEntries = (coreRaw['entries'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final byKey = <String, Map<String, dynamic>>{};
  for (final entry in coreEntries) {
    byKey[_key(entry)] = Map<String, dynamic>.from(entry);
  }
  print('Core entries: ${byKey.length}');

  if (!coreOnly) {
    try {
      final extra = await _streamWiktionary();
      var added = 0;
      for (final entry in extra) {
        final key = _key(entry);
        if (byKey.containsKey(key)) continue;
        byKey[key] = entry;
        added++;
      }
      print('Wiktionary added: $added');
    } catch (error) {
      print('Wiktionary download skipped: $error');
    }
  }

  final entries = byKey.values.toList()
    ..sort((a, b) => (a['en'] as String).compareTo(b['en'] as String));

  final out = {
    'source':
        'Hublee MSA core plus Wiktionary Arabic (English edition) via '
        'kaikki.org / wiktextract',
    'license': 'CC-BY-SA 3.0 and GNU FDL for Wiktionary rows',
    'attribution': 'https://en.wiktionary.org and https://kaikki.org',
    'entries': entries,
  };

  await Directory(p.dirname(outPath)).create(recursive: true);
  await File(outPath).writeAsString(const JsonEncoder().convert(out));
  print('Wrote ${entries.length} entries to $outPath');
}

String _key(Map<String, dynamic> entry) =>
    '${entry['ar']}|${(entry['en'] as String).toLowerCase()}';

Future<List<Map<String, dynamic>>> _streamWiktionary() async {
  final client = HttpClient();
  client.userAgent = 'Hublee/1.0 (MSA dictionary build; offline Quran app)';
  final request = await client.getUrl(Uri.parse(_wiktionaryUrl));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw StateError('Wiktionary HTTP ${response.statusCode}');
  }

  final entries = <Map<String, dynamic>>[];
  final seen = <String>{};
  var buffer = '';
  var lines = 0;

  await for (final chunk in response.transform(utf8.decoder)) {
    buffer += chunk;
    var newline = buffer.indexOf('\n');
    while (newline >= 0) {
      final line = buffer.substring(0, newline);
      buffer = buffer.substring(newline + 1);
      newline = buffer.indexOf('\n');
      lines++;
      final parsed = _parseLine(line);
      if (parsed == null) continue;
      final key = _key(parsed);
      if (!seen.add(key)) continue;
      entries.add(parsed);
      if (entries.length % 3000 == 0) {
        print('Parsed $lines lines, kept ${entries.length}');
      }
    }
  }

  final tail = _parseLine(buffer);
  if (tail != null && seen.add(_key(tail))) {
    entries.add(tail);
  }
  client.close(force: true);
  print('Finished Wiktionary: $lines lines, ${entries.length} kept');
  return entries;
}

Map<String, dynamic>? _parseLine(String line) {
  if (line.isEmpty) return null;
  Map<String, dynamic> obj;
  try {
    obj = jsonDecode(line) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }

  final word = obj['word'] as String? ?? '';
  if (word.isEmpty || !_arabicLetter.hasMatch(word)) return null;

  final pos = obj['pos'] as String? ?? '';
  if (_skipPos.contains(pos)) return null;

  final gloss = _firstGloss(obj);
  if (gloss == null) return null;

  final entry = <String, dynamic>{'ar': word, 'en': gloss, 'pos': pos};
  final root = _rootOf(obj);
  if (root != null) entry['root'] = root;
  return entry;
}

String? _firstGloss(Map<String, dynamic> obj) {
  final senses = obj['senses'];
  if (senses is! List) return null;
  for (final sense in senses) {
    if (sense is! Map) continue;
    final tags = [
      ...?sense['tags'] as List?,
      ...?obj['tags'] as List?,
    ].map((tag) => tag.toString()).toList();
    if (tags.any(_dialectTag.hasMatch)) continue;
    if (tags.contains('no-gloss')) continue;
    final glosses = sense['glosses'];
    if (glosses is! List || glosses.isEmpty) continue;
    var text = glosses.first.toString().trim();
    if (text.isEmpty) continue;
    if (text.length > 120) text = '${text.substring(0, 117)}...';
    return text;
  }
  return null;
}

String? _rootOf(Map<String, dynamic> obj) {
  final forms = obj['forms'];
  if (forms is List) {
    for (final form in forms) {
      if (form is! Map) continue;
      final tags = form['tags'];
      if (tags is List && tags.map((tag) => tag.toString()).contains('root')) {
        final value = (form['form'] as String?)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
  }
  final categories = obj['categories'];
  if (categories is List) {
    for (final category in categories) {
      final text = category.toString();
      const marker = 'belonging to the root ';
      final at = text.indexOf(marker);
      if (at >= 0) {
        return text.substring(at + marker.length).trim();
      }
    }
  }
  return null;
}
