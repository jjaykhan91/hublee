/// Tajweed colour-coding engine for Qur'anic Arabic text.
///
/// This module:
/// 1. **Sanitizes** raw text (removes decorative rosettes, dotted
///    circles, and dangling combining marks).
/// 2. **Clusterizes** the text into base-letter + diacritics groups.
/// 3. **Applies** colour based on tajweed rules (Qalqala, Idgham,
///    Ikhfa, Iqlab, Ghunnah, Ikhfa Shafawi).
///
/// The public entry point is [tajweedSpans], which returns a list
/// of [InlineSpan]s suitable for a [RichText] widget.
library;

import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────
//  Arabic character constants
// ────────────────────────────────────────────────────────────────

const _sukun = '\u0652';
const _shadda = '\u0651';
const _fathatan = '\u064B';
const _dammatan = '\u064C';
const _kasratan = '\u064D';

const _noon = '\u0646';
const _meem = '\u0645';
const _ba = '\u0628';

/// The five Qalqala letters: Qaf, Taa, Ba, Jeem, Dal.
const _qalqalaLetters = {
  '\u0642',
  '\u0637',
  '\u0628',
  '\u062C',
  '\u062F',
};

/// Letters that trigger Idgham with Ghunnah: Ya, Noon, Meem, Waw.
const _idghamWithGhunnahLetters = {
  '\u064A',
  '\u0646',
  '\u0645',
  '\u0648',
};

/// Letters that trigger Idgham without Ghunnah: Ra, Lam.
const _idghamWithoutGhunnahLetters = {'\u0631', '\u0644'};

/// Letters that trigger Ikhfa (concealment).
const _ikhfaLetters = {
  '\u062A', '\u062B', '\u062C', '\u062F', '\u0630',
  '\u0632', '\u0633', '\u0634', '\u0635', '\u0636',
  '\u0637', '\u0638', '\u0641', '\u0642', '\u0643', //
};

// ────────────────────────────────────────────────────────────────
//  Character classification helpers
// ────────────────────────────────────────────────────────────────

/// Returns `true` for whitespace and common Arabic punctuation.
bool _isSpaceLike(String ch) =>
    ch.trim().isEmpty || RegExp(r'[،؛؟,.!:؛—\-–\(\)\[\]{}…]').hasMatch(ch);

/// Returns `true` for Unicode combining marks used in Qur'anic text.
bool _isCombiningMark(String ch) {
  final codePoint = ch.codeUnitAt(0);
  // Alef-above and standard tashkeel range.
  if (codePoint == 0x0670 || (codePoint >= 0x064B && codePoint <= 0x0652)) {
    return true;
  }
  // Small high marks used in the Hafs Smart dataset.
  if (codePoint == 0x06DF ||
      codePoint == 0x06E0 ||
      codePoint == 0x06E2 ||
      codePoint == 0x06E7 ||
      codePoint == 0x06E8) {
    return true;
  }
  return false;
}

/// Qur'anic **spacing** signs (Waqf marks, Sajdah marks, etc.)
/// that are visible but not combining marks.
bool _isQuranSpacingSign(String ch) {
  final codePoint = ch.codeUnitAt(0);
  if (codePoint >= 0x06D6 && codePoint <= 0x06ED) {
    // Exclude decorative rosettes and combining marks.
    if (codePoint == 0x06DD || codePoint == 0x06DE) {
      return false;
    }
    if (codePoint == 0x06DF ||
        codePoint == 0x06E0 ||
        codePoint == 0x06E2 ||
        codePoint == 0x06E7 ||
        codePoint == 0x06E8) {
      return false;
    }
    return true;
  }
  // Extended Arabic supplement range.
  if (codePoint >= 0x08D3 && codePoint <= 0x08FF) return true;
  return false;
}

// ────────────────────────────────────────────────────────────────
//  Text sanitization
// ────────────────────────────────────────────────────────────────

/// Matches decorative end-of-ayah rosettes and rub el-hizb signs,
/// including any trailing Eastern-Arabic digit sequences.
final _rosettesAndRubPattern = RegExp(r'[\u06DD\u06DE\u08E2][\u0660-\u0669]*');

const _dottedCircle = '\u25CC';

bool _isArabicBaseCodePoint(int cp) =>
    (cp >= 0x0621 && cp <= 0x064A) ||
    cp == 0x0671 ||
    cp == 0x0672 ||
    cp == 0x0673 ||
    cp == 0x0674 ||
    (cp >= 0x066E && cp <= 0x066F);

bool _isCombiningCodePoint(int cp) =>
    cp == 0x0670 ||
    (cp >= 0x064B && cp <= 0x0652) ||
    cp == 0x06DF ||
    cp == 0x06E0 ||
    cp == 0x06E2 ||
    cp == 0x06E7 ||
    cp == 0x06E8;

