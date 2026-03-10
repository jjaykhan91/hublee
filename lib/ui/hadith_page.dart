/// Hadith tab: shows all books from all collections in a single
/// scrollable list, grouped by collection with section headers.
///
/// Tapping a book navigates directly to the [HadithReaderPage].
/// No intermediate collections grid — the user sees all available
/// books immediately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_repository.dart';
import '../router_paths.dart';

/// Main Hadith tab displaying all hadith books grouped by
/// collection.
class HadithPage extends StatefulWidget {
  const HadithPage({super.key});

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  /// Cached future to avoid re-fetching on rebuild.
  late final Future<List<_CollectionWithBooks>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllBooks();
  }

  /// Loads all collections and their books in one pass.
  Future<List<_CollectionWithBooks>> _loadAllBooks() async {
    final repository = const HadithRepository();
    final collections = await repository.loadCollections();
    final results = <_CollectionWithBooks>[];

    for (final collection in collections) {
      try {
        final books = await repository.loadBooksForCollection(
          collection.id,
        );
        results.add(_CollectionWithBooks(
          collection: collection,
          books: books,
        ));
      } catch (_) {
        // Skip collections with missing index files.
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hadith')),
      body: FutureBuilder<List<_CollectionWithBooks>>(
        future: _dataFuture,
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

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(
              child: Text('No hadith books found.'),
            );
          }

          return _buildBookList(context, groups);
        },
      ),
    );
  }

  /// Builds a single flat list with collection headers and book
  /// tiles.
  Widget _buildBookList(
    BuildContext context,
    List<_CollectionWithBooks> groups,
  ) {
    // Build a flat list of widgets: header + books per group.
    final items = <Widget>[];
    var animIndex = 0;
    for (final group in groups) {
      items.add(_CollectionHeader(
        title: group.collection.title,
        bookCount: group.books.length,
      ));
      for (final book in group.books) {
        final delay = (30 * animIndex).clamp(0, 600);
        items.add(
          _BookTile(
            book: book,
            collectionId: group.collection.id,
          ).animate().fadeIn(duration: 400.ms, delay: delay.ms).slideX(
                begin: 0.03,
                end: 0,
                duration: 400.ms,
                delay: delay.ms,
                curve: Curves.easeOut,
              ),
        );
        animIndex++;
      }
      items.add(const SizedBox(height: 8));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: items,
    );
  }
}

/// Groups a collection with its resolved book list.
class _CollectionWithBooks {
  final HadithCollectionMeta collection;
  final List<HadithBookMeta> books;

  const _CollectionWithBooks({
    required this.collection,
    required this.books,
  });
}

/// Section header for a hadith collection group.
class _CollectionHeader extends StatelessWidget {
  final String title;
  final int bookCount;

