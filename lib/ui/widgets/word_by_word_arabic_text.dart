/// Renders an ayah as individually tappable words.
///
/// The design goal is that word-by-word study and tajweed colouring coexist.
/// Tapping a word therefore highlights it with a *background* tint and leaves
/// every letter's tajweed colour untouched — recolouring the word, as is
/// common, would destroy the recitation information the reader came for.
///
/// Word boundaries come from [segmentArabicWords] on exactly the string being
/// drawn, and the glosses are pre-aligned to that segmentation at build time
/// (see `tools/build_word_by_word.dart`). If the two ever disagree, the widget
/// renders plain text rather than showing a word the wrong meaning.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../quran/arabic_word_segmenter.dart';
import '../../quran/word_by_word_repository.dart';
import '../../services/settings_controller.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';
import 'tajweed.dart';

/// A word-by-word selection: the phrase that was tapped plus the Arabic it
/// covers, so callers can present it without re-segmenting the ayah.
@immutable
class WordByWordSelection {
  final GlossPhrase phrase;

  /// The Arabic text of the phrase, trimmed of surrounding whitespace.
  final String arabic;

  const WordByWordSelection({required this.phrase, required this.arabic});

  /// The English gloss for the phrase.
  String get gloss => phrase.gloss;
}

/// A run of text within a word that shares one tajweed colour.
@immutable
class _Piece {
  final String text;
  final Color? color;
  const _Piece(this.text, this.color);
}

/// Identifies a computed layout so it is only recomputed when an input that
/// actually affects word boundaries or colours changes.
@immutable
class _LayoutKey {
  final String text;
  final bool tajweed;
  final Brightness brightness;
  const _LayoutKey(this.text, this.tajweed, this.brightness);

  @override
  bool operator ==(Object other) =>
      other is _LayoutKey &&
      other.text == text &&
      other.tajweed == tajweed &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(text, tajweed, brightness);
}

/// Arabic ayah text whose words can be tapped to reveal an English gloss.
class WordByWordArabicText extends StatefulWidget {
  /// The ayah text to draw. Must be standard Uthmani Unicode, because the
  /// glosses are aligned against that segmentation.
  final String text;

  /// One gloss per word. An empty entry continues the previous gloss.
  final List<String> glosses;

  final double fontSize;
  final bool tajweed;
  final FontWeight? weight;
  final Color? color;
  final ArabicFontOption? fontOverride;

  /// The phrase currently revealed, or `null` when nothing is selected.
  final GlossPhrase? selectedPhrase;

  /// Called with the tapped selection, or `null` when the tap clears it by
  /// hitting an already-selected word.
  final ValueChanged<WordByWordSelection?> onPhraseSelected;

  const WordByWordArabicText({
    super.key,
    required this.text,
    required this.glosses,
    required this.fontSize,
    required this.onPhraseSelected,
    this.tajweed = true,
    this.weight,
    this.color,
    this.fontOverride,
    this.selectedPhrase,
  });

  @override
  State<WordByWordArabicText> createState() => _WordByWordArabicTextState();
}

class _WordByWordArabicTextState extends State<WordByWordArabicText> {
  _LayoutKey? _layoutKey;

  /// Pieces grouped per word, in reading order.
  List<List<_Piece>> _wordPieces = const [];

  /// One recognizer per word, reused across rebuilds and disposed with the
  /// widget. Creating these in `build` would leak a recognizer per frame.
  List<TapGestureRecognizer> _recognizers = const [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = const [];
  }

  /// Recomputes word grouping and colours when [key] changes.
  void _ensureLayout(_LayoutKey key) {
    if (_layoutKey == key) return;
    _layoutKey = key;
    _wordPieces = _computePieces(key);

    if (_recognizers.length != _wordPieces.length) {
      _disposeRecognizers();
      _recognizers = List.generate(
        _wordPieces.length,
        (index) => TapGestureRecognizer()..onTap = () => _handleTap(index),
        growable: false,
      );
    }
  }

  static List<List<_Piece>> _computePieces(_LayoutKey key) {
    if (!key.tajweed) {
      return [
        for (final word in segmentArabicWords(key.text))
          [_Piece(key.text.substring(word.start, word.end), null)],
      ];
    }

    // The tajweed engine sanitizes its input, so segment the string it
    // actually produced. Joining the clusters reconstructs it exactly, which
    // keeps cluster offsets and word offsets in the same coordinate space.
    final clusters = tajweedColorAssignments(
      key.text,
      brightness: key.brightness,
    );
    final sanitized = clusters.map((c) => c.text).join();
    final words = segmentArabicWords(sanitized);
    if (words.isEmpty) return const [];

    final pieces = List.generate(words.length, (_) => <_Piece>[]);
    var offset = 0;
    for (final cluster in clusters) {
      final index = wordIndexAtOffset(words, offset);
      if (index != null) {
        pieces[index].add(_Piece(cluster.text, cluster.color));
      }
      offset += cluster.text.length;
    }
    return pieces;
  }

  void _handleTap(int wordIndex) {
    final phrase = glossPhraseAt(widget.glosses, wordIndex);
    if (phrase == null) return;
    AppHaptics.selection();
    if (widget.selectedPhrase == phrase) {
      widget.onPhraseSelected(null);
      return;
    }
    widget.onPhraseSelected(
      WordByWordSelection(phrase: phrase, arabic: _arabicFor(phrase)),
    );
  }

  /// Joins the drawn text of the words the phrase covers.
  String _arabicFor(GlossPhrase phrase) {
    final buffer = StringBuffer();
    for (var i = phrase.firstWord; i <= phrase.lastWord; i++) {
      if (i < 0 || i >= _wordPieces.length) continue;
      for (final piece in _wordPieces[i]) {
        buffer.write(piece.text);
      }
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = arabicTextStyle(
      context,
      fontSize: widget.fontSize,
      fontOverride: widget.fontOverride,
      weight: widget.weight ?? FontWeight.bold,
      color: widget.color,
    );

    _ensureLayout(_LayoutKey(widget.text, widget.tajweed, theme.brightness));

    // The build-time tool guarantees one gloss per word. If a data refresh
    // ever breaks that, show the ayah without taps instead of mislabelling it.
    final isAligned =
        widget.glosses.isNotEmpty &&
        widget.glosses.length == _wordPieces.length;

    final highlight = theme.colorScheme.primary.withValues(alpha: 0.3);
    final selected = isAligned ? widget.selectedPhrase : null;

    final spans = <InlineSpan>[];
    for (var wordIndex = 0; wordIndex < _wordPieces.length; wordIndex++) {
      final isHighlighted =
          selected != null &&
          wordIndex >= selected.firstWord &&
          wordIndex <= selected.lastWord;
      final isLastHighlightedWord =
          isHighlighted && wordIndex == selected.lastWord;
      final pieces = _wordPieces[wordIndex];

      for (var i = 0; i < pieces.length; i++) {
        final piece = pieces[i];
        // Don't tint the space that trails the phrase — it would leave the
        // highlight hanging past the final letter.
        final tintable =
            isHighlighted &&
            !(isLastHighlightedWord &&
                i == pieces.length - 1 &&
                piece.text.trim().isEmpty);
        spans.add(
          TextSpan(
            text: piece.text,
            style: style.copyWith(
              color: piece.color,
              backgroundColor: tintable ? highlight : null,
            ),
            recognizer: isAligned ? _recognizers[wordIndex] : null,
          ),
        );
      }
    }

    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        text: TextSpan(style: style, children: spans),
        strutStyle: arabicStrutStyle(style),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}
