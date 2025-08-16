import 'package:flutter/material.dart';
import '../hadith/hadith_repository.dart';
import 'hadith_books_page.dart';

class HadithCollectionsPage extends StatelessWidget {
  const HadithCollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = const HadithRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Hadith Collections')),
      body: FutureBuilder<List<HadithCollectionMeta>>(
        future: repo.loadCollections(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}'),
            );
          }

          final collections = snap.data ?? const [];
          if (collections.isEmpty) {
            return const Center(child: Text('No collections found.'));
          }

          final scheme = Theme.of(context).colorScheme;

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            itemCount: collections.length,
            itemBuilder: (context, i) {
              final c = collections[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HadithBooksPage(collectionId: c.id, title: c.title),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.25),
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.collections_bookmark_outlined,
                          size: 28,
                          color: scheme.primary,
                        ),
                        const Spacer(),
                        Text(
                          c.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (c.count != null)
                          Text(
                            '${c.count} books',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
