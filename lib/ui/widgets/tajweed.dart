import 'package:flutter/material.dart';

// Diacritics
const _sukun = '\u0652';
const _shadda = '\u0651';
const _fathatan = '\u064B';
const _dammatan = '\u064C';
const _kasratan = '\u064D';

// Letters
const _noon = '\u0646';
const _meem = '\u0645';
const _ba = '\u0628';

// Core sets
const _qalqala = {'\u0642', '\u0637', '\u0628', '\u062C', '\u062F'}; // ق ط ب ج د
const _idghamGhunnah = {'\u064A', '\u0646', '\u0645', '\u0648'};     // ي ن م و
const _idghamNoGhunnah = {'\u0631', '\u0644'};                       // ر ل
const _ikhfa = {
  '\u062A','\u062B','\u062C','\u062F','\u0630','\u0632','\u0633','\u0634',
  '\u0635','\u0636','\u0637','\u0638','\u0641','\u0642','\u0643'
};

bool _isTanween(String ch) => ch == _fathatan || ch == _dammatan || ch == _kasratan;
bool _isDiacritic(String ch) =>
    ch == _sukun || ch == _shadda || _isTanween(ch) ||
    (ch.codeUnitAt(0) >= 0x064B && ch.codeUnitAt(0) <= 0x0652);

bool _isSpaceLike(String ch) => ch.trim().isEmpty || RegExp(r'[،؛؟,.!:؛—\-–\(\)\[\]{}…]').hasMatch(ch);

int? _nextLetterIndex(List<String> chars, int k) {
  for (int j = k + 1; j < chars.length; j++) {
    final c = chars[j];
    if (_isDiacritic(c)) continue;
    if (_isSpaceLike(c)) continue;
    return j;
  }
  return null;
}

int? _prevLetterIndex(List<String> chars, int k) {
  for (int j = k - 1; j >= 0; j--) {
    final c = chars[j];
    if (_isDiacritic(c)) continue;
    if (_isSpaceLike(c)) continue;
    return j;
  }
  return null;
}

/// Heuristic tajwīd color engine that works well with standard Uthmani text
/// even when sukūn is not explicitly written at word end.
List<InlineSpan> tajweedSpans(BuildContext context, String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final chars = text.runes.map((r) => String.fromCharCode(r)).toList();

  Color? colorForIndex(int i) {
    final current = chars[i];

    // ---------- Qalqala ----------
    // If the letter is qalqala and:
    //  (a) followed by sukūn among the diacritics, OR
    //  (b) it is word-final (next non-diacritic is space/punct or end of line)
    if (_qalqala.contains(current)) {
      bool hasSukun = false;
      int j = i + 1;
      for (; j < chars.length && _isDiacritic(chars[j]); j++) {
        if (chars[j] == _sukun) { hasSukun = true; break; }
      }
      if (!hasSukun) {
        // infer word-final sukūn
        final nextIdx = _nextLetterIndex(chars, i);
        if (nextIdx == null) {
          // end of line => treat as sukūn
          hasSukun = true;
        } else {
          // if everything until next letter is space/punct, consider word-final
          bool onlySpaces = true;
          for (int k = i + 1; k < nextIdx; k++) {
            if (!_isDiacritic(chars[k]) && !_isSpaceLike(chars[k])) {
              onlySpaces = false; break;
            }
          }
          if (onlySpaces) hasSukun = true;
        }
      }
      if (hasSukun) return const Color(0xFFD32F2F); // red
    }

    // ---------- Ghunnah on شدة (نّ / مّ) ----------
    if ((current == _noon || current == _meem)) {
      // if a shadda appears immediately after diacritics of this letter
      for (int j = i + 1; j < chars.length && _isDiacritic(chars[j]); j++) {
        if (chars[j] == _shadda) return const Color(0xFF2E7D32); // green
      }
    }

    // ---------- Noon sākin or Tanween rules ----------
    bool isNoonSakinOrTanweenHere() {
      if (current == _noon) {
        for (int j = i + 1; j < chars.length && _isDiacritic(chars[j]); j++) {
          if (chars[j] == _sukun) return true;
        }
      }
      if (_isTanween(current)) return true;
      return false;
    }

    if (isNoonSakinOrTanweenHere()) {
      final j = _nextLetterIndex(chars, i);
      if (j != null) {
        final nxt = chars[j];
        if (_idghamGhunnah.contains(nxt)) return const Color(0xFF2E7D32); // idghām w/ ghunnah - green
        if (_idghamNoGhunnah.contains(nxt)) return const Color(0xFF00897B); // idghām no ghunnah - teal
        if (_ikhfa.contains(nxt)) return const Color(0xFF8E24AA); // ikhfaʼ - magenta
        if (nxt == _ba) return const Color(0xFF1E88E5); // iqlāb - blue
      }
    }

    // ---------- Ikhfāʼ meemī: مْ + ب ----------
    if (current == _meem) {
      bool hasSukun = false;
      for (int j = i + 1; j < chars.length && _isDiacritic(chars[j]); j++) {
        if (chars[j] == _sukun) { hasSukun = true; break; }
      }
      if (hasSukun) {
        final j = _nextLetterIndex(chars, i);
        if (j != null && chars[j] == _ba) return const Color(0xFFF4511E); // orange
      }
    }

    return null;
  }

  for (int i = 0; i < chars.length; i++) {
    final c = chars[i];
    final col = colorForIndex(i);
    spans.add(TextSpan(text: c, style: col == null ? base : base.copyWith(color: col)));
  }
  return spans;
}
