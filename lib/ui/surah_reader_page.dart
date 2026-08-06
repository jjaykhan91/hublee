/// Full-screen surah reading view.
///
/// Loads Arabic text (Uthmanic glyph) and ClearQuran English
/// translation. Supports:
/// - Bismillah header (except for Al-Fatiha and At-Tawba)
/// - Tajweed-coloured Arabic rendering
/// - Per-ayah bookmarking
/// - Scroll-to-ayah via query parameter
/// - In-surah search (filters ayahs within the current surah)
/// - Tajweed colour legend at the bottom
library;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/surah_info_repository.dart';
import '../quran/models.dart';

import '../services/settings_controller.dart';
import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';

import 'widgets/arabic_text.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/scroll_scrubber.dart';
import 'widgets/quran_reading_guide_sheet.dart';

/// Displays all ayahs of a single surah with bookmarking and
/// tajweed rendering.
class SurahReaderPage extends StatefulWidget {
  /// 1-based surah number.
  final int surahId;

  /// If provided, the list auto-scrolls to this ayah on load.
  final int? scrollToAyah;

  const SurahReaderPage({super.key, required this.surahId, this.scrollToAyah});

  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  /// Cached future so rebuilds don't re-fetch data.
  late final Future<List<dynamic>> _dataFuture;

  /// Ensures last-read is saved only once per page visit.
  bool _hasPersistedLastRead = false;

  /// Ensures scroll-to-ayah fires only once.
  bool _hasScrolledToAyah = false;

  // ── In-surah search state ──────────────────────────────────
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  /// Cycle index for header title: 0=Arabic, 1=English, 2=Meaning, 3=Revelation.
  int _titleCycleIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load PUA glyph text (for KFGQPC font), standard Uthmanic
    // text (for Google Fonts + tajweed), and English translation.
    _dataFuture = Future.wait([
      const QuranChaptersRepository().loadChapters(),
      const QuranArabicRepository().loadArabicSurah(widget.surahId),
      const QuranTranslationRepository().loadClearQuran(widget.surahId),
      const QuranArabicRepository().loadUthmaniStandard(widget.surahId),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Opens the in-surah search bar.
  void _openSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.requestFocus();
  }

  /// Closes the in-surah search bar and shows all ayahs.
  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  /// Shows a modal bottom sheet with surah background information.
  Future<void> _showSurahInfo(BuildContext context, ChapterMeta chapter) async {
    final info = await const SurahInfoRepository().loadBySurahId(chapter.id);
    if (!mounted || info.shortText.isEmpty) return;

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;

          // Parse HTML into structured sections for display.
          final sections = _parseHtmlSections(info.fullText);

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header card with Makki/Madani background image
              _buildSurahInfoHeader(ctx, chapter),
              const SizedBox(height: 16),

              // Short summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: colorScheme.primary, width: 3),
                  ),
                ),
                child: Text(
                  info.shortText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),

              // Rendered HTML sections
              if (sections.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...sections.map(
                  (section) =>
                      _buildInfoSection(ctx, section.heading, section.body),
                ),
              ],

