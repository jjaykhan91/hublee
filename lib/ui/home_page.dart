/// Landing page shown in the Home tab.
///
/// Displays a search shortcut, "Continue Reading" cards for
/// last-read Quran and Hadith positions, and quick-access tiles
/// for the Quran and Hadith sections.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/bookmark_scope.dart';
import 'widgets/gradient_tile.dart';

/// Home tab content with search, continue-reading, and explore.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          gradient: RadialGradient(
            center: const Alignment(0, -0.9),
            radius: 1.2,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.02),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ── Search shortcut ──────────────────────────────
            GestureDetector(
              onTap: () => context.push('/search'),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Search Quran and Hadith',
                    suffixIcon: Icon(
                      Icons.arrow_forward_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
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
                  context.push(
                    '/quran/${lastRead['surahId']}'
                    '?ayah=${lastRead['ayah']}',
                  );
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
                  context.push(
                    '/hadith/${lastRead['collectionId']}'
                    '/${lastRead['bookFile']}'
                    '?title=${Uri.encodeComponent(lastRead['bookTitle'] ?? '')}'
                    '&index=${lastRead['hadithIndex']}',
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // ── Explore section ──────────────────────────────
            if (bookmarkService.lastReadQuran != null ||
                bookmarkService.lastReadHadith != null)
              const SizedBox(height: 8),

            Text(
              'Explore',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),

            GradientTile(
              icon: Icons.menu_book_rounded,
              title: 'Quran',
              subtitle: 'Read by surah with translations and tajweed',
              onTap: () => context.go('/quran'),
            ),
            const SizedBox(height: 12),
            GradientTile(
              icon: Icons.library_books_rounded,
              title: 'Hadith',
              subtitle: 'Forties, The Nine Books, and more',
              onTap: () => context.go('/hadith'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact card that shows the user's last-read position and
/// allows one-tap navigation back to that spot.
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Label + detail text
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
        ),
      ),
    );
  }
}
