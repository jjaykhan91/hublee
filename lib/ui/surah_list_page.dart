import 'package:flutter/material.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/models.dart';
import 'surah_detail_page.dart';

class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = const QuranChaptersRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Qur’an')),
      body: FutureBuilder<List<ChapterMeta>>(
        future: repo.loadChapters(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}'),
            );
          }

          final chapters = snap.data ?? const <ChapterMeta>[];
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = chapters[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${c.id}')),
                  title: Text(c.nameSimple),
                  subtitle: Text('${c.nameArabic} • ${c.versesCount} ayat'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SurahDetailPage(surahId: c.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
