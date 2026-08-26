/// Learn tab: Quranic and Modern Standard Arabic study, grouped like Hadith.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../theme/app_tokens.dart';

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
            icon: Icons.translate_rounded,
            title: 'English → Arabic',
            subtitle: 'Type an English word and see the Quranic Arabic',
            onTap: () => context.push(AppRoute.dictionary),
          ),
          _LearnTile(
            icon: Icons.school_rounded,
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
            icon: Icons.translate_rounded,
            title: 'MSA dictionary',
            subtitle: 'Type English — water, government, computer',
            onTap: () => context.push(AppRoute.msaDictionary),
          ),
          _LearnTile(
            icon: Icons.menu_book_outlined,
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
