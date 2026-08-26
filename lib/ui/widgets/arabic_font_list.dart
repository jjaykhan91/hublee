/// Vertical selectable list of Arabic typefaces.
library;

import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

/// One row per [ArabicFontOption], with a check on the selected face.
class ArabicFontList extends StatelessWidget {
  const ArabicFontList({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ArabicFontOption selected;
  final ValueChanged<ArabicFontOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fonts = ArabicFontOption.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fonts.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _FontRow(
            font: fonts[i],
            selected: fonts[i] == selected,
            colorScheme: colorScheme,
            onTap: () {
              AppHaptics.selection();
              onChanged(fonts[i]);
            },
          ),
        ],
      ],
    );
  }
}

class _FontRow extends StatelessWidget {
  const _FontRow({
    required this.font,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final ArabicFontOption font;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: AppRadius.chip,
      child: InkWell(
        key: Key('arabic-font-${font.name}'),
        borderRadius: AppRadius.chip,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  font.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
