/// Reusable section header with optional icon.
///
/// Use for "Explore", "Quran (n)", "Hadith (n)" style headers.
library;

import 'package:flutter/material.dart';

/// A row with optional leading icon and bold title.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.icon,
    this.iconSize = 18,
    this.color,
    this.padding,
  });

  final String title;
  final IconData? icon;
  final double iconSize;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.primary;

    final child = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: resolvedColor),
          SizedBox(width: iconSize * 0.35),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: resolvedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (padding != null) {
      return Padding(padding: padding!, child: child);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: child,
    );
  }
}
