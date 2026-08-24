/// Desktop reading chrome: NavigationRail breakpoint and max column width.
library;

import 'package:flutter/material.dart';

/// Layout breakpoints for wide windows.
abstract final class ReadingLayout {
  ReadingLayout._();

  /// Use a [NavigationRail] at this width and above.
  static const double railBreakpoint = 600;

  /// Cap reading columns so lines do not span a full ultrawide window.
  static const double maxContentWidth = 840;

  /// Whether [width] should show the rail instead of a bottom bar.
  static bool useRail(double width) => width >= railBreakpoint;
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
