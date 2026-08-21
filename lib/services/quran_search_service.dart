/// Orchestrates full-text search across all Quran surahs (Arabic + English).
///
/// Uses [QuranChaptersRepository], [QuranArabicRepository], and
/// [QuranTranslationRepository] to produce [QuranSearchHit] results.
library;

import '../quran/quran_arabic_repository.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_translation_repository.dart';
import 'search_models.dart';

/// Service that searches Quran ayahs by Arabic or English text.
class QuranSearchService {
  const QuranSearchService({
    QuranChaptersRepository? chaptersRepo,
    QuranArabicRepository? arabicRepo,
    QuranTranslationRepository? translationRepo,
  }) : _chaptersRepo = chaptersRepo ?? const QuranChaptersRepository(),
       _arabicRepo = arabicRepo ?? const QuranArabicRepository(),
       _translationRepo = translationRepo ?? const QuranTranslationRepository();

  final QuranChaptersRepository _chaptersRepo;
  final QuranArabicRepository _arabicRepo;
  final QuranTranslationRepository _translationRepo;

  /// Searches all surahs for ayahs matching [query]. Returns up to [limit] hits.
  Future<List<QuranSearchHit>> search(String query, {int limit = 150}) async {
    final queryLower = query.trim().toLowerCase();
    if (queryLower.isEmpty) return [];

    final chapters = await _chaptersRepo.loadChapters();
    final hits = <QuranSearchHit>[];

    for (final chapter in chapters) {
      Map<String, String> arabicAyahs = const {};
      Map<String, String> englishAyahs = const {};
      try {
        arabicAyahs = await _arabicRepo.loadArabicSurah(
          chapter.id,
          useGlyphText: false, // aya_text_emlaey — searchable Imla'i
        );
        englishAyahs = await _translationRepo.loadClearQuran(chapter.id);
      } catch (_) {
        continue;
      }

      for (var ayahNum = 1; ayahNum <= chapter.versesCount; ayahNum++) {
        final key = '$ayahNum';
        final arabicText = arabicAyahs[key] ?? '';
        final englishText = englishAyahs[key] ?? '';

        final isMatch =
            arabicText.contains(query) ||
            englishText.toLowerCase().contains(queryLower);
        if (!isMatch) continue;

        final snippet = _buildSnippet(
          englishText,
          queryLower,
          query.trim().length,
        );

        hits.add(
          QuranSearchHit(
            surahId: chapter.id,
            ayah: ayahNum,
            surahName: chapter.nameSimple,
            snippet: snippet,
          ),
        );

        if (hits.length >= limit) return hits;
      }
      if (hits.length >= limit) break;
    }
    return hits;
  }

  static String? _buildSnippet(
    String text,
    String queryLower,
    int queryLength,
  ) {
    if (text.isEmpty) return null;
    final matchIndex = text.toLowerCase().indexOf(queryLower);
    if (matchIndex >= 0) {
      final start = (matchIndex - 40).clamp(0, text.length);
      final end = (matchIndex + queryLength + 60).clamp(0, text.length);
      var snippet = text.substring(start, end).trim();
      if (start > 0) snippet = '\u2026$snippet';
      if (end < text.length) snippet = '$snippet\u2026';
      return snippet;
    }
    return text;
  }
}
