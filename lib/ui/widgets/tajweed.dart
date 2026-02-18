/// Tajweed colour-coding engine for Qur'anic Arabic text.
///
/// Colours match the **Madani tajweed mushaf** scheme used by
/// quran.com (github.com/quran/tajweed):
///
/// | Rule | Colour | Hex |
/// |------|--------|-----|
/// | Ghunnah | Green | #43A047 |
/// | Ikhfa | Yellow | #EACE00 |
/// | Idgham with Ghunnah (receiving) | Green | #43A047 |
/// | Idgham (noon not pronounced) | Light Grey | #EEEEEE |
/// | Iqlab (ba) | Green | #43A047 |
/// | Iqlab (noon not pronounced) | Light Grey | #EEEEEE |
/// | Qalqalah | Light Blue | #0091EA |
/// | Meem Ikhfa (Shafawi) | Yellow | #EACE00 |
/// | Meem Idgham | Green | #43A047 |
/// | Maad Sukoon | Orange | #FB8C00 |
/// | Maad Muttasil/Munfasil | Red | #F44336 |
/// | Maad 6 Harakat | Dark Red | #B71C1C |
///
/// For Idgham and Iqlab, quran.com uses **two-part** colouring:
/// the noon sakin / tanween becomes grey ("not pronounced") while
/// the receiving letter gets the rule colour.
///
/// The public entry point is [tajweedSpans].
library;

import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────
//  Arabic character constants
// ────────────────────────────────────────────────────────────────

const _shadda = '\u0651';
const _fathatan = '\u064B';
const _dammatan = '\u064C';
const _kasratan = '\u064D';
const _fatha = '\u064E';
const _damma = '\u064F';
const _kasra = '\u0650';

const _noon = '\u0646';
const _meem = '\u0645';
const _ba = '\u0628';

/// The five Qalqala letters: Qaf, Taa, Ba, Jeem, Dal.
const _qalqalaLetters = {
  '\u0642', // ق
  '\u0637', // ط
  '\u0628', // ب
  '\u062C', // ج
  '\u062F', // د
};

/// Letters that trigger Idgham with Ghunnah: Ya, Noon, Meem, Waw.
const _idghamWithGhunnahLetters = {
  '\u064A', // ي
  '\u0646', // ن
  '\u0645', // م
  '\u0648', // و
};

/// Letters that trigger Idgham without Ghunnah: Ra, Lam.
const _idghamWithoutGhunnahLetters = {'\u0631', '\u0644'};

/// Letters that trigger Ikhfa (concealment).
const _ikhfaLetters = {
  '\u062A', '\u062B', '\u062C', '\u062F', '\u0630',
  '\u0632', '\u0633', '\u0634', '\u0635', '\u0636',
  '\u0637', '\u0638', '\u0641', '\u0642', '\u0643', //
};

/// Hamza variants that trigger Maad Muttasil/Munfasil.
const _hamzaVariants = {
  '\u0621', // ء hamza
  '\u0623', // أ alef + hamza above
  '\u0625', // إ alef + hamza below
  '\u0624', // ؤ waw + hamza
  '\u0626', // ئ ya + hamza
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
  return _isCombiningCodePoint(codePoint);
}

/// Qur'anic **spacing** signs (Waqf marks, Sajdah marks, etc.)
/// that are visible but not combining marks.
bool _isQuranSpacingSign(String ch) {
  final codePoint = ch.codeUnitAt(0);
  if (codePoint >= 0x06D6 && codePoint <= 0x06ED) {
    if (codePoint == 0x06DD || codePoint == 0x06DE) return false;
    if (_isCombiningCodePoint(codePoint)) return false;
    return true;
  }
  if (codePoint >= 0x08D3 && codePoint <= 0x08FF) return true;
  return false;
}

// ────────────────────────────────────────────────────────────────
//  Text sanitization
// ────────────────────────────────────────────────────────────────

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
    (cp >= 0x064B && cp <= 0x0653) || // includes maad marker U+0653
    cp == 0x06DF ||
    cp == 0x06E0 ||
    cp == 0x06E2 ||
    cp == 0x06E7 ||
    cp == 0x06E8;

