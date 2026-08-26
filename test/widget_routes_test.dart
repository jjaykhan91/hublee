/// Tests for `hublee://` launcher-widget tap mapping.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/services/widget_routes.dart';

void main() {
  tearDown(WidgetLaunch.reset);

  test('ayah uri opens the surah reader', () {
    expect(
      pathForWidgetUri(Uri.parse('hublee://ayah?surah=2&ayah=255')),
      AppRoute.surah(2, ayah: 255),
    );
  });

  test('ayah uri without ayah still opens the surah', () {
    expect(
      pathForWidgetUri(Uri.parse('hublee://ayah?surah=1')),
      AppRoute.surah(1),
    );
  });

  test('rejects out-of-range surah', () {
    expect(pathForWidgetUri(Uri.parse('hublee://ayah?surah=115')), isNull);
  });

  test('hadith uri opens the book at the given index', () {
    final path = pathForWidgetUri(
      Uri.parse(
        'hublee://hadith?collection=forties&book=nawawi40.json'
        '&title=Nawawi%2040&index=3',
      ),
    );
    expect(path, contains('/hadith/forties/nawawi40.json'));
    expect(path, contains('index=3'));
  });

  test('arabic uri opens the MSA dictionary', () {
    expect(
      pathForWidgetUri(Uri.parse('hublee://arabic')),
      AppRoute.msaDictionary,
    );
  });

  test('unknown scheme is ignored', () {
    expect(pathForWidgetUri(Uri.parse('https://example.com')), isNull);
  });

  test('hold and takePath consume the tap once', () {
    WidgetLaunch.hold(Uri.parse('hublee://ayah?surah=1&ayah=1'));
    expect(WidgetLaunch.takePath(), AppRoute.surah(1, ayah: 1));
    expect(WidgetLaunch.takePath(), isNull);
  });
}
