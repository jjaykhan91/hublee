/// Shared card wrapper with consistent padding and tap handling.
///
/// Use for list tiles, result tiles, and content cards so styling
/// stays in one place.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A [Card] with theme styling, optional [onTap], and [AppRadius.card] padding.
class HubleeCard extends StatelessWidget {
  const HubleeCard({super.key, this.onTap, required this.child, this.padding});

  final VoidCallback? onTap;
  final Widget child;

  /// Override default card padding (defaults to [AppSpacing.cardTight]).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(padding: padding ?? AppSpacing.cardTight, child: child),
      ),
    );
  }
}
