/// Hub and detail pages for Prophet Muhammad (peace be upon him).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../guidance/guidance_models.dart';
import '../guidance/guidance_repository.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';
import 'widgets/guidance_nav_card.dart';
import 'widgets/guidance_section_body.dart';

/// Full-screen Prophet guide. [sectionId] `null` is the hub.
class ProphetPage extends StatefulWidget {
  const ProphetPage({super.key, this.sectionId});

  final String? sectionId;

  @override
  State<ProphetPage> createState() => _ProphetPageState();
}

class _ProphetPageState extends State<ProphetPage> {
  late Future<ProphetGuide> _future;

  @override
  void initState() {
    super.initState();
    _future = const GuidanceRepository().loadProphet();
  }

  void _retry() {
    setState(() {
      _future = const GuidanceRepository().loadProphet(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProphetGuide>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prophet Muhammad')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Couldn't load this guide."),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _retry, child: const Text('Try again')),
                ],
              ),
            ),
          );
        }
        final guide = snapshot.data;
        if (guide == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prophet Muhammad')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final sectionId = widget.sectionId;
        if (sectionId == null) {
          return _ProphetHub(guide: guide);
        }
        final section = guide.sectionById(sectionId);
        if (section == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prophet Muhammad')),
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

class _ProphetHub extends StatelessWidget {
  const _ProphetHub({required this.guide});

  final ProphetGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      color: colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Prophet Muhammad')),
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
            'ﷺ',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${guide.englishName} (${guide.honorific})',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(guide.intro, style: muted),
          const SizedBox(height: 20),
          for (final section in guide.sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GuidanceNavCard(
                title: section.title,
                subtitle: section.subtitle,
                onTap: () =>
                    context.push(AppRoute.aboutProphetSection(section.id)),
              ),
            ),
        ],
      ),
    );
  }
}
