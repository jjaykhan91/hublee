// Builds offline guidance assets: Allah (with 99 names), Prophet, and duas.
//
//   dart run tools/build_guidance.dart
//
// Quranic du'as are extracted from Hublee's own Uthmani + ClearQuran
// files so the Arabic is never scraped. Hisnul Muslim is flattened from
// the bundled JSON. The 99 names come from Aladhan's Asma al-Husna API
// snapshot, with English typos corrected and optional Quran citations.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// English glosses in the Aladhan snapshot that need a spelling fix.
const _meaningFixes = <String, String>{
  'The Maginificent': 'The Magnificent',
  'The Inhertior': 'The Inheritor',
  'The Owner / Soverign of All': 'The Owner / Sovereign of All',
  'The Guide to Repentence': 'The Guide to Repentance',
  'The Forebearing': 'The Forbearing',
  'The inspirer of faith': 'The Inspirer of Faith',
};

/// Transliteration cleanups (whitespace / well-known truncation).
const _translFixes = <String, String>{
  'Al Mujeeb ': 'Al Mujeeb',
  'Al Mughi': 'Al Mughni',
};

/// Quran citations for names that appear plainly in the text.
/// Keyed by the traditional list number (1–99).
const _nameAyahs = <int, (int surah, int ayah)>{
  1: (55, 1),
  2: (1, 3),
  3: (59, 23),
  4: (59, 23),
  5: (59, 23),
  6: (59, 23),
  7: (59, 23),
  8: (59, 23),
  9: (59, 23),
  10: (59, 23),
  11: (59, 24),
  12: (59, 24),
  13: (59, 24),
  26: (2, 127),
  27: (4, 58),
  33: (2, 255),
  34: (2, 173),
  36: (2, 255),
  51: (22, 6),
  62: (2, 255),
  63: (2, 255),
  67: (112, 1),
  68: (112, 2),
  73: (57, 3),
  74: (57, 3),
  75: (57, 3),
  76: (57, 3),
  93: (24, 35),
};

class _QuranDua {
  const _QuranDua({
    required this.surah,
    required this.start,
    required this.end,
    required this.title,
    this.note,
    this.group = 'Rabbana — Our Lord',
  });

  final int surah;
  final int start;
  final int end;
  final String title;
  final String? note;
  final String group;
}

