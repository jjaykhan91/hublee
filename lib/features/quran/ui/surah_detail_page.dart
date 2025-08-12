import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di.dart';

class SurahDetailPage extends ConsumerWidget {
  final int chapter;
  const SurahDetailPage({super.key, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Surah $chapter')),
      body: FutureBuilder(
        future: ref.read(repoProvider.future).then(
              (repo) => repo.versesByChapter(chapter, perPage: 50, page: 1),
            ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final data = snap.data!;
          final verses = (data['verses'] as List).cast<Map<String, dynamic>>();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: verses.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (_, i) {
              final v = verses[i];
              final ar = (v['text_uthmani'] ?? v['text_indopak'] ?? '') as String;
              final transList = (v['translations'] ?? []) as List;
              final en = transList.isNotEmpty ? (transList.first['text'] ?? '') as String : '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(ar, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(en, style: const TextStyle(fontSize: 16)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
