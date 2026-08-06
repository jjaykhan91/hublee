// Quick test to verify tajweed cluster analysis on standard Uthmanic text.
// Run: dart run tools/test_tajweed.dart

// ignore_for_file: avoid_print

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

bool _isArabicBaseCodePoint(int cp) =>
    (cp >= 0x0621 && cp <= 0x064A) ||
    cp == 0x0671 ||
    cp == 0x0672 ||
    cp == 0x0673 ||
    cp == 0x0674 ||
    (cp >= 0x066E && cp <= 0x066F);

bool _isCombiningCodePoint(int cp) =>
    cp == 0x0670 ||
    (cp >= 0x064B && cp <= 0x0653) || // includes U+0653 maddah
    cp == 0x06DF ||
    cp == 0x06E0 ||
    cp == 0x06E2 ||
    cp == 0x06E7 ||
    cp == 0x06E8;

bool _isCombiningMark(String ch) => _isCombiningCodePoint(ch.codeUnitAt(0));

bool _isQuranSpacingSign(String ch) {
  final cp = ch.codeUnitAt(0);
  if (cp >= 0x06D6 && cp <= 0x06ED) {
    if (cp == 0x06DD || cp == 0x06DE) return false;
    if (_isCombiningCodePoint(cp)) return false;
    return true;
  }
  if (cp >= 0x08D3 && cp <= 0x08FF) return true;
  return false;
}

bool _hasVowel(String diacritics) {
  return diacritics.contains(_fatha) ||
      diacritics.contains(_kasra) ||
      diacritics.contains(_damma) ||
      diacritics.contains(_fathatan) ||
      diacritics.contains(_kasratan) ||
      diacritics.contains(_dammatan) ||
      diacritics.contains(_shadda);
}

final _rosettesAndRubPattern = RegExp(r'[\u06DD\u06DE\u08E2][\u0660-\u0669]*');
const _dottedCircle = '\u25CC';

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

String sanitize(String text) {
  var result = text.replaceAll(_rosettesAndRubPattern, '');
  result = result.replaceAll(_dottedCircle, '');
  result = _removeDanglingCombiningMarks(result);
  return result;
}

enum ClusterKind { space, letter, sign }

class Cluster {
  final ClusterKind kind;
  final String text;
  final String? base;
  final String diacritics;
  Cluster.space(this.text)
    : kind = ClusterKind.space,
      base = null,
      diacritics = '';
  Cluster.sign(this.text)
    : kind = ClusterKind.sign,
      base = null,
      diacritics = '';
  Cluster.letter(this.base, this.diacritics)
    : kind = ClusterKind.letter,
      text = '$base$diacritics';
}

