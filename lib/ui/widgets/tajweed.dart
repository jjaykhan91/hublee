import 'package:flutter/material.dart';

/// Keeps Qur’anic marks (e.g., ۟ U+06DF), strips decorative rings (۝/۞),
/// removes dotted-circle placeholders, clusters base+marks, and applies tajwīd
/// coloring. You can optionally render a tiny overlay ring for U+06DF on fonts
/// that misplace it (set `overlay06df: true`), but it’s OFF by default.

/// --- Basic marks/letters used in rules ---
const _sukun = '\u0652';
const _shadda = '\u0651';
const _fathatan = '\u064B';
const _dammatan = '\u064C';
const _kasratan = '\u064D';

const _noon = '\u0646';
const _meem = '\u0645';
const _ba   = '\u0628';

const _qalqala = {'\u0642', '\u0637', '\u0628', '\u062C', '\u062F'};
const _idghamGhunnah   = {'\u064A', '\u0646', '\u0645', '\u0648'};
const _idghamNoGhunnah = {'\u0631', '\u0644'};
const _ikhfa = {
  '\u062A','\u062B','\u062C','\u062F','\u0630','\u0632','\u0633','\u0634',
  '\u0635','\u0636','\u0637','\u0638','\u0641','\u0642','\u0643'
};

bool _isSpaceLike(String ch) =>
    ch.trim().isEmpty || RegExp(r'[،؛؟,.!:؛—\-–\(\)\[\]{}…]').hasMatch(ch);

bool _isCombiningMark(String ch) {
  final cp = ch.codeUnitAt(0);
  if (cp == 0x0670 || (cp >= 0x064B && cp <= 0x0652)) return true;
  if (cp == 0x06DF || cp == 0x06E0 || cp == 0x06E2 || cp == 0x06E7 || cp == 0x06E8) return true;
  return false;
}

/// Qur’anic **spacing** signs (kept visible), excluding rosettes/rub and the
/// small-high marks handled above as combining.
bool _isQuranSpacingSign(String ch) {
  final cp = ch.codeUnitAt(0);
  if (cp >= 0x06D6 && cp <= 0x06ED) {
    if (cp == 0x06DD /* ۝ */ || cp == 0x06DE /* ۞ */) return false;
    if (cp == 0x06DF || cp == 0x06E0 || cp == 0x06E2 || cp == 0x06E7 || cp == 0x06E8) return false;
    return true;
  }
  if (cp >= 0x08D3 && cp <= 0x08FF) return true;
  return false;
}

/// --- Sanitizer: remove decorative rings, dotted-circles, and dangling marks ---
final _stripRosettesOrRub = RegExp(r'[\u06DD\u06DE\u08E2][\u0660-\u0669]*'); // ۝, ۞, U+08E2 in some datasets
const _dottedCircle = '\u25CC';

bool _isArabicBaseCp(int cp) =>
    (cp >= 0x0621 && cp <= 0x064A) ||
    cp == 0x0671 || cp == 0x0672 || cp == 0x0673 || cp == 0x0674 ||
    (cp >= 0x066E && cp <= 0x066F);

bool _isCombiningCp(int cp) =>
    cp == 0x0670 || (cp >= 0x064B && cp <= 0x0652) ||
    cp == 0x06DF || cp == 0x06E0 || cp == 0x06E2 || cp == 0x06E7 || cp == 0x06E8;

/// Drop combining marks that have no Arabic base neighbor
String _removeDanglingCombiningMarks(String s) {
  final runes = s.runes.toList();
  final kept = <int>[];
  for (var i = 0; i < runes.length; i++) {
    final cp = runes[i];
    if (!_isCombiningCp(cp)) { kept.add(cp); continue; }
    final prev = (i > 0) ? runes[i - 1] : null;
    final next = (i + 1 < runes.length) ? runes[i + 1] : null;
    if ((prev != null && _isArabicBaseCp(prev)) || (next != null && _isArabicBaseCp(next))) {
      kept.add(cp);
    }
  }
  return String.fromCharCodes(kept);
}

String _sanitize(String s) {
  var out = s.replaceAll(_stripRosettesOrRub, '');
  out = out.replaceAll(_dottedCircle, '');
  out = _removeDanglingCombiningMarks(out);
  return out;
}

/// --- Clustering (also fixes mark-before-base by attaching forward) ---
enum _Kind { space, letter, sign }

class _Cluster {
  final _Kind kind;
  final String text;     // rendered chunk
  final String? base;    // for letters
  final String diacs;    // attached diacritics/signs
  const _Cluster.space(this.text)
      : kind = _Kind.space, base = null, diacs = '';
  const _Cluster.sign(this.text)
      : kind = _Kind.sign, base = null, diacs = '';
  const _Cluster.letter(this.base, this.diacs)
      : kind = _Kind.letter, text = '$base$diacs';
}

