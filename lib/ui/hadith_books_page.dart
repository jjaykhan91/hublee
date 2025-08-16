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

              return _BookTile(
                title: b.title, // human title from index.json
                subtitle: subtitle,
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

class _BookTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _BookTile({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: theme.textTheme.labelSmall),
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