/// Removes combining marks that have no adjacent Arabic base
/// letter, which would otherwise render as floating diacritics.
String _removeDanglingCombiningMarks(String text) {
  final runes = text.runes.toList();
  final kept = <int>[];
  for (var i = 0; i < runes.length; i++) {
    final cp = runes[i];
    if (!_isCombiningCodePoint(cp)) {
      kept.add(cp);
      continue;
    }
    final prev = (i > 0) ? runes[i - 1] : null;
    final next = (i + 1 < runes.length) ? runes[i + 1] : null;
    if ((prev != null && _isArabicBaseCodePoint(prev)) ||
        (next != null && _isArabicBaseCodePoint(next))) {
      kept.add(cp);
    }
  }
  return String.fromCharCodes(kept);
}

/// Removes decorative signs, dotted circles, and dangling marks.
String _sanitize(String text) {
  var result = text.replaceAll(_rosettesAndRubPattern, '');
  result = result.replaceAll(_dottedCircle, '');
  result = _removeDanglingCombiningMarks(result);
  return result;
}

// ────────────────────────────────────────────────────────────────
//  Clustering (base letter + attached marks)
// ────────────────────────────────────────────────────────────────

/// The kind of cluster: whitespace, a standalone sign, or a letter
/// with its diacritics.
enum _ClusterKind { space, letter, sign }

/// A single cluster: one base letter plus all attached diacritics
/// and signs, or a standalone space/sign.
class _Cluster {
  final _ClusterKind kind;

  /// The full rendered text for this cluster.
  final String text;

  /// The base letter (null for spaces and signs).
  final String? base;

  /// Concatenated diacritics/signs attached to [base].
  final String diacritics;

  const _Cluster.space(this.text)
      : kind = _ClusterKind.space,
        base = null,
        diacritics = '';
  const _Cluster.sign(this.text)
      : kind = _ClusterKind.sign,
        base = null,
        diacritics = '';
  const _Cluster.letter(this.base, this.diacritics)
      : kind = _ClusterKind.letter,
        text = '$base$diacritics';
}

/// Splits [text] into a list of clusters, grouping each base
/// letter with its following combining marks and spacing signs.
List<_Cluster> _clusterize(String text) {
  final runes = text.runes.toList();
  final chars = List<String>.generate(
    runes.length,
    (i) => String.fromCharCode(runes[i]),
  );
  final clusters = <_Cluster>[];

  bool isLetterLike(String ch) =>
      !_isSpaceLike(ch) && !_isCombiningMark(ch) && !_isQuranSpacingSign(ch);

  int i = 0;
  while (i < chars.length) {
    final ch = chars[i];

    // Whitespace / punctuation.
    if (_isSpaceLike(ch)) {
      clusters.add(_Cluster.space(ch));
      i++;
      continue;
    }

    // Standalone spacing sign — attach to previous letter if any.
    if (_isQuranSpacingSign(ch)) {
      if (clusters.isNotEmpty && clusters.last.kind == _ClusterKind.letter) {
        final last = clusters.removeLast();
        clusters.add(
          _Cluster.letter(last.base!, last.diacritics + ch),
        );
      } else {
        clusters.add(_Cluster.sign(ch));
      }
      i++;
      continue;
    }

    // Combining mark — try to attach backwards, then forwards.
    if (_isCombiningMark(ch)) {
      int j = clusters.length - 1;
      while (j >= 0 && clusters[j].kind != _ClusterKind.letter) {
        j--;
      }
      if (j >= 0) {
        final prev = clusters.removeAt(j);
        clusters.insert(
          j,
          _Cluster.letter(prev.base!, prev.diacritics + ch),
        );
        i++;
        continue;
      }
      // Attach forward to the next base letter if present.
      if (i + 1 < chars.length && isLetterLike(chars[i + 1])) {
        final base = chars[i + 1];
        var diacritics = ch;
        int k = i + 2;
        while (k < chars.length) {
          final d = chars[k];
          if (_isCombiningMark(d) || _isQuranSpacingSign(d)) {
            diacritics += d;
            k++;
            continue;
          }
          break;
        }
        clusters.add(_Cluster.letter(base, diacritics));
        i = k;
        continue;
      }
      i++;
      continue;
    }

    // New base letter — absorb all following marks and signs.
    final base = ch;
    var diacritics = '';
    int j = i + 1;
    while (j < chars.length) {
      final d = chars[j];
      if (_isCombiningMark(d) || _isQuranSpacingSign(d)) {
        diacritics += d;
        j++;
        continue;
      }
      break;
    }
    clusters.add(_Cluster.letter(base, diacritics));
    i = j;
  }

  return clusters;
}

/// Returns the index of the next letter cluster after [start],
/// or `null` if none exists.
int? _nextLetterIndex(List<_Cluster> clusters, int start) {
  for (int j = start + 1; j < clusters.length; j++) {
    if (clusters[j].kind == _ClusterKind.letter) return j;
  }
  return null;
}

