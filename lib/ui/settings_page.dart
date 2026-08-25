/// User-facing settings page for font sizes, theme toggle, and
/// app info.
///
/// Replaces the earlier drawer-based settings approach with a
/// dedicated tab accessible from the bottom navigation bar.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../router_paths.dart';
import '../services/settings_controller.dart';
import '../services/settings_scope.dart';
import '../services/app_scope.dart';
import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';
import 'widgets/appearance_chips.dart';

/// Settings tab: display preferences, appearance, and about info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final appearance = AppScope.of(context).appearance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Display section ──────────────────────────────
          const _SectionHeader('Display', icon: Icons.text_fields_rounded)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms),
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
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 60.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 60.ms),
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
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 120.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 120.ms),
          const SizedBox(height: 12),

          // Arabic font picker
          Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arabic Font',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ArabicFontOption.values.map((font) {
                          final isSelected = font == settings.arabicFont;
                          return ChoiceChip(
                            label: Text(font.label),
                            selected: isSelected,
                            onSelected: (_) {
                              AppHaptics.selection();
                              settings.arabicFont = font;
                            },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.4)
                                  : colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 12),

          // Tajweed toggle
          Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.color_lens_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Tajweed Colors'),
                  subtitle: Text(
                    settings.tajweedEnabled
                        ? 'Colour-coded tajweed rules shown'
                        : 'Plain Arabic text displayed',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Semantics(
                    label: 'Tajweed colors',
                    toggled: settings.tajweedEnabled,
                    child: Switch(
                      value: settings.tajweedEnabled,
                      onChanged: (v) {
                        AppHaptics.selection();
                        settings.tajweedEnabled = v;
                      },
                    ),
                  ),
                  onTap: () {
                    AppHaptics.selection();
                    settings.tajweedEnabled = !settings.tajweedEnabled;
                  },
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 210.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 210.ms),

          // Word-by-word toggle
          Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.touch_app_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Word by Word'),
                  subtitle: Text(
                    settings.wordByWordEnabled
                        ? 'Tap any word to see its meaning'
                        : 'Tapping words is off',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Semantics(
                    label: 'Word by word',
                    toggled: settings.wordByWordEnabled,
                    child: Switch(
                      value: settings.wordByWordEnabled,
                      onChanged: (v) {
                        AppHaptics.selection();
                        settings.wordByWordEnabled = v;
                      },
                    ),
                  ),
                  onTap: () {
                    AppHaptics.selection();
                    settings.wordByWordEnabled = !settings.wordByWordEnabled;
                  },
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 240.ms),

          // Tajweed guide link
          Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Tajweed Guide'),
                  subtitle: Text(
                    'Learn tajweed rules and color coding',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoute.tajweedGuide),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 240.ms),
          const SizedBox(height: 24),

          // ── Appearance section ───────────────────────────
          const _SectionHeader('Appearance', icon: Icons.palette_outlined)
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 8),

          Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppearanceChips(
                        value: appearance,
                        onChanged: (value) =>
                            AppScope.of(context).setAppearance(value),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 360.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 360.ms),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Icon(
                Icons.translate_rounded,
                color: colorScheme.primary,
              ),
              title: const Text('Show translation'),
              subtitle: const Text('Hide English to read Arabic only'),
              value: settings.showTranslation,
              onChanged: (value) {
                AppHaptics.selection();
                settings.showTranslation = value;
              },
            ),
          ),
          if (!kReleaseMode) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(Icons.speed_rounded, color: colorScheme.primary),
                title: const Text('Diagnostics'),
                subtitle: Text(
                  'Timings, jank, and the performance overlay',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoute.diagnostics),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── About section ───────────────────────────────
          const _SectionHeader('About', icon: Icons.info_outline_rounded)
              .animate()
              .fadeIn(duration: 400.ms, delay: 420.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 420.ms),
          const SizedBox(height: 8),

          Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hublee',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quran & Hadith Reader',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sources',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Word-by-word English from "The Glorious Qur\u2019an: '
                        'Word-for-Word Translation to Facilitate Learning of '
                        'Qur\u2019anic Arabic" by Dr. Shehnaz Shaikh and '
                        'Ms. Kausar Khatri. The in-app dictionary and '
                        'learning cards use that same glossary — it covers '
                        'the Quran, not modern newspaper Arabic.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Modern Arabic dictionary: Wiktionary (English edition) '
                        'via kaikki.org / wiktextract, CC BY-SA 3.0 and GFDL, '
                        'plus a Hublee newspaper-Arabic core list. Grammar '
                        'lessons are original Hublee notes; verb forms follow '
                        'the classical I–X paradigm.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Verse translation: ClearQuran. Arabic script: KFGQPC '
                        'Hafs and Uthmani text. Recitation: Quran.com CDN and '
                        'EveryAyah (Hafs). Choose a reciter from the play '
                        'control on any ayah. Download a surah from the '
                        'reader for offline play.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Privacy policy'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoute.privacy),
                      ),
                      const SizedBox(height: 12),
                      const _AppVersionLabel(),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 480.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 480.ms),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
            Semantics(
              label: label,
              value: '${(value * 100).round()} percent',
              slider: true,
              child: Slider(
                value: value,
                min: 0.8,
                max: 1.8,
                divisions: 10,
                label: '${(value * 100).round()}%',
                onChanged: onChanged,
              ),
            ),
            const SizedBox(height: 4),
            preview,
          ],
        ),
      ),
    );
  }
}

/// Shows the version from the host package, not a hardcoded string.
class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  String _label = 'Version \u2026';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() {
        _label = 'Version ${info.version}+${info.buildNumber}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
