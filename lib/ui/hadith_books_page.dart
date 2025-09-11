import 'package:flutter/material.dart';
import '../hadith/hadith_repository.dart';
import 'hadith_book_page.dart';

class HadithBooksPage extends StatelessWidget {
  final String collectionId; // e.g. 'forties'
  final String title;        // e.g. 'Forties'

  const HadithBooksPage({
    super.key,
    required this.collectionId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final repo = const HadithRepository();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<HadithBookMeta>>(
        future: repo.loadBooksForCollection(collectionId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snap.error}\n\n'
                'Tried: assets/hadith/$collectionId/index.json',
              ),
            );
          }

          final books = snap.data ?? const <HadithBookMeta>[];
          if (books.isEmpty) {
            return const Center(child: Text('No books found in this collection.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = books[i];

              // Subtitle parts: "40 hadith • nawawi40"
              final parts = <String>[];
              if (b.length != null) parts.add('${b.length} hadith');
              final fileBase = b.file.split('/').last.split('.').first;
              parts.add(fileBase);
              final subtitle = parts.where((s) => s.isNotEmpty).join(' • ');

              // Summary: use title first; if not matched, try fileBase as a key.
              final summary = _lookupSummaryFor(b.title, fileBase);

              return _BookTile(
                title: b.title,           // human title from index.json
                subtitle: subtitle,       // e.g., "40 hadith • nawawi40"
                summary: summary,         // short description shown under title
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HadithBookPage(
                        collectionId: collectionId,
                        bookFile: b.file,
                        title: b.title, // pass human title as fallback
                      ),
                    ),
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

/// Short, app-friendly summaries for well-known “Forty Hadith” books.
/// Keys match by either `title` or `fileBase` (e.g., 'nawawi40', 'qudsi40').
String? _lookupSummaryFor(String title, String fileBase) {
  // Normalize for robust matching
  final t = title.toLowerCase().trim();
  final f = fileBase.toLowerCase().trim();

  const nawawi = 'Concise foundations of Islam—faith, worship, ethics, and sincerity. '
      'A beloved set of core principles often memorized and taught worldwide.';
  const qudsi = 'Forty sacred sayings in which the Prophet ﷺ narrates the words of Allah ﷻ '
      'outside the Qur’an—highlighting divine mercy, love, justice, and guidance.';
  const waliullah = 'A practical revivalist selection by Shah Waliullah, balancing worship, '
      'morals, and social conduct—aimed at everyday practice of the Sunnah.';

  // Title-based checks
  if (t.contains('nawawi')) return nawawi;
  if (t.contains('qudsi')) return qudsi;
  if (t.contains('waliullah') || t.contains('wali allah') || t.contains('shah wali')) return waliullah;

  // File-base fallbacks
  if (f.contains('nawawi')) return nawawi;
  if (f.contains('qudsi')) return qudsi;
  if (f.contains('wali')) return waliullah;

  return null; // unknown book -> no summary shown
}

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

    // Styles: keep hierarchy clear and readable on both light/dark.
    final titleStyle   = theme.textTheme.titleMedium;
    final subtitleStyle= theme.textTheme.labelSmall?.copyWith(
  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
    );
    final summaryStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.3,
  color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
      fontWeight: FontWeight.w500,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    // Title
                    Text(title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),

                    // Subtitle (length • fileBase)
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: subtitleStyle),
                    ],

                    // Summary
                    if (summary != null && summary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary!,
                        style: summaryStyle,
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
