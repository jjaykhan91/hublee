/// Golden snapshots of chrome that is not Arabic-font-sensitive.
///
/// Run locally: `flutter test --update-goldens test/ui_snapshot_test.dart`
/// CI excludes the `golden` tag.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/app_metrics.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/ui/diagnostics_page.dart';
import 'package:hublee/ui/global_search_page.dart';
import 'package:hublee/ui/route_error_page.dart';
import 'package:hublee/services/hadith_search_service.dart';
import 'package:hublee/services/quran_search_service.dart';
import 'package:hublee/services/search_models.dart';

class _EmptyQuranSearch extends QuranSearchService {
  @override
  Future<void> warmIndex() async {}

  @override
  Future<QuranSearchResult> search(String query, {int limit = 150}) async {
    return const QuranSearchResult();
  }
}

class _EmptyHadithSearch extends HadithSearchService {
  @override
  Future<void> warmIndex() async {}

  @override
  Future<HadithSearchResult> search(String query, {int limit = 100}) async {
    return const HadithSearchResult();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppMetrics.instance.reset);

  Future<void> pumpAndMatch(
    WidgetTester tester, {
    required Widget home,
    required String name,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(debugShowCheckedModeBanner: false, theme: theme, home: home),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('route error, light', (tester) async {
    await pumpAndMatch(
      tester,
      theme: buildLightTheme(),
      home: const RouteErrorPage(message: 'Surah not found'),
      name: 'ui_route_error_light',
    );
  }, tags: 'golden');

  testWidgets('route error, dark', (tester) async {
    await pumpAndMatch(
      tester,
      theme: buildDarkTheme(),
      home: const RouteErrorPage(message: 'Surah not found'),
      name: 'ui_route_error_dark',
    );
  }, tags: 'golden');

  testWidgets('search empty, light', (tester) async {
    await pumpAndMatch(
      tester,
      theme: buildLightTheme(),
      home: SearchPage(
        quranSearch: _EmptyQuranSearch(),
        hadithSearch: _EmptyHadithSearch(),
      ),
      name: 'ui_search_empty_light',
    );
  }, tags: 'golden');

  testWidgets('diagnostics empty, light', (tester) async {
    await pumpAndMatch(
      tester,
      theme: buildLightTheme(),
      home: const DiagnosticsPage(),
      name: 'ui_diagnostics_light',
    );
  }, tags: 'golden');

  testWidgets('card elevation, light vs dark', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Widget cards(ThemeData theme) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                title: Text('Card sample'),
                subtitle: Text('Elevation follows the theme'),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(cards(buildLightTheme()));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ui_card_light.png'),
    );

    await tester.pumpWidget(cards(buildDarkTheme()));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ui_card_dark.png'),
    );
  }, tags: 'golden');
}
