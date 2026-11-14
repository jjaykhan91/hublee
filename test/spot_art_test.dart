/// Tests for the in-code line illustrations.
///
/// Goldens: `flutter test --update-goldens test/spot_art_test.dart`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/widgets/spot_art.dart';

Widget _sheet(ThemeData theme) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final art in SpotArt.values)
              SpotIllustration(art, key: ValueKey(art)),
          ],
        ),
      ),
    ),
  );
}

void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('every illustration paints, $name', (tester) async {
      tester.view.physicalSize = const Size(560, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_sheet(theme));

      expect(tester.takeException(), isNull);
      for (final art in SpotArt.values) {
        expect(tester.getSize(find.byKey(ValueKey(art))), const Size(160, 160));
      }
    });

    testWidgets('illustration sheet, $name', (tester) async {
      tester.view.physicalSize = const Size(560, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_sheet(theme));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/ui_spot_art_$name.png'),
      );
    }, tags: 'golden');
  }

  testWidgets('illustrations are hidden from screen readers', (tester) async {
    await tester.pumpWidget(_sheet(buildLightTheme()));

    expect(
      find.descendant(
        of: find.byType(SpotIllustration),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNWidgets(SpotArt.values.length),
    );
  });
}
