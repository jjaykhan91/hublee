/// Hub and detail pages for the Allah guide (tawhid, names, key ayahs).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../guidance/guidance_models.dart';
import '../guidance/guidance_repository.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';
import 'widgets/guidance_nav_card.dart';
import 'widgets/guidance_section_body.dart';
import 'widgets/hublee_card.dart';

/// Full-screen Allah guide. [sectionId] `null` is the hub; `names` is
/// the 99 names; any other id is a prose section.
class AllahPage extends StatefulWidget {
  const AllahPage({super.key, this.sectionId});

  final String? sectionId;

  @override
  State<AllahPage> createState() => _AllahPageState();
}

class _AllahPageState extends State<AllahPage> {
  late Future<AllahGuide> _future;

  @override
  void initState() {
    super.initState();
    _future = const GuidanceRepository().loadAllah();
  }

  void _retry() {
    setState(() {
      _future = const GuidanceRepository().loadAllah(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AllahGuide>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _GuideErrorScaffold(title: 'Allah', onRetry: _retry);
        }
        final guide = snapshot.data;
        if (guide == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Allah')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final sectionId = widget.sectionId;
        if (sectionId == null) {
          return _AllahHub(guide: guide);
        }
        if (sectionId == 'names') {
          return _AllahNamesPage(guide: guide);
        }
        final section = guide.sectionById(sectionId);
        if (section == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Allah')),
            body: const Center(child: Text('That section was not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(section.title)),
          body: ListView(
            padding: AppSpacing.page,
            children: [GuidanceSectionBody(section: section)],
          ),
        );
      },
    );
  }
}

class _AllahHub extends StatelessWidget {
  const _AllahHub({required this.guide});

  final AllahGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      color: colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Allah')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          GuidanceArabicText(
            guide.arabicName,
            fontSize: 40,
            align: TextAlign.center,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            guide.englishName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(guide.intro, style: muted),
          const SizedBox(height: 20),
          for (final section in guide.sections) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GuidanceNavCard(
                title: section.title,
                subtitle: section.subtitle,
                onTap: () =>
                    context.push(AppRoute.aboutAllahSection(section.id)),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GuidanceNavCard(
              title: 'The 99 names',
              subtitle: 'Asma ul-Husna, as commonly taught',
              trailingLabel: '${guide.names.length}',
              onTap: () => context.push(AppRoute.aboutAllahNames),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In the Quran',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final ayah in guide.ayahs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GuidanceAyahCard(ayah: ayah),
            ),
        ],
      ),
    );
  }
}

class _AllahNamesPage extends StatefulWidget {
  const _AllahNamesPage({required this.guide});

  final AllahGuide guide;

  @override
  State<_AllahNamesPage> createState() => _AllahNamesPageState();
}

class _AllahNamesPageState extends State<_AllahNamesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final names = widget.guide.names
        .where((name) => name.matches(_query))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('The 99 names')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search a name or meaning',
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.list,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(
                    widget.guide.namesNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NameCard(name: name),
                  ),
                if (names.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No names match that search.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name});

  final AllahName name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return HubleeCard(
      onTap: name.surahId == null || name.ayah == null
          ? null
          : () => context.push(AppRoute.surah(name.surahId!, ayah: name.ayah)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.badge,
            ),
            child: Text(
              '${name.number}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GuidanceArabicText(
                  name.arabic,
                  fontSize: 26,
                  align: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  name.transliteration,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name.meaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                if (name.surahId != null && name.ayah != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Quran ${name.surahId}:${name.ayah}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideErrorScaffold extends StatelessWidget {
  const _GuideErrorScaffold({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't load this guide."),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
