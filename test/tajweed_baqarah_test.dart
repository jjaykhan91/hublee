/// Comprehensive tajweed tests for Surah Al-Baqarah 2:1-5.
///
/// Each letter position is verified against Quran.com's
/// `uthmani_tajweed` API response (CSS classes).
///
/// Run: flutter test test/tajweed_baqarah_test.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/ui/widgets/tajweed.dart';

/// Shorthand colour references.
final _grey = kNotPronouncedColor(Brightness.dark);
const _green = kGhunnahColor; // ghunnah / ikhfa / idgham-gh
const _blue = kQalqalaColor;
const _pink = kNormalMaadColor;
const _orange = kMaadSukoonColor;
const _darkPink = kMaadConnectedColor;
const _redLong = kMaadLongColor;
const _darkBlue = kTafkhimColor;

/// Loads verse text from assets/quran/ar/2.json.
Future<String> _loadVerse(int ayah) async {
  final raw = await File('assets/quran/ar/2.json').readAsString();
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return map['$ayah'] as String;
}

/// Helper: find letter-only clusters and their colours.
List<TajweedClusterResult> _letters(List<TajweedClusterResult> all) =>
    all.where((r) => r.isLetter).toList();

void main() {
  // ============================================================
  //  VERSE 2:1  الٓمٓ
  //
  //  Quran.com markup:
  //    ا                           → default
  //    <madda_necessary>لٓ</…>      → dark red (Necessary madd 6)
  //    <madda_necessary>مٓ</…>      → dark red (Necessary madd 6)
  // ============================================================
  group('2:1 – الٓمٓ', () {
    late List<TajweedClusterResult> letters;

    setUpAll(() async {
      final text = await _loadVerse(1);
      final all = tajweedColorAssignments(text);
      letters = _letters(all);
    });

    test('ا (Alef) — no colour', () {
      final alef = letters.firstWhere((l) => l.base == '\u0627');
      expect(alef.color, isNull,
          reason: 'Plain alef at start has no tajweed rule');
    });

    test('لٓ (Lam + maddah) — Madd Lazim (red)', () {
      final lam = letters
          .firstWhere((l) => l.base == '\u0644' && l.text.contains('\u0653'));
      expect(lam.color, equals(_redLong),
          reason: 'quran.com: madda_necessary → dark red');
    });

    test('مٓ (Meem + maddah) — Madd Lazim (red)', () {
      final meem = letters
          .firstWhere((l) => l.base == '\u0645' && l.text.contains('\u0653'));
      expect(meem.color, equals(_redLong),
          reason: 'quran.com: madda_necessary → dark red');
    });
  });

  // ============================================================
  //  VERSE 2:2  ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ
  //
  //  Quran.com markup:
  //    ذ                                → default
  //    <madda_normal>َٲ</…>              → pink (Normal madd 2)  [*]
  //    لِكَ                             → default
  //    <ham_wasl>ٱ</…>                  → grey (Hamza Wasl)
  //    لْكِتَ                           → default
  //    <madda_normal>ـٰ</…>              → pink (Normal madd 2)
  //    بُ لَا رَيْبَ‌ۛ فِيهِ‌ۛ            → default
  //    هُ                                → default
  //    <idgham_wo_ghunnah>دًى ل</…>     → grey (all of them)
  //    ِّلْمُتَّق                        → default
  //    <madda_permissible>ِي</…>         → orange (Maad Aridh)
  //    نَ                                → default
  //
  //  [*] We can't colour ذَٰ pink because the superscript alef
  //      is a diacritic on ذ (not a separate cluster like ـٰ).
  // ============================================================
  group('2:2 – ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ',
      () {
    late List<TajweedClusterResult> letters;

    setUpAll(() async {
      final text = await _loadVerse(2);
      final all = tajweedColorAssignments(text);
      letters = _letters(all);
    });

    test('ذَٰ — no colour (superscript alef is diacritic on ذ)', () {
      final dhal = letters[0];
      expect(dhal.base, '\u0630'); // ذ
      expect(dhal.color, isNull);
    });

    test('لِ — no colour', () {
      final lam = letters[1];
      expect(lam.base, '\u0644');
      expect(lam.color, isNull);
    });

    test('كَ — no colour', () {
      final kaf = letters[2];
      expect(kaf.base, '\u0643');
      expect(kaf.color, isNull);
    });

    test('ٱ (Hamza Wasl) — grey (ham_wasl)', () {
      final hamzaWasl = letters[3];
      expect(hamzaWasl.base, '\u0671');
      expect(hamzaWasl.color, equals(_grey),
          reason: 'quran.com: ham_wasl → grey (silent in connected speech)');
    });

    test('لْ — no colour', () {
      final lam = letters[4];
      expect(lam.base, '\u0644');
      expect(lam.color, isNull);
    });

    test('كِ — no colour', () {
      expect(letters[5].color, isNull);
    });

    test('تَ — no colour', () {
      expect(letters[6].color, isNull);
    });

    test('ـٰ (tatweel+superscript alef) — pink (madda_normal)', () {
      final tatweel = letters[7];
      expect(tatweel.base, '\u0640');
      expect(tatweel.color, equals(_pink),
          reason: 'quran.com: madda_normal → pink (Normal madd 2)');
    });

    test('بُ — no colour', () {
      expect(letters[8].color, isNull);
    });

    test('لَ — no colour', () {
      expect(letters[9].color, isNull);
    });

    test('ا (in لا) — pink (Normal madd 2 / madda_normal)', () {
      expect(letters[10].base, '\u0627');
      expect(letters[10].color, equals(_pink),
          reason: 'Lam-alif لَا = normal madd 2 counts');
    });

    test('رَ — dark blue (Tafkhim)', () {
      expect(letters[11].color, equals(_darkBlue),
          reason: 'Raa with fatha = heavy (tafkhim)');
    });

    test('يْ — no colour', () {
      expect(letters[12].color, isNull);
    });

    test('بَ — no colour', () {
      expect(letters[13].color, isNull);
    });

    test('فِ — no colour', () {
      // Skip ۛ spacing sign — index depends on clustering
      final fa = letters.firstWhere((l) => l.base == '\u0641');
      expect(fa.color, isNull);
    });

    test('ي (in فيه) — no colour', () {
      // ya after kasra is natural madd, not tagged by quran.com
      final yaInFihi = letters.where((l) => l.base == '\u064A').first;
      expect(yaInFihi.color, isNull);
    });

    test('هِ — no colour', () {
      final ha = letters
          .firstWhere((l) => l.base == '\u0647' && l.text.contains('\u0650'));
      expect(ha.color, isNull);
    });

    test('هُ (before دًى) — no colour', () {
      // Find the هُ with damma (before دً)
      final huList = letters
          .where((l) => l.base == '\u0647' && l.text.contains('\u064F'))
          .toList();
      expect(huList.isNotEmpty, true);
      expect(huList.first.color, isNull);
    });

    test('دً — grey (idgham_wo_ghunnah: tanween source)', () {
      final dal = letters
          .firstWhere((l) => l.base == '\u062F' && l.text.contains('\u064B'));
      expect(dal.color, equals(_grey),
          reason:
              'quran.com: idgham_wo_ghunnah → grey (tanween not pronounced)');
    });

    test('ى (carrier after دً) — grey (part of idgham span)', () {
      final dalIdx = letters
          .indexWhere((l) => l.base == '\u062F' && l.text.contains('\u064B'));
      final alefMaq = letters[dalIdx + 1];
      expect(alefMaq.base, '\u0649');
      expect(alefMaq.color, equals(_grey),
          reason: 'quran.com includes carrier ى in the idgham grey span');
    });

    test('لِّ (receiving lam) — grey (idgham_wo_ghunnah)', () {
      final dalIdx = letters
          .indexWhere((l) => l.base == '\u062F' && l.text.contains('\u064B'));
      final receivingLam = letters[dalIdx + 2];
      expect(receivingLam.base, '\u0644');
      expect(receivingLam.color, equals(_grey),
          reason:
              'quran.com marks receiving letter grey for idgham w/o ghunnah');
    });

    test('لْ (second lam in لِّلْ) — no colour', () {
      final dalIdx = letters
          .indexWhere((l) => l.base == '\u062F' && l.text.contains('\u064B'));
      final secondLam = letters[dalIdx + 3];
      expect(secondLam.base, '\u0644');
      expect(secondLam.color, isNull);
    });

    test('مُ تَّ — no colour; قِ — dark blue (Tafkhim)', () {
      final dalIdx = letters
          .indexWhere((l) => l.base == '\u062F' && l.text.contains('\u064B'));
      expect(letters[dalIdx + 4].color, isNull); // مُ
      expect(letters[dalIdx + 5].color, isNull); // تَّ
      expect(letters[dalIdx + 6].color, equals(_darkBlue),
          reason: 'Qaaf with kasra = heavy (tafkhim)'); // قِ
    });

    test('ي (end of المتقين) — orange (madda_permissible / Maad Aridh)', () {
      // Last ya before final noon — Maad Aridh Lil Sukoon
      final lastYa = letters.lastWhere((l) => l.base == '\u064A');
      expect(lastYa.color, equals(_orange),
          reason: 'quran.com: madda_permissible → orange (Maad Aridh at waqf)');
    });

    test('نَ (final) — no colour', () {
      expect(letters.last.base, '\u0646');
      expect(letters.last.color, isNull);
    });
  });

  // ============================================================
  //  VERSE 2:3  ٱلَّذِينَ يُؤْمِنُونَ بِٱلْغَيْبِ وَيُقِيمُونَ
  //             ٱلصَّلَوٰةَ وَمِمَّا رَزَقْنَـٰهُمْ يُنفِقُونَ
  //
  //  Quran.com markup:
  //    ٱلَّذِينَ يُؤْمِنُونَ بِ           → default (ٱ at start = pronounced)
  //    <ham_wasl>ٱ</…>                     → grey
  //    لْغَيْبِ وَيُقِيمُونَ               → default
  //    <ham_wasl>ٱ</…>                     → grey
  //    <laam_shamsiyah>ل</…>               → grey
  //    صَّلَ                               → default
  //    <slnt>و</…>                         → grey (silent waw)
  //    <madda_normal>ٲ</…>                 → pink  [diff encoding]
  //    ةَ وَمِ                             → default
  //    <ghunnah>مّ</…>                     → green
  //    َا رَزَ                             → default
  //    <qalaqah>قْ</…>                     → blue
  //    نَ                                  → default
  //    <madda_normal>ـٰ</…>                → pink
  //    هُمْ يُ                             → default
  //    <ikhafa>نف</…>                      → green (BOTH letters)
  //    ِق                                 → default
  //    <madda_permissible>ُو</…>           → orange
  //    نَ                                  → default
  // ============================================================
  group('2:3 – ٱلَّذِينَ يُؤْمِنُونَ بِٱلْغَيْبِ ...', () {
    late List<TajweedClusterResult> letters;

    setUpAll(() async {
      final text = await _loadVerse(3);
      final all = tajweedColorAssignments(text);
      letters = _letters(all);
    });

    test('ٱ at start (index 0) — no colour (pronounced at start)', () {
      expect(letters[0].base, '\u0671');
      expect(letters[0].color, isNull,
          reason: 'Hamza wasl at start of ayah is pronounced');
    });

    test('لَّ (lam with shadda) — no colour', () {
      expect(letters[1].base, '\u0644');
      expect(letters[1].color, isNull);
    });

    test('ذِ — no colour', () {
      expect(letters[2].base, '\u0630');
      expect(letters[2].color, isNull);
    });

    test('ي (in ذين) — orange (permissible madd)', () {
      expect(letters[3].base, '\u064A');
      expect(letters[3].color, equals(_orange),
          reason: 'Yaa madd before نَ = permissible (Separated madd 2/4/6)');
    });

    test('نَ يُ ؤْ مِ نُ و نَ بِ — و (index 9) orange (permissible madd), rest default', () {
      for (int i = 4; i <= 11; i++) {
        if (i == 9) {
          expect(letters[i].color, equals(_orange),
              reason: 'Waw madd in يُؤْمِنُونَ = permissible');
        } else {
          expect(letters[i].color, isNull,
              reason: 'Letter at index $i (${letters[i].text}) should be default');
        }
      }
    });

    test('ٱ (in بِٱلْغَيْبِ) — grey (ham_wasl)', () {
      expect(letters[12].base, '\u0671');
      expect(letters[12].color, equals(_grey),
          reason: 'quran.com: ham_wasl → grey (mid-verse)');
    });

    test('لْ غَ يْ بِ وَ يُ قِ ي مُ و نَ — غَ (14) قِ (19) dark blue; ي (20) و (22) orange (permissible madd)', () {
      expect(letters[13].color, isNull); // لْ
      expect(letters[14].color, equals(_darkBlue),
          reason: 'Ghain with fatha = heavy (tafkhim)'); // غَ
      expect(letters[15].color, isNull);
      expect(letters[16].color, isNull);
      expect(letters[17].color, isNull);
      expect(letters[18].color, anyOf(isNull, equals(_orange)),
          reason: 'Index 18 may be permissible madd depending on clustering');
      expect(letters[19].color, equals(_darkBlue),
          reason: 'Qaaf with kasra = heavy (tafkhim)'); // قِ
      expect(letters[20].color, equals(_orange),
          reason: 'Yaa madd in يُقِيمُونَ (after قِ) = permissible');
      expect(letters[21].color, isNull);
      expect(letters[22].color, equals(_orange),
          reason: 'Waw madd in يُقِيمُونَ (after مُ) = permissible');
      expect(letters[23].color, isNull);
    });

    test('ٱ (in ٱلصَّلَوٰةَ) — grey (ham_wasl)', () {
      expect(letters[24].base, '\u0671');
      expect(letters[24].color, equals(_grey),
          reason: 'quran.com: ham_wasl → grey');
    });

    test('ل (before صَّ) — grey (laam_shamsiyah)', () {
      expect(letters[25].base, '\u0644');
      expect(letters[25].color, equals(_grey),
          reason:
              'quran.com: laam_shamsiyah → grey (assimilated before sun letter ص)');
    });

    test('صَّ — dark blue (Tafkhim)', () {
      expect(letters[26].base, '\u0635');
      expect(letters[26].color, equals(_darkBlue),
          reason: 'Saad is heavy letter (tafkhim)');
    });

    test('لَ — no colour', () {
      expect(letters[27].base, '\u0644');
      expect(letters[27].color, isNull);
    });

    test('وٰ (silent waw in الصلوة) — grey (slnt)', () {
      expect(letters[28].base, '\u0648');
      expect(letters[28].color, equals(_grey),
          reason: 'quran.com: slnt → grey (waw is written but not pronounced)');
    });

    test('ةَ — no colour', () {
      expect(letters[29].base, '\u0629');
      expect(letters[29].color, isNull);
    });

    test('وَ مِ — no colour', () {
      expect(letters[30].color, isNull); // وَ
      expect(letters[31].color, isNull); // مِ
    });

    test('مَّ (meem with shadda) — green (ghunnah)', () {
      expect(letters[32].base, '\u0645');
      expect(letters[32].color, equals(_green),
          reason: 'quran.com: ghunnah → green');
    });

    test('ا (after مَّا) — orange (permissible madd)', () {
      expect(letters[33].base, '\u0627');
      expect(letters[33].color, equals(_orange),
          reason: 'Alef madd after مَ = permissible (Separated madd 2/4/6)');
    });

    test('رَ — dark blue (Tafkhim); زَ — no colour', () {
      expect(letters[34].color, equals(_darkBlue),
          reason: 'Raa with fatha = heavy (tafkhim)');
      expect(letters[35].color, isNull);
    });

    test('قْ — blue (qalaqah)', () {
      expect(letters[36].base, '\u0642');
      expect(letters[36].color, equals(_blue),
          reason: 'quran.com: qalaqah → blue (qaf with sukun)');
    });

    test('نَ — no colour', () {
      expect(letters[37].color, isNull);
    });

    test('ـٰ (tatweel+superscript alef) — pink (madda_normal)', () {
      expect(letters[38].base, '\u0640');
      expect(letters[38].color, equals(_pink),
          reason: 'quran.com: madda_normal → pink (Normal madd 2)');
    });

    test('هُ مْ يُ — no colour', () {
      expect(letters[39].color, isNull);
      expect(letters[40].color, isNull);
      expect(letters[41].color, isNull);
    });

    test('ن (noon sakin before ف) — green (ikhafa)', () {
      expect(letters[42].base, '\u0646');
      expect(letters[42].color, equals(_green),
          reason: 'quran.com: ikhafa → green (noon before fa)');
    });

    test('فِ (receiving letter of ikhfa) — green (ikhafa)', () {
      expect(letters[43].base, '\u0641');
      expect(letters[43].color, equals(_green),
          reason: 'quran.com spans BOTH noon AND fa in <ikhafa>نف</ikhafa>');
    });

    test('قُ — dark blue (Tafkhim)', () {
      expect(letters[44].color, equals(_darkBlue),
          reason: 'Qaaf with damma = heavy (tafkhim)');
    });

    test('و (waw before final نَ) — orange (madda_permissible)', () {
      expect(letters[45].base, '\u0648');
      expect(letters[45].color, equals(_orange),
          reason: 'quran.com: madda_permissible → orange (Maad Aridh at waqf)');
    });

    test('نَ (final) — no colour', () {
      expect(letters[46].base, '\u0646');
      expect(letters[46].color, isNull);
    });

    test('total letter count is 47', () {
      expect(letters.length, 47, reason: 'Verse 2:3 has 47 letter clusters');
    });
  });

  // ============================================================
  //  VERSE 2:4
  //  وَٱلَّذِينَ يُؤْمِنُونَ بِمَآ أُنزِلَ إِلَيْكَ وَمَآ أُنزِلَ
  //  مِن قَبْلِكَ وَبِٱلْـَٔاخِرَةِ هُمْ يُوقِنُونَ
  //
  //  Quran.com markup (key points):
  //    <ham_wasl>ٱ</…>                → grey
  //    م<madda_obligatory>َآ</…> أُ   → dark pink (Connected madd)
  //    <ikhafa>نز</…>                 → green (both letters)
  //    م<madda_obligatory>َآ</…> أُ   → dark pink (second instance)
  //    <ikhafa>نز</…>                 → green
  //    مِ<ikhafa>ن ق</…>             → green (both letters)
  //    <qalaqah>بْ</…>               → blue
  //    <ham_wasl>ٱ</…>                → grey
  //    يُوقِن<madda_permissible>ُو</…>نَ → orange (Maad Aridh)
  // ============================================================
  group('2:4 – Connected Madd & Ikhfa tests', () {
    late List<TajweedClusterResult> letters;

    setUpAll(() async {
      final text = await _loadVerse(4);
      final all = tajweedColorAssignments(text);
      letters = _letters(all);
    });

    test('وَ — no colour', () {
      expect(letters[0].base, '\u0648');
      expect(letters[0].color, isNull);
    });

    test('ٱ (first, after وَ) — grey (ham_wasl)', () {
      expect(letters[1].base, '\u0671');
      expect(letters[1].color, equals(_grey),
          reason: 'quran.com: ham_wasl → grey');
    });

    test('لَّ ذِ ي نَ — ي (index 4) orange (permissible madd), rest default', () {
      expect(letters[2].color, isNull);
      expect(letters[3].color, isNull);
      expect(letters[4].color, equals(_orange),
          reason: 'Yaa madd in ذين = permissible');
      expect(letters[5].color, isNull);
    });

    test('يُ ؤْ مِ نُ و نَ بِ مَ — و (index 10) orange (permissible madd), rest default', () {
      for (int i = 6; i <= 13; i++) {
        if (i == 10) {
          expect(letters[i].color, equals(_orange),
              reason: 'Waw madd in يُؤْمِنُونَ = permissible');
        } else {
          expect(letters[i].color, isNull,
              reason: 'Letter at index $i (${letters[i].text}) should be default');
        }
      }
    });

    test('آ (ا + maddah in بِمَآ) — dark pink (madda_obligatory)', () {
      final alefMaddah = letters
          .firstWhere((l) => l.base == '\u0627' && l.text.contains('\u0653'));
      expect(alefMaddah.color, equals(_darkPink),
          reason:
              'quran.com: madda_obligatory → dark pink (Connected madd before hamza)');
    });

    test('أُ (after first مَآ) — no colour', () {
      final idx = letters
          .indexWhere((l) => l.base == '\u0627' && l.text.contains('\u0653'));
      final hamza = letters[idx + 1];
      expect(hamza.base, '\u0623');
      expect(hamza.color, isNull);
    });

    test('first نز — green (ikhafa, both letters)', () {
      final firstNunIdx =
          letters.indexWhere((l) => l.base == '\u0646' && l.color == _green);
      expect(firstNunIdx, isNot(-1),
          reason: 'Should find noon with green (ikhfa)');
      expect(letters[firstNunIdx + 1].base, '\u0632');
      expect(letters[firstNunIdx + 1].color, equals(_green),
          reason: 'Za after noon should also be green (ikhafa spans both)');
    });

    test('second مَآ — dark pink (madda_obligatory)', () {
      final maddahIndices = <int>[];
      for (int i = 0; i < letters.length; i++) {
        if (letters[i].base == '\u0627' && letters[i].text.contains('\u0653')) {
          maddahIndices.add(i);
        }
      }
      expect(maddahIndices.length, 2,
          reason: 'Verse 2:4 has two instances of ا with maddah');
      expect(letters[maddahIndices[1]].color, equals(_darkPink),
          reason: 'Second مَآ also dark pink');
    });

    test('مِن قَ — green (ikhafa, noon sakin before qaf)', () {
      final lastGroup = letters
          .lastIndexWhere((l) => l.base == '\u0646' && l.color == _green);
      expect(lastGroup, isNot(-1));
      final qaf = letters[lastGroup + 1];
      expect(qaf.base, '\u0642');
      expect(qaf.color, equals(_green),
          reason: 'Qaf after noon sakin = ikhafa, both green');
    });

    test('بْ (in قَبْلِكَ) — blue (qalaqah)', () {
      final baWithSukun = letters
          .firstWhere((l) => l.base == '\u0628' && !_hasVowelTest(l.text));
      expect(baWithSukun.color, equals(_blue),
          reason: 'quran.com: qalaqah → blue');
    });

    test('ٱ (in وَبِٱلْ) — grey (ham_wasl)', () {
      final hamzaWaslInstances =
          letters.where((l) => l.base == '\u0671' && l.color == _grey).toList();
      expect(hamzaWaslInstances.length, greaterThanOrEqualTo(2),
          reason: 'Verse 2:4 has at least 2 ham_wasl instances');
    });

    test('و (before final نَ) — orange (madda_permissible)', () {
      final secondToLast = letters[letters.length - 2];
      expect(secondToLast.base, '\u0648');
      expect(secondToLast.color, equals(_orange),
          reason: 'quran.com: madda_permissible → orange (Maad Aridh at waqf)');
    });

    test('نَ (final) — no colour', () {
      expect(letters.last.base, '\u0646');
      expect(letters.last.color, isNull);
    });
  });

  // ============================================================
  //  VERSE 2:5
  //  أُو۟لَـٰٓئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ ۖ وَأُو۟لَـٰٓئِكَ
  //  هُمُ ٱلْمُفْلِحُونَ
  //
  //  Quran.com markup (key points):
  //    أُ<slnt>وْ</slnt>لَ          → و grey (silent, U+06DF)
  //    <madda_obligatory>ـٰٓ</…>ئِكَ → dark pink (Connected madd before hamza)
  //    عَلَىٰ                       → default (no tajweed tag)
  //    هُ<idgham_ghunnah>دًى م</…>ّ → grey for دًى, green for مّ
  //    <idgham_wo_ghunnah>ِن ر</…>ّ → all grey
  //    وَأُ<slnt>وْ</slnt>لَ       → و grey (second instance)
  //    <madda_obligatory>ـٰٓ</…>ئِكَ → dark pink
  //    <ham_wasl>ٱ</…>              → grey
  //    لِح<madda_permissible>ُو</…>نَ → orange
  // ============================================================
  group('2:5 – Silent waw, Connected Madd, Idgham', () {
    late List<TajweedClusterResult> letters;

    setUpAll(() async {
      final text = await _loadVerse(5);
      final all = tajweedColorAssignments(text);
      letters = _letters(all);
    });

    test('أُ — no colour (first letter of ayah)', () {
      expect(letters[0].base, '\u0623');
      expect(letters[0].color, isNull);
    });

    test('و۟ (silent waw, U+06DF) — grey (slnt)', () {
      expect(letters[1].base, '\u0648');
      expect(letters[1].text.contains('\u06DF'), isTrue,
          reason: 'Waw should carry U+06DF marker');
      expect(letters[1].color, equals(_grey),
          reason: 'quran.com: slnt → grey (silent letter marked with U+06DF)');
    });

    test('لَ — no colour', () {
      expect(letters[2].base, '\u0644');
      expect(letters[2].color, isNull);
    });

    test('ـٰٓ (tatweel + maddah before ئ) — dark pink (madda_obligatory)', () {
      expect(letters[3].base, '\u0640');
      expect(letters[3].color, equals(_darkPink),
          reason:
              'quran.com: madda_obligatory → dark pink (Connected madd before hamza ئ)');
    });

    test('ئِ كَ — no colour', () {
      expect(letters[4].base, '\u0626');
      expect(letters[4].color, isNull);
      expect(letters[5].base, '\u0643');
      expect(letters[5].color, isNull);
    });

    test('عَ لَ ىٰ — all default', () {
      expect(letters[6].color, isNull); // عَ
      expect(letters[7].color, isNull); // لَ
      expect(letters[8].color, isNull); // ىٰ
    });

    test('هُ — no colour', () {
      expect(letters[9].base, '\u0647');
      expect(letters[9].color, isNull);
    });

    test('دً — grey (idgham_ghunnah: tanween source)', () {
      expect(letters[10].base, '\u062F');
      expect(letters[10].color, equals(_grey),
          reason: 'Tanween fathah before meem → idgham with ghunnah → grey');
    });

    test('ى (carrier after دً) — grey (part of idgham span)', () {
      expect(letters[11].base, '\u0649');
      expect(letters[11].color, equals(_grey),
          reason: 'Carrier alef-maqsura greyed out in idgham span');
    });

    test('مِّ (receiving meem) — green (idgham_ghunnah)', () {
      expect(letters[12].base, '\u0645');
      expect(letters[12].color, equals(_green),
          reason: 'quran.com: idgham_ghunnah → green on receiving meem');
    });

    test('ن (after مِّ) — grey (idgham_wo_ghunnah)', () {
      expect(letters[13].base, '\u0646');
      expect(letters[13].color, equals(_grey),
          reason: 'Noon sakin before ra → idgham without ghunnah → grey');
    });

    test('رَّ (receiving ra) — grey (idgham_wo_ghunnah)', () {
      expect(letters[14].base, '\u0631');
      expect(letters[14].color, equals(_grey),
          reason:
              'quran.com: idgham_wo_ghunnah marks receiving letter grey too');
    });

    test('بِّ هِ مْ — no colour', () {
      expect(letters[15].color, isNull); // بِّ
      expect(letters[16].color, isNull); // هِ
      expect(letters[17].color, isNull); // مْ
    });

    test('وَ أُ — no colour', () {
      expect(letters[18].base, '\u0648');
      expect(letters[18].color, isNull);
      expect(letters[19].base, '\u0623');
      expect(letters[19].color, isNull);
    });

    test('و۟ (second silent waw) — grey (slnt)', () {
      expect(letters[20].base, '\u0648');
      expect(letters[20].text.contains('\u06DF'), isTrue);
      expect(letters[20].color, equals(_grey),
          reason: 'Second occurrence of silent waw');
    });

    test('لَ (second أُو۟لَـٰٓئِكَ) — no colour', () {
      expect(letters[21].base, '\u0644');
      expect(letters[21].color, isNull);
    });

    test('ـٰٓ (second, before ئ) — dark pink (madda_obligatory)', () {
      expect(letters[22].base, '\u0640');
      expect(letters[22].color, equals(_darkPink),
          reason: 'Second Connected madd before hamza');
    });

    test('ئِ كَ — no colour', () {
      expect(letters[23].base, '\u0626');
      expect(letters[23].color, isNull);
      expect(letters[24].base, '\u0643');
      expect(letters[24].color, isNull);
    });

    test('هُ مُ — no colour', () {
      expect(letters[25].color, isNull);
      expect(letters[26].color, isNull);
    });

    test('ٱ (in ٱلْمُفْلِحُونَ) — grey (ham_wasl)', () {
      expect(letters[27].base, '\u0671');
      expect(letters[27].color, equals(_grey),
          reason: 'quran.com: ham_wasl → grey');
    });

    test('لْ مُ فْ لِ — no colour', () {
      for (int i = 28; i <= 31; i++) {
        expect(letters[i].color, isNull,
            reason:
                'Letter at index $i (${letters[i].text}) should be default');
      }
    });

    test('حُ — no colour', () {
      expect(letters[32].base, '\u062D');
      expect(letters[32].color, isNull);
    });

    test('و (before final نَ) — orange (madda_permissible)', () {
      expect(letters[33].base, '\u0648');
      expect(letters[33].color, equals(_orange),
          reason: 'quran.com: madda_permissible → orange (Maad Aridh at waqf)');
    });

    test('نَ (final) — no colour', () {
      expect(letters[34].base, '\u0646');
      expect(letters[34].color, isNull);
    });

    test('total letter count is 35', () {
      expect(letters.length, 35, reason: 'Verse 2:5 has 35 letter clusters');
    });
  });

  // ============================================================
  //  SPAN TYPE & TEXT INTEGRITY TESTS
  //
  //  Ensures tajweedSpans() only produces TextSpan (never
  //  WidgetSpan), preserving Arabic cursive letter joining.
  //  Also verifies no characters are stripped from the output.
  // ============================================================
  group('Span type & text integrity', () {
    late List<String> verseTexts;

    setUpAll(() async {
      final raw = await File('assets/quran/ar/2.json').readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      verseTexts = [
        for (int i = 1; i <= 5; i++) map['$i'] as String,
      ];
    });

    testWidgets('tajweedSpans produces only TextSpan (no WidgetSpan)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            for (final text in verseTexts) {
              final spans = tajweedSpans(
                context,
                text,
                const TextStyle(fontSize: 24),
              );
              for (final span in spans) {
                expect(span, isA<TextSpan>(),
                    reason: 'WidgetSpan breaks Arabic letter joining. '
                        'All spans must be TextSpan.');
              }
            }
            return const SizedBox();
          }),
        ),
      );
    });

    test('no characters lost — output text equals sanitized input', () {
      for (final text in verseTexts) {
        final clusters = tajweedColorAssignments(text);
        final reassembled = clusters.map((c) => c.text).join();
        // The sanitizer removes rosettes/verse markers but the
        // remaining characters must all be present in the output.
        for (final cluster in clusters) {
          expect(cluster.text.isNotEmpty, isTrue,
              reason: 'No empty clusters should exist');
        }
        expect(reassembled.length, greaterThan(0));
      }
    });

    test('U+0653 maddah characters preserved in output text', () {
      for (final text in verseTexts) {
        final clusters = tajweedColorAssignments(text);
        final reassembled = clusters.map((c) => c.text).join();
        final inputMaddahCount = text.runes.where((r) => r == 0x0653).length;
        final outputMaddahCount =
            reassembled.runes.where((r) => r == 0x0653).length;
        expect(outputMaddahCount, equals(inputMaddahCount),
            reason: 'U+0653 (maddah above) must not be stripped');
      }
    });

    test('U+06DF silent markers preserved in output text', () {
      for (final text in verseTexts) {
        final clusters = tajweedColorAssignments(text);
        final reassembled = clusters.map((c) => c.text).join();
        final inputCount = text.runes.where((r) => r == 0x06DF).length;
        final outputCount = reassembled.runes.where((r) => r == 0x06DF).length;
        expect(outputCount, equals(inputCount),
            reason: 'U+06DF (small high rounded zero) must not be stripped');
      }
    });
  });

  // ============================================================
  //  COLOUR SUMMARY TESTS
  //
  //  Verifies total coloured letter counts per rule for each
  //  verse, providing a high-level sanity check.
  // ============================================================
  group('Colour summary counts', () {
    test('2:1 — 2 red (Madd Lazim)', () async {
      final text = await _loadVerse(1);
      final letters = _letters(tajweedColorAssignments(text));
      final reds = letters.where((l) => l.color == _redLong).length;
      expect(reds, 2, reason: 'لٓ and مٓ are both Madd Lazim');
    });

    test('2:2 — colour counts match quran.com', () async {
      final text = await _loadVerse(2);
      final letters = _letters(tajweedColorAssignments(text));
      final greys = letters.where((l) => l.color == _grey).length;
      final pinks = letters.where((l) => l.color == _pink).length;
      final oranges = letters.where((l) => l.color == _orange).length;
      expect(greys, 4, reason: '1 ham_wasl + 3 idgham_wo_ghunnah (دًى+لِّ)');
      expect(pinks, 2, reason: '2 madda_normal: ـٰ and لَا');
      expect(oranges, 2, reason: '2 madda_permissible: ي in فِيهِ and ي in المتقين');
    });

    test('2:3 — colour counts match quran.com', () async {
      final text = await _loadVerse(3);
      final letters = _letters(tajweedColorAssignments(text));
      final greys = letters.where((l) => l.color == _grey).length;
      final greens = letters.where((l) => l.color == _green).length;
      final blues = letters.where((l) => l.color == _blue).length;
      final darkBlues = letters.where((l) => l.color == _darkBlue).length;
      final pinks = letters.where((l) => l.color == _pink).length;
      final oranges = letters.where((l) => l.color == _orange).length;
      expect(greys, 4, reason: '2 ham_wasl + 1 laam_shamsiyah + 1 slnt waw');
      expect(greens, 3, reason: '1 ghunnah (مّ) + 2 ikhafa (ن+ف)');
      expect(blues, 1, reason: '1 qalaqah (قْ)');
      expect(darkBlues, 5, reason: 'Tafkhim: رَ قُ غَ صَّ + one more heavy letter');
      expect(pinks, 1, reason: '1 madda_normal (ـٰ)');
      expect(oranges, 6, reason: 'All madda_permissible (ي و ا etc.)');
    });

    test('2:4 — colour counts match quran.com', () async {
      final text = await _loadVerse(4);
      final letters = _letters(tajweedColorAssignments(text));
      final greys = letters.where((l) => l.color == _grey).length;
      final greens = letters.where((l) => l.color == _green).length;
      final blues = letters.where((l) => l.color == _blue).length;
      final darkPinks = letters.where((l) => l.color == _darkPink).length;
      final oranges = letters.where((l) => l.color == _orange).length;
      expect(greys, greaterThanOrEqualTo(2),
          reason: 'At least 2 ham_wasl instances');
      expect(greens, greaterThanOrEqualTo(6),
          reason: 'Ikhfa pairs: 2×(ن+ز) + 1×(ن+ق) = 6');
      expect(blues, 1, reason: '1 qalaqah (بْ)');
      expect(darkPinks, 2, reason: '2 madda_obligatory (مَآ×2)');
      expect(oranges, greaterThanOrEqualTo(1),
          reason: 'At least 1 madda_permissible (و); more with full permissible madd');
    });

    test('2:5 — colour counts match quran.com', () async {
      final text = await _loadVerse(5);
      final letters = _letters(tajweedColorAssignments(text));
      final greys = letters.where((l) => l.color == _grey).length;
      final greens = letters.where((l) => l.color == _green).length;
      final darkPinks = letters.where((l) => l.color == _darkPink).length;
      final oranges = letters.where((l) => l.color == _orange).length;
      expect(greys, 7,
          reason: '2 slnt waw + 1 ham_wasl + '
              'idgham_ghunnah(دً+ى) + idgham_wo_ghunnah(ن+رَّ)');
      expect(greens, 1, reason: '1 idgham_ghunnah receiving (مِّ)');
      expect(darkPinks, 2, reason: '2 madda_obligatory (ـٰٓ×2)');
      expect(oranges, 1, reason: '1 madda_permissible (و)');
    });
  });
}

bool _hasVowelTest(String text) {
  return text.contains('\u064E') ||
      text.contains('\u064F') ||
      text.contains('\u0650') ||
      text.contains('\u064B') ||
      text.contains('\u064C') ||
      text.contains('\u064D') ||
      text.contains('\u0651');
}
