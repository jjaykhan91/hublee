// Audit tajweed for Baqarah 2:1–2:5.
// Run: dart run tools/audit_baqarah_2_5.dart
//
// Uses the test_tajweed logic to output colored clusters. Compare with
// Quran.com to verify.

import 'dart:convert';
import 'dart:io';

// Copy of minimal clustering + coloring from test_tajweed
const _sukun = '\u0652';
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
const _qalqalaLetters = {'\u0642', '\u0637', '\u0628', '\u062C', '\u062F'};
const _idghamWithGhunnahLetters = {'\u064A', '\u0646', '\u0645', '\u0648'};
const _idghamWithoutGhunnahLetters = {'\u0631', '\u0644'};
const _ikhfaLetters = {
  '\u062A',
  '\u062B',
  '\u062C',
  '\u062F',
  '\u0630',
  '\u0632',
  '\u0633',
  '\u0634',
  '\u0635',
  '\u0636',
  '\u0637',
  '\u0638',
  '\u0641',
  '\u0642',
  '\u0643',
};

bool _isSpaceLike(String ch) =>
    ch.trim().isEmpty || RegExp(r'[،؛؟,.!:؛—\-–\(\)\[\]{}…]').hasMatch(ch);
bool _isCombiningCodePoint(int cp) =>
    cp == 0x0670 ||
    (cp >= 0x064B && cp <= 0x0653) ||
    cp == 0x06DF ||
    cp == 0x06E0 ||
    cp == 0x06E2 ||
    cp == 0x06E7 ||
    cp == 0x06E8;
bool _isCombiningMark(String ch) => _isCombiningCodePoint(ch.codeUnitAt(0));
bool _hasVowel(String d) =>
    d.contains(_fatha) ||
    d.contains(_kasra) ||
    d.contains(_damma) ||
    d.contains(_fathatan) ||
    d.contains(_kasratan) ||
    d.contains(_dammatan) ||
    d.contains(_shadda);

class Cluster {
  final String base;
  final String diacritics;
  Cluster(this.base, this.diacritics);
  String get text => '$base$diacritics';
}

List<Cluster> clusterize(String text) {
  final chars = text.runes.map((r) => String.fromCharCode(r)).toList();
  final clusters = <Cluster>[];
  int i = 0;
  while (i < chars.length) {
    final ch = chars[i];
    if (_isSpaceLike(ch)) {
      clusters.add(Cluster(ch, ''));
      i++;
      continue;
    }
    if (_isCombiningMark(ch)) {
      int j = clusters.length - 1;
      while (j >= 0 && clusters[j].base.length > 1) {
        j--;
      }
      if (j >= 0 && clusters[j].base.length == 1) {
        clusters[j] = Cluster(clusters[j].base, clusters[j].diacritics + ch);
        i++;
      } else if (i + 1 < chars.length) {
        final base = chars[i + 1];
        var diac = ch;
        int k = i + 2;
        while (k < chars.length && _isCombiningMark(chars[k])) {
          diac += chars[k];
          k++;
        }
        clusters.add(Cluster(base, diac));
        i = k;
      } else {
        i++;
      }
      continue;
    }
    var diac = '';
    int j = i + 1;
    while (j < chars.length && _isCombiningMark(chars[j])) {
      diac += chars[j];
      j++;
    }
    clusters.add(Cluster(ch, diac));
    i = j;
  }
  return clusters;
}

int? nextLetterIndex(List<Cluster> clusters, int start) {
  for (int j = start + 1; j < clusters.length; j++) {
    if (clusters[j].base.length == 1 && !_isSpaceLike(clusters[j].base)) {
      return j;
    }
  }
  return null;
}

