/// Grid of available hadith collections (e.g. Forties, The Nine
/// Books, Other Books).
///
/// Each card shows the collection title and book count, and
/// navigates to [HadithBooksPage] when tapped.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_repository.dart';

/// Hadith tab: displays a responsive grid of collection cards.
class HadithCollectionsPage extends StatelessWidget {
  const HadithCollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = const HadithRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Hadith')),
      body: FutureBuilder<List<HadithCollectionMeta>>(
        future: repository.loadCollections(),
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

          final collections = snapshot.data ?? const [];
          if (collections.isEmpty) {
            return const Center(
              child: Text('No collections found.'),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;

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
            itemBuilder: (context, index) {
              final collection = collections[index];
              return _CollectionCard(
                collection: collection,
                colorScheme: colorScheme,
              );
            },
          );
        },
      ),
    );
  }
}

/// A single collection card with gradient background, icon,
/// title, and optional book count.
class _CollectionCard extends StatelessWidget {
  final HadithCollectionMeta collection;
  final ColorScheme colorScheme;

  const _CollectionCard({
    required this.collection,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.push(
            '/hadith/${collection.id}'
            '?title=${Uri.encodeComponent(collection.title)}',
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
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
                color: colorScheme.primary,
              ),
              const Spacer(),
              Text(
                collection.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (collection.count != null)
                Text(
                  '${collection.count} books',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
