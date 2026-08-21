/// A large, tappable tile with a gradient background, icon badge,
/// title, subtitle, and trailing chevron.
///
/// Used on the Home page for the "Quran" and "Hadith" explore
/// shortcuts.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

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

    return InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
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
          boxShadow: AppShadows.gradientTile,
        ),
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              // Icon badge with 3D shadow
              Container(
                height: AppSpacing.minTouchTarget,
                width: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: AppRadius.chip,
                  boxShadow: AppShadows.badge,
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
