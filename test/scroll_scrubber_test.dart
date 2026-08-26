/// Widget tests for [ScrollScrubber] placement and hideaway behaviour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:hublee/ui/widgets/scroll_scrubber.dart';

void main() {
  test('gutter is a slim edge, not a reserved column', () {
    expect(ScrollScrubber.gutter, 12);
    expect(ScrollScrubber.gutter, lessThan(ScrollScrubber.overlayWidth));
  });

  testWidgets('pins the overlay to the physical right edge', (tester) async {
    final controller = ItemScrollController();
    final listener = ItemPositionsListener.create();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ScrollablePositionedList.builder(
                itemScrollController: controller,
                itemPositionsListener: listener,
                itemCount: 12,
                itemBuilder: (_, i) =>
                    SizedBox(height: 64, child: Text('item $i')),
              ),
              ScrollScrubber(
                itemCount: 12,
                labelBuilder: (i) => 'Ayah ${i + 1}',
                scrollController: controller,
                positionsListener: listener,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final overlay = tester.getRect(
      find.byKey(const Key('scroll-scrubber-overlay')),
    );
    final stack = tester.getRect(find.byType(Stack).first);

    expect(overlay.right, closeTo(stack.right - ScrollScrubber.edgeInset, 1));
    expect(overlay.left, greaterThan(stack.center.dx));
    expect(overlay.width, ScrollScrubber.overlayWidth);

    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byKey(const Key('scroll-scrubber-overlay')),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('appears after the list is scrolled', (tester) async {
    final controller = ItemScrollController();
    final listener = ItemPositionsListener.create();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ScrollablePositionedList.builder(
                itemScrollController: controller,
                itemPositionsListener: listener,
                itemCount: 20,
                itemBuilder: (_, i) =>
                    SizedBox(height: 80, child: Text('item $i')),
              ),
              ScrollScrubber(
                itemCount: 20,
                labelBuilder: (i) => 'Ayah ${i + 1}',
                scrollController: controller,
                positionsListener: listener,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(controller.isAttached, isTrue);
    expect(
      tester
          .widget<IgnorePointer>(
            find.descendant(
              of: find.byKey(const Key('scroll-scrubber-overlay')),
              matching: find.byType(IgnorePointer),
            ),
          )
          .ignoring,
      isTrue,
    );

    controller.jumpTo(index: 8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byKey(const Key('scroll-scrubber-overlay')),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isFalse);
  });
}
