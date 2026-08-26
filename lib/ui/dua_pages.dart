/// Dua hub (category cards) and per-category lists.
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
import 'widgets/section_header.dart';

/// Category grid for Quranic and sunnah du'as.
class DuaHubPage extends StatefulWidget {
  const DuaHubPage({super.key});

  @override
  State<DuaHubPage> createState() => _DuaHubPageState();
}

class _DuaHubPageState extends State<DuaHubPage> {
  late Future<DuaCatalog> _future;

  @override
  void initState() {
    super.initState();
    _future = const GuidanceRepository().loadDuas();
  }

  void _retry() {
    setState(() {
      _future = const GuidanceRepository().loadDuas(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DuaCatalog>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Duas')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Couldn't load duas."),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _retry, child: const Text('Try again')),
                ],
              ),
            ),
          );
        }
        final catalog = snapshot.data;
        if (catalog == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Duas')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _DuaHubBody(catalog: catalog);
      },
    );
  }
}

class _DuaHubBody extends StatelessWidget {
  const _DuaHubBody({required this.catalog});

  final DuaCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quran = catalog.categories.where((c) => c.isQuran).toList();
    final sunnah = catalog.categories.where((c) => !c.isQuran).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Duas')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Du\'as Allah taught in the Quran, and authentic sunnah '
            'supplications from Hisn al-Muslim (Fortress of the Muslim).',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (quran.isNotEmpty) ...[
            const SectionHeader(
              'From the Quran',
              icon: Icons.menu_book_rounded,
            ),
            for (final category in quran)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GuidanceNavCard(
                  title: category.title,
                  subtitle: category.subtitle,
                  trailingLabel: '${category.count}',
                  onTap: () => context.push(AppRoute.duaCategory(category.id)),
                ),
              ),
          ],
          if (sunnah.isNotEmpty) ...[
            const SectionHeader(
              'From the Sunnah',
              icon: Icons.library_books_rounded,
            ),
            for (final category in sunnah)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GuidanceNavCard(
                  title: category.title,
                  subtitle: category.subtitle,
                  trailingLabel: '${category.count}',
                  onTap: () => context.push(AppRoute.duaCategory(category.id)),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            catalog.sourceNote,
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

/// One category of du'as (Quranic set or a Hisn al-Muslim chapter).
class DuaCategoryPage extends StatefulWidget {
  const DuaCategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<DuaCategoryPage> createState() => _DuaCategoryPageState();
}

class _DuaCategoryPageState extends State<DuaCategoryPage> {
  late Future<DuaCatalog> _future;

  @override
  void initState() {
    super.initState();
    _future = const GuidanceRepository().loadDuas();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DuaCatalog>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Duas')),
            body: const Center(child: Text("Couldn't load duas.")),
          );
        }
        final catalog = snapshot.data;
        if (catalog == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Duas')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final category = catalog.categoryById(widget.categoryId);
        if (category == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Duas')),
            body: const Center(child: Text('That category was not found.')),
          );
        }
        return _DuaCategoryBody(category: category);
      },
    );
  }
}

class _DuaCategoryBody extends StatelessWidget {
  const _DuaCategoryBody({required this.category});

  final DuaCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          if (category.subtitle != null && category.subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                category.subtitle!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          for (final group in category.groups) ...[
            if (group.title.isNotEmpty)
              SectionHeader(group.title, icon: Icons.auto_awesome_rounded),
            for (final dua in group.duas)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DuaCard(dua: dua),
              ),
          ],
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final DuaEntry dua;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canOpenAyah = dua.surahId != null && dua.ayah != null;

    return HubleeCard(
      onTap: canOpenAyah
          ? () => context.push(AppRoute.surah(dua.surahId!, ayah: dua.ayah))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dua.title != null && dua.title!.isNotEmpty) ...[
            Text(
              dua.title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          GuidanceArabicText(dua.arabic, fontSize: 22),
          if (dua.transliteration != null &&
              dua.transliteration!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dua.transliteration!,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            dua.english,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            dua.source,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dua.note != null && dua.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dua.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          if (canOpenAyah) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Open in reader',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
