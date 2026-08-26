/// Desktop reading chrome: NavigationRail breakpoint and max column width.
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/material.dart';

/// Layout breakpoints for wide windows and foldables.
///
/// Galaxy Z Fold 7 (logical dp, 422 ppi cover / 368 ppi inner):
/// cover ≈ 410×956 (21:9), inner ≈ 856×950 (nearly square).
abstract final class ReadingLayout {
  ReadingLayout._();

  /// Use a [NavigationRail] at this width and above, unless the
  /// window is an open foldable (those keep the bottom bar).
  static const double railBreakpoint = 600;

  /// Cap reading columns so lines do not span a full ultrawide window.
  static const double maxContentWidth = 840;

  /// Compact reader chrome (overflow menu instead of five icons).
  ///
  /// Must sit above the Fold 7 cover's ~410 dp width, otherwise the
  /// gold title pill and every action icon still crowd the app bar.
  static const double compactAppBarWidth = 480;

  /// Cover-like screens whose shortest side is under
  /// [compactAppBarWidth] (Fold cover, phones).
  static bool compactChrome(Size size) {
    return size.shortestSide < compactAppBarWidth;
  }

  /// Whether [features] include an open fold or hinge.
  static bool hasFoldDisplay(Iterable<DisplayFeature> features) {
    for (final feature in features) {
      if (feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge) {
        return true;
      }
    }
    return false;
  }

  /// Inner foldable displays are nearly square; tablets and desktops
  /// are not. Used when the OS omits [DisplayFeature]s.
  static const double openFoldMaxAspect = 1.25;

  /// Whether this window is an unfolded foldable (cover is excluded
  /// because its shortest side is below [railBreakpoint]).
  static bool isOpenFold(
    Size size, {
    Iterable<DisplayFeature> displayFeatures = const [],
  }) {
    if (hasFoldDisplay(displayFeatures)) return true;
    final shortest = size.shortestSide;
    if (shortest < railBreakpoint) return false;
    return size.longestSide / shortest <= openFoldMaxAspect;
  }

  /// Whether [size] should show the rail instead of a bottom bar.
  ///
  /// Open foldables report a wide inner width but still want thumb-
  /// reachable icons on the bottom.
  static bool useRail(
    Size size, {
    Iterable<DisplayFeature> displayFeatures = const [],
  }) {
    if (isOpenFold(size, displayFeatures: displayFeatures)) return false;
    return size.width >= railBreakpoint;
  }
}

/// Centers [child] and caps its width on wide screens.
class ConstrainedReadingBody extends StatelessWidget {
  const ConstrainedReadingBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ReadingLayout.railBreakpoint) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ReadingLayout.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