String? colorFor(List<Cluster> clusters, int idx) {
  final c = clusters[idx];
  if (c.base.length != 1 || _isSpaceLike(c.base)) return null;
  final base = c.base;
  final d = c.diacritics;
  final isSakin = !_hasVowel(d);

  if (_qalqalaLetters.contains(base)) {
    if (isSakin) return 'Qalqala';
    if (nextLetterIndex(clusters, idx) == null) return 'Qalqala-waqf';
  }
  if ((base == _noon || base == _meem) && d.contains(_shadda)) return 'Ghunnah';
  final isNoonSakin = base == _noon && isSakin;
  final hasTanween =
      d.contains(_fathatan) || d.contains(_dammatan) || d.contains(_kasratan);
  if (isNoonSakin || hasTanween) {
    int? ni = nextLetterIndex(clusters, idx);
    if (hasTanween && ni != null) {
      if (clusters[ni].base == '\u0627' || clusters[ni].base == '\u0649') {
        ni = nextLetterIndex(clusters, ni);
      }
    }
    if (ni != null) {
      final nb = clusters[ni].base;
      if (_idghamWithGhunnahLetters.contains(nb)) return 'Idgham+Gh';
      if (_idghamWithoutGhunnahLetters.contains(nb)) return 'Idgham';
      if (_ikhfaLetters.contains(nb)) return 'Ikhfa';
      if (nb == _ba) return 'Iqlab';
    }
  }
  if (base == _meem && isSakin) {
    final ni = nextLetterIndex(clusters, idx);
    if (ni != null && clusters[ni].base == _ba) return 'IkhfaShafawi';
    if (ni != null && clusters[ni].base == _meem) return 'MeemIdgham';
  }
  // Maddah (U+0653): if followed by hamza → Maad Munfasil, else Madd Lazim
  if (d.contains('\u0653')) {
    final ni = nextLetterIndex(clusters, idx);
    if (ni != null) {
      final nb = clusters[ni].base;
      if ({'\u0621', '\u0623', '\u0625', '\u0624', '\u0626'}.contains(nb))
        return 'MaadMunfasil';
    }
    return 'MaddLazim';
  }

  // Maad letter detection (alef/waw/ya preceded by matching vowel)
  bool isMaad = false;
  if (!_hasVowel(d)) {
    int? pi;
    for (int j = idx - 1; j >= 0; j--) {
      if (clusters[j].base.length == 1 && !_isSpaceLike(clusters[j].base)) { pi = j; break; }
    }
    if (pi != null) {
      final pd = clusters[pi].diacritics;
      if (base == '\u0627' && pd.contains(_fatha)) isMaad = true;
      if (base == '\u0648' && pd.contains(_damma)) isMaad = true;
      if ((base == '\u064A' || base == '\u0649') && pd.contains(_kasra)) isMaad = true;
    }
    if (base == '\u0622') isMaad = true;
    if (base == '\u0640' && d.contains('\u0670')) {
      if (pi != null && clusters[pi].diacritics.contains(_fatha)) isMaad = true;
    }
  }
  if (isMaad) {
    final ni = nextLetterIndex(clusters, idx);
    if (ni != null) {
      final nb = clusters[ni].base;
      final nd = clusters[ni].diacritics;
      if ({'\u0621', '\u0623', '\u0625', '\u0624', '\u0626'}.contains(nb))
        return 'MaadMunfasil';
      if (nd.contains(_shadda)) return 'Maad6';
      if (nd.contains(_sukun)) return 'MaadSukoon';
      if (nextLetterIndex(clusters, ni) == null) return 'MaadSukoon';
    }
  }

  return null;
}

void main() async {
  final ar = jsonDecode(await File('assets/quran/ar/2.json').readAsString())
      as Map<String, dynamic>;
  for (var i = 1; i <= 5; i++) {
    final text = (ar['$i'] as String?) ?? '';
    final clusters = clusterize(text);
    print('\n=== 2:$i ===');
    print('Text: $text');
    int li = 0;
    for (var j = 0; j < clusters.length; j++) {
      final c = clusters[j];
      if (c.base.length == 1 && !_isSpaceLike(c.base)) {
        final col = colorFor(clusters, j);
        final mark = col != null ? ' [$col]' : '';
        print('  [$li] ${c.text}$mark');
        li++;
      }
    }
  }
}
