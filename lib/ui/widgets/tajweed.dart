/// Tajweed colour-coding engine for Qur'anic Arabic text.
///
/// Colours match the **Madani tajweed mushaf** scheme used by
/// quran.com (github.com/quran/tajweed). Verified against
/// quran.com's `uthmani_tajweed` API for Surah Al-Baqarah 2:1-5.
///
/// | Rule | Colour | Hex |
/// |------|--------|-----|
/// | Ghunnah | Green | #43A047 |
/// | Ikhfa (noon + receiving letter) | Green | #43A047 |
/// | Idgham with Ghunnah (receiving) | Green | #43A047 |
/// | Idgham / silent letter | Grey | #9E9E9E |
/// | Iqlab (ba) | Green | #43A047 |
/// | Qalqalah | Cyan | #00BCD4 |
/// | Meem Ikhfa (Shafawi) | Green | #43A047 |
/// | Meem Idgham | Green | #43A047 |
/// | Normal Madd (2) | Pink | #E91E8C |
/// | Maad Aridh / Sukoon | Orange | #FB8C00 |
/// | Maad Connected (before hamza) | Dark Pink | #D81B60 |
/// | Maad 6 Harakat / Madd Lazim | Red | #F44336 |
/// | Tafkhim (heavy) | Dark Blue | #1565C0 |
/// | Hamza Wasl (silent) | Grey | #9E9E9E |
/// | Lam Shamsiyah (silent) | Grey | #9E9E9E |
/// | Silent letters | Grey | #9E9E9E |
///
/// For Idgham and Iqlab, quran.com uses **two-part** colouring:
/// the noon sakin / tanween + carrier becomes grey ("not pronounced")
/// while the receiving letter gets the rule colour.
///
/// For Ikhfa, quran.com colours BOTH the noon/tanween AND the
/// following letter in green.
///
/// For Idgham without Ghunnah, quran.com colours the noon/tanween,
/// the carrier, AND the receiving letter all grey.
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

/// U+0653 ARABIC MADDAH ABOVE — used in muqatta'at (e.g. الٓمٓ) for
/// Madd Lazim Harfi — letters prolonged 6 harakat.
const _maddahAbove = '\u0653';

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

/// Hamza variants that trigger Connected Maad.
const _hamzaVariants = {
  '\u0621', // ء hamza
  '\u0623', // أ alef + hamza above
  '\u0625', // إ alef + hamza below
  '\u0624', // ؤ waw + hamza
  '\u0626', // ئ ya + hamza
};

/// Sun letters: lam in ال assimilates before these (laam_shamsiyah).
const _sunLetters = {
  '\u062A', // ت
  '\u062B', // ث
  '\u062F', // د
  '\u0630', // ذ
  '\u0631', // ر
  '\u0632', // ز
  '\u0633', // س
  '\u0634', // ش
  '\u0635', // ص
  '\u0636', // ض
  '\u0637', // ط
  '\u0638', // ظ
  '\u0644', // ل
  '\u0646', // ن
};

