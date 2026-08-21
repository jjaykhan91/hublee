/// Searchable Quranic Arabic–English vocabulary (bundled word-by-word).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/quran_dictionary_service.dart';
import '../services/vocab_scope.dart';
import '../services/vocab_service.dart';
import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';

/// Looks up Quranic Arabic from an English (or Arabic) query.
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({
    super.key,
    this.service = const QuranDictionaryService(),
    this.initialQuery = '',
  });

  final QuranDictionaryService service;
  final String initialQuery;

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  late final TextEditingController _controller;
  late final Future<List<DictionaryEntry>> _frequentFuture;
  List<DictionaryEntry> _hits = [];
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _frequentFuture = widget.service.frequent();
    if (widget.initialQuery.trim().isNotEmpty) {
      _runSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String raw) async {
    final query = raw.trim();
    setState(() {
      _query = query;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      setState(() => _hits = []);
      return;
    }
    final hits = await widget.service.search(query);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('English → Arabic')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              autofocus: widget.initialQuery.isEmpty,
              decoration: const InputDecoration(
                hintText: 'Type an English word — mercy, lord, path…',
                prefixIcon: Icon(Icons.translate_rounded),
              ),
              onChanged: _runSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Shows the Arabic used in the Quran for that English meaning. '
              'It is a Quranic glossary, not a modern newspaper dictionary.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_query.isEmpty) {
      return FutureBuilder<List<DictionaryEntry>>(
        future: _frequentFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _EntryList(
            heading: 'Most frequent in the Quran',
            entries: snapshot.data!,
            onOpen: _openEntry,
          );
        },
      );
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hits.isEmpty) {
      return Center(
        child: Text(
          'No Arabic in the Quran for “$_query”. Try lord, mercy, path, or Allah.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    return _EntryList(
      heading: _query.isEmpty
          ? 'Most frequent in the Quran'
          : 'Arabic for “$_query”',
      entries: _hits,
      onOpen: _openEntry,
    );
  }

  void _openEntry(DictionaryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _EntrySheet(entry: entry),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.heading,
    required this.entries,
    required this.onOpen,
  });

  final String heading;
  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              heading,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        }
        final entry = entries[index - 1];
        return Card(
          child: ListTile(
            title: Text(
              entry.gloss,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ArabicText(
                entry.arabic,
                tajweed: false,
                fontSize: 26,
                weight: FontWeight.w700,
              ),
            ),
            trailing: Text(
              '${entry.count}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            onTap: () => onOpen(entry),
          ),
        );
      },
    );
  }
}

class _EntrySheet extends StatelessWidget {
  const _EntrySheet({required this.entry});

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final vocab = VocabScope.of(context);
    final saved = vocab.isSaved(entry.id);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArabicText(
              entry.arabic,
              tajweed: false,
              fontSize: 32,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              entry.gloss,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.count} times in the Quran',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                AppHaptics.selection();
                final sample = entry.samples.first;
                vocab.toggle(
                  VocabEntry.fromReader(
                    arabic: entry.arabic,
                    gloss: entry.gloss,
                    surahId: sample.surahId,
                    ayah: sample.ayah,
                    surahName: sample.surahName,
                  ),
                );
              },
              icon: Icon(
                saved ? Icons.star_rounded : Icons.star_outline_rounded,
              ),
              label: Text(saved ? 'Saved to learn' : 'Save to learn'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Where it appears',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final sample in entry.samples)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${sample.surahName} ${sample.surahId}:${sample.ayah}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    AppRoute.surah(sample.surahId, ayah: sample.ayah),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
