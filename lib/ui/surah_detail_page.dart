import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/models.dart';
import 'widgets/arabic_text.dart';

class SurahDetailPage extends StatefulWidget {
  final int surahId;
  final int? scrollToAyah; // 1-based

  const SurahDetailPage({super.key, required this.surahId, this.scrollToAyah});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final chaptersRepo = const QuranChaptersRepository();
    final arRepo = const QuranArabicRepository();
    final enRepo = const QuranTranslationRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chaptersRepo.loadChapters(),
        arRepo.loadArabicSurah(widget.surahId),
        enRepo.loadClearQuran(widget.surahId),
      ]),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final error = snap.hasError ? snap.error.toString() : null;

        ChapterMeta? meta;
        Map<String, String> ar = const {};
        Map<String, String> en = const {};

        if (snap.hasData) {
          final chapters = snap.data![0] as List<ChapterMeta>;
          meta = chapters.firstWhere((c) => c.id == widget.surahId);
          ar = snap.data![1] as Map<String, String>;
          en = snap.data![2] as Map<String, String>;
        }

        return Scaffold(
          appBar: AppBar(title: Text(meta?.nameSimple ?? 'Surah')),
          body: () {
            if (loading) return const Center(child: CircularProgressIndicator());
            if (error != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $error'),
              );
            }

            final count = meta!.versesCount;

            // Jump exactly to requested ayah after first build
            if (widget.scrollToAyah != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final idx = (widget.scrollToAyah! - 1).clamp(0, count - 1);
                if (_scroll.isAttached) {
                  _scroll.jumpTo(index: idx);
                  _scroll.scrollTo(
                    index: idx,
                    duration: const Duration(milliseconds: 200),
                    alignment: 0.08,
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return Column(
              children: [
                // List
                Expanded(
                  child: ScrollablePositionedList.separated(
                    itemScrollController: _scroll,
                    itemPositionsListener: _positions,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: count,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = i + 1;
                      final a = ar['$n'];
                      final e = en['$n'];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Ayah $n',
                                  style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8),
                              if (a != null && a.isNotEmpty)
                                ArabicText(
                                  a,
                                  tajweed: true,      // ✅ enable tajwīd coloring
                                  fontSize: 22,
                                  weight: FontWeight.w600,
                                ),
                              if (a != null && a.isNotEmpty)
                                const SizedBox(height: 8),
                              if (e != null && e.isNotEmpty)
                                Text(e,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Legend row
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 6, 16, 12), // SafeArea above
                  child: _tajweedLegend(context),
                ),
                SafeArea(top: false, child: SizedBox(height: 4)),
              ],
            );
          }(),
        );
      },
    );
  }

  Widget _tajweedLegend(BuildContext context) {
    Chip chip(String label, Color color) => Chip(
          label: Text(label),
          backgroundColor: color.withOpacity(0.12),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('QALQALA', const Color(0xFFD32F2F)),       // red
        chip('IQLAB',   const Color(0xFF1E88E5)),       // blue
        chip('IDGHAM',  const Color(0xFF2E7D32)),       // green (with ghunnah)
        chip('IDGHAM*', const Color(0xFF00897B)),       // teal (no ghunnah)
        chip('IKHFAAʼ', const Color(0xFF8E24AA)),       // magenta
        chip('IKHFAA MEEMI', const Color(0xFFF4511E)),  // orange
      ],
    );
  }
}
