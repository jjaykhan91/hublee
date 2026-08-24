/// Parses jump references such as `2:255` from search queries.
library;

import '../router_paths.dart';

/// A surah and ayah the user asked to open by number.
class SurahAyahRef {
  const SurahAyahRef({required this.surahId, required this.ayah});

  final int surahId;
  final int ayah;
}

/// Parses `2:255`, `2.255`, or `2 255`. Returns null when the text is
/// not a verse reference or the surah is outside 1–114.
SurahAyahRef? tryParseSurahAyah(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})$').firstMatch(trimmed);
  final spaced =
      match ?? RegExp(r'^(\d{1,3})\s+(\d{1,3})$').firstMatch(trimmed);
  if (spaced == null) return null;

  final surahId = AppRoute.tryParseSurahId(spaced.group(1));
  final ayah = int.tryParse(spaced.group(2) ?? '');
  if (surahId == null || ayah == null || ayah < 1) return null;
  return SurahAyahRef(surahId: surahId, ayah: ayah);
}
