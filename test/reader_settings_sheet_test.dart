/// Widget tests for the reader settings sheet height and scroll.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/app_scope.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/services/settings_scope.dart';
import 'package:hublee/theme/app_appearance.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/widgets/reader_settings_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens halfway and scrolls to Tajweed Guide', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = SettingsController();
    await settings.load();

    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: AppScope(
          appearance: AppAppearance.dark,
          setAppearance: (_) {},
          child: MaterialApp(
            theme: buildDarkTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showReaderSettingsSheet(context, showTajweedToggle: true),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Reader Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final listSize = tester.getSize(
      find.byKey(const Key('reader-settings-list')),
    );
    expect(listSize.height, lessThan(800 * 0.7));
    expect(listSize.height, greaterThan(800 * 0.35));

    await tester.scrollUntilVisible(
      find.text('Tajweed Guide'),
      80,
      scrollable: find.descendant(
        of: find.byKey(const Key('reader-settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Tajweed Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
