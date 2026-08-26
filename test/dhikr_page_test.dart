/// Widget tests for the dhikr catalog page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/guidance/everyday_dhikr.dart';
import 'package:hublee/ui/dhikr_page.dart';

void main() {
  testWidgets('lists every catalog dhikr and opens the wording sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DhikrPage()));

    expect(find.text('Dhikr'), findsWidgets);
    for (final dhikr in everydayDhikrCatalog) {
      expect(find.byKey(Key('dhikr-item-${dhikr.id}')), findsOneWidget);
    }

    final first = everydayDhikrCatalog.first;
    await tester.tap(find.byKey(Key('dhikr-item-${first.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text(first.source), findsWidgets);
    expect(find.text(first.transliteration), findsWidgets);
  });
}
