/// Lists all 114 surahs with grouping views: Surah (default),
/// Juz, Makki/Madani, and Revelation Order.
///
/// Each surah card shows its number, English name, verse count,
/// Arabic name, and a Makki/Madani badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/models.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';

/// Juz names (commonly used Arabic names for the 30 parts).
const _juzNames = <int, String>{
  1: 'Alif Lam Mim',
  2: 'Sayaqool',
  3: 'Tilkal Rusul',
  4: 'Lan Tanaloo',
  5: 'Wal Muhsanat',
  6: 'La Yuhibbullah',
  7: 'Wa Iza Samiu',
  8: 'Wa Lau Annana',
  9: 'Qalal Malau',
  10: 'Wa A\'lamu',
  11: 'Yatazeroon',
  12: 'Wa Mamin Daabbah',
  13: 'Wa Ma Ubarri\'u',
  14: 'Rubama',
  15: 'Subhanallazi',
  16: 'Qal Alam',
  17: 'Iqtaraba',
  18: 'Qad Aflaha',
  19: 'Wa Qalallazina',
  20: 'Amman Khalaq',
  21: 'Utlu Ma Uhiya',
  22: 'Wa Manyaqnut',
  23: 'Wa Mali',
  24: 'Faman Azlamu',
  25: 'Ilaihi Yuraddu',
  26: 'Ha Mim',
  27: 'Qala Fama Khatbukum',
  28: 'Qad Sami Allah',
  29: 'Tabarakallazi',
  30: 'Amma',
};

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

  static const _tabs = ['Surah', 'Juz', 'Type', 'Revelation'];

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: FutureBuilder<List<ChapterMeta>>(
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
              _SurahListView(chapters: chapters, colorScheme: colorScheme),
              _JuzGroupView(chapters: chapters, colorScheme: colorScheme),
              _MakkiMadaniView(chapters: chapters, colorScheme: colorScheme),
              _RevelationOrderView(
                chapters: chapters,
                colorScheme: colorScheme,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 1: Flat surah list (default)
// ────────────────────────────────────────────────────────────────

class _SurahListView extends StatelessWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _SurahListView({required this.chapters, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: chapters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) =>
          _SurahCard(chapter: chapters[index], colorScheme: colorScheme)
              .animate()
              .fadeIn(duration: 400.ms, delay: (30 * index).clamp(0, 600).ms)
              .slideX(
                begin: 0.03,
                end: 0,
                duration: 400.ms,
                delay: (30 * index).clamp(0, 600).ms,
                curve: Curves.easeOut,
              ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 2: Grouped by Juz
// ────────────────────────────────────────────────────────────────

class _JuzGroupView extends StatelessWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _JuzGroupView({required this.chapters, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    // Build juz -> list of surahs mapping.
    final juzMap = <int, List<ChapterMeta>>{};
    for (final chapter in chapters) {
      for (var juz = chapter.startJuz; juz <= chapter.endJuz; juz++) {
        juzMap.putIfAbsent(juz, () => []);
        // Avoid duplicates if a surah spans multiple juz.
        if (!juzMap[juz]!.any((c) => c.id == chapter.id)) {
          juzMap[juz]!.add(chapter);
        }
      }
    }
    final sortedJuzKeys = juzMap.keys.toList()..sort();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: sortedJuzKeys.length,
      itemBuilder: (context, index) {
        final juzNumber = sortedJuzKeys[index];
        final juzChapters = juzMap[juzNumber]!;
        final juzName = _juzNames[juzNumber] ?? 'Juz $juzNumber';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.auto_stories_rounded,
              title: 'Juz $juzNumber',
              subtitle: juzName,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 6),
            ...juzChapters.map(
              (chapter) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SurahCard(chapter: chapter, colorScheme: colorScheme),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 3: Makki / Madani
// ────────────────────────────────────────────────────────────────

class _MakkiMadaniView extends StatelessWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _MakkiMadaniView({required this.chapters, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final meccan = chapters.where((c) => c.isMeccan).toList();
    final medinan = chapters.where((c) => c.isMedinan).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _SectionHeader(
          icon: Icons.mosque_rounded,
          title: 'Meccan (${meccan.length})',
          subtitle: 'Revealed in Mecca',
          color: const Color(0xFFD97706),
        ),
        const SizedBox(height: 6),
        ...meccan.map(
          (chapter) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SurahCard(chapter: chapter, colorScheme: colorScheme),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.account_balance_rounded,
          title: 'Medinan (${medinan.length})',
          subtitle: 'Revealed in Medina',
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(height: 6),
        ...medinan.map(
          (chapter) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SurahCard(chapter: chapter, colorScheme: colorScheme),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Tab 4: Revelation Order
// ────────────────────────────────────────────────────────────────

class _RevelationOrderView extends StatelessWidget {
  final List<ChapterMeta> chapters;
  final ColorScheme colorScheme;

  const _RevelationOrderView({
    required this.chapters,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<ChapterMeta>.from(chapters)
      ..sort((a, b) => a.revelationOrder.compareTo(b.revelationOrder));

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final chapter = sorted[index];
        return _SurahCard(
          chapter: chapter,
          colorScheme: colorScheme,
          showRevelationOrder: true,
        );
      },
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
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
        ? const Color(0xFFD4A054)
        : const Color(0xFF4CAF7D);
    final bgGradient = isMeccan
        ? const [Color(0xFF3D2E1E), Color(0xFF2A1F14)]
        : const [Color(0xFF1A3529), Color(0xFF0F211A)];
    final imagePath = isMeccan
        ? 'assets/images/kaaba_makki.png'
        : 'assets/images/masjid_nabawi_madani.png';
    const textColor = Color(0xFFF5F0E8);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.card(context),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoute.surah(chapter.id)),
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
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.asset(imagePath, fit: BoxFit.cover),
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 1.5),
                            color: accentColor.withValues(alpha: 0.15),
                            boxShadow: AppShadows.badge,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            showRevelationOrder
                                ? '${chapter.revelationOrder}'
                                : '${chapter.id}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                              ),
                              if (chapter.nameTranslated != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  chapter.nameTranslated!,
                                  style: Theme.of(context).textTheme.labelSmall
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
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: textColor.withValues(alpha: 0.4),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Calligraphic Arabic surah name (Tarteel surah-name-v4 ligature).
                        Expanded(
                          child: Center(
                            child: Text(
                              'surah${chapter.id.toString().padLeft(3, '0')}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontFamily: 'SurahNameV4',
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                        // Ayah count to the right.
                        Text(
                          '${chapter.versesCount} Ayahs',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: textColor.withValues(alpha: 0.6),
                              ),
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
    );
  }
}
