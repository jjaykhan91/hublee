/// Widget tests for the sajdah chip and how-to sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/sajdah.dart';
import 'package:hublee/ui/widgets/sajdah_guide.dart';

void main() {
  testWidgets('sajdah chip opens what-to-do and what-to-recite', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SajdahChip())),
      ),
    );

    expect(find.byKey(const Key('sajdah-chip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sajdah-chip')));
    await tester.pumpAndSettle();

    expect(find.text('What to do'), findsOneWidget);
    expect(find.text('What to recite (in prostration)'), findsOneWidget);
    expect(find.text(kSajdahWhatToDo), findsOneWidget);
    expect(find.textContaining(kSajdahMeaning), findsOneWidget);
    expect(find.text(kSajdahArabic), findsOneWidget);
  });
}
