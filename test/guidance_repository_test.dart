/// Tests for bundled Allah, Prophet, and dua guides.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/guidance/guidance_models.dart';
import 'package:hublee/guidance/guidance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(GuidanceRepository.resetCache);

  test('allah.json has 99 names and required sections', () async {
    final guide = await const GuidanceRepository().loadAllah();
    expect(guide.names, hasLength(99));
    expect(guide.names.first.number, 1);
    expect(guide.names.last.number, 99);
    expect(guide.names.first.arabic, isNotEmpty);
    expect(guide.sectionById('who'), isNotNull);
    expect(guide.sectionById('tawhid'), isNotNull);
    expect(guide.sectionById('worship'), isNotNull);
    expect(guide.ayahs, isNotEmpty);
    expect(guide.namesNote, contains('Bukhari'));
    expect(
      guide.names.firstWhere((n) => n.number == 33).meaning,
      contains('Magnificent'),
    );
    expect(
      guide.names.firstWhere((n) => n.number == 89).transliteration,
      'Al Mughni',
    );
  });

  test('prophet.json has seerah sections and honorific', () async {
    final guide = await const GuidanceRepository().loadProphet();
    expect(guide.honorific, contains('peace be upon him'));
    expect(guide.sectionById('life'), isNotNull);
    expect(guide.sectionById('family'), isNotNull);
    expect(guide.sectionById('names'), isNotNull);
    expect(guide.sectionById('character'), isNotNull);
    expect(guide.sectionById('timeline')?.timeline, isNotEmpty);
  });

  test('dua catalog is Quran first, then Hisn al-Muslim', () async {
    final catalog = await const GuidanceRepository().loadDuas();
    expect(catalog.categories.first.id, 'quran');
    expect(catalog.categories.first.count, greaterThan(40));
    expect(catalog.categories.where((c) => !c.isQuran), isNotEmpty);
    final quranDua = catalog.categories.first.groups.first.duas.first;
    expect(quranDua.arabic, isNotEmpty);
    expect(quranDua.english, isNotEmpty);
    expect(quranDua.surahId, isNotNull);
    expect(quranDua.ayah, isNotNull);
  });

  test('Quranic 2:201 Arabic matches bundled Uthmani text', () {
    final duas =
        jsonDecode(File('assets/guidance/duas.json').readAsStringSync())
            as Map<String, dynamic>;
    final categories = duas['categories'] as List<dynamic>;
    final quran = categories.first as Map<String, dynamic>;
    expect(quran['id'], 'quran');
    DuaEntry? found;
    for (final group in quran['groups'] as List<dynamic>) {
      for (final raw in (group as Map)['duas'] as List<dynamic>) {
        final dua = DuaEntry.fromJson(Map<String, dynamic>.from(raw as Map));
        if (dua.surahId == 2 && dua.ayah == 201) {
          found = dua;
        }
      }
    }
    expect(found, isNotNull);
    final ar =
        jsonDecode(File('assets/quran/ar/2.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(found!.arabic, (ar['201'] as String).trim());
  });
}
