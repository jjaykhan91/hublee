import 'dart:async';
import 'package:flutter/material.dart';

import '../hadith/hadith_repository.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';

import 'hadith_book_page.dart';
import 'widgets/arabic_text.dart';
import 'surah_detail_page.dart';
import 'widgets/app_scaffold.dart';
import '../services/settings_scope.dart';
import '../services/search_models.dart';

/// Unified global search over Qur'an and Hadith.
/// - Debounced search (300ms)
/// - Qur'an: searches Arabic (exact) + English (case-insensitive)
/// - Hadith: uses HadithRepository.searchHadith(...)
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  // Search field controller + debounce timer
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;

  // UI state
  bool _isSearching = false;

  // Results
  final List<HadithSearchHit> _hadithResults = <HadithSearchHit>[];
  final List<QuranSearchHit> _quranResults = <QuranSearchHit>[];

  @override
  void dispose() {
    _queryController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounce wrapper for the text field
  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(raw);
    });
  }

  /// Core search routine: queries Hadith and Qur'an
  Future<void> _performSearch(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _hadithResults.clear();
        _quranResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      // --- Hadith search ---
      final hadithRepo = const HadithRepository();
      final hadithHits = await hadithRepo.searchHadith(query, limit: 100);

      // --- Qur'an search ---
      final chaptersRepo = const QuranChaptersRepository();
      final arabicRepo   = const QuranArabicRepository();
      final transRepo    = const QuranTranslationRepository();

      final chapters = await chaptersRepo.loadChapters();
      final List<QuranSearchHit> qHits = [];
      final qLower = query.toLowerCase();

      // Walk surahs; collect hits until we reach a soft cap.
      for (final c in chapters) {
        Map<String, String> ar = const {};
        Map<String, String> en = const {};
        try {
          ar = await arabicRepo.loadArabicSurah(c.id);
          en = await transRepo.loadClearQuran(c.id);
        } catch (_) {
          continue; // skip if a surah is missing either map
        }

        for (var i = 1; i <= c.versesCount; i++) {
          final key = '$i';
          final arText = ar[key] ?? '';
          final enText = en[key] ?? '';

          final bool matches =
              arText.contains(query) || enText.toLowerCase().contains(qLower);
          if (!matches) continue;

          // Build a small English snippet around the match if available.
          String? snippet;
          if (enText.isNotEmpty) {
            final idx = enText.toLowerCase().indexOf(qLower);
            if (idx >= 0) {
              final start = (idx - 40).clamp(0, enText.length);
              final end   = (idx + query.length + 60).clamp(0, enText.length);
              snippet = enText.substring(start, end).trim();
              if (start > 0) snippet = '…$snippet';
              if (end < enText.length) snippet = '$snippet…';
            } else {
              snippet = enText;
            }
          }

          qHits.add(QuranSearchHit(
            surahId: c.id,
            ayah: i,
            surahName: c.nameSimple,
            snippet: snippet,
          ));

          if (qHits.length >= 150) break;
        }
        if (qHits.length >= 150) break;
      }

      if (!mounted) return;
      setState(() {
        _hadithResults
          ..clear()
          ..addAll(hadithHits);
        _quranResults
          ..clear()
          ..addAll(qHits);
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final settings = SettingsScope.of(context); // for Arabic preview scaling

    return AppScaffold(
      // The AppBar contains the search field; a consistent settings gear
      // is auto-injected by AppScaffold on the right.
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onSubmitted: _performSearch,
          decoration: const InputDecoration(
            hintText: 'Search Qur’an and Hadith…',
            border: InputBorder.none,
          ),
        ),
      ),

      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : (_hadithResults.isEmpty && _quranResults.isEmpty)
              ? Center(
                  child: Text(
                    'Type to search Qur’an and Hadith.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: [
                    if (_quranResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Text('Qur’an',
                            style: theme.textTheme.titleMedium),
                      ),
                      ..._quranResults.map(
                        (hit) => _QuranTile(
                          hit: hit,
                          englishStyle: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_hadithResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Text('Hadith',
                            style: theme.textTheme.titleMedium),
                      ),
                      ..._hadithResults.map(
                        (hit) => _HadithTile(
                          hit: hit,
                          arabicFontSize: 38 * settings.arabicZoom,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

/// Hadith search result tile.
/// Shows book + item index; snippet rendered in Arabic with ArabicText.
class _HadithTile extends StatelessWidget {
  final HadithSearchHit hit;
  final double arabicFontSize;

  const _HadithTile({
    required this.hit,
    required this.arabicFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HadithBookPage(
                collectionId: hit.collectionId,
                bookFile: hit.bookFile,
                title: hit.bookTitle ?? hit.bookFile,
                scrollToIndex: hit.hadithIndex,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.bookTitle ?? hit.bookFile} • Hadith ${hit.hadithIndex + 1}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty)
                      ArabicText(
                        hit.snippet!,
                        tajweed: true,
                        fontSize: arabicFontSize,      // 👈 scales with settings
                        weight: FontWeight.w800,
                        style: const TextStyle(
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Qur’an search result tile.
/// Shows surah name + ayah number and an English snippet.
class _QuranTile extends StatelessWidget {
  final QuranSearchHit hit;
  final TextStyle? englishStyle;

  const _QuranTile({
    required this.hit,
    required this.englishStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahDetailPage(
                surahId: hit.surahId,
                scrollToAyah: hit.ayah,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.book_outlined, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.surahName} • Ayah ${hit.ayah}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty)
                      Text(
                        hit.snippet!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        // English sizes already follow global englishZoom via theme
                        style: englishStyle,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
