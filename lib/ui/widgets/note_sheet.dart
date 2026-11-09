/// The reader's own notes on an ayah or a hadith: an editor sheet and the
/// note shown inside a reading card.
library;

import 'package:flutter/material.dart';

import '../../services/bookmark_service.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

/// Longest note, so one passage cannot fill local storage.
const noteMaxLength = 2000;

/// "Sahih al-Bukhari · Hadith 12", preferring the book's own number.
String hadithNoteTitle(String bookTitle, int hadithIndex, int? idInBook) =>
    '$bookTitle · Hadith ${idInBook ?? hadithIndex + 1}';

/// Opens the note editor for [target], titled with [title] such as
/// `Al-Baqarah 2:255`.
Future<void> showNoteSheet(
  BuildContext context, {
  required BookmarkService service,
  required Bookmark target,
  required String title,
}) {
  AppHaptics.selection();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (_) => _NoteEditor(service: service, target: target, title: title),
  );
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.service,
    required this.target,
    required this.title,
  });

  final BookmarkService service;
  final Bookmark target;
  final String title;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final ReadingNote? _existing = widget.service.noteFor(widget.target.id);
  late final _controller = TextEditingController(text: _existing?.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await widget.service.saveNote(
      target: widget.target,
      text: _controller.text,
    );
    AppHaptics.lightImpact();
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    await widget.service.deleteNote(widget.target.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_existing == null ? 'Add a note' : 'Your note'} · '
            '${widget.title}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('note-field'),
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            maxLength: noteMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'A reflection, a lesson, a reminder',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_existing != null)
                TextButton.icon(
                  key: const Key('note-delete'),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('note-save'),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Note button for a reading card's action row: outlined when there is
/// no note, filled when there is one.
class NoteButton extends StatelessWidget {
  const NoteButton({super.key, required this.hasNote, required this.onTap});

  final bool hasNote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(
        hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
        color: hasNote
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.3),
        size: 22,
      ),
      onPressed: onTap,
      tooltip: hasNote ? 'Edit note' : 'Add note',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}

/// The reader's note shown inside a reading card. Tap to edit.
class NotePreview extends StatelessWidget {
  const NotePreview({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sticky_note_2_rounded,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel: 'Your note: $text',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    height: 1.45,
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