/// Quranic du'as: the common Rabbana collection plus well-known extras.
/// Arabic and English are filled from bundled Quran JSON at build time.
const _quranDuas = <_QuranDua>[
  _QuranDua(
    surah: 1,
    start: 5,
    end: 7,
    title: 'Guide us along the Straight Path',
    group: 'Opening of the Book',
  ),
  _QuranDua(surah: 2, start: 127, end: 127, title: 'Accept this from us'),
  _QuranDua(
    surah: 2,
    start: 128,
    end: 128,
    title: 'Make us Muslims, and from our descendants a Muslim nation',
  ),
  _QuranDua(
    surah: 2,
    start: 201,
    end: 201,
    title: 'Good in this world and the next',
    note:
        'Anas (may Allah be pleased with him) said this was the du\'a '
        'the Prophet (peace be upon him) recited most often '
        '(Sahih al-Bukhari 6389).',
  ),
  _QuranDua(
    surah: 2,
    start: 250,
    end: 250,
    title: 'Pour patience on us and make our feet firm',
  ),
  _QuranDua(
    surah: 2,
    start: 285,
    end: 285,
    title: 'We hear and we obey',
    note:
        'The last two verses of Al-Baqarah: the Prophet (peace be upon him) '
        'said that whoever recites them at night, they will suffice him '
        '(Sahih al-Bukhari 5009).',
  ),
  _QuranDua(
    surah: 2,
    start: 286,
    end: 286,
    title: 'Do not take us to account if we forget or err',
  ),
  _QuranDua(
    surah: 3,
    start: 8,
    end: 8,
    title: 'Do not let our hearts deviate after You have guided us',
  ),
  _QuranDua(
    surah: 3,
    start: 9,
    end: 9,
    title: 'You will surely gather all people',
  ),
  _QuranDua(
    surah: 3,
    start: 16,
    end: 16,
    title: 'We have believed, so forgive our sins',
  ),
  _QuranDua(
    surah: 3,
    start: 38,
    end: 38,
    title: 'Grant me from Yourself good offspring',
  ),
  _QuranDua(
    surah: 3,
    start: 53,
    end: 53,
    title: 'We have believed in what You revealed',
  ),
  _QuranDua(
    surah: 3,
    start: 147,
    end: 147,
    title: 'Forgive us, make our feet firm, and give us victory',
  ),
  _QuranDua(
    surah: 3,
    start: 191,
    end: 191,
    title: 'You did not create this in vain',
  ),
  _QuranDua(
    surah: 3,
    start: 192,
    end: 192,
    title: 'Whomever You enter into the Fire',
  ),
  _QuranDua(
    surah: 3,
    start: 193,
    end: 193,
    title: 'We heard a caller to faith',
  ),
  _QuranDua(
    surah: 3,
    start: 194,
    end: 194,
    title: 'Give us what You promised through Your messengers',
  ),
  _QuranDua(
    surah: 5,
    start: 83,
    end: 83,
    title: 'Write us down among the witnesses',
  ),
  _QuranDua(
    surah: 5,
    start: 114,
    end: 114,
    title: 'Send down a table-spread from heaven',
  ),
  _QuranDua(surah: 7, start: 23, end: 23, title: 'We have wronged ourselves'),
  _QuranDua(
    surah: 7,
    start: 47,
    end: 47,
    title: 'Do not place us with the wrongdoing people',
  ),
  _QuranDua(
    surah: 7,
    start: 89,
    end: 89,
    title: 'Decide between us and our people with truth',
  ),
  _QuranDua(
    surah: 7,
    start: 126,
    end: 126,
    title: 'Pour patience on us and let us die as Muslims',
  ),
  _QuranDua(surah: 7, start: 151, end: 151, title: 'Forgive me and my brother'),
  _QuranDua(
    surah: 7,
    start: 155,
    end: 155,
    title: 'You are our Protector, so forgive us',
  ),
  _QuranDua(
    surah: 10,
    start: 85,
    end: 86,
    title: 'Do not make us a trial for the wrongdoing people',
  ),
  _QuranDua(
    surah: 14,
    start: 38,
    end: 38,
    title: 'You know what we conceal and what we reveal',
  ),
  _QuranDua(
    surah: 14,
    start: 40,
    end: 40,
    title: 'Make me an establisher of prayer',
  ),
  _QuranDua(
    surah: 14,
    start: 41,
    end: 41,
    title: 'Forgive me, my parents, and the believers',
  ),
  _QuranDua(
    surah: 17,
    start: 24,
    end: 24,
    title: 'My Lord, have mercy on my parents',
  ),
  _QuranDua(
    surah: 17,
    start: 80,
    end: 80,
    title: 'Cause me to enter and exit with truth',
  ),
  _QuranDua(
    surah: 18,
    start: 10,
    end: 10,
    title: 'Grant us mercy from Yourself',
  ),
  _QuranDua(
    surah: 20,
    start: 25,
    end: 28,
    title: 'Expand my chest and ease my task',
  ),
  _QuranDua(
    surah: 20,
    start: 114,
    end: 114,
    title: 'My Lord, increase me in knowledge',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 23,
    start: 29,
    end: 29,
    title: 'Land me at a blessed landing place',
  ),
  _QuranDua(
    surah: 23,
    start: 97,
    end: 98,
    title: 'I seek refuge in You from the whispers of the devils',
  ),
  _QuranDua(
    surah: 23,
    start: 109,
    end: 109,
    title: 'We have believed, so forgive us and have mercy',
  ),
  _QuranDua(
    surah: 23,
    start: 118,
    end: 118,
    title: 'My Lord, forgive and have mercy',
  ),
  _QuranDua(
    surah: 25,
    start: 65,
    end: 66,
    title: 'Turn the punishment of Hell away from us',
  ),
  _QuranDua(
    surah: 25,
    start: 74,
    end: 74,
    title: 'Grant us coolness of the eyes in our spouses and children',
  ),
  _QuranDua(
    surah: 26,
    start: 83,
    end: 85,
    title: 'Grant me wisdom and join me with the righteous',
  ),
  _QuranDua(
    surah: 28,
    start: 24,
    end: 24,
    title: 'I am in need of whatever good You send down',
  ),
  _QuranDua(
    surah: 40,
    start: 7,
    end: 8,
    title: 'The angels\' prayer for the believers',
  ),
  _QuranDua(
    surah: 46,
    start: 15,
    end: 15,
    title: 'Inspire me to be grateful and make my offspring righteous',
  ),
  _QuranDua(
    surah: 59,
    start: 10,
    end: 10,
    title: 'Forgive us and our brothers who preceded us in faith',
  ),
  _QuranDua(
    surah: 60,
    start: 4,
    end: 5,
    title: 'In You we trust; do not make us a trial',
  ),
  _QuranDua(
    surah: 66,
    start: 8,
    end: 8,
    title: 'Perfect our light and forgive us',
  ),
  _QuranDua(
    surah: 12,
    start: 101,
    end: 101,
    title: 'Take my soul in submission and join me with the righteous',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 21,
    start: 83,
    end: 83,
    title: 'Adversity has touched me',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 21,
    start: 87,
    end: 87,
    title: 'There is no god except You; I have done wrong',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 21,
    start: 89,
    end: 89,
    title: 'Do not leave me childless',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 37,
    start: 100,
    end: 100,
    title: 'Grant me one of the righteous',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 38,
    start: 35,
    end: 35,
    title: 'Forgive me and grant me a kingdom',
    group: 'Prophets in the Quran',
  ),
  _QuranDua(
    surah: 71,
    start: 28,
    end: 28,
    title: 'Forgive me, my parents, and whoever enters my house as a believer',
    group: 'Prophets in the Quran',
  ),
];

