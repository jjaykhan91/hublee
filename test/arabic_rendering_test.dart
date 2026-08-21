/// Rendering tests for Arabic Qur'anic text.
///
/// These cover what unit tests on `tajweedColorAssignments` cannot: that the
/// bundled font actually has glyphs for the text the app feeds it, that the
/// text lays out without overflow at every supported zoom level, that tajweed
/// spans survive as `TextSpan`s through the widget tree, and that the rendered
/// pixels do not change unnoticed.
///
/// All file I/O happens in `setUpAll`. Real async I/O inside a `testWidgets`
/// body deadlocks under the fake-async zone.
///
/// Run: flutter test test/arabic_rendering_test.dart
/// Regenerate goldens: flutter test --update-goldens
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/widgets/arabic_text.dart';

/// Family name declared in `pubspec.yaml` for the bundled mushaf font.
const _kArabicFamily = 'KFGQPCQuranicFontHafsSmart';

/// Standard-Unicode Arabic face backing [AppFonts.arabicFallback].
const _kFallbackFamily = 'Amiri';

/// Default Arabic font size used by `ArabicText`.
const _kBaseFontSize = 26.0;

/// Zoom bounds enforced by `SettingsController`.
const _kMinZoom = 0.8;
const _kMaxZoom = 1.8;

/// Maddah above (U+0653) and small high rounded zero (U+06DF) must never be
/// stripped — they carry the necessary-madd and silent-letter rules.
const _kMaddah = 0x0653;
const _kSilentMarker = 0x06DF;

const _targetKey = ValueKey<String>('arabic-render-target');

/// PUA glyph text (`aya_text`), which the app renders with the bundled font
/// when tajweed is off.
late String _puaVerse;
late String _puaLongVerse;

/// Standard Uthmanic Unicode, which the app renders when tajweed is on.
late String _standardVerse;

/// Registers the bundled Arabic fonts with the test font system.
///
/// Without this, the framework substitutes its own fallback font, and every
/// layout and golden assertion below becomes meaningless.
Future<void> _loadArabicFonts() async {
  const families = <String, String>{
    _kArabicFamily: 'assets/fonts/KFGQPCQuranicFontHafsSmart_08.ttf',
    _kFallbackFamily: 'assets/fonts/Amiri-Regular.ttf',
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(File(entry.value).readAsBytes().then(ByteData.sublistView));
    await loader.load();
  }
}

/// Loads standard Uthmanic text for a single ayah.
Future<String> _loadStandardVerse(int surah, int ayah) async {
  final raw = await File('assets/quran/ar/$surah.json').readAsString();
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return map['$ayah'] as String;
}

/// Loads PUA glyph text (`aya_text`) for the given ayahs in one pass over the
/// mushaf dataset, which is large enough that we only want to parse it once.
Future<Map<int, String>> _loadPuaVerses(int surah, Set<int> ayahs) async {
  final raw = await File(
    'assets/quran/KFGQPCQuranMushaf_smart_v8.json',
  ).readAsString();
  final decoded = jsonDecode(raw);
  final entries = decoded is List
      ? decoded
      : (decoded as Map<String, dynamic>).values
            .whereType<List<dynamic>>()
            .first;

  final result = <int, String>{};
  for (final entry in entries.whereType<Map<String, dynamic>>()) {
    if (entry['sura_no'] == surah && ayahs.contains(entry['aya_no'])) {
      result[entry['aya_no'] as int] = entry['aya_text'] as String;
    }
  }
  return result;
}

/// Fixes the test surface so layout and goldens are deterministic.
void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _harness({
  required Widget child,
  required ThemeData theme,
  double width = 360,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: _targetKey,
          child: Container(
            width: width,
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            // `ArabicText` wraps its content in an `Align` with no height
            // factor, so under loose constraints it expands to fill the
            // surface. The min-size Column passes unbounded height down so
            // the box hugs the paragraph and measurements stay meaningful.
            child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
          ),
        ),
      ),
    ),
  );
}

