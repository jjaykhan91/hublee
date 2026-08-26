/// Widget tests for the home-screen widget settings page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/home_widgets_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lists all four widgets with look chips', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const HomeWidgetsPage()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ayah of the day'), findsOneWidget);
    expect(find.text('Hadith of the day'), findsOneWidget);
    expect(find.text('Quran word of the day'), findsOneWidget);
    expect(find.text('Arabic word of the day'), findsOneWidget);
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Paper'), findsWidgets);
    expect(find.text('Show English'), findsWidgets);
    expect(find.text('Add to home screen'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
