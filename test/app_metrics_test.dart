/// Unit tests for [AppMetrics].
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/app_metrics.dart';

void main() {
  setUp(AppMetrics.instance.reset);

  test('time records duration and name', () async {
    await AppMetrics.instance.time('search.global', () async {});

    final event = AppMetrics.instance.lastTiming;
    expect(event, isNotNull);
    expect(event!.name, 'search.global');
    expect(event.duration, isNotNull);
  });

  test('recordNav skips consecutive duplicates', () {
    AppMetrics.instance.recordNav('/home');
    AppMetrics.instance.recordNav('/home');
    AppMetrics.instance.recordNav('/quran');

    final navs = AppMetrics.instance.events
        .where((e) => e.kind == MetricKind.navigation)
        .map((e) => e.name)
        .toList();
    expect(navs, ['/quran', '/home']);
  });

  test('recordUi is listed with timings', () {
    AppMetrics.instance.recordUi('theme', detail: {'mode': 'dark'});
    expect(AppMetrics.instance.events.single.kind, MetricKind.ui);
    expect(AppMetrics.instance.events.single.detail['mode'], 'dark');
  });

  test('clear keeps the overlay flag', () {
    AppMetrics.instance.overlayEnabled = true;
    AppMetrics.instance.recordTiming('x', const Duration(milliseconds: 1));
    AppMetrics.instance.clear();
    expect(AppMetrics.instance.events, isEmpty);
    expect(AppMetrics.instance.overlayEnabled, isTrue);
  });
}
