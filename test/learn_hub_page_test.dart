/// Widget tests for the Learn tab hub.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/learn_hub_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('groups Quranic and Modern Arabic study tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LearnHubPage()));

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Quranic Arabic'), findsOneWidget);
    expect(find.text('Modern Arabic'), findsOneWidget);
    expect(find.text('English → Arabic'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('MSA dictionary'), findsOneWidget);
    expect(find.text('Grammar course'), findsOneWidget);
    expect(find.text('Spaced repetition'), findsNothing);
    expect(find.text('Explore'), findsNothing);
  });
}
