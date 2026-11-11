/// Meccan and Medinan labels use the palette's readable accent colours.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/models.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/theme/app_tokens.dart';
import 'package:hublee/ui/widgets/surah_app_bar_title.dart';

const _fatiha = ChapterMeta(
  id: 1,
  nameSimple: 'Al-Fatiha',
  nameTranslated: 'The Opener',
  nameArabic: 'الفاتحة',
  versesCount: 7,
  revelationType: 'Meccan',
);

const _baqarah = ChapterMeta(
  id: 2,
  nameSimple: 'Al-Baqarah',
  nameTranslated: 'The Cow',
  nameArabic: 'البقرة',
  versesCount: 286,
  revelationType: 'Medinan',
);

void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'paper': buildPaperTheme(),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final palette = theme.extension<AppPalette>()!;

    testWidgets('$name: reader title uses the palette revelation colours', (
      tester,
    ) async {
      Future<Color?> titleColor(ChapterMeta chapter) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              appBar: AppBar(title: SurahAppBarTitle(chapter: chapter)),
            ),
          ),
        );
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byType(SurahAppBarTitle),
            matching: find.byType(Text),
          ),
        );
        return text.style?.color;
      }

      expect(await titleColor(_fatiha), palette.meccan);
      expect(await titleColor(_baqarah), palette.medinan);
    });
  }
}
