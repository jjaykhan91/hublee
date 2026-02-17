/// User-facing settings page for font sizes, theme toggle, and
/// app info.
///
/// Replaces the earlier drawer-based settings approach with a
/// dedicated tab accessible from the bottom navigation bar.
library;

import 'package:flutter/material.dart';

import '../services/settings_scope.dart';
import '../services/app_scope.dart';
import 'widgets/arabic_text.dart';

/// Settings tab: display preferences, appearance, and about info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Display section ──────────────────────────────
          _SectionHeader(
            'Display',
            icon: Icons.text_fields_rounded,
          ),
          const SizedBox(height: 8),

          // Arabic font zoom with live preview
          _FontSizeCard(
            label: 'Quran Arabic Size',
            value: settings.arabicZoom,
            onChanged: (value) => settings.arabicZoom = value,
            preview: ArabicText(
              '\u0628\u0650\u0633\u0652\u0645\u0650 '
              '\u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
              '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0640\u0670\u0646\u0650 '
              '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
              tajweed: false,
              fontSize: 26 * settings.arabicZoom,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // English font zoom with live preview
          _FontSizeCard(
            label: 'Translation Size',
            value: settings.englishZoom,
            onChanged: (value) => settings.englishZoom = value,
            preview: Text(
              'In the name of God, the Most Gracious, '
              'the Most Merciful',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16 * settings.englishZoom,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Appearance section ───────────────────────────
          _SectionHeader(
            'Appearance',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: colorScheme.primary,
              ),
              title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
              subtitle: Text(
                isDark
                    ? 'Easier on the eyes at night'
                    : 'Bright and clear display',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => AppScope.of(context).toggleTheme(),
              ),
              onTap: () => AppScope.of(context).toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),

          // ── About section ───────────────────────────────
          _SectionHeader(
            'About',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hublee',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quran & Hadith Reader',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled section header used to group settings categories.
class _SectionHeader extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionHeader(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

/// A card containing a font-size slider with a percentage badge
/// and a live text preview that scales in real time.
class _FontSizeCard extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  /// The widget displayed below the slider as a live preview.
  final Widget preview;

  const _FontSizeCard({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label + percentage badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 0.8,
              max: 1.8,
              divisions: 10,
              onChanged: onChanged,
            ),
            const SizedBox(height: 4),
            preview,
          ],
        ),
      ),
    );
  }
}
