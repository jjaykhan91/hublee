/// Hub for Modern Standard Arabic: dictionary, grammar, reviews.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/srs_scope.dart';
import '../theme/app_tokens.dart';

class ArabicHubPage extends StatelessWidget {
  const ArabicHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = SrsScope.of(context).dueCount(deck: 'msa');

    return Scaffold(
      appBar: AppBar(title: const Text('Modern Arabic')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Newspaper Arabic (Modern Standard), separate from the Quran '
            'glossary. Dictionary, grammar with roots and verb forms, '
            'and spaced-repetition reviews.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: const Text('MSA dictionary'),
              subtitle: const Text(
                'Type English — water, government, computer',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoute.msaDictionary),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Grammar course'),
              subtitle: const Text(
                'Roots, forms I–X, article, verbs, questions',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoute.grammar),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.school_rounded),
              title: const Text('Spaced repetition'),
              subtitle: Text(
                due == 0
                    ? 'Star words in the MSA dictionary, then review here'
                    : '$due card${due == 1 ? '' : 's'} due',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoute.arabicReview),
            ),
          ),
        ],
      ),
    );
  }
}
