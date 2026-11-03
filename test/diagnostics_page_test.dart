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

    await tester.tap(find.text('Performance overlay'));
    await tester.pump();

    expect(AppMetrics.instance.overlayEnabled, isTrue);
    expect(
      AppMetrics.instance.events.any((e) => e.name == 'performanceOverlay'),
      isTrue,
    );
  });

  testWidgets('timing chip is off until switched on here', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const DiagnosticsPage()),
    );
    expect(AppMetrics.instance.hudEnabled, isFalse);

    await tester.tap(find.text('Timing chip'));
    await tester.pump();

    expect(AppMetrics.instance.hudEnabled, isTrue);
  });

  testWidgets('recorded errors are listed', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    AppMetrics.instance.recordError(StateError('boom\nstack detail'));

    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const DiagnosticsPage()),
    );

    expect(find.text('Bad state: boom'), findsOneWidget);
    expect(find.text('error'), findsOneWidget);
    expect(AppMetrics.instance.errorCount, 1);
  });
}
