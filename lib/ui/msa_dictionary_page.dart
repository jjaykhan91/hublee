/// English → Modern Standard Arabic dictionary (not the Quran glossary).
library;

import 'package:flutter/material.dart';

import '../services/msa_dictionary_service.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';

class MsaDictionaryPage extends StatefulWidget {
  const MsaDictionaryPage({
    super.key,
    this.service = const MsaDictionaryService(),
    this.initialQuery = '',
  });

  final MsaDictionaryService service;
  final String initialQuery;

  @override
  State<MsaDictionaryPage> createState() => _MsaDictionaryPageState();
}

class _MsaDictionaryPageState extends State<MsaDictionaryPage> {
  late final TextEditingController _controller;
  late final Future<List<MsaEntry>> _allFuture;
  List<MsaEntry> _hits = [];
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _allFuture = widget.service.load();
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
      appBar: AppBar(title: const Text('MSA dictionary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery.isEmpty,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Type English — newspaper, government, water',
                prefixIcon: Icon(Icons.translate_rounded),
              ),
              onChanged: _runSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Modern Standard Arabic (newspaper style). Not the Quran '
              'glossary. Meanings come from Wiktionary (CC BY-SA) plus a '
              'Hublee core list.',
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
      return FutureBuilder<List<MsaEntry>>(
        future: _allFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _EntryList(
            heading: '${snapshot.data!.length} entries · try “computer”',
            entries: snapshot.data!.take(40).toList(),
            onOpen: _open,
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
          'No MSA entry for “$_query”. Try newspaper, government, or computer.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return _EntryList(
      heading: 'Arabic for “$_query”',
      entries: _hits,
      onOpen: _open,
    );
  }

  void _open(MsaEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MsaSheet(entry: entry),
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
  final List<MsaEntry> entries;
  final ValueChanged<MsaEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.list,
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
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
              entry.english,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArabicText(
                  entry.arabic,
                  tajweed: false,
                  fontSize: 26,
                  weight: FontWeight.w700,
                ),
                if (entry.root != null)
                  Text(
                    'Root ${entry.root}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            trailing: Text(entry.pos),
            onTap: () => onOpen(entry),
          ),
        );
      },
    );
  }
}

class _MsaSheet extends StatelessWidget {
  const _MsaSheet({required this.entry});

  final MsaEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArabicText(
            entry.arabic,
            tajweed: false,
            fontSize: 36,
            weight: FontWeight.bold,
            align: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            entry.english,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (entry.root != null) ...[
            const SizedBox(height: 6),
            Text('Root ${entry.root} · ${entry.pos}'),
          ],
        ],
      ),
    );
  }
}