List<Cluster> clusterize(String text) {
  final runes = text.runes.toList();
  final chars = List<String>.generate(
    runes.length,
    (i) => String.fromCharCode(runes[i]),
  );
  final clusters = <Cluster>[];
  bool isLetterLike(String ch) =>
      !_isSpaceLike(ch) && !_isCombiningMark(ch) && !_isQuranSpacingSign(ch);

  int i = 0;
  while (i < chars.length) {
    final ch = chars[i];
    if (_isSpaceLike(ch)) {
      clusters.add(Cluster.space(ch));
      i++;
      continue;
    }
    if (_isQuranSpacingSign(ch)) {
      if (clusters.isNotEmpty && clusters.last.kind == ClusterKind.letter) {
        final last = clusters.removeLast();
        clusters.add(Cluster.letter(last.base!, last.diacritics + ch));
      } else {
        clusters.add(Cluster.sign(ch));
      }
      i++;
      continue;
    }
    if (_isCombiningMark(ch)) {
      int j = clusters.length - 1;
      while (j >= 0 && clusters[j].kind != ClusterKind.letter) {
        j--;
      }
      if (j >= 0) {
        final prev = clusters.removeAt(j);
        clusters.insert(j, Cluster.letter(prev.base!, prev.diacritics + ch));
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
        clusters.add(Cluster.letter(base, diacritics));
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
    clusters.add(Cluster.letter(base, diacritics));
    i = j;
  }
  return clusters;
}

int? nextLetterIndex(List<Cluster> clusters, int start) {
  for (int j = start + 1; j < clusters.length; j++) {
    if (clusters[j].kind == ClusterKind.letter) return j;
  }
  return null;
}

String? colorForCluster(List<Cluster> clusters, int index) {
  final cluster = clusters[index];
  if (cluster.kind != ClusterKind.letter) return null;

  final baseLetter = cluster.base!;
  final diacritics = cluster.diacritics;
  final isSakin = !_hasVowel(diacritics);

  // Qalqala
  if (_qalqalaLetters.contains(baseLetter)) {
    if (isSakin) return 'RED(Qalqala)';
    final next = nextLetterIndex(clusters, index);
    if (next == null) return 'RED(Qalqala-waqf)';
  }

  // Ghunnah
  if ((baseLetter == _noon || baseLetter == _meem) &&
      diacritics.contains(_shadda)) {
    return 'GREEN(Ghunnah)';
  }

  // Noon Sakin / Tanween
  final isNoonSakin = baseLetter == _noon && isSakin;
  final hasTanween =
      diacritics.contains(_fathatan) ||
      diacritics.contains(_dammatan) ||
      diacritics.contains(_kasratan);

  if (isNoonSakin || hasTanween) {
    int? nextIndex = nextLetterIndex(clusters, index);
    if (hasTanween && nextIndex != null) {
      final carrier = clusters[nextIndex].base!;
      if (carrier == '\u0627' || carrier == '\u0649') {
        nextIndex = nextLetterIndex(clusters, nextIndex);
      }
    }
    if (nextIndex != null) {
      final nextBase = clusters[nextIndex].base!;
      if (_idghamWithGhunnahLetters.contains(nextBase)) {
        return 'GREEN(Idgham+Ghunnah)';
      }
      if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
        return 'TEAL(Idgham-noGhunnah)';
      }
      if (_ikhfaLetters.contains(nextBase)) return 'MAGENTA(Ikhfa)';
      if (nextBase == _ba) return 'BLUE(Iqlab)';
    }
  }

  // Ikhfa Shafawi
  if (baseLetter == _meem && isSakin) {
    final nextIndex = nextLetterIndex(clusters, index);
    if (nextIndex != null && clusters[nextIndex].base == _ba) {
      return 'ORANGE(IkhfaShafawi)';
    }
  }

  // Maddah letters (U+0653)
  if (diacritics.contains('\u0653')) {
    final nextIndex = nextLetterIndex(clusters, index);
    if (nextIndex != null) {
      final nextBase = clusters[nextIndex].base!;
      if ({
        '\u0621',
        '\u0623',
        '\u0625',
        '\u0624',
        '\u0626',
      }.contains(nextBase)) {
        return 'RED(MaadMunfasil)'; // maddah before hamza
      }
    }
    return 'DARK_RED(MaddLazim)'; // e.g. لٓ مٓ in الٓمٓ
  }

  return null;
}

void testText(String label, String text, Map<String, String> expected) {
  print('\n=== $label ===');
  final sanitized = sanitize(text);
  final clusters = clusterize(sanitized);

  final results = <String, String>{};
  for (int i = 0; i < clusters.length; i++) {
    final c = clusters[i];
    final color = colorForCluster(clusters, i);
    if (c.kind == ClusterKind.letter) {
      final baseCP = c.base!
          .codeUnitAt(0)
          .toRadixString(16)
          .toUpperCase()
          .padLeft(4, '0');
      final diacCP = c.diacritics.runes
          .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
          .join(' ');
      final colorStr = color ?? 'none';
      print('  [$i] U+$baseCP "${c.base}" diac=[$diacCP] => $colorStr');
      if (color != null) results['$i:${c.base}'] = color;
    }
  }

  // Verify expectations
  bool allPassed = true;
  for (final entry in expected.entries) {
    if (results[entry.key] == entry.value) {
      print('  PASS: ${entry.key} => ${entry.value}');
    } else {
      print(
        '  FAIL: ${entry.key} expected ${entry.value} but got ${results[entry.key] ?? "none"}',
      );
      allPassed = false;
    }
  }
  if (allPassed) {
    print('  All tests PASSED');
  }
}

void main() {
  // Test 1: Qalqala with explicit sukun (Dal)
  testText('Qalqala: لَمْ يَلِدْ', 'لَمْ يَلِدْ وَلَمْ يُولَدْ', {
    '5:د': 'RED(Qalqala)', // dal+sukun in يَلِدْ
    '14:د': 'RED(Qalqala)', // dal+sukun in يُولَدْ
  });

  // Test 2: Qalqala should NOT trigger on voweled letters
  testText(
    'No false Qalqala: قُلْ هُوَ ٱللَّهُ أَحَدٌ',
    'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
    {
      '13:د': 'RED(Qalqala-waqf)', // dal with dammatan at END of ayah (waqf)
    },
  );

  // Test 3: Ghunnah (noon + shadda)
  testText('Ghunnah: إِنَّ ٱللَّهَ', 'إِنَّ ٱللَّهَ', {
    '1:ن': 'GREEN(Ghunnah)', // noon+shadda
  });

  // Test 4: Ghunnah (meem + shadda)
  testText('Ghunnah: وَمِمَّا', 'وَمِمَّا رَزَقْنَـٰهُمْ يُنفِقُونَ', {
    '2:م': 'GREEN(Ghunnah)', // meem+shadda
    '7:ق': 'RED(Qalqala)', // qaf+sukun
  });

  // Test 5: Ikhfa (noon sakin before ta)
  testText('Ikhfa: مِن تَحْتِهَا', 'مِن تَحْتِهَا', {
    '1:ن': 'MAGENTA(Ikhfa)', // bare noon before ta
  });

  // Test 6: Ikhfa (bare noon before fa)
  testText('Ikhfa: يُنفِقُونَ', 'يُنفِقُونَ', {
    '1:ن': 'MAGENTA(Ikhfa)', // bare noon before fa
  });

  // Test 7: Iqlab (noon with small high meem before ba)
  testText('Iqlab: مِنۢ بَعْدِ', 'مِنۢ بَعْدِ', {
    '1:ن': 'BLUE(Iqlab)', // noon+U+06E2 before ba
  });

  // Test 8: Ikhfa Shafawi (meem sakin before ba)
  testText('Ikhfa Shafawi: هُمْ بِمَا', 'هُمْ بِمَا', {
    '1:م': 'ORANGE(IkhfaShafawi)', // meem+sukun before ba
  });

  // Test 9: Idgham with Ghunnah (tanween before meem/noon/waw/ya)
  testText('Idgham: هُدًى لِّلْمُتَّقِينَ', 'هُدًى لِّلْمُتَّقِينَ', {
    '1:د':
        'TEAL(Idgham-noGhunnah)', // dal+fathatan before lam (Idgham without ghunnah)
  });

  // Test 11: Madd Lazim - muqatta'at الٓمٓ (Baqarah 2:1)
  testText('Madd Lazim: الٓمٓ (2:1)', ' الٓمٓ', {
    '2:ل': 'DARK_RED(MaddLazim)', // lam with maddah (cluster 2)
    '3:م': 'DARK_RED(MaddLazim)', // meem with maddah (cluster 3)
  });

  // Test 12: Maddah before hamza → Maad Munfasil (red)
  testText('Maad Munfasil: بِمَآ أُنزِلَ', 'بِمَآ أُنزِلَ', {
    '2:ا': 'RED(MaadMunfasil)', // alef+maddah (cluster 2) before hamza أ
  });

  // Test 10: Al-Fatiha 1:7 comprehensive
  testText(
    'Al-Fatiha 1:7',
    'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
    {},
  ); // Just observe, no specific expectations

  print('\n\n========== SUMMARY ==========');
  print('Tests complete. Review output above for PASS/FAIL.');
}