Future<void> main() async {
  final root = Directory.current.path;
  final outDir = Directory(p.join(root, 'assets', 'guidance'));
  outDir.createSync(recursive: true);

  await _writeAllah(root, outDir.path);
  await _writeProphet(root, outDir.path);
  await _writeDuas(root, outDir.path);
  print('Wrote assets/guidance/{allah,prophet,duas}.json');
}

Future<void> _writeAllah(String root, String outDir) async {
  final contentFile = File(
    p.join(root, 'tools', 'data', 'guidance', 'allah_content.json'),
  );
  final namesFile = File(
    p.join(root, 'tools', 'data', 'guidance', 'asma_al_husna.json'),
  );
  final content =
      jsonDecode(await contentFile.readAsString()) as Map<String, dynamic>;
  final api =
      jsonDecode(await namesFile.readAsString()) as Map<String, dynamic>;
  final rows = api['data'];
  if (rows is! List || rows.length != 99) {
    stderr.writeln('Expected 99 names in asma_al_husna.json, got $rows');
    exitCode = 1;
    return;
  }

  final names = <Map<String, dynamic>>[];
  for (final row in rows) {
    if (row is! Map) continue;
    final number = row['number'] as int;
    final arabic = (row['name'] as String).trim();
    var transl = (row['transliteration'] as String).trim();
    transl = _translFixes[transl] ?? transl;
    final en = row['en'];
    var meaning = '';
    if (en is Map && en['meaning'] is String) {
      meaning = (en['meaning'] as String).trim();
    }
    meaning = _meaningFixes[meaning] ?? meaning;
    final entry = <String, dynamic>{
      'number': number,
      'arabic': arabic,
      'transliteration': transl,
      'meaning': meaning,
    };
    final ayah = _nameAyahs[number];
    if (ayah != null) {
      entry['surahId'] = ayah.$1;
      entry['ayah'] = ayah.$2;
    }
    names.add(entry);
  }
  if (names.length != 99) {
    stderr.writeln('Parsed ${names.length} names, expected 99');
    exitCode = 1;
    return;
  }

  content['names'] = names;
  await File(
    p.join(outDir, 'allah.json'),
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(content)}\n');
}

