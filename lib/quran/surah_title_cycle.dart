/// Cycles the reader app-bar surah name through Arabic, English,
/// meaning, and the city of revelation.
library;

import 'models.dart';

/// One pass of the tappable surah title.
enum SurahTitleCycle {
  /// Calligraphic Arabic name (surah-name ligature font).
  arabic,

  /// Transliterated English name (e.g. Al-Fatiha).
  english,

  /// English meaning of the name (e.g. The Opener).
  meaning,

  /// Mecca or Medina.
  revelationCity,
}

/// Ligature token consumed by [AppFonts.surahName] (`surah001`–`surah114`).
String surahNameLigature(int surahId) =>
    'surah${surahId.toString().padLeft(3, '0')}';

/// Display and accessibility helpers for [SurahTitleCycle].
extension SurahTitleCycleX on SurahTitleCycle {
  /// The next mode, wrapping after the city of revelation.
  SurahTitleCycle get next =>
      SurahTitleCycle.values[(index + 1) % SurahTitleCycle.values.length];

  /// Latin (or city) label. `null` means show the calligraphic ligature.
  String? displayText(ChapterMeta chapter) {
    switch (this) {
      case SurahTitleCycle.arabic:
        return null;
      case SurahTitleCycle.english:
        return chapter.nameSimple;
      case SurahTitleCycle.meaning:
        final meaning = chapter.nameTranslated?.trim();
        if (meaning == null || meaning.isEmpty) return chapter.nameSimple;
        return meaning;
      case SurahTitleCycle.revelationCity:
        return chapter.isMeccan ? 'Mecca' : 'Medina';
    }
  }

  /// Spoken label, including a hint that the title is tappable.
  String semanticsLabel(ChapterMeta chapter) {
    switch (this) {
      case SurahTitleCycle.arabic:
        return 'Surah ${chapter.id}, ${chapter.nameSimple}, Arabic name. '
            'Tap to cycle English name, meaning, and where it was revealed.';
      case SurahTitleCycle.english:
        return '${chapter.nameSimple}. Tap to cycle.';
      case SurahTitleCycle.meaning:
        return '${displayText(chapter)}. Tap to cycle.';
      case SurahTitleCycle.revelationCity:
        return 'Revealed in ${displayText(chapter)}. Tap to cycle.';
    }
  }
}