/// Heavy letters (tafkhim): always thick articulation. ص ض ط ظ ق غ خ.
/// Qaaf and Taa (ط) are also qalqala when sakin — we apply tafkhim when
/// they have a vowel. Raa (ر) is heavy with fatha/damma, light (tarqeeq) with kasra.
const _tafkhimHeavyLetters = {
  '\u0635', // ص
  '\u0636', // ض
  '\u0637', // ط
  '\u0638', // ظ
  '\u0642', // ق
  '\u063A', // غ
  '\u062E', // خ
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
//  Tajweed rule colours (Madani mushaf scheme from quran.com)
// ────────────────────────────────────────────────────────────────

const kQalqalaColor = Color(0xFF00BCD4); // cyan
const kGhunnahColor = Color(0xFF43A047); // green
const kIdghamGhunnahColor = Color(0xFF43A047); // green (receiving letter)
const kIkhfaColor = Color(0xFF43A047); // green (matches quran.com ghunna/ikhfa)
const kIqlabColor = Color(0xFF43A047); // green (receiving ba)
const kMeemIkhfaColor = Color(0xFF43A047); // green (matches ghunna/ikhfa grouping)
const kMeemIdghamColor = Color(0xFF43A047); // green
const kNormalMaadColor = Color(0xFFE91E8C); // pink (Normal madd 2 counts)
const kMaadSukoonColor = Color(0xFFFB8C00); // orange (Separated / Aridh)
const kMaadConnectedColor = Color(0xFFD81B60); // dark pink (Connected madd 4/5 — before hamza)
const kMaadLongColor = Color(0xFFF44336); // red (Necessary madd 6 — Madd Lazim)

/// Tafkhim (heavy/thick articulation) — dark blue. Applied to Qaaf with vowel,
/// Raa with fatha/damma, and the seven heavy letters (ص ض ط ظ ق غ خ).
const kTafkhimColor = Color(0xFF1565C0); // dark blue

/// "Not pronounced" colour for noon/tanween in idgham & iqlab.
/// Clearly muted compared to surrounding text so the silent letter
/// is visually distinct, matching quran.com's dark-theme rendering.
Color kNotPronouncedColor(Brightness brightness) =>
    brightness == Brightness.dark
        ? const Color(0xFF9E9E9E) // clearly muted grey on dark bg
        : const Color(0xFFBDBDBD); // muted grey on light bg

// ────────────────────────────────────────────────────────────────
//  Public API: tajweed span builder
// ────────────────────────────────────────────────────────────────

/// Converts raw Qur'anic text into a list of colour-coded
/// [InlineSpan]s according to tajweed recitation rules.
List<InlineSpan> tajweedSpans(
  BuildContext context,
  String rawText,
  TextStyle baseStyle,
) {
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
    // Check if a prior rule already assigned a colour to this cluster
    // (receiving letter in idgham / iqlab / ikhfa).
    if (overrides.containsKey(index)) return overrides[index];

    final cluster = clusters[index];
    if (cluster.kind != _ClusterKind.letter) return null;

    final baseLetter = cluster.base!;
    final diacritics = cluster.diacritics;
    final isSakin = !_hasVowel(diacritics);

    // ── 0a. Hamza Wasl (ٱ) — silent in connected speech ─
    // quran.com class: ham_wasl. At the start of an ayah the
    // hamza wasl IS pronounced, so only mark non-initial ones.
    if (baseLetter == '\u0671' && index > 0) {
      final prevLetter = _prevLetterIndex(clusters, index);
      if (prevLetter != null) return notPronounced;
    }

    // ── 0b. Lam Shamsiyah — assimilated lam in ال ────────
    // quran.com class: laam_shamsiyah. The lam in definite
    // article ال is silent when followed by a sun letter.
    if (baseLetter == '\u0644' && isSakin) {
      final prevIdx = _prevLetterIndex(clusters, index);
      final nextIdx = _nextLetterIndex(clusters, index);
      if (prevIdx != null &&
          nextIdx != null &&
          clusters[prevIdx].base == '\u0671' &&
          _sunLetters.contains(clusters[nextIdx].base) &&
          clusters[nextIdx].diacritics.contains(_shadda)) {
        return notPronounced;
      }
    }

    // ── 0c. Silent letters (U+06DF marker) ─────────────
    // quran.com class: slnt. In Uthmanic script, U+06DF
    // (ARABIC SMALL HIGH ROUNDED ZERO) marks letters that
    // are written but not pronounced — e.g. waw in أُو۟لَـٰٓئِكَ
    // and alef in ٱعْبُدُوا۟.
    if (diacritics.contains('\u06DF')) {
      return notPronounced;
    }

    // ── 0d. Silent Waw — orthographic waw not pronounced ─
    // quran.com class: slnt. In Uthmanic script, words like
    // الصلوة have a waw that is written but not pronounced.
    // Detected as: waw + superscript alef (U+0670) where the
    // preceding letter has fatha (not damma).
    if (baseLetter == '\u0648' &&
        diacritics.contains('\u0670') &&
        !_hasVowel(diacritics.replaceAll('\u0670', ''))) {
      final prevIdx = _prevLetterIndex(clusters, index);
      if (prevIdx != null &&
          clusters[prevIdx].diacritics.contains(_fatha) &&
          !clusters[prevIdx].diacritics.contains(_damma)) {
        return notPronounced;
      }
    }

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

    // ── 1b. Tafkhim (heavy letters) ─────────────────────
    // Qaaf (ق) with vowel, Raa (ر) with fatha/damma, and the seven
    // heavy letters (ص ض ط ظ ق غ خ) when they have a vowel (ط/ق sakin
    // are already handled by Qalqala above).
    if (baseLetter == '\u0642' && _hasVowel(diacritics)) return kTafkhimColor;
    if (baseLetter == '\u0631' &&
        (diacritics.contains(_fatha) || diacritics.contains(_damma))) {
      return kTafkhimColor;
    }
    if (_tafkhimHeavyLetters.contains(baseLetter)) {
      // ص ض ظ غ خ: always heavy. ط with vowel (sakin = qalqala already).
      if (baseLetter != '\u0637' || _hasVowel(diacritics)) {
        return kTafkhimColor;
      }
    }

    // ── 2. Ghunnah: Noon/Meem + Shadda ──────────────────
    if ((baseLetter == _noon || baseLetter == _meem) &&
        diacritics.contains(_shadda)) {
      return kGhunnahColor;
    }

    // ── 3. Noon Sakin / Tanween rules ───────────────────
    // Matching quran.com's two-part colouring:
    //   • Idgham with Ghunnah → noon/tanween+carrier grey,
    //     receiving letter green.
    //   • Idgham without Ghunnah → noon/tanween+carrier+
    //     receiving letter ALL grey.
    //   • Iqlab → noon/tanween+carrier grey, ba green.
    //   • Ikhfa → noon green, receiving letter green.
    final isNoonSakin = baseLetter == _noon && isSakin;
    final hasTanween = diacritics.contains(_fathatan) ||
        diacritics.contains(_dammatan) ||
        diacritics.contains(_kasratan);

    if (isNoonSakin || hasTanween) {
      int? nextIndex = _nextLetterIndex(clusters, index);
      // Skip and grey-out the tanween carrier alef/alef-maqsura.
      int? carrierIndex;
      if (hasTanween && nextIndex != null) {
        final carrier = clusters[nextIndex].base!;
        if (carrier == '\u0627' || carrier == '\u0649') {
          carrierIndex = nextIndex;
          nextIndex = _nextLetterIndex(clusters, nextIndex);
        }
      }
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_idghamWithGhunnahLetters.contains(nextBase)) {
          overrides[nextIndex] = kIdghamGhunnahColor;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
        if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
          // quran.com marks noon+carrier+receiving letter ALL grey.
          overrides[nextIndex] = notPronounced;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
        if (_ikhfaLetters.contains(nextBase)) {
          // quran.com colours both noon AND the next letter green.
          overrides[nextIndex] = kIkhfaColor;
          return kIkhfaColor;
        }
        if (nextBase == _ba) {
          overrides[nextIndex] = kIqlabColor;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
      }
    }

    // ── 4. Meem Sakin rules ─────────────────────────────
    if (baseLetter == _meem && isSakin) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (nextBase == _ba) return kMeemIkhfaColor;
        if (nextBase == _meem) return kMeemIdghamColor;
      }
    }

    // ── 5. Maddah letters (U+0653) ───────────────────────
    if (diacritics.contains(_maddahAbove)) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_hamzaVariants.contains(nextBase)) {
          return kMaadConnectedColor;
        }
      }
      return kMaadLongColor;
    }

    // ── 6. Maad (prolongation) ──────────────────────────
    if (_isMaadLetter(clusters, index)) {
      // 6a. Normal Madd (2 counts) — check first so ـٰ and لَا get pink.
      if (baseLetter == '\u0640' && diacritics.contains('\u0670')) {
        return kNormalMaadColor;
      }
      final prevIdx = _prevLetterIndex(clusters, index);
      if (baseLetter == '\u0627' &&
          prevIdx != null &&
          clusters[prevIdx].base == '\u0644' &&
          clusters[prevIdx].diacritics.contains(_fatha)) {
        return kNormalMaadColor; // لَا
      }

      int? nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null && clusters[nextIndex].base == '\u0671') {
        nextIndex = _nextLetterIndex(clusters, nextIndex);
      }

      if (nextIndex != null) {
        final nextCluster = clusters[nextIndex];
        final nextBase = nextCluster.base!;
        final nextDiac = nextCluster.diacritics;

        if (_hamzaVariants.contains(nextBase)) {
          return kMaadConnectedColor;
        }
        if (nextDiac.contains(_shadda)) return kMaadLongColor;
        if (_hasExplicitSukun(nextDiac)) return kMaadSukoonColor;
        final afterNext = _nextLetterIndex(clusters, nextIndex);
        if (afterNext == null) return kMaadSukoonColor;
        return kMaadSukoonColor; // permissible: next has vowel
      }
      return kMaadSukoonColor; // end of phrase
    }

    return null;
  }

  // Build spans from clusters. Every cluster becomes a TextSpan so
  // that the paragraph-level text shaper can join Arabic letters
  // across span boundaries. WidgetSpans are never used because they
  // break Arabic cursive joining.
  for (int i = 0; i < clusters.length; i++) {
    final cluster = clusters[i];

    if (cluster.kind != _ClusterKind.letter) {
      spans.add(TextSpan(text: cluster.text, style: baseStyle));
      continue;
    }

    final color = colorForCluster(i);
    final letterStyle =
        color == null ? baseStyle : baseStyle.copyWith(color: color);

    spans.add(TextSpan(text: cluster.text, style: letterStyle));
  }

  return spans;
}

