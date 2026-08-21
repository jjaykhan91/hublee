/// Widget tests for [DiagnosticsPage].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/app_metrics.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/diagnostics_page.dart';

void main() {
  setUp(AppMetrics.instance.reset);

  testWidgets('shows recorded timings', (tester) async {
    AppMetrics.instance.recordTiming(
      'search.quranIndex',
      const Duration(milliseconds: 42),
    );

    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const DiagnosticsPage()),
    );

    expect(find.text('search.quranIndex'), findsWidgets);
    expect(find.text('42 ms'), findsWidgets);
  });

  testWidgets('overlay switch records a UI event', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const DiagnosticsPage()),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(AppMetrics.instance.overlayEnabled, isTrue);
    expect(
      AppMetrics.instance.events.any((e) => e.name == 'performanceOverlay'),
      isTrue,
    );
  });
}
