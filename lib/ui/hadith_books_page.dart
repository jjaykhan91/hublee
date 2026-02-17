/// Lists all books within a hadith collection.
///
/// Shows each book's title, hadith count (if available), and an
/// optional summary blurb for well-known collections like Nawawi's
/// Forty Hadith.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_repository.dart';

/// Displays the books index for a single hadith collection.
class HadithBooksPage extends StatelessWidget {
  /// Directory ID of the collection (e.g. `"forties"`).
  final String collectionId;

  /// Human-readable collection title for the app bar.
  final String title;

  const HadithBooksPage({
    super.key,
    required this.collectionId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final repository = const HadithRepository();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<HadithBookMeta>>(
        future: repository.loadBooksForCollection(collectionId),
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

          final books = snapshot.data ?? const <HadithBookMeta>[];
          if (books.isEmpty) {
            return const Center(
              child: Text('No books found in this collection.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = books[index];

              // Build subtitle from hadith count + filename.
              final subtitleParts = <String>[];
              if (book.length != null) {
                subtitleParts.add('${book.length} hadith');
              }
              final fileBaseName = book.file.split('/').last.split('.').first;
              subtitleParts.add(fileBaseName);
              final subtitle = subtitleParts
                  .where((part) => part.isNotEmpty)
                  .join(' \u2022 ');

              final summary = _lookupBookSummary(
                book.title,
                fileBaseName,
              );

              return _BookTile(
                title: book.title,
                subtitle: subtitle,
                summary: summary,
                onTap: () {
                  context.push(
                    '/hadith/$collectionId/${book.file}'
                    '?title=${Uri.encodeComponent(book.title)}',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Returns a brief description for well-known hadith books.
///
/// Matches by title or file name against known collections.
/// Returns `null` for unrecognised books.
String? _lookupBookSummary(String title, String fileBaseName) {
  final titleLower = title.toLowerCase().trim();
  final fileLower = fileBaseName.toLowerCase().trim();

  const nawawiSummary =
      'Concise foundations of Islam\u2014faith, worship, ethics, '
      'and sincerity. A beloved set of core principles often '
      'memorized and taught worldwide.';
  const qudsiSummary =
      'Forty sacred sayings in which the Prophet \uFDFA narrates '
      'the words of Allah outside the Quran\u2014highlighting '
      'divine mercy, love, justice, and guidance.';
  const waliullahSummary =
      'A practical revivalist selection by Shah Waliullah, '
      'balancing worship, morals, and social conduct\u2014aimed '
      'at everyday practice of the Sunnah.';

  if (titleLower.contains('nawawi')) return nawawiSummary;
  if (titleLower.contains('qudsi')) return qudsiSummary;
  if (titleLower.contains('waliullah') ||
      titleLower.contains('wali allah') ||
      titleLower.contains('shah wali')) {
    return waliullahSummary;
  }
  if (fileLower.contains('nawawi')) return nawawiSummary;
  if (fileLower.contains('qudsi')) return qudsiSummary;
  if (fileLower.contains('wali')) return waliullahSummary;

  return null;
}

/// A list tile for a single hadith book with title, subtitle,
/// optional summary, and a chevron.
class _BookTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? summary;
  final VoidCallback onTap;

  const _BookTile({
    required this.title,
    this.subtitle,
    this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.menu_book_outlined, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    if (summary != null && summary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
