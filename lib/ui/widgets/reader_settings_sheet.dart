/// Bottom sheet for quick reader settings accessible from reading
/// pages. Provides live-preview sliders for Arabic and English
/// font sizes, an Arabic font picker, a theme toggle, and
/// optionally a tajweed toggle with guide link.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router_paths.dart';
import '../../services/settings_controller.dart';
import '../../services/settings_scope.dart';
import '../../services/app_scope.dart';
import '../../theme/app_tokens.dart';

/// Shows the reader settings bottom sheet.
///
/// If [showTajweedToggle] is true, a tajweed on/off switch and a
/// "Tajweed Guide" info button are included (Quran reader only).
void showReaderSettingsSheet(
  BuildContext context, {
  bool showTajweedToggle = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReaderSettingsSheet(
      showTajweedToggle: showTajweedToggle,
    ),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final bool showTajweedToggle;

  const _ReaderSettingsSheet({required this.showTajweedToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = SettingsScope.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.sheetTop,
        boxShadow: AppShadows.sheet,
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Reader Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Arabic font picker
          _FontPicker(
            selected: settings.arabicFont,
            onChanged: (font) => settings.arabicFont = font,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),

          // Arabic font size slider
          _ZoomSlider(
            label: 'Arabic Size',
            value: settings.arabicZoom,
            icon: Icons.format_size_rounded,
            onChanged: (v) => settings.arabicZoom = v,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),

          // English font size slider
          _ZoomSlider(
            label: 'Translation Size',
            value: settings.englishZoom,
            icon: Icons.text_fields_rounded,
            onChanged: (v) => settings.englishZoom = v,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 18),

          // Theme toggle
          _SettingRow(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            label: isDark ? 'Moon Mode' : 'Sun Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => AppScope.of(context).toggleTheme(),
            ),
            onTap: () => AppScope.of(context).toggleTheme(),
            colorScheme: colorScheme,
          ),

          // Tajweed toggle + guide button (Quran reader only)
          if (showTajweedToggle) ...[
            const SizedBox(height: 8),
            _SettingRow(
              icon: Icons.color_lens_rounded,
              label: 'Tajweed Colors',
              trailing: Switch(
                value: settings.tajweedEnabled,
                onChanged: (v) => settings.tajweedEnabled = v,
              ),
              onTap: () => settings.tajweedEnabled = !settings.tajweedEnabled,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 4),
            _SettingRow(
              icon: Icons.info_outline_rounded,
              label: 'Tajweed Guide',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              onTap: () {
                Navigator.of(context).pop(); // close sheet
                context.push(AppRoute.tajweedGuide);
              },
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal font family picker with selectable chips.
class _FontPicker extends StatelessWidget {
  final ArabicFontOption selected;
  final ValueChanged<ArabicFontOption> onChanged;
  final ColorScheme colorScheme;

  const _FontPicker({
    required this.selected,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.font_download_rounded,
                size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Arabic Font',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ArabicFontOption.values.map((font) {
              final isSelected = font == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(font.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(font),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Compact slider for font zoom with label and percentage badge.
class _ZoomSlider extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final ValueChanged<double> onChanged;
  final ColorScheme colorScheme;

  const _ZoomSlider({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.8,
            max: 1.8,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}

/// A tappable row for toggle settings.
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
