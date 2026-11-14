/// The one drag handle for bottom sheets that draw their own.
///
/// Sheets opened with `showDragHandle: true` get the same size and
/// colour from the theme; this is for sheets whose handle scrolls with
/// the content or sits inside a custom container.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// A centred pill sized by [AppSheetHandle.size].
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.padding = EdgeInsets.zero});

  /// Space around the pill, e.g. the gap before the sheet's title.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: padding,
        child: Align(
          heightFactor: 1,
          child: SizedBox.fromSize(
            size: AppSheetHandle.size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: AppPalette.of(context).outline,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
