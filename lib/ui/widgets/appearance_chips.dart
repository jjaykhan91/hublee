/// Choice chips for System / Light / Dark / Paper.
library;

import 'package:flutter/material.dart';

import '../../theme/app_appearance.dart';
import 'app_haptics.dart';

/// Compact appearance picker used in Settings and the reader sheet.
class AppearanceChips extends StatelessWidget {
  const AppearanceChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppAppearance value;
  final ValueChanged<AppAppearance> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: AppAppearance.values.map((choice) {
        final selected = choice == value;
        return ChoiceChip(
          avatar: Icon(choice.icon, size: 18),
          label: Text(choice.label),
          selected: selected,
          onSelected: (_) {
            AppHaptics.selection();
            onChanged(choice);
          },
          materialTapTargetSize: MaterialTapTargetSize.padded,
          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }
}
