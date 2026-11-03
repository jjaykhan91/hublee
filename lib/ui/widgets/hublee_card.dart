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
    this.semanticLabel,
    this.longPressHint,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  /// Override default card padding (defaults to [AppSpacing.cardTight]).
  final EdgeInsets? padding;

  /// When set, screen readers get one button with this label and the
  /// card's tap and long-press actions, instead of its inner widgets.
  final String? semanticLabel;

  /// Spoken for the long-press action, e.g. "About this book".
  final String? longPressHint;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    final card = _buildCard();
    if (label == null) return card;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : longPressHint,
      excludeSemantics: true,
      child: card,
    );
  }

  Widget _buildCard() {
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
