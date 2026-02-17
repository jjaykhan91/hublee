/// Lists all 114 surahs with their number, English name, verse
/// count, and Arabic name.
///
/// Tapping a surah navigates to the full-screen [SurahDetailPage]
/// for reading.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/models.dart';

/// Quran tab: scrollable list of all surahs.
class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = const QuranChaptersRepository();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quran')),
      body: FutureBuilder<List<ChapterMeta>>(
        future: repository.loadChapters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final chapters = snapshot.data ?? const <ChapterMeta>[];

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return _SurahCard(
                chapter: chapter,
                colorScheme: colorScheme,
              );
            },
          );
        },
      ),
    );
  }
}

/// A single surah row with number badge, names, and verse count.
class _SurahCard extends StatelessWidget {
  final ChapterMeta chapter;
  final ColorScheme colorScheme;

  const _SurahCard({
    required this.chapter,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/quran/${chapter.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Surah number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${chapter.id}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              // English name + verse count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.nameSimple,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${chapter.versesCount} ayat',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              // Arabic surah name
              Text(
                chapter.nameArabic,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'KFGQPCQuranicFontHafsSmart',
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
