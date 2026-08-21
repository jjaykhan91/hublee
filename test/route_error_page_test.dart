/// Widget tests for [RouteErrorPage].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/ui/route_error_page.dart';

void main() {
  testWidgets('shows the message and returns home', (tester) async {
    final router = GoRouter(
      initialLocation: '/missing',
      routes: [
        GoRoute(path: AppRoute.home, builder: (_, _) => const Text('HOME')),
        GoRoute(
          path: '/missing',
          builder: (_, _) => const RouteErrorPage(message: 'Surah not found'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('Surah not found'), findsOneWidget);

    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
