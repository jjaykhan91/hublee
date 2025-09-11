import 'package:flutter/material.dart';
import '../../services/settings_scope.dart';
import '../widgets/arabic_text.dart';

/// Half-width drawer that slides in from the right.
/// Provides controls for font size (Arabic + English) and theme switching,
/// with sample preview text under each slider.
class SettingsDrawer extends StatelessWidget {
  final VoidCallback onToggleTheme; // Uses your ThemeModeService callback

  const SettingsDrawer({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context); // Access user settings
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width * 0.70; // 70% width

    return SizedBox(
      width: w,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Drawer title
              Row(
                children: [
                  Icon(Icons.settings, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Settings',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),

              // Display section
              const _SectionHeader('Display'),
              const SizedBox(height: 8),

              // Arabic font zoom + preview
              _LabeledSliderWithPreview(
                label: 'Arabic size',
                value: settings.arabicZoom,
                min: 0.8,
                max: 1.8,
                divisions: 10,
                onChanged: (v) => settings.arabicZoom = v,
                valueText: '${(settings.arabicZoom * 100).round()}%',
                preview: ArabicText(
                  'الْحَمْدُ لِلَّهِ',
                  tajweed: true,
                  fontSize: 26 * settings.arabicZoom,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // English font zoom + preview
              _LabeledSliderWithPreview(
                label: 'English size',
                value: settings.englishZoom,
                min: 0.8,
                max: 1.8,
                divisions: 10,
                onChanged: (v) => settings.englishZoom = v,
                valueText: '${(settings.englishZoom * 100).round()}%',
                preview: Text(
                  'All praise is due to Allah',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16 * settings.englishZoom,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 20),

              // Theme section
              const _SectionHeader('Theme'),
              const SizedBox(height: 8),
              _ThemeSwitch(onToggle: onToggleTheme),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header text (e.g. "Display", "Theme").
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(
      text,
      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// Slider with label, current value, and a preview widget below.
class _LabeledSliderWithPreview extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String valueText;
  final Widget preview;

  const _LabeledSliderWithPreview({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    required this.valueText,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  valueText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: valueText,
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            preview, // 👈 live sample text preview
          ],
        ),
      ),
    );
  }
}

/// Theme switch card with sun/moon icon.
class _ThemeSwitch extends StatelessWidget {
  final VoidCallback onToggle;
  const _ThemeSwitch({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(isDark ? Icons.nights_stay : Icons.wb_sunny_rounded),
        title: Text(isDark ? 'Moon Mode' : 'Sun Mode'),
        trailing: Switch(
          value: isDark,
          onChanged: (_) => onToggle(),
        ),
        onTap: onToggle,
      ),
    );
  }
}
