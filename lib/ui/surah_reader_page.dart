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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../quran/arabic_fold.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/surah_info_repository.dart';
import '../quran/word_by_word_repository.dart';
import '../quran/models.dart';
import '../quran/sajdah.dart';

import '../services/settings_controller.dart';
import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import '../services/vocab_scope.dart';
import '../services/vocab_service.dart';
import '../services/srs_scope.dart';
import '../services/srs_service.dart';
import '../services/recitation_scope.dart';
import '../services/recitation_service.dart';
import '../theme/app_tokens.dart';

import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/scroll_scrubber.dart';
import 'widgets/quran_reading_guide_sheet.dart';
import 'widgets/word_by_word_arabic_text.dart';
import 'widgets/word_gloss_card.dart';
import 'widgets/passage_actions.dart';
import 'widgets/reading_width.dart';

/// PUA glyph column is only for plain KFGQPC reading. Tajweed and
/// word-by-word need standard Uthmani, so the 4.3 MB mushaf decode
/// can wait until this returns true.
bool surahReaderNeedsGlyphColumn({
  required bool tajweedEnabled,
  required bool wordByWordEnabled,
  required ArabicFontOption font,
}) {
  return font == ArabicFontOption.uthmanic &&
      !tajweedEnabled &&
      !wordByWordEnabled;
}

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

  /// Columns loaded for the current settings. Glyph, emlaey, and
  /// word-by-word are filled only when that path is actually used.
  _SurahReaderData? _data;
  bool _loading = true;
  Object? _loadError;
  int _loadGeneration = 0;

  /// Ensures last-read is saved only once per page visit.
  bool _hasPersistedLastRead = false;

  /// Ensures scroll-to-ayah fires only once.
  bool _hasScrolledToAyah = false;

  Timer? _lastReadTimer;
  BookmarkService? _bookmarks;
  RecitationService? _recitation;
  String? _surahName;
  bool _hasBismillah = false;
  int? _visibleAyah;

  // ── In-surah search state ──────────────────────────────────
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  /// Cycle index for header title: 0=Arabic, 1=English, 2=Meaning, 3=Revelation.
  int _titleCycleIndex = 0;

  // ── Word-by-word state ─────────────────────────────────────
  /// The revealed word, or null when nothing is selected. Only one word is
  /// selected at a time across the whole surah.
  WordByWordSelection? _wordSelection;

  /// Ayah the selected word belongs to, so only that card highlights.
  int? _wordSelectionAyah;

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_onScrollPositions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recitation = RecitationScope.maybeOf(context);
    unawaited(_ensureData());
  }

  /// Loads chapters, translation, and Uthmani always. Glyph, emlaey,
  /// and word-by-word only when the current settings need them.
  Future<void> _ensureData() async {
    final settings = SettingsScope.of(context);
    final needGlyph = surahReaderNeedsGlyphColumn(
      tajweedEnabled: settings.tajweedEnabled,
      wordByWordEnabled: settings.wordByWordEnabled,
      font: settings.arabicFont,
    );
    final needWbw = settings.wordByWordEnabled;
    final needEmlaey = _isSearching;

    final existing = _data;
    final missingCore = existing == null;
    final missingGlyph = needGlyph && existing?.glyph == null;
    final missingWbw = needWbw && existing?.glosses == null;
    final missingEmlaey = needEmlaey && existing?.emlaey == null;
    if (!missingCore && !missingGlyph && !missingWbw && !missingEmlaey) {
      return;
    }

    final generation = ++_loadGeneration;
    if (missingCore && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final arabicRepo = const QuranArabicRepository();
      final chaptersF = const QuranChaptersRepository().loadChapters();
      final englishF = const QuranTranslationRepository().loadClearQuran(
        widget.surahId,
      );
      final uthmaniF = arabicRepo.loadUthmaniStandard(widget.surahId);
      final glyphF = existing?.glyph != null
          ? Future.value(existing!.glyph)
          : (needGlyph ? arabicRepo.loadArabicSurah(widget.surahId) : null);
      final wbwF = existing?.glosses != null
          ? Future.value(existing!.glosses)
          : (needWbw
                ? const WordByWordRepository().loadSurah(widget.surahId)
                : null);
      final emlaeyF = existing?.emlaey != null
          ? Future.value(existing!.emlaey)
          : (needEmlaey
                ? arabicRepo.loadArabicSurah(
                    widget.surahId,
                    useGlyphText: false,
                  )
                : null);

      final chapters = await chaptersF;
      final english = await englishF;
      final uthmani = await uthmaniF;
      final glyph = glyphF == null ? existing?.glyph : await glyphF;
      final glosses = wbwF == null ? existing?.glosses : await wbwF;
      final emlaey = emlaeyF == null ? existing?.emlaey : await emlaeyF;

      if (!mounted || generation != _loadGeneration) return;

      final chapter = chapters.firstWhere((item) => item.id == widget.surahId);
      setState(() {
        _data = _SurahReaderData(
          chapter: chapter,
          english: english,
          uthmani: uthmani,
          glyph: glyph,
          emlaey: emlaey,
          glosses: glosses,
        );
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        if (existing == null) _loading = false;
        _loadError = error;
      });
    }
  }

  void _onScrollPositions() {
    if (!mounted || _isSearching || _surahName == null) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final visible = positions.where(
      (position) =>
          position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
    );
    if (visible.isEmpty) return;
    final top = visible.reduce(
      (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
    );
    var ayahIndex = top.index - (_hasBismillah ? 1 : 0);
    if (ayahIndex < 0) ayahIndex = 0;
    final ayah = ayahIndex + 1;
    if (_visibleAyah == ayah) return;
    _visibleAyah = ayah;
    _scheduleLastRead();
  }

  void _scheduleLastRead() {
    final name = _surahName;
    final ayah = _visibleAyah;
    if (name == null || ayah == null) return;
    _lastReadTimer?.cancel();
    _lastReadTimer = Timer(const Duration(milliseconds: 400), () {
      _bookmarks?.saveLastReadQuran(
        surahId: widget.surahId,
        ayah: ayah,
        surahName: name,
        notify: false,
      );
    });
  }

  /// Reveals [selection] within [ayahNumber], or clears when null.
  void _selectWord(int ayahNumber, WordByWordSelection? selection) {
    setState(() {
      _wordSelection = selection;
      _wordSelectionAyah = selection == null ? null : ayahNumber;
    });
  }

  void _clearWordSelection() {
    if (_wordSelection == null) return;
    setState(() {
      _wordSelection = null;
      _wordSelectionAyah = null;
    });
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScrollPositions);
    _lastReadTimer?.cancel();
    unawaited(_recitation?.stop());
    final name = _surahName;
    final ayah = _visibleAyah ?? widget.scrollToAyah ?? 1;
    if (name != null) {
      _bookmarks?.saveLastReadQuran(
        surahId: widget.surahId,
        ayah: ayah,
        surahName: name,
      );
    }
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
      _wordSelection = null;
      _wordSelectionAyah = null;
    });
    _searchFocusNode.requestFocus();
    unawaited(_ensureData());
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
    final data = _data;
    final chapterMeta = data?.chapter;
    final arabicGlyphAyahs = data?.glyph ?? const <String, String>{};
    final englishAyahs = data?.english ?? const <String, String>{};
    final arabicStandardAyahs = data?.uthmani ?? const <String, String>{};
    final arabicEmlaeyAyahs = data?.emlaey ?? const <String, String>{};
    final wordGlosses = data?.glosses ?? const <int, List<String>>{};
    final isLoading = _loading && data == null;
    final errorMessage = _loadError?.toString();

    return Scaffold(
      appBar: _isSearching
          ? _buildSearchAppBar(context)
          : _buildNormalAppBar(context, chapterMeta),
      body: ConstrainedReadingBody(
        child: () {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${errorMessage ?? 'Could not load surah'}'),
            );
          }

          if (_isSearching && _searchQuery.isNotEmpty) {
            if (data.emlaey == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildSearchResults(
              context,
              chapterMeta!,
              arabicGlyphAyahs,
              englishAyahs,
              arabicStandardAyahs,
              arabicEmlaeyAyahs,
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
                wordGlosses,
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
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: WordGlossCard(
                    selection: _wordSelection,
                    reference: _wordSelectionAyah == null
                        ? null
                        : '${chapterMeta.nameSimple} '
                              '${widget.surahId}:$_wordSelectionAyah',
                    isFavorite:
                        _wordSelection != null &&
                        VocabScope.of(context).isSavedWord(
                          _wordSelection!.arabic,
                          _wordSelection!.gloss,
                        ),
                    onToggleFavorite:
                        _wordSelection == null || _wordSelectionAyah == null
                        ? null
                        : () {
                            final selection = _wordSelection!;
                            final ayah = _wordSelectionAyah!;
                            VocabScope.of(context).toggle(
                              VocabEntry.fromReader(
                                arabic: selection.arabic,
                                gloss: selection.gloss,
                                surahId: widget.surahId,
                                ayah: ayah,
                                surahName: chapterMeta.nameSimple,
                              ),
                            );
                            SrsScope.of(context).ensure(
                              SrsCard(
                                id: SrsCard.cardId(
                                  deck: 'quran',
                                  arabic: selection.arabic,
                                  english: selection.gloss,
                                ),
                                deck: 'quran',
                                arabic: selection.arabic,
                                english: selection.gloss,
                                due: DateTime.now(),
                              ),
                            );
                          },
                    onDismiss: _clearWordSelection,
                  ),
                ),
              ),
            ],
          );
        }(),
      ),
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
              );
            },
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Quran reading & Tajweed guide',
          onPressed: () => showQuranReadingGuideSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search in this surah',
          onPressed: _openSearch,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Reader settings',
          onPressed: () =>
              showReaderSettingsSheet(context, showTajweedToggle: true),
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
    Map<String, String> arabicEmlaeyAyahs,
  ) {
    final queryLower = _searchQuery.toLowerCase();
    final settings = SettingsScope.of(context);
    final bookmarkService = BookmarkScope.of(context);

    final queryFolded = foldArabicForSearch(_searchQuery);
    final matches = <int>[];
    for (var ayahNum = 1; ayahNum <= chapterMeta.versesCount; ayahNum++) {
      final arabic = arabicEmlaeyAyahs['$ayahNum'] ?? '';
      final english = englishAyahs['$ayahNum'] ?? '';
      if ((queryFolded.isNotEmpty &&
              foldArabicForSearch(arabic).contains(queryFolded)) ||
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
              final usePua = surahReaderNeedsGlyphColumn(
                tajweedEnabled: settings.tajweedEnabled,
                wordByWordEnabled: false,
                font: settings.arabicFont,
              );
              final arabicText = usePua
                  ? (arabicGlyphAyahs['$ayahNumber'] ??
                        arabicStandardAyahs['$ayahNumber'])
                  : arabicStandardAyahs['$ayahNumber'];
              final englishText = englishAyahs['$ayahNumber'];
              final bookmarkId = 'quran:${widget.surahId}:$ayahNumber';
              final isBookmarked = bookmarkService.isBookmarked(bookmarkId);

              return RepaintBoundary(
                child: _AyahCard(
                  ayahNumber: ayahNumber,
                  arabic: arabicText,
                  english: englishText,
                  arabicZoom: settings.arabicZoom,
                  englishZoom: settings.englishZoom,
                  isBookmarked: isBookmarked,
                  tajweedEnabled: settings.tajweedEnabled,
                  // Search results stay plain: the gloss card belongs to the
                  // reading view, and tapping words while filtering competes
                  // with tapping a result.
                  onWordSelected: (_) {},
                  onBookmarkToggle: () {
                    AppHaptics.lightImpact();
                    bookmarkService.toggleBookmark(
                      Bookmark.quran(
                        surahId: widget.surahId,
                        ayah: ayahNumber,
                        surahName: chapterMeta.nameSimple,
                        snippet: englishText,
                      ),
                    );
                  },
                  surahId: widget.surahId,
                  surahName: chapterMeta.nameSimple,
                  showTranslation: settings.showTranslation,
                  isSajdah:
                      isSajdahAyah(widget.surahId, ayahNumber) ||
                      hasSajdahMarker(arabicText),
                ),
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
    Map<int, List<String>> wordGlosses,
  ) {
    final totalAyahs = chapterMeta.versesCount;

    // Bismillah is shown for all surahs except Al-Fatiha (1)
    // and At-Tawba (9).
    final hasBismillah = widget.surahId != 1 && widget.surahId != 9;
    _hasBismillah = hasBismillah;
    _surahName = chapterMeta.nameSimple;
    _visibleAyah ??= widget.scrollToAyah ?? 1;
    _bookmarks = BookmarkScope.of(context);

    if (!_hasPersistedLastRead) {
      _hasPersistedLastRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bookmarks?.saveLastReadQuran(
          surahId: widget.surahId,
          ayah: _visibleAyah ?? 1,
          surahName: chapterMeta.nameSimple,
          notify: false,
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

    // Total items: optional bismillah + ayahs.
    final itemCount = (hasBismillah ? 1 : 0) + totalAyahs;

    return ScrollablePositionedList.separated(
      itemScrollController: _scrollController,
      itemPositionsListener: _positionsListener,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, ScrollScrubber.gutter, 24),
      minCacheExtent: AppSpacing.cacheExtent,
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
        // Word-by-word glosses are aligned to the standard Uthmanic text, and
        // tajweed needs parseable Arabic, so either feature rules out the PUA
        // glyph column. It is only used for plain KFGQPC reading.
        final wordByWord = settings.wordByWordEnabled;
        final usePua = surahReaderNeedsGlyphColumn(
          tajweedEnabled: settings.tajweedEnabled,
          wordByWordEnabled: wordByWord,
          font: settings.arabicFont,
        );
        final arabicText = usePua
            ? (arabicGlyphAyahs['$ayahNumber'] ??
                  arabicStandardAyahs['$ayahNumber'])
            : arabicStandardAyahs['$ayahNumber'];
        final englishText = englishAyahs['$ayahNumber'];
        final bookmarkId = 'quran:${widget.surahId}:$ayahNumber';
        final isBookmarked = bookmarkService.isBookmarked(bookmarkId);

        return RepaintBoundary(
          child: _AyahCard(
            ayahNumber: ayahNumber,
            arabic: arabicText,
            english: englishText,
            arabicZoom: settings.arabicZoom,
            englishZoom: settings.englishZoom,
            isBookmarked: isBookmarked,
            tajweedEnabled: settings.tajweedEnabled,
            glosses: wordByWord ? wordGlosses[ayahNumber] : null,
            selection: _wordSelectionAyah == ayahNumber ? _wordSelection : null,
            onWordSelected: (selection) => _selectWord(ayahNumber, selection),
            onBookmarkToggle: () {
              AppHaptics.lightImpact();
              bookmarkService.toggleBookmark(
                Bookmark.quran(
                  surahId: widget.surahId,
                  ayah: ayahNumber,
                  surahName: chapterMeta.nameSimple,
                  snippet: englishText,
                ),
              );
            },
            surahId: widget.surahId,
            surahName: chapterMeta.nameSimple,
            showTranslation: settings.showTranslation,
            isSajdah:
                isSajdahAyah(widget.surahId, ayahNumber) ||
                hasSajdahMarker(arabicText),
          ),
        );
      },
    );
  }
}

class _SurahReaderData {
  const _SurahReaderData({
    required this.chapter,
    required this.english,
    required this.uthmani,
    this.glyph,
    this.emlaey,
    this.glosses,
  });

  final ChapterMeta chapter;
  final Map<String, String> english;
  final Map<String, String> uthmani;
  final Map<String, String>? glyph;
  final Map<String, String>? emlaey;
  final Map<int, List<String>>? glosses;
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
/// with tajweed, English translation, bookmark, and copy/share.
class _AyahCard extends StatelessWidget {
  final int ayahNumber;
  final String? arabic;
  final String? english;
  final double arabicZoom;
  final double englishZoom;
  final bool isBookmarked;
  final bool tajweedEnabled;
  final VoidCallback onBookmarkToggle;
  final int surahId;
  final String surahName;
  final bool showTranslation;
  final bool isSajdah;

  /// One gloss per word, or null when word-by-word is off for this card.
  final List<String>? glosses;

  /// The revealed word when it belongs to this ayah.
  final WordByWordSelection? selection;

  final ValueChanged<WordByWordSelection?> onWordSelected;

  const _AyahCard({
    required this.ayahNumber,
    this.arabic,
    this.english,
    required this.arabicZoom,
    required this.englishZoom,
    required this.isBookmarked,
    this.tajweedEnabled = true,
    required this.onBookmarkToggle,
    required this.surahId,
    required this.surahName,
    required this.showTranslation,
    required this.isSajdah,
    required this.onWordSelected,
    this.glosses,
    this.selection,
  });

  String get _reference => '$surahName $surahId:$ayahNumber';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => showPassageActionsSheet(
          context,
          reference: _reference,
          arabic: arabic,
          english: english,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  if (isSajdah) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Prostration is recommended',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sajdah \u06E9',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (RecitationScope.maybeOf(context) != null)
                    _AyahPlayButton(surahId: surahId, ayahNumber: ayahNumber),
                  PassageActionsButton(
                    reference: _reference,
                    arabic: arabic,
                    english: english,
                  ),
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
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (arabic != null && arabic!.isNotEmpty)
                if (glosses case final wordGlosses?)
                  WordByWordArabicText(
                    text: arabic!,
                    glosses: wordGlosses,
                    tajweed: tajweedEnabled,
                    fontSize: 34 * arabicZoom,
                    weight: FontWeight.bold,
                    selectedPhrase: selection?.phrase,
                    onPhraseSelected: onWordSelected,
                  )
                else
                  ArabicText(
                    arabic!,
                    tajweed: tajweedEnabled,
                    fontSize: 34 * arabicZoom,
                    weight: FontWeight.bold,
                  ),
              if (arabic != null && arabic!.isNotEmpty)
                const SizedBox(height: 20),
              if (showTranslation &&
                  english != null &&
                  english!.isNotEmpty) ...[
                Text(
                  english!,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 17 * englishZoom,
                    height: 1.5,
                    letterSpacing: 0.1,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ClearQuran',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahPlayButton extends StatelessWidget {
  const _AyahPlayButton({required this.surahId, required this.ayahNumber});

  final int surahId;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final recitation = RecitationScope.maybeOf(context);
    if (recitation == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: recitation,
      builder: (context, _) {
        final playing = recitation.isPlayingPassage(surahId, ayahNumber);
        return IconButton(
          tooltip: playing ? 'Pause recitation' : 'Play recitation',
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 22,
          ),
          onPressed: () async {
            final error = await recitation.toggle(
              surahId: surahId,
              ayah: ayahNumber,
            );
            if (error == null || !context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          },
        );
      },
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
                      width: AppSpacing.minTouchTarget,
                      height: AppSpacing.minTouchTarget,
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
        return Semantics(
          label: 'Surah ${chapter.id}, ${chapter.nameSimple}',
          child: ExcludeSemantics(
            child: Text(
              ligature,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppFonts.surahName,
                fontWeight: FontWeight.w600,
                fontSize: 24,
                color: accent,
                height: 1.3,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
