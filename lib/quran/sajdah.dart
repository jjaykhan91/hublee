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
