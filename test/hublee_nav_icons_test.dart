/// Widget tests for custom Hublee tab icons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/hublee_nav_icons.dart';

void main() {
  testWidgets('every tab mark paints outline and filled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              HubleeNavIcon(kind: HubleeNavKind.home),
              HubleeNavIcon(kind: HubleeNavKind.home, filled: true),
              HubleeNavIcon(kind: HubleeNavKind.quran),
              HubleeNavIcon(kind: HubleeNavKind.quran, filled: true),
              HubleeNavIcon(kind: HubleeNavKind.hadith),
              HubleeNavIcon(kind: HubleeNavKind.hadith, filled: true),
              HubleeNavIcon(kind: HubleeNavKind.learn),
              HubleeNavIcon(kind: HubleeNavKind.learn, filled: true),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(HubleeNavIcon), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });
}
