import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di.dart';
import 'surah_detail_page.dart';

final chaptersProvider = FutureProvider((ref) async {
  final repo = await ref.watch(repoProvider.future);
  return repo.chapters();
});

class SurahListPage extends ConsumerWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chaptersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hublee — Surahs')),
      body: async.when(
        data: (data) {
          final chapters = (data['chapters'] as List).cast<Map>();
          return ListView.separated(
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = chapters[i];
              return ListTile(
                title: Text('${c['id']}. ${c['name_simple']}'),
                subtitle: Text('${c['name_arabic']} • ${c['revelation_place']}'),
                trailing: Text('${c['verses_count']} ayat'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SurahDetailPage(chapter: c['id'] as int)),
                ),
              );
            },
          );
        },
        error: (e, _) {
          debugPrint('Chapters error: $e');
          return Center(child: Text('Failed to load chapters: $e'));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
