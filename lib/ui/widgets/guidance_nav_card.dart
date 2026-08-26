/// Shared navigation card for Allah, Prophet, and dua hubs.
library;

import 'package:flutter/material.dart';

import 'hublee_card.dart';

/// A tappable card with a title, optional Arabic, subtitle, and chevron.
class GuidanceNavCard extends StatelessWidget {
  const GuidanceNavCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailingLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return HubleeCard(
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingLabel != null) ...[
            Text(
              trailingLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