              // Source attribution
              if (info.source.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        info.source,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final errorMessage = snapshot.hasError
            ? snapshot.error.toString()
            : null;

        ChapterMeta? chapterMeta;
        Map<String, String> arabicGlyphAyahs = const {};
        Map<String, String> englishAyahs = const {};
        Map<String, String> arabicStandardAyahs = const {};

        if (snapshot.hasData) {
          final chapters = snapshot.data![0] as List<ChapterMeta>;
          chapterMeta = chapters.firstWhere(
            (chapter) => chapter.id == widget.surahId,
          );
          arabicGlyphAyahs = snapshot.data![1] as Map<String, String>;
          englishAyahs = snapshot.data![2] as Map<String, String>;
          arabicStandardAyahs = snapshot.data![3] as Map<String, String>;
        }

        return Scaffold(
          appBar: _isSearching
              ? _buildSearchAppBar(context)
              : _buildNormalAppBar(context, chapterMeta),
          body: () {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $errorMessage'),
              );
            }

            if (_isSearching && _searchQuery.isNotEmpty) {
              return _buildSearchResults(
                context,
                chapterMeta!,
                arabicGlyphAyahs,
                englishAyahs,
                arabicStandardAyahs,
              );
            }

            final totalAyahs = chapterMeta!.versesCount;
            final hasBismillah = widget.surahId != 1 && widget.surahId != 9;
            final itemCount = (hasBismillah ? 1 : 0) + totalAyahs;

            return Stack(
              children: [
                _buildAyahList(
                  context,
                  chapterMeta,
                  arabicGlyphAyahs,
                  englishAyahs,
                  arabicStandardAyahs,
                ),
                ScrollScrubber(
                  itemCount: itemCount,
                  labelBuilder: (index) {
                    if (hasBismillah && index == 0) {
                      return 'Bismillah';
                    }
                    final ayahIndex = index - (hasBismillah ? 1 : 0);
                    return 'Ayah ${ayahIndex + 1} of $totalAyahs';
                  },
                  scrollController: _scrollController,
                  positionsListener: _positionsListener,
                ),
              ],
            );
          }(),
        );
      },
    );
  }

  /// Normal app bar: single clickable title that cycles Arabic → English → Meaning → Revelation.
  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    ChapterMeta? chapterMeta,
  ) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 16,
      leadingWidth: 48,
      title: chapterMeta == null
          ? Text(
              'Surah',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
          : _CyclingSurahTitle(
              chapter: chapterMeta,
              cycleIndex: _titleCycleIndex,
              onTap: () {
                setState(() {
                  _titleCycleIndex = (_titleCycleIndex + 1) % 4;
                });
              },
            ),
      actions: [
        if (chapterMeta != null)
          Builder(
            builder: (ctx) {
              final chapter = chapterMeta;
              return IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'Surah info',
                onPressed: () => _showSurahInfo(ctx, chapter),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Quran reading & Tajweed guide',
          onPressed: () => showQuranReadingGuideSheet(context),
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search in this surah',
          onPressed: _openSearch,
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Reader settings',
          onPressed: () =>
              showReaderSettingsSheet(context, showTajweedToggle: true),
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Search app bar with text field and close button.
  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search in this surah\u2026',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
      ],
    );
  }

  /// Shows filtered ayah results matching the search query.
  Widget _buildSearchResults(
    BuildContext context,
    ChapterMeta chapterMeta,
    Map<String, String> arabicGlyphAyahs,
    Map<String, String> englishAyahs,
    Map<String, String> arabicStandardAyahs,
  ) {
    final queryLower = _searchQuery.toLowerCase();
    final settings = SettingsScope.of(context);
    final bookmarkService = BookmarkScope.of(context);
    final isUthmanic = settings.arabicFont == ArabicFontOption.uthmanic;

    // Find matching ayah numbers (search against standard text).
    final matches = <int>[];
    for (var ayahNum = 1; ayahNum <= chapterMeta.versesCount; ayahNum++) {
      final arabic = arabicStandardAyahs['$ayahNum'] ?? '';
      final english = englishAyahs['$ayahNum'] ?? '';
      if (arabic.contains(_searchQuery) ||
          english.toLowerCase().contains(queryLower)) {
        matches.add(ayahNum);
      }
    }

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching ayahs found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match count header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            '${matches.length} result${matches.length == 1 ? '' : 's'} found',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Matching ayahs list
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ayahNumber = matches[index];
              // When tajweed is on, always use standard text.
              final usePua = isUthmanic && !settings.tajweedEnabled;
              final arabicText = usePua
                  ? arabicGlyphAyahs['$ayahNumber']
                  : arabicStandardAyahs['$ayahNumber'];
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
                tajweedEnabled: settings.tajweedEnabled,
                onBookmarkToggle: () {
                  bookmarkService.toggleBookmark(
                    Bookmark.quran(
                      surahId: widget.surahId,
                      ayah: ayahNumber,
                      surahName: chapterMeta.nameSimple,
                      snippet: englishText,
                    ),
                  );
                },
                isMeccan: chapterMeta.isMeccan,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable list of ayah cards, optionally preceded
  /// by a Bismillah header.
  Widget _buildAyahList(
    BuildContext context,
    ChapterMeta chapterMeta,
    Map<String, String> arabicGlyphAyahs,
    Map<String, String> englishAyahs,
    Map<String, String> arabicStandardAyahs,
  ) {
    final totalAyahs = chapterMeta.versesCount;

    // Bismillah is shown for all surahs except Al-Fatiha (1)
    // and At-Tawba (9).
    final hasBismillah = widget.surahId != 1 && widget.surahId != 9;

    // Persist last-read position only once.
    if (!_hasPersistedLastRead) {
      _hasPersistedLastRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        BookmarkScope.of(context).saveLastReadQuran(
          surahId: widget.surahId,
          ayah: widget.scrollToAyah ?? 1,
          surahName: chapterMeta.nameSimple,
        );
      });
    }

    // Auto-scroll to the requested ayah only once.
    if (!_hasScrolledToAyah && widget.scrollToAyah != null) {
      _hasScrolledToAyah = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = hasBismillah ? 1 : 0;
        final targetIndex = (widget.scrollToAyah! - 1 + offset).clamp(
          0,
          totalAyahs - 1 + offset,
        );
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
    final isUthmanic = settings.arabicFont == ArabicFontOption.uthmanic;

    // Total items: optional bismillah + ayahs.
    final itemCount = (hasBismillah ? 1 : 0) + totalAyahs;

    return ScrollablePositionedList.separated(
      itemScrollController: _scrollController,
      itemPositionsListener: _positionsListener,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        // First item: Bismillah header (if applicable).
        if (hasBismillah && index == 0) {
          return _BismillahHeader(arabicZoom: settings.arabicZoom);
        }

        // Normal ayah card.
        final ayahIndex = index - (hasBismillah ? 1 : 0);
        final ayahNumber = ayahIndex + 1;
        // When tajweed is enabled, always use standard Uthmanic text
        // (parseable Arabic with full tashkeel). When tajweed is off,
        // KFGQPC uses PUA glyph text for its optimised rendering.
        final usePua = isUthmanic && !settings.tajweedEnabled;
        final arabicText = usePua
            ? arabicGlyphAyahs['$ayahNumber']
            : arabicStandardAyahs['$ayahNumber'];
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
          tajweedEnabled: settings.tajweedEnabled,
          onBookmarkToggle: () {
            bookmarkService.toggleBookmark(
              Bookmark.quran(
                surahId: widget.surahId,
                ayah: ayahNumber,
                surahName: chapterMeta.nameSimple,
                snippet: englishText,
              ),
            );
          },
          isMeccan: chapterMeta.isMeccan,
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
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
  final bool tajweedEnabled;
  final VoidCallback onBookmarkToggle;
  final bool isMeccan;

  const _AyahCard({
    required this.ayahNumber,
    this.arabic,
    this.english,
    required this.arabicZoom,
    required this.englishZoom,
    required this.isBookmarked,
    this.tajweedEnabled = true,
    required this.onBookmarkToggle,
    required this.isMeccan,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Subtle Makki/Madani accent backgrounds to mirror the Quran list cards.
    const makkiBg = Color(0xFFFFF7EC); // light warm parchment
    const madaniBg = Color(0xFFE9F6F1); // light cool green

    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.surface
        : (isMeccan ? makkiBg : madaniBg);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
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
                tajweed: tajweedEnabled,
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
                  fontFamilyFallback: const ['Arial', 'sans-serif'],
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

// ────────────────────────────────────────────────────────────────
//  Surah info header with Makki/Madani image background
// ────────────────────────────────────────────────────────────────

/// Builds a visually rich header card for the surah info modal.
/// Uses a Kaaba image for Makki surahs and a Masjid Nabawi image
/// for Madani surahs as a subtle background overlay. Shows the
/// surah number in a modern circular badge under the name.
Widget _buildSurahInfoHeader(BuildContext context, ChapterMeta chapter) {
  final theme = Theme.of(context);
  final isMakki = chapter.revelationType == 'Meccan';

  // Colour schemes for Makki (warm amber) vs Madani (cool green).
  final bgGradient = isMakki
      ? const [Color(0xFF4A3728), Color(0xFF2C1E12)]
      : const [Color(0xFF1B3A2E), Color(0xFF0E2218)];
  final accentColor = isMakki
      ? const Color(0xFFD4A054)
      : const Color(0xFF4CAF7D);
  const textColor = Color(0xFFF5F0E8);

  final imagePath = isMakki
      ? 'assets/images/kaaba_makki.png'
      : 'assets/images/masjid_nabawi_madani.png';

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
      ),
      child: Stack(
        children: [
          // Full-coverage background image.
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),

          // Content.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arabic name (vowelled when available).
                Text(
                  chapter.nameArabicVowelled ?? chapter.nameArabic,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'KFGQPCQuranicFontHafsSmart',
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),

                // English name.
                Text(
                  chapter.nameSimple,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),

                // Surah number in a modern circular badge.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${chapter.id}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${chapter.versesCount} Ayahs',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────
//  Surah info HTML parsing helpers
// ────────────────────────────────────────────────────────────────

/// Parsed section from the surah info HTML.
class _InfoSection {
  final String heading;
  final String body;
  const _InfoSection(this.heading, this.body);
}

/// Strips HTML tags from [html] and returns clean text with
/// paragraph breaks preserved.
String _stripHtml(String html) {
  // Replace block-level tags with newlines.
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'</p>'), '\n\n')
      .replaceAll(RegExp(r'</li>'), '\n')
      .replaceAll(RegExp(r'</h[1-6]>'), '\n\n')
      .replaceAll(RegExp(r'<li[^>]*>'), '  • ');
  // Remove all remaining tags.
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  // Collapse multiple newlines and trim.
  text = text
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
  return text;
}

/// Parses the quran.com surah info HTML into a list of sections
/// split at `<h2>` headings.
List<_InfoSection> _parseHtmlSections(String html) {
  if (html.isEmpty) return const [];

  final sections = <_InfoSection>[];
  // Split by <h2> tags.
  final parts = html.split(RegExp(r'<h2[^>]*>'));

  for (int i = 1; i < parts.length; i++) {
    final part = parts[i];
    final endTag = part.indexOf('</h2>');
    if (endTag < 0) continue;

    final heading = _stripHtml(part.substring(0, endTag)).trim();
    final body = _stripHtml(part.substring(endTag + 5)).trim();

    if (heading.isNotEmpty && body.isNotEmpty) {
      sections.add(_InfoSection(heading, body));
    }
  }

  // If no <h2> tags found, use the whole text as one section.
  if (sections.isEmpty && html.isNotEmpty) {
    final body = _stripHtml(html).trim();
    if (body.isNotEmpty) {
      sections.add(_InfoSection('Overview', body));
    }
  }

  return sections;
}

/// Builds a single section card with heading and body.
Widget _buildInfoSection(BuildContext context, String heading, String body) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading with decorative accent.
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                heading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Section body.
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.7,
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    ),
  );
}

/// Single tappable title in the app bar. Cycles: Arabic → English → Meaning → Revelation.
class _CyclingSurahTitle extends StatelessWidget {
  const _CyclingSurahTitle({
    required this.chapter,
    required this.cycleIndex,
    required this.onTap,
  });

  final ChapterMeta chapter;
  final int cycleIndex;
  final VoidCallback onTap;

  static const _makkiAccent = Color(0xFFD4A054);
  static const _madaniAccent = Color(0xFF4CAF7D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMeccan = chapter.isMeccan;
    final accent = isMeccan ? _makkiAccent : _madaniAccent;
    final outline = accent.withValues(alpha: 0.4);
    final fill = accent.withValues(alpha: 0.08);

    final content = _buildContent(context, theme, accent);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: outline, width: 1.2),
              color: fill,
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, Color accent) {
    switch (cycleIndex % 4) {
      case 0:
        // Tarteel QUL surah-name-v4 font: ligatures surah001–surah114 render calligraphic Arabic names.
        final ligature = 'surah${chapter.id.toString().padLeft(3, '0')}';
        return Text(
          ligature,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'SurahNameV4',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: accent,
            height: 1.3,
          ),
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 1:
        return Text(
          chapter.nameSimple,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: accent,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 2:
        final meaning = chapter.nameTranslated ?? '—';
        return Text(
          meaning,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: accent.withValues(alpha: 0.95),
            fontStyle: FontStyle.italic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 3:
        final place = chapter.isMeccan ? 'Meccan' : 'Medinan';
        return Text(
          place,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: accent,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