  const _CollectionHeader({
    required this.title,
    required this.bookCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.tertiary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.collections_bookmark_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
              ),
              Text(
                '$bookCount books',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single hadith book tile with title, subtitle, optional
/// summary, and navigation.
class _BookTile extends StatelessWidget {
  final HadithBookMeta book;
  final String collectionId;

  const _BookTile({
    required this.book,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build subtitle from hadith count + filename.
    final subtitleParts = <String>[];
    if (book.length != null) {
      subtitleParts.add('${book.length} hadith');
    }
    final fileBaseName = book.file.split('/').last.split('.').first;
    subtitleParts.add(fileBaseName);
    final subtitle =
        subtitleParts.where((part) => part.isNotEmpty).join(' \u2022 ');

    final summary = _lookupBookSummary(book.title, fileBaseName);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(AppRoute.hadithBook(
            collectionId: collectionId,
            bookFile: book.file,
            bookTitle: book.title,
          ));
        },
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
                      book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary,
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

/// Returns a brief description for well-known hadith books.
///
/// Covers all 17 books bundled in the app: 3 Forties collections,
/// 5 "Other Books", and the 9 canonical collections.
String? _lookupBookSummary(String title, String fileBaseName) {
  final titleLower = title.toLowerCase().trim();
  final fileLower = fileBaseName.toLowerCase().trim();

  // ── Forties (3) ─────────────────────────────────────────────
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

  // ── Other Books (5) ─────────────────────────────────────────
  const adabAlMufradSummary =
      'Imam al-Bukhari\u2019s dedicated compilation on Islamic '
      'manners, etiquette, and social conduct\u2014covering '
      'kindness to neighbours, parents, guests, and animals.';
  const bulughAlMaramSummary =
      'Ibn Hajar al-Asqalani\u2019s concise selection of hadiths '
      'used as legal evidence in Islamic jurisprudence (fiqh). '
      'Essential for students of Islamic law.';
  const mishkatSummary =
      'A comprehensive collection covering all aspects of Islamic '
      'life\u2014worship, transactions, manners, and spirituality '
      '\u2014with hadiths from multiple canonical sources.';
  const riyadSummary =
      'Imam Nawawi\u2019s selection of hadiths for righteous '
      'conduct, organised into chapters on sincerity, patience, '
      'truthfulness, and daily devotions.';
  const shamailSummary =
      'Imam al-Tirmidhi\u2019s renowned description of the '
      'Prophet\u2019s \uFDFA appearance, character, daily habits, '
      'worship, and personal qualities.';

  // ── The 9 Books ─────────────────────────────────────────────
  const bukhariSummary =
      'The most authentic hadith collection in Sunni Islam, '
      'compiled by Imam al-Bukhari with strict chains of '
      'narration. Covers worship, dealings, history, and virtues.';
  const muslimSummary =
      'The second most authentic collection, compiled by Imam '
      'Muslim. Known for its superior arrangement and grouping '
      'of similar narrations together.';
  const abuDawudSummary =
      'Imam Abu Dawud\u2019s collection focused primarily on '
      'hadiths of legal rulings (ahkam)\u2014covering purification, '
      'prayer, fasting, trade, and personal conduct.';
  const tirmidhiSummary =
      'Imam al-Tirmidhi\u2019s collection notable for including '
      'scholarly commentary and grading of each hadith. Covers '
      'faith, worship, virtues, and jurisprudence.';
  const nasaiSummary =
      'Imam al-Nasa\u2019i\u2019s rigorous collection focused on '
      'fiqh-related hadiths, with attention to narrators and '
      'precise chain verification.';
  const ibnMajahSummary =
      'Imam Ibn Majah\u2019s collection covering worship, business, '
      'asceticism, and virtues. Contains some unique hadiths not '
      'found in the other five canonical books.';
  const muwattaSummary =
      'The earliest compiled hadith book by Imam Malik, blending '
      'Prophetic traditions with the practice of the people of '
      'Madinah. Foundation of the Maliki school.';
  const musnadSummary =
      'One of the largest hadith compilations by Imam Ahmad ibn '
      'Hanbal, organised by narrator. An essential reference '
      'containing thousands of unique narrations.';
  const darimiSummary =
      'Imam al-Darimi\u2019s early collection known for its '
      'valuable introductory chapters on seeking knowledge, '
      'following the Sunnah, and Islamic methodology.';

  // ── Matching ────────────────────────────────────────────────
  // Match against title first, then file name.
  for (final key in [titleLower, fileLower]) {
    if (key.contains('nawawi') && !key.contains('riyad')) {
      return nawawiSummary;
    }
    if (key.contains('qudsi')) return qudsiSummary;
    if (key.contains('waliullah') ||
        key.contains('wali allah') ||
        key.contains('shah wali') ||
        key.contains('shahwali')) {
      return waliullahSummary;
    }
    if (key.contains('adab') && key.contains('mufrad')) {
      return adabAlMufradSummary;
    }
    if (key.contains('bulugh') || key.contains('maram')) {
      return bulughAlMaramSummary;
    }
    if (key.contains('mishkat') || key.contains('masabih')) {
      return mishkatSummary;
    }
    if (key.contains('riyad') || key.contains('salihin')) {
      return riyadSummary;
    }
    if (key.contains('shamail') || key.contains('muhammadiyah')) {
      return shamailSummary;
    }
    if (key.contains('bukhari') && !key.contains('adab')) {
      return bukhariSummary;
    }
    if (key.contains('muslim')) return muslimSummary;
    if (key.contains('abu') && key.contains('dawud')) return abuDawudSummary;
    if (key.contains('abudawud')) return abuDawudSummary;
    if (key.contains('tirmidhi')) return tirmidhiSummary;
    if (key.contains('nasa')) return nasaiSummary;
    if (key.contains('ibn') && key.contains('majah')) return ibnMajahSummary;
    if (key.contains('ibnmajah')) return ibnMajahSummary;
    if (key.contains('muwatta') || key.contains('malik')) {
      return muwattaSummary;
    }
    if (key.contains('musnad') || key.contains('ahmad') || key.contains('ahmed')) {
      return musnadSummary;
    }
    if (key.contains('darimi')) return darimiSummary;
  }

  return null;
}