// ────────────────────────────────────────────────────────────────
//  Optional small-high-ring overlay for U+06DF
// ────────────────────────────────────────────────────────────────

/// Renders a cluster with a manually positioned tiny ring overlay,
/// used as a fallback when the font misplaces U+06DF.
InlineSpan _buildOverlay06DF({
  required String textWithout06DF,
  required TextStyle style,
}) {
  final fs = style.fontSize ?? 24.0;
  final ringSize = fs * 0.22;
  final topLift = fs * 0.58;
  final ringColor = style.color ?? Colors.white;

  return WidgetSpan(
    alignment: PlaceholderAlignment.aboveBaseline,
    baseline: TextBaseline.alphabetic,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          textWithout06DF,
          style: style,
          textDirection: TextDirection.rtl,
        ),
        Positioned(
          right: fs * 0.10,
          top: -topLift,
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

// ────────────────────────────────────────────────────────────────
//  Public API: tajweed span builder
// ────────────────────────────────────────────────────────────────

/// Converts raw Qur'anic text into a list of colour-coded
/// [InlineSpan]s according to tajweed recitation rules.
///
/// [overlay06df]: if `true`, renders a manual overlay ring for
/// U+06DF on fonts that misplace it (off by default).
List<InlineSpan> tajweedSpans(
  BuildContext context,
  String rawText,
  TextStyle baseStyle, {
  bool overlay06df = false,
}) {
  final sanitizedText = _sanitize(rawText);
  final clusters = _clusterize(sanitizedText);
  final spans = <InlineSpan>[];

  /// Determines the tajweed colour for the cluster at [index],
  /// or `null` if the cluster should use the default colour.
  Color? colorForCluster(int index) {
    final cluster = clusters[index];
    if (cluster.kind != _ClusterKind.letter) return null;

    final baseLetter = cluster.base!;
    final diacritics = cluster.diacritics;

    // ── Qalqala: qalqala letter + sukun ───────────────────
    if (_qalqalaLetters.contains(baseLetter)) {
      bool hasSukun = diacritics.contains(_sukun);
      if (!hasSukun) {
        final next = _nextLetterIndex(clusters, index);
        hasSukun = (next == null) ||
            (() {
              for (int k = index + 1; k < next; k++) {
                if (clusters[k].kind != _ClusterKind.space) {
                  return false;
                }
              }
              return true;
            }());
      }
      if (hasSukun) return const Color(0xFFD32F2F);
    }

    // ── Ghunnah: Noon/Meem + Shadda ──────────────────────
    if ((baseLetter == _noon || baseLetter == _meem) &&
        diacritics.contains(_shadda)) {
      return const Color(0xFF2E7D32);
    }

    // ── Noon Sakin / Tanween rules ───────────────────────
    final isNoonSakin = baseLetter == _noon && diacritics.contains(_sukun);
    final hasTanween = diacritics.contains(_fathatan) ||
        diacritics.contains(_dammatan) ||
        diacritics.contains(_kasratan);

    if (isNoonSakin || hasTanween) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_idghamWithGhunnahLetters.contains(nextBase)) {
          return const Color(0xFF2E7D32); // green
        }
        if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
          return const Color(0xFF00897B); // teal
        }
        if (_ikhfaLetters.contains(nextBase)) {
          return const Color(0xFF8E24AA); // magenta
        }
        if (nextBase == _ba) {
          return const Color(0xFF1E88E5); // blue (Iqlab)
        }
      }
    }

    // ── Ikhfa Shafawi: Meem Sakin + Ba ───────────────────
    if (baseLetter == _meem && diacritics.contains(_sukun)) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null && clusters[nextIndex].base == _ba) {
        return const Color(0xFFF4511E); // orange
      }
    }

    return null;
  }

  // Build spans from clusters.
  for (int i = 0; i < clusters.length; i++) {
    final cluster = clusters[i];

    // Non-letter clusters (spaces, signs) use the base style.
    if (cluster.kind != _ClusterKind.letter) {
      spans.add(TextSpan(
        text: cluster.text,
        style: baseStyle.copyWith(
          fontFamily: 'KFGQPCQuranicFontHafsSmart',
        ),
      ));
      continue;
    }

    final color = colorForCluster(i);
    final letterStyle =
        color == null ? baseStyle : baseStyle.copyWith(color: color);

    // Optional U+06DF overlay fallback.
    if (overlay06df && cluster.diacritics.runes.any((cp) => cp == 0x06DF)) {
      final filteredDiacritics = String.fromCharCodes(
        cluster.diacritics.runes.where((cp) => cp != 0x06DF),
      );
      spans.add(_buildOverlay06DF(
        textWithout06DF: '${cluster.base!}$filteredDiacritics',
        style: letterStyle,
      ));
      continue;
    }

    spans.add(TextSpan(text: cluster.text, style: letterStyle));
  }

  return spans;
}
