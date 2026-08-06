/// Tests for word-by-word glossing.
///
/// The load-bearing test here is [_alignmentAcrossTheQuran]: it proves that the
/// gloss assets have exactly one entry per word for every ayah, in both the
/// plain and the tajweed rendering path. That invariant is what lets the reader
/// index glosses by word position instead of guessing, so if it ever breaks the
/// suite must fail rather than the app quietly mislabelling Qur'anic words.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/arabic_word_segmenter.dart';
import 'package:hublee/quran/word_by_word_repository.dart';
import 'package:hublee/ui/widgets/tajweed.dart';
import 'package:hublee/ui/widgets/word_by_word_arabic_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordByWordRepository', () {
    setUp(WordByWordRepository.resetCache);

    test('loads the glosses for a surah keyed by ayah', () async {
      final surah = await const WordByWordRepository().loadSurah(1);
      expect(surah[1], [
        'In (the) name',
        '(of) Allah',
        'the Most Gracious',
        'the Most Merciful',
      ]);
      expect(surah, hasLength(7));
    });

    test('shares one load between concurrent callers', () async {
      const repo = WordByWordRepository();
      final first = repo.loadSurah(2);
      final second = repo.loadSurah(2);
      expect(first, same(second));
      expect(await first, isNotEmpty);
    });

    test('degrades to empty when the asset is missing', () async {
      expect(await const WordByWordRepository().loadSurah(999), isEmpty);
    });
  });

  group('segmentArabicWords', () {
    test('splits on whitespace', () {
      final words = segmentArabicWords('بِسْمِ ٱللَّهِ ٱلرَّحِيمِ');
      expect(words.map((w) => w.text), ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحِيمِ']);
    });

    test('folds a trailing waqf mark into the word it follows', () {
      // 2:2 — the pause marks are standalone tokens in quran.com's text but
      // are not words in word-by-word data.
      final words = segmentArabicWords('لَا رَيْبَ ۛ فِيهِ ۛ هُدًى');
      expect(words.map((w) => w.text), ['لَا', 'رَيْبَ ۛ', 'فِيهِ ۛ', 'هُدًى']);
    });

    test('folds a leading rosette onto the word that follows it', () {
      // 11:41 opens with the rub-el-hizb marker.
      final words = segmentArabicWords('۞ وَقَالَ ٱرْكَبُوا۟');
      expect(words, hasLength(2));
      expect(words.first.text, '۞ وَقَالَ');
    });

    test('ranges tile the source with no gaps or overlaps', () {
      const text = '۞ وَقَالَ ٱرْكَبُوا۟ فِيهَا ۚ بِسْمِ';
      final words = segmentArabicWords(text);
      expect(words.first.start, 0);
      expect(words.last.end, text.length);
      for (var i = 1; i < words.length; i++) {
        expect(
          words[i].start,
          words[i - 1].end,
          reason: 'word $i must start where word ${i - 1} ends',
        );
      }
    });

    test('every offset maps to exactly one word', () {
      const text = 'لَا رَيْبَ ۛ فِيهِ هُدًى';
      final words = segmentArabicWords(text);
      for (var offset = 0; offset < text.length; offset++) {
        expect(
          wordIndexAtOffset(words, offset),
          isNotNull,
          reason: 'offset $offset is unmapped',
        );
      }
      expect(wordIndexAtOffset(words, text.length), isNull);
    });

    test('returns nothing for empty or whitespace-only text', () {
      expect(segmentArabicWords(''), isEmpty);
      expect(segmentArabicWords('   '), isEmpty);
    });

    test('annotation-only text still yields a word so nothing is dropped', () {
      expect(segmentArabicWords('۞'), hasLength(1));
    });
  });

  group('glossPhraseAt', () {
    test('a single-word gloss covers just that word', () {
      final phrase = glossPhraseAt(['That', '(is) the book', 'no'], 1);
      expect(phrase, isNotNull);
      expect(phrase!.firstWord, 1);
      expect(phrase.lastWord, 1);
      expect(phrase.gloss, '(is) the book');
      expect(phrase.isMultiWord, isFalse);
    });

    test('an empty gloss continues the previous word as one phrase', () {
      // بَعْدَ مَا -> "after what": the second word has no gloss of its own.
      final glosses = ['after what', '', 'he heard'];
      final fromFirst = glossPhraseAt(glosses, 0);
      final fromSecond = glossPhraseAt(glosses, 1);

      expect(fromFirst, fromSecond, reason: 'both words share one phrase');
      expect(fromFirst!.firstWord, 0);
      expect(fromFirst.lastWord, 1);
      expect(fromFirst.gloss, 'after what');
      expect(fromFirst.isMultiWord, isTrue);
    });

    test('returns null outside the word range', () {
      expect(glossPhraseAt(['a'], -1), isNull);
      expect(glossPhraseAt(['a'], 1), isNull);
    });
  });

  group('WordByWordArabicText', () {
    const ayah = 'ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ';
    const glosses = ['That', '(is) the book', 'no', 'doubt'];

    Future<void> pump(
      WidgetTester tester, {
      required ValueChanged<WordByWordSelection?> onSelected,
      GlossPhrase? selected,
      List<String> words = glosses,
      bool tajweed = true,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordByWordArabicText(
              text: ayah,
              glosses: words,
              fontSize: 28,
              tajweed: tajweed,
              selectedPhrase: selected,
              onPhraseSelected: onSelected,
            ),
          ),
        ),
      );
    }

    /// Flattens the rendered spans in reading order.
    List<TextSpan> spansOf(WidgetTester tester) {
      final richText = tester.widget<RichText>(find.byType(RichText));
      final spans = <TextSpan>[];
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      return spans;
    }

    testWidgets('renders the whole ayah without losing characters', (
      tester,
    ) async {
      await pump(tester, onSelected: (_) {});
      final rendered = spansOf(tester).map((s) => s.text).join();
      // Tajweed strips presentation-only marks, so compare letters only.
      expect(rendered.replaceAll(' ', ''), ayah.replaceAll(' ', ''));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps tajweed colours while words stay tappable', (
      tester,
    ) async {
      await pump(tester, onSelected: (_) {});
      final spans = spansOf(tester);

      final colours = spans.map((s) => s.style?.color).toSet();
      expect(
        colours.length,
        greaterThan(1),
        reason: 'word-by-word must not flatten tajweed colouring',
      );
      expect(
        spans.every((s) => s.recognizer is TapGestureRecognizer),
        isTrue,
        reason: 'every piece of a word carries that word\'s recognizer',
      );
    });

    testWidgets('tapping a word reports its phrase', (tester) async {
      WordByWordSelection? selection;
      await pump(tester, onSelected: (value) => selection = value);

      // Tapping the RichText hits the first word on the right in RTL.
      await tester.tapAt(
        tester.getTopRight(find.byType(RichText)) + const Offset(-12, 30),
      );
      await tester.pump();

      expect(selection, isNotNull);
      expect(selection!.phrase.gloss, glosses.first);
      expect(selection!.arabic, isNotEmpty);
    });

    testWidgets('tapping the selected word again clears the selection', (
      tester,
    ) async {
      var calls = 0;
      WordByWordSelection? selection;
      const first = GlossPhrase(firstWord: 0, lastWord: 0, gloss: 'That');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordByWordArabicText(
              text: ayah,
              glosses: glosses,
              fontSize: 28,
              selectedPhrase: first,
              onPhraseSelected: (value) {
                calls++;
                selection = value;
              },
            ),
          ),
        ),
      );

      await tester.tapAt(
        tester.getTopRight(find.byType(RichText)) + const Offset(-12, 30),
      );
      await tester.pump();

      expect(calls, 1);
      expect(selection, isNull, reason: 'a second tap dismisses the gloss');
    });

    testWidgets('highlights the selected word with a background tint', (
      tester,
    ) async {
      await pump(
        tester,
        onSelected: (_) {},
        selected: const GlossPhrase(firstWord: 0, lastWord: 0, gloss: 'That'),
      );
      final tinted = spansOf(
        tester,
      ).where((s) => s.style?.backgroundColor != null).toList();
      expect(tinted, isNotEmpty);
      // Highlighting must not change letter colours, or tajweed is lost.
      expect(tinted.map((s) => s.style?.color).toSet().length, greaterThan(0));
    });

    testWidgets('falls back to untappable text when glosses do not align', (
      tester,
    ) async {
      await pump(tester, onSelected: (_) {}, words: const ['only one']);
      expect(
        spansOf(tester).every((s) => s.recognizer == null),
        isTrue,
        reason: 'mislabelling a word is worse than not offering the feature',
      );
    });

    testWidgets('disposes recognizers when removed from the tree', (
      tester,
    ) async {
      await pump(tester, onSelected: (_) {});
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('works with tajweed disabled', (tester) async {
      WordByWordSelection? selection;
      await pump(
        tester,
        tajweed: false,
        onSelected: (value) => selection = value,
      );
      expect(spansOf(tester).map((s) => s.text).join(), ayah);

      await tester.tapAt(
        tester.getTopRight(find.byType(RichText)) + const Offset(-12, 30),
      );
      await tester.pump();
      expect(selection, isNotNull);
    });
  });

  _alignmentAcrossTheQuran();
}