List<_Cluster> _clusterize(String s) {
  final runes = s.runes.toList();
  final chars = List<String>.generate(runes.length, (i) => String.fromCharCode(runes[i]));
  final out = <_Cluster>[];

  bool isLetterLike(String ch) =>
      !_isSpaceLike(ch) && !_isCombiningMark(ch) && !_isQuranSpacingSign(ch);

  int i = 0;
  while (i < chars.length) {
    final c = chars[i];

    if (_isSpaceLike(c)) { out.add(_Cluster.space(c)); i++; continue; }

    if (_isQuranSpacingSign(c)) {
      if (out.isNotEmpty && out.last.kind == _Kind.letter) {
        final last = out.removeLast();
        out.add(_Cluster.letter(last.base!, last.diacs + c));
      } else {
        out.add(_Cluster.sign(c));
      }
      i++; continue;
    }

    if (_isCombiningMark(c)) {
      // attach back to previous letter if any
      int j = out.length - 1;
      while (j >= 0 && out[j].kind != _Kind.letter) {
        j--;
      }
      if (j >= 0) {
        final prev = out.removeAt(j);
        out.insert(j, _Cluster.letter(prev.base!, prev.diacs + c));
        i++; continue;
      }
      // attach forward to next letter if present (handles mark-before-base)
      if (i + 1 < chars.length && isLetterLike(chars[i + 1])) {
        final base = chars[i + 1];
        var diacs = c;
        int k = i + 2;
        while (k < chars.length) {
          final d = chars[k];
          if (_isCombiningMark(d) || _isQuranSpacingSign(d)) { diacs += d; k++; continue; }
          break;
        }
        out.add(_Cluster.letter(base, diacs));
        i = k; continue;
      }
      i++; continue;
    }

    // new letter → absorb following marks/signs
    final base = c;
    var diacs = '';
    int j = i + 1;
    while (j < chars.length) {
      final d = chars[j];
      if (_isCombiningMark(d) || _isQuranSpacingSign(d)) { diacs += d; j++; continue; }
      break;
    }
    out.add(_Cluster.letter(base, diacs));
    i = j;
  }
  return out;
}

int? _nextLetterIndex(List<_Cluster> cs, int k) {
  for (int j = k + 1; j < cs.length; j++) {
    if (cs[j].kind == _Kind.letter) return j;
  }
  return null;
}

/// --- Optional small overlay (fallback) for U+06DF ---
InlineSpan _overlay06DF({
  required String textWithout06DF, // base + other diacs
  required TextStyle style,
}) {
  final fs = (style.fontSize ?? 24.0);
  final ringSize = fs * 0.22;
  final topLift  = fs * 0.58;
  final ringColor = style.color ?? Colors.white;

  return WidgetSpan(
    alignment: PlaceholderAlignment.aboveBaseline,
    baseline: TextBaseline.alphabetic,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Text(textWithout06DF, style: style, textDirection: TextDirection.rtl),
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

/// --- Tajwīd coloring over clusters (overlay OFF by default) ---
List<InlineSpan> tajweedSpans(
  BuildContext context,
  String raw,
  TextStyle base, {
  bool overlay06df = false,
}) {
  final text  = _sanitize(raw);
  final cls   = _clusterize(text);
  final spans = <InlineSpan>[];

  Color? colorFor(int i) {
    final cl = cls[i];
    if (cl.kind != _Kind.letter) return null;
    final current = cl.base!;
    final diacs   = cl.diacs;

    // Qalqala: qalqala letter + sukun (explicit or inferred at word-end)
    if (_qalqala.contains(current)) {
      bool hasSukun = diacs.contains(_sukun);
      if (!hasSukun) {
        final j = _nextLetterIndex(cls, i);
        hasSukun = (j == null) || (() {
          for (int k = i + 1; k < j; k++) { if (cls[k].kind != _Kind.space) return false; }
          return true;
        }());
      }
      if (hasSukun) return const Color(0xFFD32F2F); // red
    }

    // Ghunnah on shadda (نّ / مّ)
    if ((current == _noon || current == _meem) && diacs.contains(_shadda)) {
      return const Color(0xFF2E7D32); // green
    }

    // Noon sakin or Tanwīn rules
    final isNoonSakin = current == _noon && diacs.contains(_sukun);
    final hasTanween  = diacs.contains(_fathatan) || diacs.contains(_dammatan) || diacs.contains(_kasratan);
    if (isNoonSakin || hasTanween) {
      final j = _nextLetterIndex(cls, i);
      if (j != null) {
        final nb = cls[j].base!;
        if (_idghamGhunnah.contains(nb))   return const Color(0xFF2E7D32); // green
        if (_idghamNoGhunnah.contains(nb)) return const Color(0xFF00897B); // teal
        if (_ikhfa.contains(nb))           return const Color(0xFF8E24AA); // magenta
        if (nb == _ba)                     return const Color(0xFF1E88E5); // blue (iqlāb)
      }
    }

    // Ikhfāʼ meemī: مْ + ب
    if (current == _meem && diacs.contains(_sukun)) {
      final j = _nextLetterIndex(cls, i);
      if (j != null && cls[j].base == _ba) return const Color(0xFFF4511E); // orange
    }

    return null;
  }

  for (int i = 0; i < cls.length; i++) {
    final cl = cls[i];


    // Always use the correct font for all clusters, including combining marks and signs
    if (cl.kind != _Kind.letter) {
      spans.add(TextSpan(text: cl.text, style: base.copyWith(fontFamily: 'KFGQPCQuranicFontHafsSmart'))); // spaces & signs
      continue;
    }

    final col = colorFor(i);
    final styleForLetter = (col == null) ? base : base.copyWith(color: col);

    if (overlay06df && cl.diacs.runes.any((cp) => cp == 0x06DF)) {
      final filteredDiacs = String.fromCharCodes(
        cl.diacs.runes.where((cp) => cp != 0x06DF),
      );
      final clusterWithout06df = '${cl.base!}$filteredDiacs';

      spans.add(_overlay06DF(
        textWithout06DF: clusterWithout06df,
        style: styleForLetter,
      ));
      continue;
    }

    spans.add(TextSpan(text: cl.text, style: styleForLetter));
  }

  return spans;
}
