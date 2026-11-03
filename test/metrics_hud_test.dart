/// Tests that the debug timing chip opens Diagnostics from above the router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/services/app_metrics.dart';
import 'package:hublee/ui/widgets/metrics_hud.dart';

void main() {
  setUp(AppMetrics.instance.reset);

  GoRouter testRouter() => GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: AppRoute.diagnostics,
        builder: (_, _) => const Text('diagnostics page'),
      ),
    ],
  );

  // Mounted like main.dart: in MaterialApp.builder, above the Navigator,
  // where context.push finds no GoRouter.
  Widget harness(GoRouter router) => MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => Stack(
      children: [
        child!,
        Positioned(left: 8, bottom: 88, child: MetricsHud(router: router)),
      ],
    ),
  );

  testWidgets('is hidden until switched on in Diagnostics', (tester) async {
    final router = testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(harness(router));

    expect(find.text('Metrics'), findsNothing);
  });

  testWidgets('tapping the chip opens Diagnostics', (tester) async {
    final router = testRouter();
    addTearDown(router.dispose);
    AppMetrics.instance.hudEnabled = true;
    await tester.pumpWidget(harness(router));

    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('diagnostics page'), findsOneWidget);
  });

  testWidgets('shows the error count', (tester) async {
    final router = testRouter();
    addTearDown(router.dispose);
    AppMetrics.instance.hudEnabled = true;
    AppMetrics.instance.recordError(StateError('boom'));
    await tester.pumpWidget(harness(router));
    await tester.pump();

    expect(find.text('Metrics · 1 error'), findsOneWidget);
  });
}
