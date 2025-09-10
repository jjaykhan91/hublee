import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/models.dart';
import 'widgets/arabic_text.dart';
import 'widgets/quran_debug.dart';

/// Displays the details of a Surah, including Arabic and English translation.
class SurahDetailPage extends StatefulWidget {
  final int surahId; // Surah number (1-based)
  final int? scrollToAyah; // Optional: Ayah to scroll to (1-based)

  const SurahDetailPage({
    super.key,
    required this.surahId,
    this.scrollToAyah,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

/// State for SurahDetailPage, handles loading and displaying Surah content.
class _SurahDetailPageState extends State<SurahDetailPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    // Instantiate repositories for chapters, Arabic text, and English translation
  // Use const constructors for stateless repositories
  final chaptersRepository = const QuranChaptersRepository();
  final arabicRepository = const QuranArabicRepository();
  final translationRepository = const QuranTranslationRepository();

    // Load all required data in parallel
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chaptersRepository.loadChapters(),
        arabicRepository.loadArabicSurah(widget.surahId),
        translationRepository.loadClearQuran(widget.surahId),
      ]),
      builder: (context, snapshot) {
        final bool isLoading = snapshot.connectionState != ConnectionState.done;
        final String? errorMessage =
            snapshot.hasError ? snapshot.error.toString() : null;

        ChapterMeta? chapterMeta;
        Map<String, String> arabicAyat = const {};
        Map<String, String> englishAyat = const {};

        // If data loaded, extract chapter meta and ayat maps
        if (snapshot.hasData) {
          final List<ChapterMeta> chapters =
              snapshot.data![0] as List<ChapterMeta>;
          chapterMeta = chapters.firstWhere((c) => c.id == widget.surahId);
          arabicAyat = snapshot.data![1] as Map<String, String>;
          englishAyat = snapshot.data![2] as Map<String, String>;
        }

        return Scaffold(
          appBar: AppBar(title: Text(chapterMeta?.nameSimple ?? 'Surah')),
          body: () {
            // Show loading spinner
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show error message if any
            if (errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $errorMessage'),
              );
            }

            final int ayahCount = chapterMeta!.versesCount;

            // Scroll to requested ayah after first build
            if (widget.scrollToAyah != null) {
              // Only scroll if attached and ayah is in range
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ayahIndex = (widget.scrollToAyah! - 1).clamp(0, ayahCount - 1);
                if (_itemScrollController.isAttached) {
                  _itemScrollController.jumpTo(index: ayahIndex);
                  _itemScrollController.scrollTo(
                    index: ayahIndex,
                    duration: const Duration(milliseconds: 200),
                    alignment: 0.08,
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            // Main content: List of ayat and legend
            return Column(
              children: [
                // List of ayat
                Expanded(
                  child: ScrollablePositionedList.separated(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: ayahCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ayahNumber = index + 1;
                      final arabicText = arabicAyat['$ayahNumber'];
                      final englishText = englishAyat['$ayahNumber'];

                      // Only debug in debug mode for performance
                      assert(() {
                        if (arabicText != null && arabicText.isNotEmpty) {
                          debugRunesDetailed(arabicText, label: 'Ayah $ayahNumber');
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
                              // Ayah number
                              Text(
                                '$ayahNumber',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 10),

                              // Arabic text (bold)
                              if (arabicText != null && arabicText.isNotEmpty)
                                ArabicText(
                                  arabicText,
                                  tajweed: true, // color rules on
                                  fontSize: 38, // larger for visibility
                                  weight: FontWeight.normal, // extra bold
                                  style: const TextStyle(
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2,
                                        color: Colors.black54,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),

                              if (arabicText != null && arabicText.isNotEmpty)
                                const SizedBox(height: 30),

                              // English translation (thicker and more readable font)
                              if (englishText != null && englishText.isNotEmpty)
                                Text(
                                  englishText,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900, // thickest
                                        fontFamily: 'Roboto', // use Roboto if available
                                        fontFamilyFallback: const ['Arial', 'sans-serif'], // fallback fonts
                                        fontSize: 18, // larger for readability
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

                // Tajweed legend row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _tajweedLegend(context),
                ),
                const SafeArea(top: false, child: SizedBox(height: 4)),
              ],
            );
          }(),
        );
      },
    );
  }

  /// Builds the Tajweed legend row with color-coded chips.
  Widget _tajweedLegend(BuildContext context) {
    // Helper to create a colored chip
    Chip buildChip(String label, Color color) => Chip(
          label: Text(label),
          backgroundColor: color.withOpacity(0.12),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );

    // Initial dummy chips for layout, replaced with colored chips below
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
      // Rebuild with concrete colored chips to keep constant colors centralized
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          buildChip('QALQALA', const Color(0xFFD32F2F)), // red
          buildChip('IQLAB', const Color(0xFF1E88E5)), // blue
          buildChip('IDGHAM', const Color(0xFF2E7D32)), // green (with ghunnah)
          buildChip('IDGHAM*', const Color(0xFF00897B)), // teal (no ghunnah)
          buildChip('IKHFAAʼ', const Color(0xFF8E24AA)), // magenta
          buildChip('IKHFAA MEEMI', const Color(0xFFF4511E)), // orange
        ],
      );
    });
  }
}

// Small helper extension to allow us to rebuild the legend with context
extension WidgetBuildExtension on Widget {
  Widget build(
      BuildContext context, Widget Function(BuildContext, Widget) wrap) {
    return Builder(builder: (ctx) => wrap(ctx, this));
  }
}
