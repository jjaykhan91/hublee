import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/models.dart';

import 'widgets/arabic_text.dart';
import 'widgets/quran_debug.dart';
import '../services/settings_scope.dart';
import 'widgets/app_scaffold.dart';

/// Displays one Surah with all of its ayat (Arabic + English),
/// including tajwīd coloring and a legend.
class SurahDetailPage extends StatefulWidget {
  final int surahId;
  final int? scrollToAyah;

  const SurahDetailPage({
    super.key,
    required this.surahId,
    this.scrollToAyah,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final ItemScrollController _scrollCtrl = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final chaptersRepo = const QuranChaptersRepository();
    final arabicRepo = const QuranArabicRepository();
    final translationRepo = const QuranTranslationRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chaptersRepo.loadChapters(),
        arabicRepo.loadArabicSurah(widget.surahId),
        translationRepo.loadClearQuran(widget.surahId),
      ]),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final errorMsg = snap.hasError ? snap.error.toString() : null;

        ChapterMeta? chapterMeta;
        Map<String, String> arabicAyahs = const {};
        Map<String, String> englishAyahs = const {};

        if (snap.hasData) {
          final chapters = snap.data![0] as List<ChapterMeta>;
          chapterMeta = chapters.firstWhere((c) => c.id == widget.surahId);
          arabicAyahs = snap.data![1] as Map<String, String>;
          englishAyahs = snap.data![2] as Map<String, String>;
        }

        // Use AppScaffold so this page also has the Settings drawer + gear.
        return AppScaffold(
          appBar: AppBar(title: Text(chapterMeta?.nameSimple ?? 'Surah')),
          body: () {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (errorMsg != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $errorMsg'),
              );
            }

            final totalAyahs = chapterMeta!.versesCount;

            if (widget.scrollToAyah != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final idx = (widget.scrollToAyah! - 1).clamp(0, totalAyahs - 1);
                if (_scrollCtrl.isAttached) {
                  _scrollCtrl.jumpTo(index: idx);
                  _scrollCtrl.scrollTo(
                    index: idx,
                    duration: const Duration(milliseconds: 200),
                    alignment: 0.08,
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            final settings = SettingsScope.of(context);

            return Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.separated(
                    itemScrollController: _scrollCtrl,
                    itemPositionsListener: _positions,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: totalAyahs,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = i + 1;
                      final ar = arabicAyahs['$n'];
                      final en = englishAyahs['$n'];

                      assert(() {
                        if (ar != null && ar.isNotEmpty) {
                          debugRunesDetailed(ar, label: 'Ayah $n');
                        }
                        return true;
                      }());

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('$n',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 10),

                              if (ar != null && ar.isNotEmpty)
                                ArabicText(
                                  ar,
                                  tajweed: true,
                                  fontSize: 34 * settings.arabicZoom,
                                  weight: FontWeight.bold,
                                ),

                              if (ar != null && ar.isNotEmpty)
                                const SizedBox(height: 24),

                              if (en != null && en.isNotEmpty)
                                Text(
                                  en,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Roboto',
                                        fontFamilyFallback: const [
                                          'Arial',
                                          'sans-serif'
                                        ],
                                        fontSize: 18 * settings.englishZoom,
                                        height: 1.35,
                                        letterSpacing: 0.1,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _buildTajweedLegend(context),
                ),
                const SafeArea(top: false, child: SizedBox(height: 4)),
              ],
            );
          }(),
        );
      },
    );
  }

  Widget _buildTajweedLegend(BuildContext context) {
    Chip chip(String label, Color color) => Chip(
          label: Text(label),
          backgroundColor: color.withValues(alpha: 0.12),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        Chip(label: Text('QALQALA')),
        Chip(label: Text('IQLAB')),
        Chip(label: Text('IDGHAM')),
        Chip(label: Text('IDGHAM*')),
        Chip(label: Text('IKHFAAʼ')),
        Chip(label: Text('IKHFAA MEEMI')),
      ],
    ).build(context, (ctx, _) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('QALQALA', const Color(0xFFD32F2F)),
          chip('IQLAB', const Color(0xFF1E88E5)),
          chip('IDGHAM', const Color(0xFF2E7D32)),
          chip('IDGHAM*', const Color(0xFF00897B)),
          chip('IKHFAAʼ', const Color(0xFF8E24AA)),
          chip('IKHFAA MEEMI', const Color(0xFFF4511E)),
        ],
      );
    });
  }
}

// Helper to rebuild placeholder widgets with context
extension WidgetBuildExtension on Widget {
  Widget build(
    BuildContext context,
    Widget Function(BuildContext, Widget) wrap,
  ) {
    return Builder(builder: (ctx) => wrap(ctx, this));
  }
}
