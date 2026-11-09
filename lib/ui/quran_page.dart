/// Lists all 114 surahs with grouping views: Surah (default),
/// a 30-day lunar month plan, Makki/Madani, and Revelation Order.
///
/// Each surah card shows its number, English name, verse count,
/// Arabic name, and a Makki/Madani badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/lunar_month_schedule.dart';
import '../quran/models.dart';
import '../router_paths.dart';
import '../services/bookmark_scope.dart';
import '../theme/app_tokens.dart';
import 'widgets/hublee_card.dart';
import 'widgets/lunar_month_sheet.dart';
import 'widgets/quran_overview_sheet.dart';
import 'widgets/surah_bookmarks_sheet.dart';
import 'widgets/quran_reading_guide_sheet.dart';

/// Quran tab: segmented views of all 114 surahs.
class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage>
    with SingleTickerProviderStateMixin {
  late final Future<List<ChapterMeta>> _chaptersFuture;
  late final TabController _tabController;

  static const _tabs = ['Surah', '30 Days', 'Type', 'Revelation'];

  @override
  void initState() {
    super.initState();
    _chaptersFuture = const QuranChaptersRepository().loadChapters();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastRead = BookmarkScope.maybeOf(context)?.lastReadQuran;
    final continueSurah = lastRead?['surahId'];
    final continueAyah = lastRead?['ayah'];
    final showContinue = continueSurah is int && continueAyah is int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About the Quran',
            onPressed: () => showQuranOverviewSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Quran reading & Tajweed guide',
            onPressed: () => showQuranReadingGuideSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (showContinue)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _QuranContinueBanner(lastRead: lastRead!),
            ),
          Expanded(
            child: FutureBuilder<List<ChapterMeta>>(
              future: _chaptersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final chapters = snapshot.data ?? const <ChapterMeta>[];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _SurahListView(
                      chapters: chapters,
                      colorScheme: colorScheme,
                    ),
                    _LunarMonthView(
                      chapters: chapters,
                      colorScheme: colorScheme,
                    ),
                    _MakkiMadaniView(
                      chapters: chapters,
                      colorScheme: colorScheme,
                    ),
                    _RevelationOrderView(
                      chapters: chapters,
                      colorScheme: colorScheme,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Number of cards that get an entry animation.
///
/// Past roughly the first screenful the animation has finished long before the
/// card is scrolled into view, so animating all 114 is work the reader never
/// sees.
const _animatedCardLimit = 25;

const _cardAnimationDuration = Duration(milliseconds: 300);

// ────────────────────────────────────────────────────────────────
//  Tab 1: Flat surah list (default)
// ────────────────────────────────────────────────────────────────

class _SurahListView extends StatefulWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _SurahListView({required this.chapters, required this.colorScheme});

  @override
  State<_SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<_SurahListView>
    with AutomaticKeepAliveClientMixin {
  // Kept alive so switching tabs and coming back preserves scroll position
  // instead of dropping the reader back at Al-Fatiha.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: widget.chapters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final card = _SurahCard(
          chapter: widget.chapters[index],
          colorScheme: widget.colorScheme,
        );
        if (index >= _animatedCardLimit) return card;

        final delay = (30 * index).clamp(0, 480).ms;
        return card
            .animate()
            .fadeIn(duration: _cardAnimationDuration, delay: delay)
            .slideX(
              begin: 0.03,
              end: 0,
              duration: _cardAnimationDuration,
              delay: delay,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 2: The Quran over a lunar month, in whole surahs
// ────────────────────────────────────────────────────────────────

class _LunarMonthView extends StatefulWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _LunarMonthView({required this.chapters, required this.colorScheme});

  @override
  State<_LunarMonthView> createState() => _LunarMonthViewState();
}

class _LunarMonthViewState extends State<_LunarMonthView>
    with AutomaticKeepAliveClientMixin {
  /// Flattened header + card rows, after the intro row at index 0.
  late List<_TypeRow> _rows;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rows = _monthRows(widget.chapters, widget.colorScheme);
  }

  @override
  void didUpdateWidget(_LunarMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.chapters, widget.chapters) ||
        oldWidget.colorScheme != widget.colorScheme) {
      _rows = _monthRows(widget.chapters, widget.colorScheme);
    }
  }

  static List<_TypeRow> _monthRows(
    List<ChapterMeta> chapters,
    ColorScheme colorScheme,
  ) {
    final byId = {for (final chapter in chapters) chapter.id: chapter};
    final opening = byId[lunarOpeningSurah];
    return [
      if (opening != null) ...[
        _TypeHeaderRow(
          icon: Icons.auto_awesome_rounded,
          title: 'Al-Fatihah',
          subtitle: 'The opening, before Day 1',
          color: colorScheme.primary,
        ),
        _TypeCardRow(opening),
      ],
      for (final day in lunarMonthSchedule) ...[
        const _TypeSpacerRow(),
        _TypeHeaderRow(
          icon: day.day == 15
              ? Icons.brightness_1_rounded
              : Icons.nightlight_round,
          title: 'Day ${day.day}',
          subtitle: _daySubtitle(day, byId),
          color: colorScheme.primary,
        ),
        ...day.surahs.map((id) => byId[id]).nonNulls.map(_TypeCardRow.new),
      ],
    ];
  }

  /// "286 ayahs", or "3 surahs · 233 ayahs", then the day's note.
  static String _daySubtitle(LunarReadingDay day, Map<int, ChapterMeta> byId) {
    final ayahs = day.surahs.fold<int>(
      0,
      (sum, id) => sum + (byId[id]?.versesCount ?? 0),
    );
    return [
      if (day.surahs.length > 1) '${day.surahs.length} surahs',
      '$ayahs ayahs',
      ?day.note,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: _rows.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _LunarMonthIntro();
        return switch (_rows[index - 1]) {
          _TypeHeaderRow(
            :final icon,
            :final title,
            :final subtitle,
            :final color,
          ) =>
            _SectionHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              color: color,
            ),
          _TypeCardRow(:final chapter) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SurahCard(
              chapter: chapter,
              colorScheme: widget.colorScheme,
            ),
          ),
          _TypeSpacerRow() => const SizedBox(height: 16),
        };
      },
    );
  }
}

