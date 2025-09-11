import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../quran/models.dart';
import 'widgets/arabic_text.dart';
import 'widgets/quran_debug.dart';
import '../services/settings_scope.dart';

/// SurahDetailPage displays the details of a Surah (chapter), including all ayat (verses)
/// in both Arabic and English, with Tajweed coloring and a legend.
/// Displays the details of a Surah, including Arabic and English translation.
class SurahDetailPage extends StatefulWidget {
  /// Surah number (1-based)
  final int surahId;
  /// Optional: Ayah to scroll to (1-based)
  final int? scrollToAyah;

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
  // Controller for programmatic scrolling of the ayah list
  final ItemScrollController _itemScrollController = ItemScrollController();
  // Listener to get visible item positions in the list
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    // Instantiate repositories for chapters, Arabic text, and English translation
    final chaptersRepository = const QuranChaptersRepository();
    final arabicRepository = const QuranArabicRepository();
    final translationRepository = const QuranTranslationRepository();

    // Use FutureBuilder to load all required data in parallel
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        chaptersRepository.loadChapters(),
        arabicRepository.loadArabicSurah(widget.surahId),
        translationRepository.loadClearQuran(widget.surahId),
      ]),
      builder: (context, snapshot) {
        // Show loading spinner while waiting for data
        final bool isLoading = snapshot.connectionState != ConnectionState.done;
        // Show error message if any error occurs
        final String? errorMessage =
            snapshot.hasError ? snapshot.error.toString() : null;

        // Variables to hold loaded data
        ChapterMeta? selectedChapterMeta;
        Map<String, String> surahArabicAyat = const {};
        Map<String, String> surahEnglishAyat = const {};

        // If data loaded, extract chapter meta and ayat maps
        if (snapshot.hasData) {
          final List<ChapterMeta> allChapters =
              snapshot.data![0] as List<ChapterMeta>;
          selectedChapterMeta = allChapters.firstWhere((chapter) => chapter.id == widget.surahId);
          surahArabicAyat = snapshot.data![1] as Map<String, String>;
          surahEnglishAyat = snapshot.data![2] as Map<String, String>;
        }

        // Main page scaffold
        return Scaffold(
          appBar: AppBar(title: Text(selectedChapterMeta?.nameSimple ?? 'Surah')),
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

            final int ayahCount = selectedChapterMeta!.versesCount;

            // Scroll to requested ayah after first build (if provided)
            if (widget.scrollToAyah != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ayahIndex =
                    (widget.scrollToAyah! - 1).clamp(0, ayahCount - 1);
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
                // List of ayat (verses)
                Expanded(
                  child: ScrollablePositionedList.separated(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: ayahCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      // Get user settings (for zoom)
                      final settings = SettingsScope.of(context);

                      final ayahNumber = index + 1;
                      final String? ayahArabicText = surahArabicAyat['$ayahNumber'];
                      final String? ayahEnglishText = surahEnglishAyat['$ayahNumber'];

                      // Debug: print runes in debug mode only
                      assert(() {
                        if (ayahArabicText != null && ayahArabicText.isNotEmpty) {
                          debugRunesDetailed(ayahArabicText, label: 'Ayah $ayahNumber');
                        }
                        return true;
                      }());

                      // Card for each ayah
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

                              // Arabic text (with Tajweed coloring)
                              if (ayahArabicText != null && ayahArabicText.isNotEmpty)
                                ArabicText(
                                  ayahArabicText,
                                  tajweed: true,
                                  fontSize: 34 * settings.arabicZoom, // Zoomable font size
                                  weight: FontWeight.bold,
                                ),

                              // Spacer below Arabic
                              if (ayahArabicText != null && ayahArabicText.isNotEmpty)
                                const SizedBox(height: 24),

                              // English translation
                              if (ayahEnglishText != null && ayahEnglishText.isNotEmpty)
                                Text(
                                  ayahEnglishText,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900, // Extra bold
                                        fontFamily: 'Roboto',
                                        fontFamilyFallback: const [
                                          'Arial',
                                          'sans-serif'
                                        ],
                                        fontSize: 18 * settings.englishZoom, // Zoomable font size
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
                // Add bottom safe area padding
                const SafeArea(top: false, child: SizedBox(height: 4)),
              ],
            );
          }(),
        );
      },
    );
  }

}

  /// Builds the Tajweed legend row with color-coded chips for each rule.
  Widget _tajweedLegend(BuildContext context) {
    // Helper to create a colored chip for a Tajweed rule
    Chip buildChip(String label, Color color) => Chip(
          label: Text(label),
          backgroundColor: color.withValues(alpha: 0.12), // Slightly colored background
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

// Helper extension to allow us to rebuild the legend with context
extension WidgetBuildExtension on Widget {
  Widget build(BuildContext context, Widget Function(BuildContext, Widget) wrap) {
    return Builder(builder: (ctx) => wrap(ctx, this));
  }
}
