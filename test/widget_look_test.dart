/// Tests for launcher-widget look encoding and word-safe clipping.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/widget_look.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('encode and decode round-trip', () {
    const look = WidgetLook(
      theme: WidgetLookTheme.paper,
      size: WidgetLookSize.large,
      showTranslation: false,
    );
    final raw = WidgetLookStore.encode(look);
    final decoded = WidgetLookStore.decode(HomeWidgetKind.hadith, raw);
    expect(decoded.theme, WidgetLookTheme.paper);
    expect(decoded.size, WidgetLookSize.large);
    expect(decoded.showTranslation, isFalse);
  });

  test('decode falls back on junk', () {
    final look = WidgetLookStore.decode(HomeWidgetKind.ayah, 'nope');
    expect(look.theme, WidgetLookTheme.accent);
    expect(look.size, WidgetLookSize.comfortable);
    expect(look.showTranslation, isTrue);
  });

  test('load and save persist the look', () async {
    const look = WidgetLook(
      theme: WidgetLookTheme.dark,
      size: WidgetLookSize.compact,
      showTranslation: true,
    );
    await WidgetLookStore.save(HomeWidgetKind.quranWord, look);
    final loaded = await WidgetLookStore.load(HomeWidgetKind.quranWord);
    expect(loaded.theme, WidgetLookTheme.dark);
    expect(loaded.size, WidgetLookSize.compact);
    final other = await WidgetLookStore.load(HomeWidgetKind.ayah);
    expect(other.theme, WidgetLookTheme.accent);
  });

  test('clipAtWord keeps short text', () {
    expect(clipAtWord('one two', 20), 'one two');
  });

  test('clipAtWord breaks on a space', () {
    expect(clipAtWord('one two three four', 10), 'one two...');
  });

  test('clipAtWord does not slice a single long word', () {
    const word = 'supercalifragilisticexpialidocious';
    expect(clipAtWord(word, 8), word);
  });
}
