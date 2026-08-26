/// Hub for Modern Standard Arabic: dictionary and grammar.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../theme/app_tokens.dart';

class ArabicHubPage extends StatelessWidget {
  const ArabicHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Modern Arabic')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Newspaper Arabic (Modern Standard), separate from the Quran '
            'glossary. Dictionary and grammar with roots and verb forms.',
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
        ],
      ),
    );
  }
}
