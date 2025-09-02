import 'dart:async';
import 'package:flutter/material.dart';

import '../hadith/hadith_repository.dart';
import '../quran/models.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';

import 'hadith_book_page.dart';
import 'surah_detail_page.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  final _hadith = <HadithSearchHit>[];
  final _quran = <QuranSearchHit>[];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _hadith.clear();
        _quran.clear();
      });
      return;
    }

    setState(() => _searching = true);
    try {
      // Hadith
      final hadithRepo = const HadithRepository();
      final hadithHits = await hadithRepo.searchHadith(query, limit: 100);

      // Qur'an
      final chaptersRepo = const QuranChaptersRepository();
      final arRepo = const QuranArabicRepository();
      final enRepo = const QuranTranslationRepository();

      final chapters = await chaptersRepo.loadChapters();
      final qHits = <QuranSearchHit>[];
      final qLower = query.toLowerCase();

      for (final c in chapters) {
        Map<String, String> ar = const {};
        Map<String, String> en = const {};
        try {
          ar = await arRepo.loadArabicSurah(c.id);
          en = await enRepo.loadClearQuran(c.id);
        } catch (_) {
          continue;
        }

        for (var i = 1; i <= c.versesCount; i++) {
          final k = '$i';
          final arText = ar[k] ?? '';
          final enText = en[k] ?? '';
          final match = arText.contains(query) || enText.toLowerCase().contains(qLower);
          if (!match) continue;

          String? snippet;
          if (enText.isNotEmpty) {
            final idx = enText.toLowerCase().indexOf(qLower);
            if (idx >= 0) {
              final start = (idx - 40).clamp(0, enText.length);
              final end = (idx + query.length + 60).clamp(0, enText.length);
              snippet = enText.substring(start, end).trim();
              if (start > 0) snippet = '…$snippet';
              if (end < enText.length) snippet = '$snippet…';
            } else {
              snippet = enText;
            }
          }

          qHits.add(QuranSearchHit(
            surahId: c.id,
            ayah: i,
            surahName: c.nameSimple,
            snippet: snippet,
          ));
          if (qHits.length >= 150) break;
        }
        if (qHits.length >= 150) break;
      }

      if (!mounted) return;
      setState(() {
        _hadith
          ..clear()
          ..addAll(hadithHits);
        _quran
          ..clear()
          ..addAll(qHits);
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Search Qur’an and Hadith…',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : (_hadith.isEmpty && _quran.isEmpty)
              ? Center(
                  child: Text('Type to search Qur’an and Hadith.', style: theme.textTheme.bodyMedium),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: [
                    if (_quran.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text('Qur’an', style: theme.textTheme.titleMedium),
                      ),
                      ..._quran.map((v) => _QuranTile(hit: v)),
                      const SizedBox(height: 12),
                    ],
                    if (_hadith.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text('Hadith', style: theme.textTheme.titleMedium),
                      ),
                      ..._hadith.map((h) => _HadithTile(hit: h)),
                    ],
                  ],
                ),
    );
  }
}

class _HadithTile extends StatelessWidget {
  final HadithSearchHit hit;
  const _HadithTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HadithBookPage(
                collectionId: hit.collectionId,
                bookFile: hit.bookFile,
                title: hit.bookTitle ?? hit.bookFile,
                scrollToIndex: hit.hadithIndex,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.bookTitle ?? hit.bookFile} • Hadith ${hit.hadithIndex + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty)
                      Text(hit.snippet!, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
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

class _QuranTile extends StatelessWidget {
  final QuranSearchHit hit;
  const _QuranTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahDetailPage(surahId: hit.surahId, scrollToAyah: hit.ayah),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.book_outlined, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${hit.surahName} • Ayah ${hit.ayah}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty)
                      Text(hit.snippet!, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
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
