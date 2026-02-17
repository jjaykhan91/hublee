/// A large, tappable tile with a gradient background, icon badge,
/// title, subtitle, and trailing chevron.
///
/// Used on the Home page for the "Quran" and "Hadith" explore
/// shortcuts.
library;

import 'package:flutter/material.dart';

/// Gradient-filled card with an icon, title, and subtitle.
class GradientTile extends StatelessWidget {
  /// Icon displayed in a rounded badge on the left.
  final IconData icon;

  /// Primary title text.
  final String title;

  /// Secondary description text.
  final String subtitle;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  const GradientTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Resolve the card's border radius from the theme, falling
    // back to a default of 16 px.
    final shape = Theme.of(context).cardTheme.shape;
    final BorderRadius borderRadius = switch (shape) {
      final RoundedRectangleBorder r when r.borderRadius is BorderRadius =>
        r.borderRadius as BorderRadius,
      _ => const BorderRadius.all(Radius.circular(16)),
    };

    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.9),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.06),
                colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon badge
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