Future<void> _writeProphet(String root, String outDir) async {
  final src = File(p.join(root, 'tools', 'data', 'guidance', 'prophet.json'));
  await File(
    p.join(outDir, 'prophet.json'),
  ).writeAsString(await src.readAsString());
}

Future<void> _writeDuas(String root, String outDir) async {
  final quranCategory = await _buildQuranCategory(root);
  final hisnul = await _buildHisnulCategories(root);
  final catalog = <String, dynamic>{
    'sourceNote':
        'Quranic du\'as use Hublee\'s Uthmani Arabic (quran.com text_uthmani) '
        'and ClearQuran English. The Rabbana set follows the well-known '
        'collection of Quranic "Our Lord" prayers (indexes such as '
        'MyIslam and FivePrayer), plus other famous prophetic du\'as in '
        'the Quran. Sunnah du\'as are from Hisn al-Muslim (Fortress of the '
        'Muslim) by Sa\'id ibn Ali ibn Wahf al-Qahtani, bundled from a '
        'public JSON of that compilation. Each sunnah entry keeps its '
        'book citation as given; Hublee does not add a grade.',
    'categories': <dynamic>[quranCategory, ...hisnul],
  };
  await File(p.join(outDir, 'duas.json')).writeAsString(jsonEncode(catalog));
}

Future<Map<String, dynamic>> _buildQuranCategory(String root) async {
  final bySurah = <int, ({Map<String, String> ar, Map<String, String> en})>{};
  final groups = <String, List<Map<String, dynamic>>>{};

  for (final dua in _quranDuas) {
    final texts = bySurah[dua.surah] ??= await _loadSurah(root, dua.surah);
    final arabicParts = <String>[];
    final englishParts = <String>[];
    for (var n = dua.start; n <= dua.end; n++) {
      final key = '$n';
      final ar = texts.ar[key];
      final en = texts.en[key];
      if (ar == null || ar.trim().isEmpty) {
        throw StateError('Missing Arabic for ${dua.surah}:$n');
      }
      if (en == null || en.trim().isEmpty) {
        throw StateError('Missing English for ${dua.surah}:$n');
      }
      arabicParts.add(ar.trim());
      englishParts.add(en.trim());
    }
    final ref = dua.start == dua.end
        ? 'Quran ${dua.surah}:${dua.start}'
        : 'Quran ${dua.surah}:${dua.start}–${dua.end}';
    final entry = <String, dynamic>{
      'id':
          'quran-${dua.surah}-${dua.start}'
          '${dua.end != dua.start ? '-${dua.end}' : ''}',
      'title': dua.title,
      'arabic': arabicParts.join('\n'),
      'english': englishParts.join('\n'),
      'source': ref,
      'surahId': dua.surah,
      'ayah': dua.start,
    };
    if (dua.end != dua.start) entry['ayahEnd'] = dua.end;
    if (dua.note != null) entry['note'] = dua.note;
    groups.putIfAbsent(dua.group, () => []).add(entry);
  }

  final groupList = groups.entries
      .map((e) => <String, dynamic>{'title': e.key, 'duas': e.value})
      .toList(growable: false);
  final count = groups.values.fold<int>(0, (n, list) => n + list.length);
  return <String, dynamic>{
    'id': 'quran',
    'title': 'Quranic du\'as',
    'subtitle': 'Rabbana and other prayers from the Quran',
    'kind': 'quran',
    'count': count,
    'groups': groupList,
  };
}

