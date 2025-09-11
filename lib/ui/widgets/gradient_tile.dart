import 'package:flutter/material.dart';

class GradientTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
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
    final cs = Theme.of(context).colorScheme;

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
          border: Border.all(color: cs.outline.withValues(alpha: 0.9), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHighest,
              Color.alphaBlend(cs.primary.withValues(alpha: 0.06), cs.surfaceContainerHighest),
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
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ),
    );
  }
}
