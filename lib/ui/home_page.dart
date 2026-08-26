/// Landing page shown in the Home tab.
///
/// Displays the meaning of Hublee, Allah / Prophet / Dhikr / Salah / Dua
/// cards, a search shortcut, and Ayah / Hadith / Dhikr of the Day.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/daily_content_service.dart';
import '../services/settings_controller.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/dhikr_of_the_day_card.dart';
import 'widgets/hublee_marks.dart';

/// Home tab content with the app name, search, and daily reading.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DailyVerse> _verseFuture;
  late Future<DailyHadith> _hadithFuture;

  @override
  void initState() {
    super.initState();
    _verseFuture = DailyContentService.loadVerseOfTheDay();
    _hadithFuture = DailyContentService.loadHadithOfTheDay();
  }

  void _reloadVerse() {
    setState(() {
      _verseFuture = DailyContentService.loadVerseOfTheDay();
    });
  }

  void _reloadHadith() {
    setState(() {
      _hadithFuture = DailyContentService.loadHadithOfTheDay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const HubleeWordmark(), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: [
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.06),
                    colorScheme.surface,
                  ),
                  colorScheme.surface,
                  colorScheme.surface,
                  Color.alphaBlend(
                    colorScheme.tertiary.withValues(alpha: 0.04),
                    colorScheme.surface,
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: IslamicStarLatticePainter(
                        color: colorScheme.primary.withValues(alpha: 0.045),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: AppSpacing.page,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Search shortcut (3D shadow) ─────────────────
                      Material(
                        color: Colors.transparent,
                        borderRadius: AppRadius.input,
                        child: InkWell(
                          onTap: () => context.push(AppRoute.search),
                          borderRadius: AppRadius.input,
                          child: Semantics(
                            button: true,
                            label: 'Search Quran and Hadith',
                            child: AbsorbPointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: AppRadius.input,
                                  boxShadow: AppShadows.input,
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    hintText: 'Search Quran and Hadith',
                                    suffixIcon: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const _HubleeMeaningCard(),
                      const SizedBox(height: 16),
                      const _HomeGuideCards(),
                      const SizedBox(height: 20),

                      // ── Verse of the Day ────────────────────────────
                      FutureBuilder<DailyVerse>(
                        future: _verseFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _DailyCardError(
                              key: const Key('verse-of-the-day-error'),
                              message: "Couldn't load ayah of the day",
                              onRetry: _reloadVerse,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const _DailyCardSkeleton(
                              key: Key('verse-of-the-day-skeleton'),
                              label: 'Loading ayah of the day',
                            );
                          }
                          return _VerseOfTheDayCard(verse: snapshot.data!)
                              .animate()
                              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOut,
                              );
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Hadith of the Day ───────────────────────────
                      FutureBuilder<DailyHadith>(
                        future: _hadithFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _DailyCardError(
                              key: const Key('hadith-of-the-day-error'),
                              message: "Couldn't load hadith of the day",
                              onRetry: _reloadHadith,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const _DailyCardSkeleton(
                              key: Key('hadith-of-the-day-skeleton'),
                              label: 'Loading hadith of the day',
                            );
                          }
                          return _HadithOfTheDayCard(hadith: snapshot.data!)
                              .animate()
                              .fadeIn(
                                duration: 600.ms,
                                delay: 150.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 600.ms,
                                delay: 150.ms,
                                curve: Curves.easeOut,
                              );
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Dhikr of the Day ────────────────────────────
                      DhikrOfTheDayCard(
                            key: const Key('dhikr-of-the-day-card'),
                            dhikr: DailyContentService.dhikrOfTheDay(),
                          )
                          .animate()
                          .fadeIn(
                            duration: 600.ms,
                            delay: 300.ms,
                            curve: Curves.easeOut,
                          )
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 600.ms,
                            delay: 300.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Verse of the Day card (compact + tappable)
// ────────────────────────────────────────────────────────────────

class _VerseOfTheDayCard extends StatelessWidget {
  final DailyVerse verse;

  const _VerseOfTheDayCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ayah of the day, ${verse.surahName} ayah ${verse.ayah}',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.featureCard,
        child: InkWell(
          onTap: () =>
              context.push(AppRoute.surah(verse.surahId, ayah: verse.ayah)),
          borderRadius: AppRadius.featureCard,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.verseOfDay,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.featureCard,
              boxShadow: AppShadows.featureCardShadow(AppColors.verseOfDayTint),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: IslamicStarLatticePainter(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppRadius.badge,
                              boxShadow: AppShadows.badge,
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Ayah of the Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          HubleeStarMark(
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${verse.surahName} : ${verse.ayah}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Arabic text (compact)
                      if (verse.arabic.isNotEmpty)
                        ArabicText(
                          verse.arabic,
                          tajweed: false,
                          fontSize: 20,
                          weight: FontWeight.bold,
                          align: TextAlign.center,
                          color: Colors.white,
                          fontOverride: ArabicFontOption.uthmanic,
                        ),
                      if (verse.arabic.isNotEmpty) const SizedBox(height: 10),

                      // English translation (show full but clamp height)
                      if (verse.english.isNotEmpty)
                        Text(
                          verse.english,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (verse.english.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'ClearQuran',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // "Tap to read more" footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tap to read full surah',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Hadith of the Day card (compact + tappable)
// ────────────────────────────────────────────────────────────────

class _HadithOfTheDayCard extends StatelessWidget {
  final DailyHadith hadith;

  const _HadithOfTheDayCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hadith of the day, ${hadith.bookTitle}',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.featureCard,
        child: InkWell(
          onTap: () => context.push(
            AppRoute.hadithBook(
              collectionId: hadith.collectionId,
              bookFile: hadith.bookFile,
              bookTitle: hadith.bookTitle,
              index: hadith.hadithIndex,
            ),
          ),
          borderRadius: AppRadius.featureCard,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.hadithOfDay,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.featureCard,
              boxShadow: AppShadows.featureCardShadow(
                AppColors.hadithOfDayTint,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: IslamicStarLatticePainter(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppRadius.badge,
                              boxShadow: AppShadows.badge,
                            ),
                            child: const Icon(
                              Icons.library_books_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Hadith of the Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          HubleeStarMark(
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hadith.bookTitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Narrator (compact)
                      if (hadith.narrator != null &&
                          hadith.narrator!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hadith.narrator!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Arabic text (compact)
                      if (hadith.arabic.isNotEmpty)
                        ArabicText(
                          hadith.arabic,
                          tajweed: false,
                          fontSize: 18,
                          weight: FontWeight.bold,
                          align: TextAlign.center,
                          color: Colors.white,
                        ),
                      if (hadith.arabic.isNotEmpty) const SizedBox(height: 10),

                      // English translation (show preview)
                      if (hadith.english.isNotEmpty)
                        Text(
                          hadith.english,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // "Tap to read more" footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tap to read full hadith',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Allah, the Prophet ﷺ, Dhikr, Salah, and Duas
// ────────────────────────────────────────────────────────────────

class _HomeGuideCards extends StatelessWidget {
  const _HomeGuideCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeIdentityCard(
                key: const Key('home-card-allah'),
                arabic: '\u0627\u0644\u0644\u0647',
                english: 'Allah',
                onTap: () => context.push(AppRoute.aboutAllah),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeIdentityCard(
                key: const Key('home-card-prophet'),
                arabic: '\u0645\u064f\u062d\u064e\u0645\u0651\u064e\u062f',
                english: 'The Prophet \uFDFA',
                onTap: () => context.push(AppRoute.aboutProphet),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeIdentityCard(
                key: const Key('home-card-dhikr'),
                arabic: '\u0630\u0650\u0643\u0652\u0631',
                english: 'Dhikr',
                onTap: () => context.push(AppRoute.dhikr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeIdentityCard(
                key: const Key('home-card-salah'),
                arabic: '\u0635\u064e\u0644\u064e\u0627\u0629',
                english: 'Salah',
                onTap: () => context.push(AppRoute.salah),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _HomeIdentityCard(
          key: const Key('home-card-duas'),
          arabic: '\u0623\u064e\u062f\u0652\u0639\u0650\u064a\u064e\u0629',
          english: 'Duas from the Quran and Sunnah',
          onTap: () => context.push(AppRoute.duas),
        ),
      ],
    );
  }
}

class _HomeIdentityCard extends StatelessWidget {
  const _HomeIdentityCard({
    super.key,
    required this.arabic,
    required this.english,
    required this.onTap,
  });

  final String arabic;
  final String english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          child: Column(
            children: [
              ArabicText(
                arabic,
                fontOverride: ArabicFontOption.amiri,
                fontSize: 28,
                weight: FontWeight.w700,
                align: TextAlign.center,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                english,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Hublee — “my rope”
// ────────────────────────────────────────────────────────────────

/// Name and meaning. Tap opens Ali \u2018Imran 3:103, the ayah of
/// holding fast to the rope of Allah.
class _HubleeMeaningCard extends StatelessWidget {
  const _HubleeMeaningCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          'Hublee means my rope. The rope of Allah is the Quran and '
          'the Sunnah. Opens Ali Imran 3:103.',
      child: Card(
        key: const Key('hublee-meaning-card'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoute.surah(3, ayah: 103)),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.55 : 0.7,
                  ),
                  colorScheme.surface,
                  colorScheme.tertiaryContainer.withValues(
                    alpha: isDark ? 0.4 : 0.55,
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: IslamicStarLatticePainter(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                  child: Column(
                    children: [
                      HubleeStarMark(size: 20, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      ArabicText(
                        '\u062D\u064E\u0628\u0652\u0644\u0650\u064A',
                        fontOverride: ArabicFontOption.amiri,
                        fontSize: 36,
                        weight: FontWeight.w700,
                        align: TextAlign.center,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hublee \u00b7 my rope',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      HubleeRopeMark(
                        width: 120,
                        height: 16,
                        colorA: colorScheme.primary.withValues(alpha: 0.7),
                        colorB: colorScheme.tertiary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'In Arabic, Hublee means \u201cmy rope.\u201d The '
                        'rope of Allah is the Quran and the Sunnah of '
                        'Prophet Muhammad (peace be upon him) \u2014 '
                        'hold fast to both.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ali \u2018Imran 3:103',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder sized to the daily feature cards so the home layout
/// does not jump when verse/hadith finish loading.
class _DailyCardSkeleton extends StatelessWidget {
  final String label;

  const _DailyCardSkeleton({super.key, required this.label});

  static const double height = 168;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
          borderRadius: AppRadius.featureCard,
        ),
      ),
    );
  }
}

/// Same footprint as [_DailyCardSkeleton], with a retry action.
class _DailyCardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DailyCardError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        height: _DailyCardSkeleton.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: AppRadius.featureCard,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
