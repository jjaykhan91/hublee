import 'package:flutter/material.dart';
import 'widgets/gradient_tile.dart';

// REAL pages
import 'global_search_page.dart';
import 'surah_list_page.dart';
import 'hadith_collections_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    void openSearch() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
        );
    void openQuran() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SurahListPage()),
        );
    void openHadith() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HadithCollectionsPage()),
        );

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.2,
          colors: [
            cs.surface,
            Color.alphaBlend(Colors.white.withValues(alpha: 0.02), cs.surface),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Hublee'),
          actions: [
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: onToggleTheme,
              icon: const Icon(Icons.brightness_6_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Make the search field a tappable launcher (avoids duplicate FAB)
            GestureDetector(
              onTap: openSearch,
              child: const AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search Qur’an and Hadith',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What would you like to explore?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GradientTile(
              icon: Icons.menu_book_rounded,
              title: 'Qur’an',
              subtitle: 'Read by sūrah • translations • bookmarks',
              onTap: openQuran,
            ),
            const SizedBox(height: 12),
            GradientTile(
              icon: Icons.library_books_rounded,
              title: 'Hadith',
              subtitle: 'Forties, The Nine Books, and more',
              onTap: openHadith,
            ),
          ],
        ),
      ),
    );
  }
}
