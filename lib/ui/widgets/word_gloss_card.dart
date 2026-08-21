/// Floating card that reveals the meaning of a tapped Qur'anic word.
///
/// It floats above the ayah list rather than expanding the card that was
/// tapped, so revealing a meaning never shifts the text the reader is looking
/// at. It sits at the bottom of the screen to stay within thumb reach.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';
import 'word_by_word_arabic_text.dart';

/// Shows the Arabic phrase, its English gloss, and where it came from.
///
/// Pass a `null` [selection] to dismiss; the card keeps rendering the previous
/// selection while it animates out.
class WordGlossCard extends StatefulWidget {
  final WordByWordSelection? selection;

  /// Human-readable location, e.g. `Al-Fatiha 1:2`.
  final String? reference;

  /// When set, a star is shown so the word can be saved for learning.
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  final VoidCallback onDismiss;

  const WordGlossCard({
    super.key,
    required this.selection,
    required this.onDismiss,
    this.reference,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<WordGlossCard> createState() => _WordGlossCardState();
}

class _WordGlossCardState extends State<WordGlossCard> {
  /// Retained so the content does not vanish mid-animation on dismiss.
  WordByWordSelection? _lastSelection;
  String? _lastReference;

  @override
  void initState() {
    super.initState();
    _lastSelection = widget.selection;
    _lastReference = widget.reference;
  }

  @override
  void didUpdateWidget(WordGlossCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != null) {
      _lastSelection = widget.selection;
      _lastReference = widget.reference;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVisible = widget.selection != null;
    final selection = _lastSelection;

    if (selection == null) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 1.4),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Semantics(
            liveRegion: true,
            label: 'Word meaning: ${selection.gloss}',
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.card,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                ),
                boxShadow: AppShadows.sheet,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    child: widget.onToggleFavorite == null
                        ? null
                        : IconButton(
                            icon: Icon(
                              widget.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: widget.isFavorite
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            tooltip: widget.isFavorite
                                ? 'Remove from learning list'
                                : 'Save word to learn',
                            onPressed: () {
                              AppHaptics.selection();
                              widget.onToggleFavorite!();
                            },
                          ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ArabicText(
                          selection.arabic,
                          tajweed: false,
                          fontSize: 32,
                          weight: FontWeight.bold,
                          align: TextAlign.center,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selection.gloss,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            height: 1.3,
                          ),
                        ),
                        if (_lastReference != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            selection.phrase.isMultiWord
                                ? '${_lastReference!} · phrase'
                                : _lastReference!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                    tooltip: 'Dismiss',
                    onPressed: () {
                      AppHaptics.selection();
                      widget.onDismiss();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
