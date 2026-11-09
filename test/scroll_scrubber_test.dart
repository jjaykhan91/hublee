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

    expect(_gate(tester).ignoring, isTrue);
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
    expect(_gate(tester).ignoring, isTrue);

    controller.jumpTo(index: 8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(_gate(tester).ignoring, isFalse);
  });

  group('while shown', () {
    late ItemScrollController controller;
    late ItemPositionsListener listener;

    int topIndex() =>
        (listener.itemPositions.value.toList()
              ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge)))
            .first
            .index;

    Future<void> pumpShown(WidgetTester tester) async {
      controller = ItemScrollController();
      listener = ItemPositionsListener.create();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScrollablePositionedList.builder(
                  itemScrollController: controller,
                  itemPositionsListener: listener,
                  itemCount: 100,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 80, child: Text('item $i')),
                ),
                ScrollScrubber(
                  itemCount: 100,
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
      controller.jumpTo(index: 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_gate(tester).ignoring, isFalse);
    }

    testWidgets('a tap on the edge away from the handle does not jump', (
      tester,
    ) async {
      await pumpShown(tester);
      final overlay = tester.getRect(
        find.byKey(const Key('scroll-scrubber-overlay')),
      );

      await tester.tapAt(Offset(overlay.center.dx, overlay.bottom - 40));
      await tester.pump();

      expect(topIndex(), 2);
    });

    testWidgets('a swipe on the edge scrolls the list instead of jumping', (
      tester,
    ) async {
      await pumpShown(tester);
      final overlay = tester.getRect(
        find.byKey(const Key('scroll-scrubber-overlay')),
      );

      // Swipe up by two items from low on the edge, where the old track
      // would have jumped to the end of the list.
      await tester.dragFrom(
        Offset(overlay.center.dx, overlay.bottom - 40),
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();

      expect(topIndex(), inInclusiveRange(3, 6));
    });

    testWidgets('dragging the handle moves through the list', (tester) async {
      await pumpShown(tester);
      final handle = find.byKey(const Key('scroll-scrubber-handle'));
      final overlay = tester.getRect(
        find.byKey(const Key('scroll-scrubber-overlay')),
      );

      await tester.dragFrom(
        tester.getCenter(handle),
        Offset(0, overlay.height),
      );
      await tester.pump();

      expect(topIndex(), greaterThan(80));
      expect(find.text('Ayah 100'), findsOneWidget);
    });
  });

  testWidgets('a big bubble shows the ayah only while dragging', (
    tester,
  ) async {
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
                itemCount: 100,
                itemBuilder: (_, i) =>
                    SizedBox(height: 80, child: Text('item $i')),
              ),
              ScrollScrubber(
                itemCount: 100,
                labelBuilder: (i) => 'Ayah ${i + 1} of 100',
                scrollController: controller,
                positionsListener: listener,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    controller.jumpTo(index: 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    double bubbleOpacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('scroll-scrubber-bubble')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(bubbleOpacity(), 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('scroll-scrubber-handle'))),
    );
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(bubbleOpacity(), 1);
    expect(find.text('of 100'), findsOneWidget);
    expect(find.text('Ayah'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(bubbleOpacity(), 0);
  });
}

IgnorePointer _gate(WidgetTester tester) =>
    tester.widget<IgnorePointer>(find.byKey(const Key('scroll-scrubber-gate')));
