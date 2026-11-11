/// Theme contract that must stay in sync with `.cursor/rules/theming.mdc`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/theme/app_tokens.dart';

void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'paper': buildPaperTheme(),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    group('$name theme', () {
      final palette = theme.extension<AppPalette>()!;

      test('cards are flat with a hairline border', () {
        final card = theme.cardTheme;
        expect(card.elevation, 0);
        expect(card.margin, EdgeInsets.zero);
        expect(card.color, palette.surface);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, AppRadius.card);
        expect(shape.side.color, palette.hairline);
      });

      test('chrome is flat and sits on the canvas', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.appBarTheme.backgroundColor, palette.canvas);
        expect(theme.navigationBarTheme.elevation, 0);
        expect(theme.navigationBarTheme.backgroundColor, palette.canvas);
        expect(theme.navigationRailTheme.backgroundColor, palette.canvas);
      });

      test('elevation never tints a surface', () {
        expect(theme.colorScheme.surfaceTint, Colors.transparent);
      });

      test('text follows the type scale', () {
        final text = theme.textTheme;
        expect(text.headlineMedium!.fontSize, AppType.display.fontSize);
        expect(text.titleLarge!.fontSize, AppType.title.fontSize);
        expect(text.titleMedium!.fontSize, AppType.subtitle.fontSize);
        expect(text.bodyLarge!.fontSize, AppType.body.fontSize);
        expect(text.bodyLarge!.height, 1.5);
        expect(text.bodyMedium!.fontSize, AppType.bodyCompact.fontSize);
        expect(text.bodyMedium!.height, 1.5);
        expect(text.bodySmall!.fontSize, AppType.caption.fontSize);
        expect(text.labelSmall!.fontSize, AppType.caption.fontSize);
        expect(
          theme.appBarTheme.titleTextStyle!.fontSize,
          AppType.headline.fontSize,
        );
      });

      test('no text style is smaller than the caption step', () {
        final text = theme.textTheme;
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(style!.fontSize, greaterThanOrEqualTo(12));
          expect(style.fontFamilyFallback, AppFonts.arabicFallback);
          expect(style.color, palette.ink);
        }
      });

      test('component text styles carry the platform font family', () {
        final family = theme.textTheme.bodyMedium!.fontFamily;
        expect(family, isNotNull);

        final nav = theme.navigationBarTheme.labelTextStyle!;
        for (final style in [
          theme.appBarTheme.titleTextStyle,
          theme.searchBarTheme.textStyle!.resolve({}),
          theme.searchBarTheme.hintStyle!.resolve({}),
          theme.filledButtonTheme.style!.textStyle!.resolve({}),
          theme.elevatedButtonTheme.style!.textStyle!.resolve({}),
          theme.outlinedButtonTheme.style!.textStyle!.resolve({}),
          theme.textButtonTheme.style!.textStyle!.resolve({}),
          theme.chipTheme.labelStyle,
          theme.tabBarTheme.labelStyle,
          theme.tabBarTheme.unselectedLabelStyle,
          nav.resolve({}),
          nav.resolve({WidgetState.selected}),
          theme.navigationRailTheme.selectedLabelTextStyle,
          theme.navigationRailTheme.unselectedLabelTextStyle,
          theme.snackBarTheme.contentTextStyle,
          theme.dialogTheme.titleTextStyle,
          theme.dialogTheme.contentTextStyle,
        ]) {
          expect(style!.fontFamily, family);
          expect(style.fontFamilyFallback, AppFonts.arabicFallback);
        }
      });

      testWidgets('titles, chips and buttons draw in the body font', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Settings')),
              body: Column(
                children: [
                  const Text('Body'),
                  ChoiceChip(
                    label: const Text('Paper'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilledButton(onPressed: () {}, child: const Text('Save')),
                ],
              ),
            ),
          ),
        );

        String? familyOf(String text) => tester
            .renderObject<RenderParagraph>(find.text(text))
            .text
            .style!
            .fontFamily;

        final body = familyOf('Body');
        expect(body, isNotNull);
        expect(familyOf('Settings'), body);
        expect(familyOf('Paper'), body);
        expect(familyOf('Save'), body);
      });

      test('buttons are flat and at least 48dp tall', () {
        for (final style in [
          theme.filledButtonTheme.style!,
          theme.elevatedButtonTheme.style!,
          theme.outlinedButtonTheme.style!,
        ]) {
          expect(
            style.minimumSize!.resolve({})!.height,
            AppSpacing.minTouchTarget,
          );
        }
        expect(theme.filledButtonTheme.style!.elevation!.resolve({}), 0);
        expect(theme.elevatedButtonTheme.style!.elevation!.resolve({}), 0);
      });

      test('text fields have a visible edge and a brand focus ring', () {
        final input = theme.inputDecorationTheme;
        final enabled = input.enabledBorder! as OutlineInputBorder;
        final focused = input.focusedBorder! as OutlineInputBorder;
        expect(enabled.borderRadius, AppRadius.input);
        expect(enabled.borderSide.color, palette.outline);
        expect(focused.borderSide.color, palette.primary);
        expect(input.fillColor, palette.surface);
      });

      test('snackbars float on the inverse surface', () {
        final snack = theme.snackBarTheme;
        expect(snack.behavior, SnackBarBehavior.floating);
        expect(snack.backgroundColor, palette.inverseSurface);
        expect(snack.contentTextStyle!.color, palette.onInverseSurface);
      });

      test('sheets share one shape and handle', () {
        final sheet = theme.bottomSheetTheme;
        expect(sheet.backgroundColor, palette.surface);
        expect(
          (sheet.shape! as RoundedRectangleBorder).borderRadius,
          AppRadius.sheetTop,
        );
        expect(sheet.dragHandleSize, AppSheetHandle.size);
      });

      test('selected chips use the brand tint', () {
        final chip = theme.chipTheme;
        expect(chip.selectedColor, palette.primaryTint);
        final label = chip.labelStyle!.color! as WidgetStateColor;
        expect(label.resolve({WidgetState.selected}), palette.onPrimaryTint);
        expect(label.resolve({}), palette.ink);
      });
    });
  }

  test('page transitions cover desktop platforms', () {
    final builders = buildLightTheme().pageTransitionsTheme.builders;
    expect(builders[TargetPlatform.windows], isNotNull);
    expect(builders[TargetPlatform.linux], isNotNull);
    expect(builders[TargetPlatform.macOS], isNotNull);
  });

  test('paper and light are light, dark is dark', () {
    expect(buildLightTheme().brightness, Brightness.light);
    expect(buildPaperTheme().brightness, Brightness.light);
    expect(buildDarkTheme().brightness, Brightness.dark);
  });
}
