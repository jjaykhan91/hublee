/// Hub and section pages for the salah guide.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../guidance/salah_guide.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../router_paths.dart';
import '../services/settings_scope.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/guidance_nav_card.dart';
import 'widgets/guidance_section_body.dart';
import 'widgets/hublee_card.dart';
import 'widgets/section_header.dart';

/// Full-screen salah guide. [sectionId] `null` is the hub.
class SalahPage extends StatelessWidget {
  const SalahPage({super.key, this.sectionId});

  final String? sectionId;

  @override
  Widget build(BuildContext context) {
    final id = sectionId;
    if (id == null) return const _SalahHub();
    switch (id) {
      case SalahSectionId.fard:
        return const _SalahPrayersPage(
          title: 'The five daily prayers',
          prayers: salahFardPrayers,
        );
      case SalahSectionId.sunnah:
        return const _SalahPrayersPage(
          title: 'Sunnah around the fard',
          prayers: salahSunnahPrayers,
          intro:
              'The Prophet ﷺ said whoever prays twelve rak‘ahs in a day '
              'and a night, a house is built for him in Paradise. '
              '(Sahih Muslim 728). Jami at-Tirmidhi 414 lists them around '
              'the fard. Asr has no rak‘ah in that twelve. Witr is separate '
              'and follows Isha.',
        );
      case SalahSectionId.nawafil:
        return const _SalahPrayersPage(
          title: 'Nawafil',
          prayers: salahNaflPrayers,
          intro:
              'These are extra. They do not replace the five. This is a '
              'short list, not every voluntary prayer that exists.',
        );
      case SalahSectionId.howTo:
        return const _HowToPrayPage();
      case SalahSectionId.recite:
        return const _WhatToRecitePage();
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Salah')),
          body: const Center(child: Text('That section was not found.')),
        );
    }
  }
}

class _SalahHub extends StatelessWidget {
  const _SalahHub();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Salah')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          for (final paragraph in salahIntroParagraphs) ...[
            Text(
              paragraph,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 14),
          ],
          for (final tile in salahHubTiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GuidanceNavCard(
                title: tile.title,
                subtitle: tile.subtitle,
                onTap: () => context.push(AppRoute.salahSection(tile.id)),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            salahSourceNote,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalahPrayersPage extends StatelessWidget {
  const _SalahPrayersPage({
    required this.title,
    required this.prayers,
    this.intro,
  });

  final String title;
  final List<SalahPrayer> prayers;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          if (intro != null) ...[
            Text(
              intro!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          for (final prayer in prayers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SalahPrayerCard(prayer: prayer),
            ),
        ],
      ),
    );
  }
}

class _SalahPrayerCard extends StatelessWidget {
  const _SalahPrayerCard({required this.prayer});

  final SalahPrayer prayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return HubleeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuidanceArabicText(
            prayer.arabicName,
            fontSize: 26,
            align: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            prayer.englishName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _SalahChip(label: prayer.rakahsLabel),
              _SalahChip(label: _kindLabel(prayer.kind)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prayer.when,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prayer.how,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (prayer.note != null) ...[
            const SizedBox(height: 8),
            Text(
              prayer.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _kindLabel(SalahKind kind) {
    switch (kind) {
      case SalahKind.fard:
        return 'Fard';
      case SalahKind.sunnah:
        return 'Sunnah';
      case SalahKind.nafl:
        return 'Nafl';
    }
  }
}

class _SalahChip extends StatelessWidget {
  const _SalahChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.chip,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HowToPrayPage extends StatelessWidget {
  const _HowToPrayPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to pray')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          for (var i = 0; i < salahHowToSteps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SalahStepCard(index: i + 1, step: salahHowToSteps[i]),
            ),
        ],
      ),
    );
  }
}

class _SalahStepCard extends StatelessWidget {
  const _SalahStepCard({required this.index, required this.step});

  final int index;
  final SalahStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recitation = step.recitationId == null
        ? null
        : salahRecitationById(step.recitationId!);
    return HubleeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                child: Text(
                  '$index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (recitation != null) ...[
            const SizedBox(height: 12),
            _RecitationBody(recitation: recitation, compact: true),
          ],
        ],
      ),
    );
  }
}

class _WhatToRecitePage extends StatefulWidget {
  const _WhatToRecitePage();

  @override
  State<_WhatToRecitePage> createState() => _WhatToRecitePageState();
}

class _WhatToRecitePageState extends State<_WhatToRecitePage> {
  late final Future<({Map<String, String> arabic, Map<String, String> english})>
  _fatihaFuture;

  @override
  void initState() {
    super.initState();
    _fatihaFuture = _loadFatiha();
  }

  Future<({Map<String, String> arabic, Map<String, String> english})>
  _loadFatiha() async {
    const arabicRepo = QuranArabicRepository();
    const englishRepo = QuranTranslationRepository();
    final arabic = await arabicRepo.loadUthmaniStandard(1);
    final english = await englishRepo.loadClearQuran(1);
    return (arabic: arabic, english: english);
  }

  bool _tajweed(BuildContext context) {
    try {
      return SettingsScope.of(context).tajweedEnabled;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('What to recite')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Al-Fatiha is required in every rak‘ah. The other phrases are '
            'the usual wording of the Prophet ﷺ. Opening du‘a and extra '
            'surahs are sunnah.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SectionHeader('Al-Fatiha', icon: Icons.menu_book_rounded),
          FutureBuilder(
            future: _fatihaFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text("Couldn't load Al-Fatiha.");
              }
              final data = snapshot.data;
              if (data == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return HubleeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var ayah = 1; ayah <= 7; ayah++) ...[
                      if (ayah > 1) const SizedBox(height: 10),
                      Text(
                        '1:$ayah',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ArabicText(
                        data.arabic['$ayah'] ?? '',
                        tajweed: _tajweed(context),
                        fontSize: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.english['$ayah'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoute.surah(1)),
                        child: const Text('Open in reader'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader(
            'In every rak‘ah',
            icon: Icons.auto_awesome_rounded,
          ),
          for (final recitation in salahRecitations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HubleeCard(child: _RecitationBody(recitation: recitation)),
            ),
        ],
      ),
    );
  }
}

class _RecitationBody extends StatelessWidget {
  const _RecitationBody({required this.recitation, this.compact = false});

  final SalahRecitation recitation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          recitation.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        GuidanceArabicText(recitation.arabic, fontSize: compact ? 20 : 22),
        const SizedBox(height: 6),
        Text(
          recitation.transliteration,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.4,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          recitation.english,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 6),
        Text(
          recitation.source,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (recitation.note != null) ...[
          const SizedBox(height: 6),
          Text(
            recitation.note!,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}
