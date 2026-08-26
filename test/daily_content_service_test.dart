/// Tests for daily verse sharing the mushaf decode with search.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/quran/word_by_word_repository.dart';
import 'package:hublee/services/daily_content_service.dart';
import 'package:hublee/services/msa_dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DailyContentService.resetCache();
    QuranArabicRepository.resetCache();
    QuranTranslationRepository.resetCache();
    WordByWordRepository.resetCache();
    MsaDictionaryService.resetCache();
  });

  test('verse of the day loads through QuranArabicRepository', () async {
    final verse = await DailyContentService.loadVerseOfTheDay();
    expect(verse.surahId, inInclusiveRange(1, 114));
    expect(verse.ayah, greaterThan(0));
    expect(verse.arabic, isNotEmpty);
    expect(verse.english, isNotEmpty);

    final cached = await DailyContentService.loadVerseOfTheDay();
    expect(cached.surahId, verse.surahId);
    expect(cached.ayah, verse.ayah);
  });

  test('uthmaniFor is standard Unicode, not PUA glyphs', () async {
    final verse = await DailyContentService.loadVerseOfTheDay();
    final uthmani = await DailyContentService.uthmaniFor(
      verse.surahId,
      verse.ayah,
    );
    expect(uthmani, isNotEmpty);
    expect(
      uthmani.codeUnits.any((unit) => unit >= 0xE000 && unit <= 0xF8FF),
      isFalse,
    );
  });

  test('quran word of the day has a gloss', () async {
    final word = await DailyContentService.loadQuranWordOfTheDay();
    expect(word.arabic, isNotEmpty);
    expect(word.gloss, isNotEmpty);
    expect(word.surahId, inInclusiveRange(1, 114));
    expect(word.ayah, greaterThan(0));
  });

  test('arabic word of the day comes from the MSA dictionary', () async {
    final word = await DailyContentService.loadArabicWordOfTheDay();
    expect(word.arabic, isNotEmpty);
    expect(word.english, isNotEmpty);
  });

  test('dayIndex is a non-negative calendar offset', () {
    expect(DailyContentService.dayIndex, greaterThanOrEqualTo(0));
  });

  test('dhikr of the day is a catalog entry and is stable', () {
    final today = DailyContentService.dhikrOfTheDay();
    expect(today.arabic, isNotEmpty);
    expect(today.english, isNotEmpty);
    expect(today.source, isNotEmpty);
    expect(DailyContentService.dhikrOfTheDay().id, today.id);
    expect(
      DailyContentService.dhikrForDay(DailyContentService.dayIndex).id,
      today.id,
    );
  });
}
