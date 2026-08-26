/// Widget tests for [SplashPage] preload-and-advance behaviour.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/services/widget_routes.dart';
import 'package:hublee/ui/splash_page.dart';

void main() {
  late GoRouter router;

  setUp(WidgetLaunch.reset);
  tearDown(() => router.dispose());

  GoRouter buildRouter({
    required Future<void> Function() preload,
    Duration minDisplay = const Duration(milliseconds: 40),
    Duration maxWait = const Duration(seconds: 2),
  }) {
    return GoRouter(
      initialLocation: AppRoute.splash,
      routes: [
        GoRoute(
          path: AppRoute.splash,
          builder: (_, _) => SplashPage(
            preload: preload,
            minDisplay: minDisplay,
            maxWait: maxWait,
            resolveNext: () async => AppRoute.home,
          ),
        ),
        GoRoute(path: AppRoute.home, builder: (_, _) => const Text('HOME')),
      ],
    );
  }

  Future<void> pumpSplash(WidgetTester tester, GoRouter goRouter) {
    return tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));
  }

  testWidgets('waits for preload and min display then goes home', (
    tester,
  ) async {
    var loaded = false;
    router = buildRouter(
      preload: () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        loaded = true;
      },
    );

    await pumpSplash(tester, router);
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('HOME'), findsNothing);

    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump();
    expect(loaded, isTrue);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('leaves splash when preload hangs past maxWait', (tester) async {
    router = buildRouter(
      preload: () => Completer<void>().future,
      minDisplay: const Duration(milliseconds: 10),
      maxWait: const Duration(milliseconds: 50),
    );

    await pumpSplash(tester, router);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('tap skips a hanging preload', (tester) async {
    router = buildRouter(
      preload: () => Completer<void>().future,
      minDisplay: const Duration(milliseconds: 10),
      maxWait: const Duration(seconds: 8),
    );

    await pumpSplash(tester, router);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('does not navigate after dispose', (tester) async {
    router = buildRouter(
      preload: () => Completer<void>().future,
      minDisplay: const Duration(milliseconds: 80),
      maxWait: const Duration(milliseconds: 80),
    );

    await pumpSplash(tester, router);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
