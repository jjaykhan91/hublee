/// The shared bottom-sheet handle matches the themed drag handle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/theme/app_tokens.dart';
import 'package:hublee/ui/widgets/sheet_handle.dart';

void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'paper': buildPaperTheme(),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    testWidgets('$name: token size and the theme handle colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Column(
              children: [
                SheetHandle(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
                Text('Sheet title'),
              ],
            ),
          ),
        ),
      );

      final pill = find.descendant(
        of: find.byType(SheetHandle),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(pill), AppSheetHandle.size);

      final decoration =
          tester.widget<DecoratedBox>(pill).decoration as ShapeDecoration;
      expect(decoration.color, theme.bottomSheetTheme.dragHandleColor);
      expect(decoration.shape, isA<StadiumBorder>());

      // Centred, with the requested gap before the title.
      final screen = tester.getSize(find.byType(Scaffold));
      expect(tester.getCenter(pill).dx, screen.width / 2);
      expect(
        tester.getTopLeft(find.text('Sheet title')).dy,
        AppSheetHandle.size.height + AppSpacing.lg,
      );
    });
  }

  testWidgets('is silent to screen readers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const Scaffold(body: SheetHandle()),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(SheetHandle),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });
}