Future<({Map<String, String> ar, Map<String, String> en})> _loadSurah(
  String root,
  int surahId,
) async {
  Map<String, String> parse(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! Map) {
      throw StateError('Expected a map in $path');
    }
    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }

  final ar = parse(p.join(root, 'assets', 'quran', 'ar', '$surahId.json'));
  final en = parse(
    p.join(root, 'assets', 'quran', 'en.clearquran', '$surahId.json'),
  );
  return (ar: ar, en: en);
}

Future<List<Map<String, dynamic>>> _buildHisnulCategories(String root) async {
  final file = File(
    p.join(root, 'tools', 'data', 'guidance', 'hisnul_muslim.json'),
  );
  final rootJson = jsonDecode(await file.readAsString());
  if (rootJson is! Map) {
    throw StateError('Hisnul Muslim JSON must be a map');
  }
  final segments = rootJson['segments'];
  if (segments is! List) {
    throw StateError('Hisnul Muslim JSON missing segments');
  }

  final categories = <Map<String, dynamic>>[];
  for (final segment in segments) {
    if (segment is! Map) continue;
    final segmentName = '${segment['segment_name'] ?? ''}'.trim();
    // Quranic Arabic in this dump is simplified and sometimes split
    // mid-ayah. Hublee's "From the Quran" category uses our Uthmani
    // text instead.
    if (segmentName == 'Quranic Duas') continue;
    final cats = segment['categories'];
    if (cats is! List) continue;
    for (final cat in cats) {
      if (cat is! Map) continue;
      final id = 'hisnul-${cat['category_id']}';
      final title = '${cat['category_name'] ?? ''}'.trim();
      if (title.isEmpty) continue;
      final groups = <Map<String, dynamic>>[];
      var count = 0;
      final titles = cat['titles'];
      if (titles is List) {
        for (final t in titles) {
          if (t is! Map) continue;
          final groupTitle = '${t['title_name'] ?? ''}'.trim();
          final duas = <Map<String, dynamic>>[];
          final rawDuas = t['duas'];
          if (rawDuas is List) {
            for (final d in rawDuas) {
              if (d is! Map) continue;
              final arabic = '${d['arabic'] ?? ''}'.trim();
              final english = '${d['translation'] ?? ''}'.trim();
              if (arabic.isEmpty || english.isEmpty) continue;
              final latin = '${d['latin'] ?? ''}'.trim();
              final source = '${d['source'] ?? ''}'.trim();
              var note = d['benefits'] is String
                  ? (d['benefits'] as String).trim()
                  : '';
              note = _honorifics(note);
              final entry = <String, dynamic>{
                'id': 'hisnul-dua-${d['id']}',
                'arabic': arabic,
                'english': english,
                'source': source.isEmpty ? 'Hisn al-Muslim' : source,
              };
              if (latin.isNotEmpty) entry['transliteration'] = latin;
              if (note.isNotEmpty) entry['note'] = note;
              duas.add(entry);
            }
          }
          if (duas.isEmpty) continue;
          count += duas.length;
          groups.add(<String, dynamic>{
            'title': groupTitle.isEmpty ? title : groupTitle,
            'duas': duas,
          });
        }
      }
      if (groups.isEmpty) continue;
      categories.add(<String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': segmentName.isEmpty ? 'Hisn al-Muslim' : segmentName,
        'kind': 'sunnah',
        'count': count,
        'groups': groups,
      });
    }
  }
  return categories;
}

String _honorifics(String text) {
  return text
      .replaceAll('Prophet (SAW)', 'Prophet (peace be upon him)')
      .replaceAll('Prophet(SAW)', 'Prophet (peace be upon him)')
      .replaceAll('(SAW)', '(peace be upon him)')
      .replaceAll('(PBUH)', '(peace be upon him)');
}
