/// The shared entrance animation and its reduced-motion behaviour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_tokens.dart';
import 'package:hublee/ui/widgets/fade_slide_in.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

double _opacity(WidgetTester tester) {
  return tester
      .widget<FadeTransition>(find.byType(FadeTransition))
      .opacity
      .value;
}

Offset _offset(WidgetTester tester) {
  return tester
      .widget<SlideTransition>(find.byType(SlideTransition))
      .position
      .value;
}

void main() {
  testWidgets('fades and rises into place, then rests', (tester) async {
    await tester.pumpWidget(_host(const FadeSlideIn(child: Text('ayah'))));

    expect(_opacity(tester), 0);
    expect(_offset(tester).dy, greaterThan(0));
    expect(_offset(tester).dx, 0);

    await tester.pump(AppMotion.slow ~/ 2);
    expect(_opacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(_offset(tester), Offset.zero);
    expect(find.text('ayah'), findsOneWidget);
  });

  testWidgets('horizontal entrance slides along x only', (tester) async {
    await tester.pumpWidget(
      _host(const Text('surah').entrance(axis: Axis.horizontal)),
    );

    expect(_offset(tester).dx, greaterThan(0));
    expect(_offset(tester).dy, 0);
    await tester.pumpAndSettle();
    expect(_offset(tester), Offset.zero);
  });

  testWidgets('a staggered item waits its turn', (tester) async {
    await tester.pumpWidget(
      _host(const FadeSlideIn(index: 5, child: Text('later'))),
    );

    await tester.pump(FadeSlideIn.delayFor(5) ~/ 2);
    expect(_opacity(tester), 0);

    await tester.pump(FadeSlideIn.delayFor(5) + AppMotion.slow);
    expect(_opacity(tester), 1);
  });

  testWidgets('shows the child at once when animations are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FadeSlideIn(index: 8, child: Text('still')),
        disableAnimations: true,
      ),
    );

    expect(_opacity(tester), 1);
    expect(_offset(tester), Offset.zero);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('turning animations off mid-flight finishes it', (tester) async {
    await tester.pumpWidget(_host(const FadeSlideIn(child: Text('ayah'))));
    await tester.pump(AppMotion.slow ~/ 4);
    expect(_opacity(tester), lessThan(1));

    await tester.pumpWidget(
      _host(const FadeSlideIn(child: Text('ayah')), disableAnimations: true),
    );
    expect(_opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('stagger grows by one step and stops at the cap', () {
    expect(FadeSlideIn.delayFor(0), Duration.zero);
    expect(FadeSlideIn.delayFor(1), AppMotion.stagger);
    expect(FadeSlideIn.delayFor(3), AppMotion.stagger * 3);
    expect(FadeSlideIn.delayFor(500), AppMotion.staggerCap);
  });

  test('entrances stay short', () {
    expect(
      AppMotion.slow,
      lessThanOrEqualTo(const Duration(milliseconds: 400)),
    );
    expect(
      FadeSlideIn.delayFor(500) + AppMotion.slow,
      lessThan(const Duration(seconds: 1)),
    );
  });
}
