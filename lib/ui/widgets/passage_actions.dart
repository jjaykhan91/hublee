/// Copy and share actions for a Quran ayah or a hadith.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'app_haptics.dart';

/// Overflow menu and long-press sheet for copying or sharing a passage.
class PassageActionsButton extends StatelessWidget {
  const PassageActionsButton({
    super.key,
    required this.reference,
    this.arabic,
    this.english,
  });

  /// Citation shown after the text, e.g. `Al-Baqarah 2:255`.
  final String reference;
  final String? arabic;
  final String? english;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy or share',
      icon: const Icon(Icons.more_vert_rounded, size: 22),
      onPressed: () => showPassageActionsSheet(
        context,
        reference: reference,
        arabic: arabic,
        english: english,
      ),
    );
  }
}

/// Combined Arabic + English + reference for the clipboard or share sheet.
String formatPassage({
  required String reference,
  String? arabic,
  String? english,
}) {
  final parts = <String>[
    if (arabic != null && arabic.trim().isNotEmpty) arabic.trim(),
    if (english != null && english.trim().isNotEmpty) english.trim(),
    '— $reference',
  ];
  return parts.join('\n\n');
}

/// Bottom sheet with copy Arabic, copy translation, copy all, and share.
Future<void> showPassageActionsSheet(
  BuildContext context, {
  required String reference,
  String? arabic,
  String? english,
}) {
  AppHaptics.selection();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (arabic != null && arabic.trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Arabic'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _copy(context, arabic.trim(), 'Arabic copied');
                },
              ),
            if (english != null && english.trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Copy translation'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _copy(context, english.trim(), 'Translation copied');
                },
              ),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: const Text('Copy all'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _copy(
                  context,
                  formatPassage(
                    reference: reference,
                    arabic: arabic,
                    english: english,
                  ),
                  'Copied',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _share(
                  context,
                  formatPassage(
                    reference: reference,
                    arabic: arabic,
                    english: english,
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _copy(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _share(BuildContext context, String text) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      sharePositionOrigin: box == null || !box.hasSize
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
