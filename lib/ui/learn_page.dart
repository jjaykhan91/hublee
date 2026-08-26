/// Flashcards for starred Quranic words, or a frequent-word starter deck.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/quran_dictionary_service.dart';
import '../services/vocab_scope.dart';
import '../services/vocab_service.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';

/// Review saved words, or start from the most common Quranic vocabulary.
class LearnPage extends StatefulWidget {
  const LearnPage({
    super.key,
    this.dictionary = const QuranDictionaryService(),
  });

  final QuranDictionaryService dictionary;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  List<_CardItem>? _deck;
  int _index = 0;
  bool _revealed = false;
  bool _usingFavorites = true;

  Future<void> _startFavorites(List<VocabEntry> entries) async {
    final deck = [
      for (final entry in entries)
        _CardItem(
          arabic: entry.arabic,
          gloss: entry.gloss,
          surahId: entry.surahId,
          ayah: entry.ayah,
          surahName: entry.surahName,
        ),
    ]..shuffle();
    setState(() {
      _deck = deck;
      _index = 0;
      _revealed = false;
      _usingFavorites = true;
    });
  }

  Future<void> _startFrequent() async {
    final frequent = await widget.dictionary.frequent(limit: 20);
    if (!mounted) return;
    final deck = [
      for (final entry in frequent)
        _CardItem(
          arabic: entry.arabic,
          gloss: entry.gloss,
          surahId: entry.samples.first.surahId,
          ayah: entry.samples.first.ayah,
          surahName: entry.samples.first.surahName,
        ),
    ];
    setState(() {
      _deck = deck;
      _index = 0;
      _revealed = false;
      _usingFavorites = false;
    });
  }

  void _next() {
    final deck = _deck;
    if (deck == null || deck.isEmpty) return;
    setState(() {
      _index = (_index + 1) % deck.length;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocab = VocabScope.of(context);
    final deck = _deck;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Quranic Arabic'),
        actions: [
          if (deck != null)
            TextButton(
              onPressed: () => setState(() => _deck = null),
              child: const Text('End'),
            ),
        ],
      ),
      body: deck == null
          ? _Lobby(
              savedCount: vocab.entries.length,
              onFavorites: vocab.entries.isEmpty
                  ? null
                  : () => _startFavorites(vocab.entries),
              onFrequent: _startFrequent,
            )
          : _Review(
              item: deck[_index],
              position: _index + 1,
              total: deck.length,
              revealed: _revealed,
              usingFavorites: _usingFavorites,
              onReveal: () => setState(() => _revealed = true),
              onNext: _next,
            ),
    );
  }
}

class _CardItem {
  const _CardItem({
    required this.arabic,
    required this.gloss,
    required this.surahId,
    required this.ayah,
    required this.surahName,
  });

  final String arabic;
  final String gloss;
  final int surahId;
  final int ayah;
  final String surahName;
}

class _Lobby extends StatelessWidget {
  const _Lobby({
    required this.savedCount,
    required this.onFavorites,
    required this.onFrequent,
  });

  final int savedCount;
  final VoidCallback? onFavorites;
  final VoidCallback onFrequent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.page,
      children: [
        Text(
          'Learn the Arabic of the Quran from the words you meet while '
          'reading. Star a word in the reader, or start with the most '
          'frequent vocabulary — a few hundred roots cover most of the text.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.star_rounded),
            title: const Text('Review saved words'),
            subtitle: Text(
              savedCount == 0
                  ? 'Star words in the reader (turn on word-by-word first)'
                  : '$savedCount saved',
            ),
            enabled: onFavorites != null,
            onTap: onFavorites,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.trending_up_rounded),
            title: const Text('Most common Quranic words'),
            subtitle: const Text('20 highest-frequency phrases'),
            onTap: () {
              AppHaptics.selection();
              onFrequent();
            },
          ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.item,
    required this.position,
    required this.total,
    required this.revealed,
    required this.usingFavorites,
    required this.onReveal,
    required this.onNext,
  });

  final _CardItem item;
  final int position;
  final int total;
  final bool revealed;
  final bool usingFavorites;
  final VoidCallback onReveal;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vocab = VocabScope.of(context);
    final saved = vocab.isSavedWord(item.arabic, item.gloss);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        children: [
          Text(
            '$position of $total'
            '${usingFavorites ? '' : ' · frequent words'}',
            style: theme.textTheme.labelLarge,
          ),
          const Spacer(),
          Card(
            child: InkWell(
              onTap: revealed ? onNext : onReveal,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      ArabicText(
                        item.arabic,
                        tajweed: false,
                        fontSize: 40,
                        weight: FontWeight.bold,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (revealed)
                        Text(
                          item.gloss,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          'Tap to show the meaning',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.push(AppRoute.surah(item.surahId, ayah: item.ayah)),
            child: Text(
              'See in ${item.surahName} ${item.surahId}:${item.ayah}',
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: saved ? 'Remove from saved' : 'Save to learn',
                onPressed: () {
                  AppHaptics.selection();
                  vocab.toggle(
                    VocabEntry.fromReader(
                      arabic: item.arabic,
                      gloss: item.gloss,
                      surahId: item.surahId,
                      ayah: item.ayah,
                      surahName: item.surahName,
                    ),
                  );
                },
                icon: Icon(
                  saved ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: revealed ? onNext : onReveal,
                  child: Text(revealed ? 'Next' : 'Show meaning'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
