/// Tests for the Quranic dictionary index on Surah Al-Fatiha.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/quran/word_by_word_repository.dart';
import 'package:hublee/services/quran_dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    QuranDictionaryService.resetCache();
    WordByWordRepository.resetCache();
    QuranChaptersRepository.resetCache();
    QuranArabicRepository.resetCache();
  });

  test('Al-Fatiha index finds Allah by English and Arabic', () async {
    const service = QuranDictionaryService(maxSurahId: 1);
    final englishHits = await service.search('Allah');
    expect(englishHits, isNotEmpty);
    expect(englishHits.first.gloss.toLowerCase(), contains('allah'));

    final mercyHits = await service.search('mercy');
    expect(mercyHits, isNotEmpty);
    expect(
      mercyHits.any((hit) => hit.gloss.toLowerCase().contains('merciful')),
      isTrue,
    );

    final lordHits = await service.search('lord');
    expect(lordHits, isNotEmpty);
    expect(lordHits.first.gloss.toLowerCase(), contains('lord'));

    final godHits = await service.search('god');
    expect(godHits, isNotEmpty);
    expect(godHits.first.gloss.toLowerCase(), contains('allah'));

    final arabicHits = await service.search('الله');
    expect(arabicHits, isNotEmpty);
  });
}
