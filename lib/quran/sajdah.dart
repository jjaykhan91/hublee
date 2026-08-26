/// The 15 sajdah (prostration) ayahs in the Hafs mushaf.
///
/// Used to badge those verses in the reader. Detection also falls
/// back to the ۩ marker in the displayed Arabic when present.
library;

/// Surah and ayah pairs where a recitation sajdah is marked.
const kSajdahAyahs = <({int surah, int ayah})>[
  (surah: 7, ayah: 206),
  (surah: 13, ayah: 15),
  (surah: 16, ayah: 50),
  (surah: 17, ayah: 109),
  (surah: 19, ayah: 58),
  (surah: 22, ayah: 18),
  (surah: 22, ayah: 77),
  (surah: 25, ayah: 60),
  (surah: 27, ayah: 26),
  (surah: 32, ayah: 15),
  (surah: 38, ayah: 24),
  (surah: 41, ayah: 38),
  (surah: 53, ayah: 62),
  (surah: 84, ayah: 21),
  (surah: 96, ayah: 19),
];

final _sajdahSet = {
  for (final item in kSajdahAyahs) '${item.surah}:${item.ayah}',
};

/// Whether [surahId]:[ayah] is one of the 15 sajdah verses.
bool isSajdahAyah(int surahId, int ayah) =>
    _sajdahSet.contains('$surahId:$ayah');

/// True when [arabic] contains the sajdah marker ۩ (U+06E9).
bool hasSajdahMarker(String? arabic) =>
    arabic != null && arabic.contains('\u06E9');

/// How many Hafs ayahs carry a recitation sajdah.
const kSajdahAyahCount = 15;

/// Opening line for the reading-guide sajdah section.
const kSajdahCountIntro =
    'There are 15 verses in the Quran where prostration (sajdah) '
    'is recommended when reciting or listening. They are marked '
    'with the symbol \u06E9 (sajdah marker).';

/// Physical action for a tilawah prostration.
const kSajdahWhatToDo =
    'Make one prostration (suj\u016Bd): place forehead, nose, '
    'hands, knees and toes on the ground, facing the qibla.';

/// Du'a recited in a tilawah prostration. This is not Quran text.
const kSajdahArabic =
    '\u0633\u064E\u062C\u064E\u062F\u064E '
    '\u0648\u064E\u062C\u0652\u0647\u0650\u064A\u064E '
    '\u0644\u0650\u0644\u0651\u064E\u0630\u0650\u064A '
    '\u062E\u064E\u0644\u064E\u0642\u064E\u0647\u064F '
    '\u0648\u064E\u0634\u064E\u0642\u0651\u064E '
    '\u0633\u064E\u0645\u0652\u0639\u064E\u0647\u064F '
    '\u0648\u064E\u0628\u064E\u0635\u064E\u0631\u064E\u0647\u064F '
    '\u0628\u0650\u062D\u064E\u0648\u0652\u0644\u0650\u0647\u0650 '
    '\u0648\u064E\u0642\u064F\u0648\u0651\u064E\u062A\u0650\u0647\u0650';

/// Latin rendering of [kSajdahArabic].
const kSajdahTransliteration =
    'Sajada wajh\u012B lilladh\u012B khalaqahu wa-shaqqa sam\u02BFahu '
    'wa-ba\u1E63arahu bi-\u1E25awlih\u012B wa-quwwatih\u012B.';

/// English meaning of [kSajdahArabic].
const kSajdahMeaning =
    'My face prostrated to the One who created it, gave it hearing '
    'and sight by His might and power.';
