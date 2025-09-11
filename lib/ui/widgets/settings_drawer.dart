import 'package:flutter/material.dart';
import '../../services/settings_scope.dart';

class SettingsDrawer extends StatelessWidget {
  final VoidCallback onToggleTheme; // uses your ThemeModeService via callback
  const SettingsDrawer({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final w  = MediaQuery.of(context).size.width * 0.5; // half-screen

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
              Row(
                children: [
                  Icon(Icons.settings, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              _SectionHeader('Display'),
              const SizedBox(height: 8),

              // Arabic zoom
              _LabeledSlider(
                label: 'Arabic size',
                value: s.arabicZoom,
                min: 0.8,
                max: 1.8,
                divisions: 10,
                onChanged: (v) => s.arabicZoom = v,
                valueText: '${(s.arabicZoom * 100).round()}%',
              ),
              const SizedBox(height: 12),

              // English zoom
              _LabeledSlider(
                label: 'English size',
                value: s.englishZoom,
                min: 0.8,
                max: 1.8,
                divisions: 10,
                onChanged: (v) => s.englishZoom = v,
                valueText: '${(s.englishZoom * 100).round()}%',
              ),
              const SizedBox(height: 20),

              _SectionHeader('Theme'),
              const SizedBox(height: 8),
              _ThemeSwitch(onToggle: onToggleTheme),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(text, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String valueText;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    required this.valueText,
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
                Text(valueText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        )),
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
          ],
        ),
      ),
    );
  }
}

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
        title: Text(isDark ? 'Dark mode' : 'Light mode'),
        trailing: Switch(
          value: isDark,
          onChanged: (_) => onToggle(),
        ),
        onTap: onToggle,
      ),
    );
  }
}
