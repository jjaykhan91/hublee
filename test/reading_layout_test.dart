/// Tests for [ReadingLayout] rail vs bottom-bar rules.
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/reading_width.dart';

/// Galaxy Z Fold 7 cover: 1080×2520 @ 422 ppi ≈ 410×956 dp.
const fold7Cover = Size(410, 956);

/// Galaxy Z Fold 7 inner: 1968×2184 @ 368 ppi ≈ 856×950 dp.
const fold7Inner = Size(856, 950);

void main() {
  test('phones keep the bottom bar', () {
    expect(ReadingLayout.useRail(const Size(390, 844)), isFalse);
  });

  test('wide windows without a fold use the rail', () {
    expect(ReadingLayout.useRail(const Size(1280, 800)), isTrue);
  });

  test('Fold 7 cover uses compact chrome and bottom nav', () {
    expect(ReadingLayout.compactChrome(fold7Cover), isTrue);
    expect(ReadingLayout.useRail(fold7Cover), isFalse);
  });

  test('Fold 7 inner keeps bottom nav even without DisplayFeature', () {
    expect(ReadingLayout.compactChrome(fold7Inner), isFalse);
    expect(ReadingLayout.isOpenFold(fold7Inner), isTrue);
    expect(ReadingLayout.useRail(fold7Inner), isFalse);
  });

  test('an open fold keeps bottom nav even when wide', () {
    const hinge = DisplayFeature(
      bounds: Rect.fromLTWH(390, 0, 20, 840),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    );
    expect(
      ReadingLayout.useRail(
        const Size(800, 840),
        displayFeatures: const [hinge],
      ),
      isFalse,
    );
  });

  test('tablets keep the rail (not confused with an open fold)', () {
    // 11" iPad landscape, longest/shortest ≈ 1.43.
    expect(ReadingLayout.useRail(const Size(1194, 834)), isTrue);
    expect(ReadingLayout.isOpenFold(const Size(1194, 834)), isFalse);
  });
}