/// Heading for the 30-day plan, with an info button that explains it.
class _LunarMonthIntro extends StatelessWidget {
  const _LunarMonthIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Quran in a lunar month',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Whole surahs each day, from the new crescent',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('lunar-month-info'),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'How the 30-day plan works',
            onPressed: () => showLunarMonthSheet(context),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 3: Makki / Madani
// ────────────────────────────────────────────────────────────────

class _MakkiMadaniView extends StatefulWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _MakkiMadaniView({required this.chapters, required this.colorScheme});

  @override
  State<_MakkiMadaniView> createState() => _MakkiMadaniViewState();
}

class _MakkiMadaniViewState extends State<_MakkiMadaniView>
    with AutomaticKeepAliveClientMixin {
  late List<_TypeRow> _rows;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _partition();
  }

  @override
  void didUpdateWidget(_MakkiMadaniView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.chapters, widget.chapters)) {
      _partition();
    }
  }

  void _partition() {
    final meccan = widget.chapters.where((c) => c.isMeccan).toList();
    final medinan = widget.chapters.where((c) => c.isMedinan).toList();
    _rows = [
      _TypeHeaderRow(
        icon: Icons.mosque_rounded,
        title: 'Meccan (${meccan.length})',
        subtitle: 'Revealed in Mecca',
        color: const Color(0xFFD97706),
      ),
      for (final chapter in meccan) _TypeCardRow(chapter),
      const _TypeSpacerRow(),
      _TypeHeaderRow(
        icon: Icons.account_balance_rounded,
        title: 'Medinan (${medinan.length})',
        subtitle: 'Revealed in Medina',
        color: const Color(0xFF0D9488),
      ),
      for (final chapter in medinan) _TypeCardRow(chapter),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        return switch (_rows[index]) {
          _TypeHeaderRow(
            :final icon,
            :final title,
            :final subtitle,
            :final color,
          ) =>
            _SectionHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              color: color,
            ),
          _TypeCardRow(:final chapter) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SurahCard(
              chapter: chapter,
              colorScheme: widget.colorScheme,
            ),
          ),
          _TypeSpacerRow() => const SizedBox(height: 20),
        };
      },
    );
  }
}

sealed class _TypeRow {
  const _TypeRow();
}

class _TypeHeaderRow extends _TypeRow {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _TypeHeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _TypeCardRow extends _TypeRow {
  final ChapterMeta chapter;

  const _TypeCardRow(this.chapter);
}

class _TypeSpacerRow extends _TypeRow {
  const _TypeSpacerRow();
}

// ────────────────────────────────────────────────────────────────
//  Tab 4: Revelation Order
// ────────────────────────────────────────────────────────────────

class _RevelationOrderView extends StatefulWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _RevelationOrderView({
    required this.chapters,
    required this.colorScheme,
  });

  @override
  State<_RevelationOrderView> createState() => _RevelationOrderViewState();
}

