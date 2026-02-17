/// Full-screen surah reading view.
///
/// Loads Arabic text (Uthmanic glyph) and ClearQuran English
/// translation side by side. Supports:
/// - Bismillah header (except for Al-Fatiha and At-Tawba)
/// - Tajweed-coloured Arabic rendering
/// - Per-ayah bookmarking
/// - Scroll-to-ayah via query parameter
/// - Tajweed colour legend at the bottom
library;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/models.dart';

import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import '../theme/tajweed_extension.dart';

import 'widgets/arabic_text.dart';

/// Displays all ayahs of a single surah with bookmarking and
/// tajweed rendering.
class SurahDetailPage extends StatefulWidget {
  /// 1-based surah number.
  final int surahId;

  /// If provided, the list auto-scrolls to this ayah on load.
  final int? scrollToAyah;

  const SurahDetailPage({
    super.key,
    required this.surahId,
    this.scrollToAyah,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final chaptersRepo = const QuranChaptersRepository();
    final arabicRepo = const QuranArabicRepository();
    final translationRepo = const QuranTranslationRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chaptersRepo.loadChapters(),
        arabicRepo.loadArabicSurah(widget.surahId),
        translationRepo.loadClearQuran(widget.surahId),
      ]),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final errorMessage =
            snapshot.hasError ? snapshot.error.toString() : null;

        ChapterMeta? chapterMeta;
        Map<String, String> arabicAyahs = const {};
        Map<String, String> englishAyahs = const {};

        if (snapshot.hasData) {
          final chapters = snapshot.data![0] as List<ChapterMeta>;
          chapterMeta = chapters.firstWhere(
            (chapter) => chapter.id == widget.surahId,
          );
          arabicAyahs = snapshot.data![1] as Map<String, String>;
          englishAyahs = snapshot.data![2] as Map<String, String>;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(chapterMeta?.nameSimple ?? 'Surah'),
            actions: [
              if (chapterMeta != null)
                Text(
                  chapterMeta.nameArabic,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'KFGQPCQuranicFontHafsSmart',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              const SizedBox(width: 16),
            ],
          ),
          body: () {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $errorMessage'),
              );
            }