/// Renders [text] in [family] at a fixed size and returns the laid-out size.
///
/// A family with no glyph for a character contributes (almost) no advance
/// width, so this is how we detect missing coverage.
Future<Size> _measureText(
  WidgetTester tester,
  String text,
  String? family, {
  List<String>? fallback,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: family,
                  fontFamilyFallback: fallback,
                  fontSize: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return tester.getSize(find.byType(RichText).last);
}

/// Recursively collects every span under [root].
List<InlineSpan> _flatten(InlineSpan root) {
  final collected = <InlineSpan>[root];
  if (root is TextSpan) {
    for (final child in root.children ?? const <InlineSpan>[]) {
      collected.addAll(_flatten(child));
    }
  }
  return collected;
}

int _countRune(String text, int rune) =>
    text.runes.where((r) => r == rune).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadArabicFonts();
    _standardVerse = await _loadStandardVerse(2, 5);
    final pua = await _loadPuaVerses(2, {5, 255});
    _puaVerse = pua[5]!;
    _puaLongVerse = pua[255]!;
  });

  // ============================================================
  //  Font coverage
  //
  //  The app picks the text encoding based on the selected font:
  //  `usePua = isUthmanic && !tajweedEnabled` (see surah_reader_page).
  //  These tests assert the chosen font can actually render the chosen
  //  text, which is the invariant that keeps the bundled mushaf
  //  typography from being silently replaced by an OS fallback.
  // ============================================================
  group('font coverage', () {
    testWidgets('mushaf font renders PUA glyph text', (tester) async {
      final size = await _measureText(tester, _puaVerse, _kArabicFamily);

      expect(
        size.width,
        greaterThan(_puaVerse.length * 4),
        reason:
            'The bundled KFGQPC font must have glyphs for the PUA text '
            'it is paired with when tajweed is off',
      );
    });

    testWidgets('mushaf font alone cannot render standard Uthmanic Unicode', (
      tester,
    ) async {
      final size = await _measureText(tester, _standardVerse, _kArabicFamily);

      // This is a property of the font file, not a bug — it is the reason
      // `AppFonts.arabicFallback` exists. If this ever starts failing, the
      // mushaf font gained standard coverage and the fallback can be revisited.
      expect(
        size.width,
        lessThan(_standardVerse.length * 4),
        reason:
            'KFGQPCQuranicFontHafsSmart covers only PUA glyphs, so '
            'standard Unicode gets almost no advance width from it',
      );
    });

    testWidgets('Arabic fallback renders standard Uthmanic Unicode', (
      tester,
    ) async {
      final size = await _measureText(
        tester,
        _standardVerse,
        _kArabicFamily,
        fallback: const [_kFallbackFamily],
      );

      expect(
        size.width,
        greaterThan(_standardVerse.length * 4),
        reason:
            'With the Amiri fallback in place, the standard Uthmanic '
            'text the reader shows when tajweed is on must actually render '
            'instead of falling through to a platform font',
      );
    });
  });

  // ============================================================
  //  Layout integrity
  //
  //  Uses PUA text so the assertions measure real glyphs.
  // ============================================================
  group('layout integrity', () {
    testWidgets('verse lays out with a non-zero height', (tester) async {
      _setSurface(tester, const Size(1000, 2000));

      await tester.pumpWidget(
        _harness(
          theme: buildLightTheme(),
          child: ArabicText(_puaVerse, fontOverride: ArabicFontOption.uthmanic),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_targetKey)).height, greaterThan(0));
    });

    for (final zoom in const [_kMinZoom, 1.0, _kMaxZoom]) {
      testWidgets('long verse survives a narrow column at zoom $zoom', (
        tester,
      ) async {
        // 320 dp is the narrowest phone width Hublee targets.
        _setSurface(tester, const Size(1000, 4000));

        await tester.pumpWidget(
          _harness(
            width: 320,
            theme: buildLightTheme(),
            child: ArabicText(
              _puaLongVerse,
              fontSize: _kBaseFontSize * zoom,
              fontOverride: ArabicFontOption.uthmanic,
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'Arabic at zoom $zoom must not overflow or assert',
        );
      });
    }

    testWidgets('greater zoom produces a taller paragraph', (tester) async {
      _setSurface(tester, const Size(1000, 4000));

      Future<double> heightAt(double zoom) async {
        await tester.pumpWidget(
          _harness(
            theme: buildLightTheme(),
            child: ArabicText(
              _puaVerse,
              fontSize: _kBaseFontSize * zoom,
              fontOverride: ArabicFontOption.uthmanic,
            ),
          ),
        );
        return tester.getSize(find.byKey(_targetKey)).height;
      }

      final small = await heightAt(_kMinZoom);
      final large = await heightAt(_kMaxZoom);

      expect(
        large,
        greaterThan(small),
        reason:
            'Font zoom must change the rendered height; a fixed-height '
            'container would silently clip instead',
      );
    });

    testWidgets('maxLines with ellipsis does not throw', (tester) async {
      _setSurface(tester, const Size(1000, 2000));

      await tester.pumpWidget(
        _harness(
          theme: buildLightTheme(),
          child: ArabicText(
            _puaLongVerse,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            fontOverride: ArabicFontOption.uthmanic,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  // ============================================================
  //  Tajweed span integrity
  //
  //  Structural assertions only — these hold regardless of which font
  //  ends up rasterizing the glyphs.
  // ============================================================
  group('span integrity', () {
    Future<RichText> pumpTajweed(WidgetTester tester, String text) async {
      _setSurface(tester, const Size(1000, 2000));

      await tester.pumpWidget(
        _harness(
          theme: buildDarkTheme(),
          child: ArabicText(
            text,
            tajweed: true,
            fontOverride: ArabicFontOption.uthmanic,
          ),
        ),
      );

      return tester.widget<RichText>(
        find.descendant(
          of: find.byKey(_targetKey),
          matching: find.byType(RichText),
        ),
      );
    }

    testWidgets('no WidgetSpan reaches the rendered tree', (tester) async {
      final richText = await pumpTajweed(tester, _standardVerse);

      expect(
        _flatten(richText.text).whereType<WidgetSpan>(),
        isEmpty,
        reason:
            'WidgetSpan shapes each child independently, which breaks '
            'Arabic cursive joining across span boundaries',
      );
    });

    testWidgets('rendered text preserves madd and silent markers', (
      tester,
    ) async {
      final richText = await pumpTajweed(tester, _standardVerse);
      final rendered = richText.text.toPlainText();

      expect(
        _countRune(rendered, _kMaddah),
        _countRune(_standardVerse, _kMaddah),
        reason: 'U+0653 (maddah) must survive rendering',
      );
      expect(
        _countRune(rendered, _kSilentMarker),
        _countRune(_standardVerse, _kSilentMarker),
        reason: 'U+06DF (silent marker) must survive rendering',
      );
    });

    testWidgets('tajweed applies more than one colour', (tester) async {
      final richText = await pumpTajweed(tester, _standardVerse);

      final colours = _flatten(richText.text)
          .whereType<TextSpan>()
          .map((s) => s.style?.color)
          .whereType<Color>()
          .toSet();

      expect(
        colours.length,
        greaterThan(1),
        reason:
            'A diacritic-dense verse must render several tajweed '
            'colours; one colour means the engine silently no-opped',
      );
    });
  });

  // ============================================================
  //  Goldens (local only — see dart_test.yaml)
  //
  //  Covers both text paths the reader uses: PUA glyphs in the mushaf font
  //  (tajweed off) and standard Uthmanic Unicode via the Arabic fallback
  //  (tajweed on).
  // ============================================================
  group('goldens', () {
    Future<void> pumpAndCompare(
      WidgetTester tester, {
      required ThemeData theme,
      required bool tajweed,
      required double zoom,
      required String name,
    }) async {
      _setSurface(tester, const Size(1000, 2000));

      await tester.pumpWidget(
        _harness(
          theme: theme,
          child: ArabicText(
            // The reader shows standard Unicode whenever tajweed is enabled.
            tajweed ? _standardVerse : _puaVerse,
            tajweed: tajweed,
            fontSize: _kBaseFontSize * zoom,
            fontOverride: ArabicFontOption.uthmanic,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(_targetKey),
        matchesGoldenFile('goldens/$name.png'),
      );
    }

    testWidgets('mushaf font, light theme', (tester) async {
      await pumpAndCompare(
        tester,
        theme: buildLightTheme(),
        tajweed: false,
        zoom: 1.0,
        name: 'arabic_pua_light',
      );
    }, tags: 'golden');

    testWidgets('mushaf font, dark theme', (tester) async {
      await pumpAndCompare(
        tester,
        theme: buildDarkTheme(),
        tajweed: false,
        zoom: 1.0,
        name: 'arabic_pua_dark',
      );
    }, tags: 'golden');

    testWidgets('mushaf font, light theme at max zoom', (tester) async {
      await pumpAndCompare(
        tester,
        theme: buildLightTheme(),
        tajweed: false,
        zoom: _kMaxZoom,
        name: 'arabic_pua_max_zoom_light',
      );
    }, tags: 'golden');

    testWidgets('tajweed colours, light theme', (tester) async {
      await pumpAndCompare(
        tester,
        theme: buildLightTheme(),
        tajweed: true,
        zoom: 1.0,
        name: 'arabic_tajweed_light',
      );
    }, tags: 'golden');

    testWidgets('tajweed colours, dark theme', (tester) async {
      await pumpAndCompare(
        tester,
        theme: buildDarkTheme(),
        tajweed: true,
        zoom: 1.0,
        name: 'arabic_tajweed_dark',
      );
    }, tags: 'golden');
  });
}