class _RevelationOrderViewState extends State<_RevelationOrderView>
    with AutomaticKeepAliveClientMixin {
  /// Chronological order, sorted once instead of on every build.
  late List<ChapterMeta> _sorted;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sort();
  }

  @override
  void didUpdateWidget(_RevelationOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.chapters, widget.chapters)) {
      _sort();
    }
  }

  void _sort() {
    _sorted = List<ChapterMeta>.from(widget.chapters)
      ..sort((a, b) => a.revelationOrder.compareTo(b.revelationOrder));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: _sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _SurahCard(
        chapter: _sorted[index],
        colorScheme: widget.colorScheme,
        showRevelationOrder: true,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Shared sub-widgets
// ────────────────────────────────────────────────────────────────

/// Section header for grouped views.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single surah card with full-width Kaaba (Makki) or Masjid
/// Nabawi (Madani) background image, colour-coded number badge,
/// and clean text overlay.
class _SurahCard extends StatelessWidget {
  final ChapterMeta chapter;
  final ColorScheme colorScheme;
  final bool showRevelationOrder;

  const _SurahCard({
    required this.chapter,
    required this.colorScheme,
    this.showRevelationOrder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = chapter.isMeccan;

    // Makki = warm amber, Madani = cool green.
    final accentColor = isMeccan
        ? AppColors.meccanAccent
        : AppColors.medinanAccent;
    final bgGradient = isMeccan
        ? AppColors.meccanCardGradient
        : AppColors.medinanCardGradient;
    final imagePath = isMeccan
        ? 'assets/images/kaaba_makki.png'
        : 'assets/images/masjid_nabawi_madani.png';
    const textColor = AppColors.surahCardOnImage;

    final bookmarks = BookmarkScope.maybeOf(context);
    final position = bookmarks?.positionFor(chapter.id);
    final hasProgress = position != null && position > 1;
    final saved = bookmarks?.quranBookmarksIn(chapter.id) ?? const [];
    final semanticsLabel = [
      'Surah ${chapter.id}',
      chapter.nameSimple,
      if (chapter.nameTranslated != null) chapter.nameTranslated!,
      '${chapter.versesCount} ayahs',
      if (isMeccan) 'Meccan' else 'Medinan',
      if (hasProgress) 'stopped at ayah $position',
      if (saved.isNotEmpty) bookmarkCountLabel(saved.length),
    ].join(', ');
    void showSaved() => showSurahBookmarksSheet(context, chapter, saved);

    return Semantics(
      button: true,
      label: semanticsLabel,
      customSemanticsActions: {
        if (saved.isNotEmpty)
          const CustomSemanticsAction(label: 'Show bookmarks'): showSaved,
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.card(context),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // The reader opens where this surah was left.
              onTap: () => context.push(AppRoute.surah(chapter.id)),
              child: ExcludeSemantics(
                child: Container(
                  height: showRevelationOrder
                      ? 96
                      : (chapter.nameTranslated != null ? 88 : 80),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: bgGradient,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Full-width background image.
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                      ),

                      if (hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            key: Key('surah-progress-${chapter.id}'),
                            value: position / chapter.versesCount,
                            minHeight: 3,
                            color: accentColor,
                            backgroundColor: Colors.transparent,
                          ),
                        ),

                      // Content row.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Surah number in modern circular badge (3D shadow).
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: AppSpacing.minTouchTarget,
                                  height: AppSpacing.minTouchTarget,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor,
                                      width: 1.5,
                                    ),
                                    color: accentColor.withValues(alpha: 0.15),
                                    boxShadow: AppShadows.badge,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    showRevelationOrder
                                        ? '${chapter.revelationOrder}'
                                        : '${chapter.id}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: accentColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // English name + translation + ayah count (Quran.com style).
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chapter.nameSimple,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                  ),
                                  if (chapter.nameTranslated != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      chapter.nameTranslated!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: textColor.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                    ),
                                  ],
                                  if (showRevelationOrder) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Surah ${chapter.id}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: textColor.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Calligraphic Arabic surah name (Tarteel surah-name-v4 ligature).
                            Expanded(
                              child: Center(
                                child: ExcludeSemantics(
                                  child: Text(
                                    'surah${chapter.id.toString().padLeft(3, '0')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontFamily: AppFonts.surahName,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ),
                            // Bookmarks, and where reading stopped.
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (saved.isNotEmpty)
                                  _SurahBookmarkChip(
                                    key: Key('surah-bookmarks-${chapter.id}'),
                                    count: saved.length,
                                    color: accentColor,
                                    onTap: showSaved,
                                  ),
                                Text(
                                  hasProgress
                                      ? 'Ayah $position / ${chapter.versesCount}'
                                      : '${chapter.versesCount} Ayahs',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: textColor.withValues(alpha: 0.6),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bookmark count on a surah card; tap to list them.
class _SurahBookmarkChip extends StatelessWidget {
  const _SurahBookmarkChip({
    super.key,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.chip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_rounded, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last-read resume strip on the Quran tab (automatic scroll position).
class _QuranContinueBanner extends StatelessWidget {
  const _QuranContinueBanner({required this.lastRead});

  final Map<String, dynamic> lastRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surahId = lastRead['surahId'] as int;
    final ayah = lastRead['ayah'] as int;
    final name = lastRead['surahName'] as String? ?? 'Surah $surahId';

    return HubleeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push(AppRoute.surah(surahId, ayah: ayah)),
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.chip,
            ),
            child: Icon(Icons.menu_book_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue where you left off',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$name · $surahId:$ayah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
        ],
      ),
    );
  }
}