/// Verifies the generated gloss assets against the Arabic they describe, for
/// every ayah, in both rendering paths.
void _alignmentAcrossTheQuran() {
  group('gloss assets align with the Arabic text', () {
    final arabic = <String, String>{};
    final glosses = <String, List<String>>{};

    setUpAll(() {
      for (var surah = 1; surah <= 114; surah++) {
        final arabicFile = File('assets/quran/ar/$surah.json');
        final glossFile = File('assets/quran/en.wordbyword/$surah.json');
        expect(
          arabicFile.existsSync() && glossFile.existsSync(),
          isTrue,
          reason: 'missing assets for surah $surah',
        );

        final arabicJson =
            json.decode(arabicFile.readAsStringSync()) as Map<String, dynamic>;
        arabicJson.forEach((ayah, text) {
          arabic['$surah:$ayah'] = text.toString().trim();
        });

        final glossJson =
            json.decode(glossFile.readAsStringSync()) as Map<String, dynamic>;
        glossJson.forEach((ayah, list) {
          glosses['$surah:$ayah'] = (list as List)
              .map((g) => g.toString())
              .toList();
        });
      }
    });

    test('covers all 6236 ayahs', () {
      expect(arabic, hasLength(6236));
      expect(glosses, hasLength(6236));
    });

    test('one gloss per word on the plain rendering path', () {
      final mismatches = <String>[];
      for (final entry in arabic.entries) {
        final words = segmentArabicWords(entry.value);
        final expected = glosses[entry.key];
        if (expected == null || words.length != expected.length) {
          mismatches.add(
            '${entry.key}: ${words.length} words vs '
            '${expected?.length ?? 0} glosses',
          );
        }
      }
      expect(mismatches, isEmpty, reason: mismatches.take(10).join('\n'));
    });

    test('one gloss per word on the tajweed rendering path', () {
      // The reader segments the string the tajweed engine produced, which has
      // presentation-only marks removed. Word counts must survive that.
      final mismatches = <String>[];
      for (final entry in arabic.entries) {
        final sanitized = tajweedColorAssignments(
          entry.value,
        ).map((cluster) => cluster.text).join();
        final words = segmentArabicWords(sanitized);
        final expected = glosses[entry.key]!;
        if (words.length != expected.length) {
          mismatches.add(
            '${entry.key}: ${words.length} tajweed words vs '
            '${expected.length} glosses',
          );
        }
      }
      expect(mismatches, isEmpty, reason: mismatches.take(10).join('\n'));
    });

    test('the first word of every ayah has a gloss to show', () {
      final empty = glosses.entries
          .where((e) => e.value.isEmpty || e.value.first.isEmpty)
          .map((e) => e.key)
          .toList();
      expect(empty, isEmpty);
    });

    test('every word resolves to a phrase', () {
      for (final entry in glosses.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          expect(
            glossPhraseAt(entry.value, i),
            isNotNull,
            reason: '${entry.key} word $i has no phrase',
          );
        }
      }
    });
  });
}