// ────────────────────────────────────────────────────────────────
//  Testing API
// ────────────────────────────────────────────────────────────────

/// Per-cluster tajweed result for testing. Contains the cluster
/// text, base letter, and assigned colour (null = default).
class TajweedClusterResult {
  final String text;
  final String? base;
  final Color? color;
  final bool isLetter;

  const TajweedClusterResult({
    required this.text,
    required this.base,
    required this.color,
    required this.isLetter,
  });

  @override
  String toString() => 'TajweedClusterResult('
      'text: "$text", base: ${base == null ? "null" : '"$base"'}, '
      'color: $color, isLetter: $isLetter)';
}

/// Returns per-cluster colour assignments for the given Qur'anic
/// text. This exposes the internal tajweed logic without requiring
/// a [BuildContext], for use in automated tests.
///
/// [brightness] controls the "not pronounced" grey shade.
List<TajweedClusterResult> tajweedColorAssignments(
  String rawText, {
  Brightness brightness = Brightness.dark,
}) {
  final sanitizedText = _sanitize(rawText);
  final clusters = _clusterize(sanitizedText);
  final notPronounced = kNotPronouncedColor(brightness);
  final overrides = <int, Color>{};
  final results = <TajweedClusterResult>[];

  Color? colorForCluster(int index) {
    if (overrides.containsKey(index)) return overrides[index];

    final cluster = clusters[index];
    if (cluster.kind != _ClusterKind.letter) return null;

    final baseLetter = cluster.base!;
    final diacritics = cluster.diacritics;
    final isSakin = !_hasVowel(diacritics);

    if (baseLetter == '\u0671' && index > 0) {
      final prevLetter = _prevLetterIndex(clusters, index);
      if (prevLetter != null) return notPronounced;
    }

    if (baseLetter == '\u0644' && isSakin) {
      final prevIdx = _prevLetterIndex(clusters, index);
      final nextIdx = _nextLetterIndex(clusters, index);
      if (prevIdx != null &&
          nextIdx != null &&
          clusters[prevIdx].base == '\u0671' &&
          _sunLetters.contains(clusters[nextIdx].base) &&
          clusters[nextIdx].diacritics.contains(_shadda)) {
        return notPronounced;
      }
    }

    if (diacritics.contains('\u06DF')) {
      return notPronounced;
    }

    if (baseLetter == '\u0648' &&
        diacritics.contains('\u0670') &&
        !_hasVowel(diacritics.replaceAll('\u0670', ''))) {
      final prevIdx = _prevLetterIndex(clusters, index);
      if (prevIdx != null &&
          clusters[prevIdx].diacritics.contains(_fatha) &&
          !clusters[prevIdx].diacritics.contains(_damma)) {
        return notPronounced;
      }
    }

    if (_qalqalaLetters.contains(baseLetter)) {
      if (isSakin) {
        final next = _nextLetterIndex(clusters, index);
        if (next != null &&
            clusters[next].base == baseLetter &&
            clusters[next].diacritics.contains(_shadda)) {
          // merges
        } else {
          return kQalqalaColor;
        }
      }
      final next = _nextLetterIndex(clusters, index);
      if (next == null) return kQalqalaColor;
    }

    // Tafkhim (heavy letters)
    if (baseLetter == '\u0642' && _hasVowel(diacritics)) return kTafkhimColor;
    if (baseLetter == '\u0631' &&
        (diacritics.contains(_fatha) || diacritics.contains(_damma))) {
      return kTafkhimColor;
    }
    if (_tafkhimHeavyLetters.contains(baseLetter)) {
      if (baseLetter != '\u0637' || _hasVowel(diacritics)) {
        return kTafkhimColor;
      }
    }

    if ((baseLetter == _noon || baseLetter == _meem) &&
        diacritics.contains(_shadda)) {
      return kGhunnahColor;
    }

    final isNoonSakin = baseLetter == _noon && isSakin;
    final hasTanween = diacritics.contains(_fathatan) ||
        diacritics.contains(_dammatan) ||
        diacritics.contains(_kasratan);

    if (isNoonSakin || hasTanween) {
      int? nextIndex = _nextLetterIndex(clusters, index);
      int? carrierIndex;
      if (hasTanween && nextIndex != null) {
        final carrier = clusters[nextIndex].base!;
        if (carrier == '\u0627' || carrier == '\u0649') {
          carrierIndex = nextIndex;
          nextIndex = _nextLetterIndex(clusters, nextIndex);
        }
      }
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_idghamWithGhunnahLetters.contains(nextBase)) {
          overrides[nextIndex] = kIdghamGhunnahColor;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
        if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
          overrides[nextIndex] = notPronounced;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
        if (_ikhfaLetters.contains(nextBase)) {
          overrides[nextIndex] = kIkhfaColor;
          return kIkhfaColor;
        }
        if (nextBase == _ba) {
          overrides[nextIndex] = kIqlabColor;
          if (carrierIndex != null) overrides[carrierIndex] = notPronounced;
          return notPronounced;
        }
      }
    }

    if (baseLetter == _meem && isSakin) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (nextBase == _ba) return kMeemIkhfaColor;
        if (nextBase == _meem) return kMeemIdghamColor;
      }
    }

    if (diacritics.contains(_maddahAbove)) {
      final nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null) {
        final nextBase = clusters[nextIndex].base!;
        if (_hamzaVariants.contains(nextBase)) return kMaadConnectedColor;
      }
      return kMaadLongColor;
    }

    if (_isMaadLetter(clusters, index)) {
      if (baseLetter == '\u0640' && diacritics.contains('\u0670')) {
        return kNormalMaadColor;
      }
      final prevIdx = _prevLetterIndex(clusters, index);
      if (baseLetter == '\u0627' &&
          prevIdx != null &&
          clusters[prevIdx].base == '\u0644' &&
          clusters[prevIdx].diacritics.contains(_fatha)) {
        return kNormalMaadColor; // لَا
      }
      int? nextIndex = _nextLetterIndex(clusters, index);
      if (nextIndex != null && clusters[nextIndex].base == '\u0671') {
        nextIndex = _nextLetterIndex(clusters, nextIndex);
      }
      if (nextIndex != null) {
        final nextCluster = clusters[nextIndex];
        final nextBase = nextCluster.base!;
        final nextDiac = nextCluster.diacritics;
        if (_hamzaVariants.contains(nextBase)) return kMaadConnectedColor;
        if (nextDiac.contains(_shadda)) return kMaadLongColor;
        if (_hasExplicitSukun(nextDiac)) return kMaadSukoonColor;
        final afterNext = _nextLetterIndex(clusters, nextIndex);
        if (afterNext == null) return kMaadSukoonColor;
        return kMaadSukoonColor; // permissible: next has vowel
      }
      return kMaadSukoonColor; // end of phrase
    }

    return null;
  }

  for (int i = 0; i < clusters.length; i++) {
    final cluster = clusters[i];
    final isLetter = cluster.kind == _ClusterKind.letter;
    results.add(TajweedClusterResult(
      text: cluster.text,
      base: cluster.base,
      color: isLetter ? colorForCluster(i) : null,
      isLetter: isLetter,
    ));
  }

  return results;
}