/// Removes combining marks that have no nearby Arabic base letter.
String _removeDanglingCombiningMarks(String text) {
  final runes = text.runes.toList();
  final kept = <int>[];
  for (var i = 0; i < runes.length; i++) {
    final cp = runes[i];
    if (!_isCombiningCodePoint(cp)) {
      kept.add(cp);
      continue;
    }
    bool foundBase = false;
    for (int j = i - 1; j >= 0; j--) {
      if (_isArabicBaseCodePoint(runes[j])) {
        foundBase = true;
        break;
      }
      if (!_isCombiningCodePoint(runes[j])) break;
    }
    if (!foundBase) {
      for (int j = i + 1; j < runes.length; j++) {
        if (_isArabicBaseCodePoint(runes[j])) {
          foundBase = true;
          break;
        }
        if (!_isCombiningCodePoint(runes[j])) break;
      }
    }
    if (foundBase) kept.add(cp);
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
//  Vowel / Sakin detection
// ────────────────────────────────────────────────────────────────

/// Returns `true` if [diacritics] contains any standard Arabic
/// vowel (fatha, kasra, damma, tanween, or shadda).
bool _hasVowel(String diacritics) {
  return diacritics.contains(_fatha) ||
      diacritics.contains(_kasra) ||
      diacritics.contains(_damma) ||
      diacritics.contains(_fathatan) ||
      diacritics.contains(_kasratan) ||
      diacritics.contains(_dammatan) ||
      diacritics.contains(_shadda);
}

/// Returns `true` if [diacritics] contains an explicit sukun mark
/// (U+0652 or the alternative jazm U+06E1). This is stricter than
/// [_hasVowel] returning false: bare letters without any diacritics
/// do NOT count as having explicit sukun.
bool _hasExplicitSukun(String diacritics) {
  return diacritics.contains('\u0652') || diacritics.contains('\u06E1');
}

// ────────────────────────────────────────────────────────────────
//  Clustering (base letter + attached marks)
// ────────────────────────────────────────────────────────────────

enum _ClusterKind { space, letter, sign }

class _Cluster {
  final _ClusterKind kind;
  final String text;
  final String? base;
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

    if (_isSpaceLike(ch)) {
      clusters.add(_Cluster.space(ch));
      i++;
      continue;
    }

    if (_isQuranSpacingSign(ch)) {
      if (clusters.isNotEmpty && clusters.last.kind == _ClusterKind.letter) {
        final last = clusters.removeLast();
        clusters.add(_Cluster.letter(last.base!, last.diacritics + ch));
      } else {
        clusters.add(_Cluster.sign(ch));
      }
      i++;
      continue;
    }

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

/// Index of the next letter cluster after [start], or null.
int? _nextLetterIndex(List<_Cluster> clusters, int start) {
  for (int j = start + 1; j < clusters.length; j++) {
    if (clusters[j].kind == _ClusterKind.letter) return j;
  }
  return null;
}

/// Index of the previous letter cluster before [start], or null.
int? _prevLetterIndex(List<_Cluster> clusters, int start) {
  for (int j = start - 1; j >= 0; j--) {
    if (clusters[j].kind == _ClusterKind.letter) return j;
  }
  return null;
}

// ────────────────────────────────────────────────────────────────
//  Maad detection
// ────────────────────────────────────────────────────────────────

/// Checks if the cluster at [index] is a maad letter (alef/waw/ya
/// preceded by the corresponding vowel, with no vowel on itself).
bool _isMaadLetter(List<_Cluster> clusters, int index) {
  final cluster = clusters[index];
  if (cluster.kind != _ClusterKind.letter) return false;

  final base = cluster.base!;
  final diac = cluster.diacritics;

  // If the letter has a standard vowel, it's not maad.
  if (_hasVowel(diac)) return false;

  // Tatweel with superscript alef (ـٰ) → maad if preceded by fatha.
  if (base == '\u0640' && diac.contains('\u0670')) {
    final prevIdx = _prevLetterIndex(clusters, index);
    return prevIdx != null &&
        clusters[prevIdx].diacritics.contains(_fatha);
  }

  // Alef with madda above (آ) — inherently a maad.
  if (base == '\u0622') return true;

  final prevIdx = _prevLetterIndex(clusters, index);
  if (prevIdx == null) return false;
  final prevDiac = clusters[prevIdx].diacritics;

  // Alef (ا) preceded by fatha.
  // Note: alef-wasla (ٱ, U+0671) is NOT a maad letter — it's
  // a silent connection hamza used in word-initial "al-" prefixes.
  if (base == '\u0627' && prevDiac.contains(_fatha)) return true;
  // Waw (و) preceded by damma.
  if (base == '\u0648' && prevDiac.contains(_damma)) return true;
  // Ya (ي / ى) preceded by kasra.
  if ((base == '\u064A' || base == '\u0649') &&
      prevDiac.contains(_kasra)) {
    return true;
  }

  return false;
}

// ────────────────────────────────────────────────────────────────
//  Optional small-high-ring overlay for U+06DF
// ────────────────────────────────────────────────────────────────

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
//  Tajweed rule colours (Madani mushaf scheme from quran.com)
// ────────────────────────────────────────────────────────────────

const kQalqalaColor = Color(0xFF0091EA); // light blue
const kGhunnahColor = Color(0xFF43A047); // green
const kIdghamGhunnahColor = Color(0xFF43A047); // green (receiving letter)
const kIkhfaColor = Color(0xFFEACE00); // yellow
const kIqlabColor = Color(0xFF43A047); // green (receiving ba)
const kMeemIkhfaColor = Color(0xFFEACE00); // yellow
const kMeemIdghamColor = Color(0xFF43A047); // green
const kMaadSukoonColor = Color(0xFFFB8C00); // orange
const kMaadMunfasilColor = Color(0xFFF44336); // red
const kMaadLongColor = Color(0xFFB71C1C); // dark red

/// "Not pronounced" colour for noon/tanween in idgham & iqlab.
/// Adapts to theme brightness: near-invisible on light bg (the
/// letter is silent), light grey on dark bg (matching quran.com).
Color kNotPronouncedColor(Brightness brightness) =>
    brightness == Brightness.dark
        ? const Color(0xFFEEEEEE) // quran.com exact value
        : const Color(0xFFCCCCCC); // visible but muted on light bg

// ────────────────────────────────────────────────────────────────
//  Public API: tajweed span builder
// ────────────────────────────────────────────────────────────────

/// Converts raw Qur'anic text into a list of colour-coded
/// [InlineSpan]s according to tajweed recitation rules.
List<InlineSpan> tajweedSpans(
  BuildContext context,
  String rawText,
  TextStyle baseStyle, {
  bool overlay06df = false,
}) {
  final sanitizedText = _sanitize(rawText);
  final clusters = _clusterize(sanitizedText);
  final spans = <InlineSpan>[];

  final brightness = Theme.of(context).brightness;
  final notPronounced = kNotPronouncedColor(brightness);

  // Pre-assigned colours for clusters that are the "receiving"
  // side of a two-part rule (idgham / iqlab). Populated during
  // analysis of the noon/tanween cluster.
  final overrides = <int, Color>{};

  Color? colorForCluster(int index) {
    // Check if a prior noon/tanween rule already assigned a colour
    // to this cluster (receiving letter in idgham / iqlab).
    if (overrides.containsKey(index)) return overrides[index];

    final cluster = clusters[index];
    if (cluster.kind != _ClusterKind.letter) return null;

    final baseLetter = cluster.base!;
    final diacritics = cluster.diacritics;
    final isSakin = !_hasVowel(diacritics);

    // ── 1. Qalqala ──────────────────────────────────────
    if (_qalqalaLetters.contains(baseLetter)) {
      if (isSakin) {
        // Skip qalqala if the next letter has shadda (idgham
        // of identical letters — the qalqala letter merges).
        final next = _nextLetterIndex(clusters, index);
        if (next != null &&
            clusters[next].base == baseLetter &&
            clusters[next].diacritics.contains(_shadda)) {
          // No qalqala — letter merges into shadda.
        } else {
          return kQalqalaColor;
        }
      }
      // Voweled but at very end of text → qalqala at waqf.
      final next = _nextLetterIndex(clusters, index);
      if (next == null) return kQalqalaColor;
    }

    // ── 2. Ghunnah: Noon/Meem + Shadda ──────────────────
    if ((baseLetter == _noon || baseLetter == _meem) &&
        diacritics.contains(_shadda)) {
      return kGhunnahColor;
    }

    // ── 3. Noon Sakin / Tanween rules ───────────────────
    // Uses two-part colouring (matching quran.com Madani):
    //   • Idgham with Ghunnah → noon/tanween grey, receiving
    //     letter green.
    //   • Idgham without Ghunnah → noon/tanween grey only.
    //   • Iqlab → noon/tanween grey, ba green.
    //   • Ikhfa → noon/tanween yellow only.
    final isNoonSakin = baseLetter == _noon && isSakin;
    final hasTanween = diacritics.contains(_fathatan) ||
        diacritics.contains(_dammatan) ||
        diacritics.contains(_kasratan);

    if (isNoonSakin || hasTanween) {
      int? nextIndex = _nextLetterIndex(clusters, index);
      // Skip tanween carrier alef/alef maqsura.
      if (hasTanween && nextIndex != null) {
        final carrier = clusters[nextIndex].base!;
        if (carrier == '\u0627' || carrier == '\u0649') {
          nextIndex = _nextLetterIndex(clusters, nextIndex);
        }
      }
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_idghamWithGhunnahLetters.contains(nextBase)) {
          // Noon is not pronounced → grey; receiving letter → green.
          overrides[nextIndex] = kIdghamGhunnahColor;
          return notPronounced;
        }
        if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
          // Noon is not pronounced → grey.
          return notPronounced;
        }
        if (_ikhfaLetters.contains(nextBase)) {
          return kIkhfaColor;
        }
        if (nextBase == _ba) {
          // Iqlab: noon not pronounced → grey; ba → green.
          overrides[nextIndex] = kIqlabColor;
          return notPronounced;
        }
      }
    }

    // ── 4. Meem Sakin rules ─────────────────────────────
    if (baseLetter == _meem && isSakin) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        // Meem Ikhfa (Shafawi): meem sakin before ba.
        if (nextBase == _ba) return kMeemIkhfaColor;
        // Meem Idgham: meem sakin before meem.
        if (nextBase == _meem) return kMeemIdghamColor;
      }
    }

    // ── 5. Maad (prolongation) ──────────────────────────
    // Natural maad (2 counts, no special condition) is NOT
    // highlighted in the Madani mushaf. Only highlight when
    // followed by hamza, shadda, or sakin/end-of-ayah.
    if (_isMaadLetter(clusters, index)) {
      int? nextIndex = _nextLetterIndex(clusters, index);

      // Skip alef-wasla (ٱ, U+0671) — it's silent in
      // continuous reading and shouldn't affect maad analysis.
      if (nextIndex != null && clusters[nextIndex].base == '\u0671') {
        nextIndex = _nextLetterIndex(clusters, nextIndex);
      }

      if (nextIndex != null) {
        final nextCluster = clusters[nextIndex];
        final nextBase = nextCluster.base!;
        final nextDiac = nextCluster.diacritics;

        // Hamza after maad → Maad Muttasil/Munfasil (red).
        if (_hamzaVariants.contains(nextBase)) {
          return kMaadMunfasilColor;
        }
        // Letter with shadda → Maad 6 harakat (dark red).
        if (nextDiac.contains(_shadda)) return kMaadLongColor;
        // Next letter has explicit sukun → Maad Sukoon (orange).
        // Bare letters (no marks) do NOT trigger this — they
        // could be orthographic (e.g. assimilated lam in "ال").
        if (_hasExplicitSukun(nextDiac)) return kMaadSukoonColor;
        // Next letter is last in text → Maad Aridh lil Sukoon
        // (the reader stops, making the final letter sakin).
        final afterNext = _nextLetterIndex(clusters, nextIndex);
        if (afterNext == null) return kMaadSukoonColor;
      }
    }

    return null;
  }

  // Build spans from clusters.
  for (int i = 0; i < clusters.length; i++) {
    final cluster = clusters[i];

    if (cluster.kind != _ClusterKind.letter) {
      spans.add(TextSpan(text: cluster.text, style: baseStyle));
      continue;
    }

    final color = colorForCluster(i);
    final letterStyle =
        color == null ? baseStyle : baseStyle.copyWith(color: color);

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
