/// Learn tab: Quranic and Modern Standard Arabic study, grouped like Hadith.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_book_art.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';
import 'widgets/hadith_book_cover.dart';

/// Covers for the Learn tools, in the style of the hadith books.
const _dictionaryArt = BookArt(
  arabicName: 'المعجم',
  arabicTitle: 'معجم القرآن',
  dark: Color(0xFF0C4547),
  light: Color(0xFF17777A),
  pattern: BookPattern.lattice,
);
const _flashcardsArt = BookArt(
  arabicName: 'بطاقات',
  arabicTitle: 'بطاقات الكلمات',
  dark: Color(0xFF503B10),
  light: Color(0xFF8C6A22),
  pattern: BookPattern.stars,
);
const _msaDictionaryArt = BookArt(
  arabicName: 'قاموس',
  arabicTitle: 'قاموس الفصحى',
  dark: Color(0xFF1B253D),
  light: Color(0xFF34466E),
  pattern: BookPattern.diamonds,
);
const _grammarArt = BookArt(
  arabicName: 'النحو',
  arabicTitle: 'النحو والصرف',
  dark: Color(0xFF55172A),
  light: Color(0xFF8A2E45),
  pattern: BookPattern.lattice,
);

/// Bottom-nav Learn page. Detail tools push full-screen above the shell.
class LearnHubPage extends StatelessWidget {
  const LearnHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: AppSpacing.list,
        children: [
          const _SectionHeader(
            icon: Icons.menu_book_rounded,
            title: 'Quranic Arabic',
            subtitle: 'From the word-by-word glossary',
          ),
          _LearnTile(
            art: _dictionaryArt,
            title: 'English → Arabic',
            subtitle: 'Type an English word and see the Quranic Arabic',
            onTap: () => context.push(AppRoute.dictionary),
          ),
          _LearnTile(
            art: _flashcardsArt,
            title: 'Flashcards',
            subtitle: 'Star words while reading, then review them here',
            onTap: () => context.push(AppRoute.learnQuranic),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(
            icon: Icons.language_rounded,
            title: 'Modern Arabic',
            subtitle: 'Newspaper MSA — separate from the Quran glossary',
          ),
          _LearnTile(
            art: _msaDictionaryArt,
            title: 'MSA dictionary',
            subtitle: 'Type English — water, government, computer',
            onTap: () => context.push(AppRoute.msaDictionary),
          ),
          _LearnTile(
            art: _grammarArt,
            title: 'Grammar course',
            subtitle: 'Roots, verb forms I–X, article, pronouns',
            onTap: () => context.push(AppRoute.grammar),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnTile extends StatelessWidget {
  const _LearnTile({
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final BookArt art;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          leading: BookCover(art: art, width: 44, height: 60),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
