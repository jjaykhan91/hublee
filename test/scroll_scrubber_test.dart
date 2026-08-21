/// Widget tests for [ScrollScrubber] placement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:hublee/ui/widgets/scroll_scrubber.dart';

void main() {
  test('gutter covers overlay width plus edge inset', () {
    expect(
      ScrollScrubber.gutter,
      ScrollScrubber.edgeInset + ScrollScrubber.overlayWidth,
    );
    expect(ScrollScrubber.gutter, greaterThan(40));
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
  });
}