            return _buildAyahList(
              context,
              chapterMeta!,
              arabicAyahs,
              englishAyahs,
            );
          }(),
        );
      },
    );
  }

  /// Builds the scrollable list of ayah cards, optionally preceded
  /// by a Bismillah header and followed by a tajweed legend.
  Widget _buildAyahList(
    BuildContext context,
    ChapterMeta chapterMeta,
    Map<String, String> arabicAyahs,
    Map<String, String> englishAyahs,
  ) {
    final totalAyahs = chapterMeta.versesCount;

    // Bismillah is shown for all surahs except Al-Fatiha (1)
    // and At-Tawba (9).
    final hasBismillah = widget.surahId != 1 && widget.surahId != 9;

    // Persist this position as last-read.
    _saveLastReadPosition(chapterMeta);

    // Auto-scroll to the requested ayah after the frame renders.
    if (widget.scrollToAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = hasBismillah ? 1 : 0;
        final targetIndex = (widget.scrollToAyah! - 1 + offset)
            .clamp(0, totalAyahs - 1 + offset);
        if (_scrollController.isAttached) {
          _scrollController.jumpTo(index: targetIndex);
          _scrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 200),
            alignment: 0.08,
            curve: Curves.easeInOut,
          );
        }
      });
    }

    final settings = SettingsScope.of(context);
    final bookmarkService = BookmarkScope.of(context);

    // Total items: optional bismillah + ayahs + tajweed legend.
    final itemCount = (hasBismillah ? 1 : 0) + totalAyahs + 1;

    return ScrollablePositionedList.separated(
      itemScrollController: _scrollController,
      itemPositionsListener: _positionsListener,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        // First item: Bismillah header (if applicable).
        if (hasBismillah && index == 0) {
          return _BismillahHeader(
            arabicZoom: settings.arabicZoom,
          );
        }

        // Last item: Tajweed colour legend.
        final ayahIndex = index - (hasBismillah ? 1 : 0);
        if (ayahIndex >= totalAyahs) {
          return _buildTajweedLegend(context);
        }

        // Normal ayah card.
        final ayahNumber = ayahIndex + 1;
        final arabicText = arabicAyahs['$ayahNumber'];
        final englishText = englishAyahs['$ayahNumber'];
        final bookmarkId = 'quran:${widget.surahId}:$ayahNumber';
        final isBookmarked = bookmarkService.isBookmarked(bookmarkId);

        return _AyahCard(
          ayahNumber: ayahNumber,
          arabic: arabicText,
          english: englishText,
          arabicZoom: settings.arabicZoom,
          englishZoom: settings.englishZoom,
          isBookmarked: isBookmarked,
          onBookmarkToggle: () {
            bookmarkService.toggleBookmark(Bookmark.quran(
              surahId: widget.surahId,
              ayah: ayahNumber,
              surahName: chapterMeta.nameSimple,
              snippet: englishText,
            ));
          },
        );
      },
    );
  }

  /// Records the current surah as the last-read position.
  void _saveLastReadPosition(ChapterMeta? meta) {
    if (meta == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BookmarkScope.of(context).saveLastReadQuran(
        surahId: widget.surahId,
        ayah: widget.scrollToAyah ?? 1,
        surahName: meta.nameSimple,
      );
    });
  }

  /// Builds a row of colour-coded tajweed rule chips.
  Widget _buildTajweedLegend(BuildContext context) {
    final tajweed = Theme.of(context).extension<TajweedTheme>();
    if (tajweed == null) return const SizedBox.shrink();

    Widget chip(String label, Color color) => Chip(
          label: Text(label),
          backgroundColor: color.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          side: BorderSide(
            color: color.withValues(alpha: 0.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          visualDensity: VisualDensity.compact,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          chip('Qalqala', tajweed.qalqalah),
          chip('Iqlab', tajweed.iqlab),
          chip('Idgham', tajweed.idgham),
          chip('Idgham*', tajweed.idghamMutajanisayn),
          chip('Ikhfaa', tajweed.ikhfa),
          chip('Ikhfaa Meemi', tajweed.ikhfaShafawi),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Private sub-widgets
// ────────────────────────────────────────────────────────────────

/// Styled Bismillah banner shown at the top of most surahs.
class _BismillahHeader extends StatelessWidget {
  final double arabicZoom;

  const _BismillahHeader({required this.arabicZoom});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.06),
            colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: ArabicText(
          '\u0628\u0650\u0633\u0652\u0645\u0650 '
          '\u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
          '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0640\u0670\u0646\u0650 '
          '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
          tajweed: false,
          fontSize: 32 * arabicZoom,
          weight: FontWeight.bold,
          align: TextAlign.center,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// A single ayah card showing the ayah number badge, Arabic text
/// with tajweed, English translation, and a bookmark toggle.
class _AyahCard extends StatelessWidget {
  final int ayahNumber;
  final String? arabic;
  final String? english;
  final double arabicZoom;
  final double englishZoom;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const _AyahCard({
    required this.ayahNumber,
    this.arabic,
    this.english,
    required this.arabicZoom,
    required this.englishZoom,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah number badge + bookmark icon
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$ayahNumber',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isBookmarked
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 22,
                  ),
                  onPressed: onBookmarkToggle,
                  visualDensity: VisualDensity.compact,
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Arabic text with tajweed colouring
            if (arabic != null && arabic!.isNotEmpty)
              ArabicText(
                arabic!,
                tajweed: true,
                fontSize: 34 * arabicZoom,
                weight: FontWeight.bold,
              ),
            if (arabic != null && arabic!.isNotEmpty)
              const SizedBox(height: 20),

            // English translation
            if (english != null && english!.isNotEmpty)
              Text(
                english!,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                      fontFamilyFallback: const [
                        'Arial',
                        'sans-serif',
                      ],
                      fontSize: 17 * englishZoom,
                      height: 1.5,
                      letterSpacing: 0.1,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
