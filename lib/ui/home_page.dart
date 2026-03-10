/// Landing page shown in the Home tab.
///
/// Displays Verse of the Day, Hadith of the Day, a search shortcut,
/// "Continue Reading" cards for last-read positions, and explore tiles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/bookmark_scope.dart';
import '../services/daily_content_service.dart';
import '../services/settings_controller.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/gradient_tile.dart';
import 'widgets/hublee_card.dart';

/// Home tab content with daily content, search, continue-reading.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<DailyVerse> _verseFuture;
  late final Future<DailyHadith> _hadithFuture;

  @override
  void initState() {
    super.initState();
    _verseFuture = DailyContentService.loadVerseOfTheDay();
    _hadithFuture = DailyContentService.loadHadithOfTheDay();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bookmarkService = BookmarkScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hublee'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.06),
                colorScheme.surface,
              ),
              colorScheme.surface,
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.tertiary.withValues(alpha: 0.04),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: ListView(
          padding: AppSpacing.page,
          children: [
            // ── Search shortcut (3D shadow) ─────────────────
            GestureDetector(
              onTap: () => context.push(AppRoute.search),
              child: AbsorbPointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: AppRadius.input,
                    boxShadow: AppShadows.input,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search Quran and Hadith',
                      suffixIcon: Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Verse of the Day ────────────────────────────
            FutureBuilder<DailyVerse>(
              future: _verseFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return _VerseOfTheDayCard(verse: snapshot.data!)
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
            const SizedBox(height: 14),

            // ── Hadith of the Day ───────────────────────────
            FutureBuilder<DailyHadith>(
              future: _hadithFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return _HadithOfTheDayCard(hadith: snapshot.data!)
                    .animate()
                    .fadeIn(
                      duration: 600.ms,
                      delay: 150.ms,
                      curve: Curves.easeOut,
                    )
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 600.ms,
                      delay: 150.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
            const SizedBox(height: 20),

            // ── Continue reading cards ───────────────────────
            if (bookmarkService.lastReadQuran != null) ...[
              _ContinueReadingCard(
                icon: Icons.menu_book_rounded,
                label: 'Continue Quran',
                detail: '${bookmarkService.lastReadQuran!['surahName']}'
                    ' - Ayah '
                    '${bookmarkService.lastReadQuran!['ayah']}',
                onTap: () {
                  final lastRead = bookmarkService.lastReadQuran!;
                  context.push(AppRoute.surah(
                    lastRead['surahId'] as int,
                    ayah: lastRead['ayah'] as int?,
                  ));
                },
              ),
              const SizedBox(height: 10),
            ],
            if (bookmarkService.lastReadHadith != null) ...[
              _ContinueReadingCard(
                icon: Icons.library_books_rounded,
                label: 'Continue Hadith',
                detail: '${bookmarkService.lastReadHadith!['bookTitle']}',
                onTap: () {
                  final lastRead = bookmarkService.lastReadHadith!;
                  context.push(AppRoute.hadithBook(
                    collectionId: lastRead['collectionId'] as String,
                    bookFile: lastRead['bookFile'] as String,
                    bookTitle: lastRead['bookTitle'] as String? ?? '',
                    index: lastRead['hadithIndex'] as int?,
                  ));
                },
              ),
              const SizedBox(height: 10),
            ],

            // ── Explore section ──────────────────────────────
            if (bookmarkService.lastReadQuran != null ||
                bookmarkService.lastReadHadith != null)
              const SizedBox(height: 8),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.14),
                        colorScheme.tertiary.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Explore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
            const SizedBox(height: 12),

            GradientTile(
              icon: Icons.menu_book_rounded,
              title: 'Quran',
              subtitle: 'Read by surah with translations and tajweed',
              onTap: () => context.go(AppRoute.quran),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideY(begin: 0.04, end: 0, duration: 500.ms, delay: 400.ms),
            const SizedBox(height: 12),
            GradientTile(
              icon: Icons.library_books_rounded,
              title: 'Hadith',
              subtitle: 'Forties, The Nine Books, and more',
              onTap: () => context.go(AppRoute.hadith),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .slideY(begin: 0.04, end: 0, duration: 500.ms, delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Verse of the Day card (compact + tappable)
// ────────────────────────────────────────────────────────────────

class _VerseOfTheDayCard extends StatelessWidget {
  final DailyVerse verse;

  const _VerseOfTheDayCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoute.surah(verse.surahId, ayah: verse.ayah)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.featureCard,
          boxShadow: AppShadows.featureCardShadow(const Color(0xFF4338CA)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.badge,
                    boxShadow: AppShadows.badge,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ayah of the Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${verse.surahName} : ${verse.ayah}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arabic text (compact)
            if (verse.arabic.isNotEmpty)
              ArabicText(
                verse.arabic,
                tajweed: false,
                fontSize: 20,
                weight: FontWeight.bold,
                align: TextAlign.center,
                color: Colors.white,
                fontOverride: ArabicFontOption.uthmanic,
              ),
            if (verse.arabic.isNotEmpty) const SizedBox(height: 10),

            // English translation (show full but clamp height)
            if (verse.english.isNotEmpty)
              Text(
                verse.english,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 10),

            // "Tap to read more" footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap to read full surah',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Hadith of the Day card (compact + tappable)
// ────────────────────────────────────────────────────────────────

class _HadithOfTheDayCard extends StatelessWidget {
  final DailyHadith hadith;

  const _HadithOfTheDayCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoute.hadithBook(
        collectionId: hadith.collectionId,
        bookFile: hadith.bookFile,
        bookTitle: hadith.bookTitle,
        index: hadith.hadithIndex,
      )),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.featureCard,
          boxShadow: AppShadows.featureCardShadow(const Color(0xFF047857)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.badge,
                    boxShadow: AppShadows.badge,
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Hadith of the Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hadith.bookTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Narrator (compact)
            if (hadith.narrator != null && hadith.narrator!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hadith.narrator!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Arabic text (compact)
            if (hadith.arabic.isNotEmpty)
              ArabicText(
                hadith.arabic,
                tajweed: false,
                fontSize: 18,
                weight: FontWeight.bold,
                align: TextAlign.center,
                color: Colors.white,
              ),
            if (hadith.arabic.isNotEmpty) const SizedBox(height: 10),

            // English translation (show preview)
            if (hadith.english.isNotEmpty)
              Text(
                hadith.english,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 10),

            // "Tap to read more" footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap to read full hadith',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Continue reading card
// ────────────────────────────────────────────────────────────────

/// A compact card showing the user's last-read position.
class _ContinueReadingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  const _ContinueReadingCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HubleeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.chip,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
