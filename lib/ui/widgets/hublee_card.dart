/// Shared card wrapper with consistent padding and tap handling.
///
/// Use for list tiles, result tiles, and content cards so styling
/// stays in one place.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A [Card] with theme styling, optional tap/long-press, and card padding.
class HubleeCard extends StatelessWidget {
  const HubleeCard({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.child,
    this.padding,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  /// Override default card padding (defaults to [AppSpacing.cardTight]).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: padding ?? AppSpacing.cardTight,
            child: child,
          ),
        ),
      ),
    );
  }
}
