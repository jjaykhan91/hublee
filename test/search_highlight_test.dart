/// Tests for search-snippet query highlighting.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/search_highlight.dart';

void main() {
  group('splitQueryHighlights', () {
    test('expands a stem to the whole English word', () {
      final parts = splitQueryHighlights(
        'marked by your Lord in the market',
        'mark',
      );
      expect(
        parts.where((part) => part.match).map((part) => part.text).toList(),
        ['marked', 'market'],
      );
    });

    test('is case-insensitive', () {
      final parts = splitQueryHighlights(
        'We will soon Mark his snout.',
        'MARK',
      );
      expect(parts.singleWhere((part) => part.match).text, 'Mark');
    });

    test('highlights a match inside a longer word', () {
      final parts = splitQueryHighlights('by landmarks and stars', 'mark');
      expect(parts.singleWhere((part) => part.match).text, 'landmarks');
    });

    test('returns the whole snippet unmatched when nothing hits', () {
      expect(splitQueryHighlights('peace and blessings', 'xyzzy'), [
        (text: 'peace and blessings', match: false),
      ]);
    });

    test('returns a single unmatched run for a blank query', () {
      expect(splitQueryHighlights('hello', '  '), [
        (text: 'hello', match: false),
      ]);
    });

    test('highlights each term of a multi-word query', () {
      final matched = splitQueryHighlights(
        'In the name of Allah, the Merciful',
        'name merciful',
      ).where((part) => part.match).map((part) => part.text).toList();
      expect(matched, ['name', 'Merciful']);
    });

    test('highlights an Arabic substring as the containing word', () {
      const text = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      final parts = splitQueryHighlights(text, 'الله');
      final matched = parts.where((part) => part.match).toList();
      expect(matched, hasLength(1));
      expect(matched.single.text, contains('لل'));
    });
  });

  testWidgets('HighlightedSnippet bolds the matched word', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightedSnippet(
            'Al-Qalam: We will soon mark his snout.',
            query: 'mark',
          ),
        ),
      ),
    );

    final rich = tester.widget<RichText>(find.byType(RichText));
    final root = rich.text as TextSpan;
    final texts = <String>[];
    final weights = <FontWeight?>[];
    root.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
        texts.add(span.text!);
        weights.add(span.style?.fontWeight);
      }
      return true;
    });
    expect(texts, contains('mark'));
    final hitIndex = texts.indexOf('mark');
    expect(weights[hitIndex], FontWeight.w800);
  });
}
