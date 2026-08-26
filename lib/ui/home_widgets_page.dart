/// Settings for Android home-screen widgets: look and pin-to-home.
library;

import 'package:flutter/material.dart';

import '../services/home_widget_sync.dart';
import '../services/widget_look.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_haptics.dart';
import 'widgets/home_screen_widget_preview.dart';

/// Per-widget look chips, live preview, and add-to-home.
class HomeWidgetsPage extends StatefulWidget {
  const HomeWidgetsPage({super.key});

  @override
  State<HomeWidgetsPage> createState() => _HomeWidgetsPageState();
}

class _HomeWidgetsPageState extends State<HomeWidgetsPage> {
  final Map<HomeWidgetKind, WidgetLook> _looks = {
    for (final kind in HomeWidgetKind.values)
      kind: WidgetLook.defaultsFor(kind),
  };
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await Future.wait(
      HomeWidgetKind.values.map((kind) async {
        return MapEntry(kind, await WidgetLookStore.load(kind));
      }),
    );
    if (!mounted) return;
    setState(() {
      _looks.addAll(Map.fromEntries(entries));
      _loaded = true;
    });
  }

  Future<void> _setLook(HomeWidgetKind kind, WidgetLook look) async {
    setState(() => _looks[kind] = look);
    await WidgetLookStore.save(kind, look);
    await HomeWidgetSync.applyLook(kind, look);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen widgets')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            HomeWidgetSync.isSupported
                ? 'Add a widget to your Android home screen. Each one '
                      'has its own look. Content changes once a day.'
                : 'Home screen widgets run on Android. On a phone, open '
                      'this page to choose a look and pin a widget, or '
                      'long-press the home screen and choose Hublee.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          for (final kind in HomeWidgetKind.values)
            _KindCard(
              kind: kind,
              look: _looks[kind] ?? WidgetLook.defaultsFor(kind),
              enabled: _loaded,
              onChanged: (look) => _setLook(kind, look),
            ),
        ],
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.look,
    required this.enabled,
    required this.onChanged,
  });

  final HomeWidgetKind kind;
  final WidgetLook look;
  final bool enabled;
  final ValueChanged<WidgetLook> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kind.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kind.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              HomeScreenWidgetPreview(
                kind: kind,
                look: look,
                copy: _sample(kind),
              ),
              const SizedBox(height: 12),
              Text(
                'Look',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final choice in WidgetLookTheme.values)
                    ChoiceChip(
                      label: Text(choice.label),
                      selected: look.theme == choice,
                      onSelected: enabled
                          ? (_) {
                              AppHaptics.selection();
                              onChanged(look.copyWith(theme: choice));
                            }
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Size',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final choice in WidgetLookSize.values)
                    ChoiceChip(
                      label: Text(choice.label),
                      selected: look.size == choice,
                      onSelected: enabled
                          ? (_) {
                              AppHaptics.selection();
                              onChanged(look.copyWith(size: choice));
                            }
                          : null,
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show English'),
                value: look.showTranslation,
                onChanged: enabled
                    ? (value) {
                        AppHaptics.selection();
                        onChanged(look.copyWith(showTranslation: value));
                      }
                    : null,
              ),
              if (HomeWidgetSync.isSupported)
                FilledButton.tonal(
                  onPressed: enabled
                      ? () async {
                          AppHaptics.lightImpact();
                          final pinned = await HomeWidgetSync.requestPin(kind);
                          if (!context.mounted || pinned) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Long-press the home screen, choose Widgets, '
                                'then Hublee.',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Add to home screen'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

WidgetPreviewCopy _sample(HomeWidgetKind kind) {
  switch (kind) {
    case HomeWidgetKind.ayah:
      return const WidgetPreviewCopy(
        kicker: 'Ayah of the day',
        arabic:
            '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064e'
            '\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e'
            '\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a'
            '\u0645\u0650',
        english: 'In the name of God, the Most Compassionate, Most Merciful.',
        ref: 'Al-Fatihah 1:1',
      );
    case HomeWidgetKind.hadith:
      return const WidgetPreviewCopy(
        kicker: 'Hadith of the day',
        arabic:
            '\u0625\u0650\u0646\u0651\u064e\u0645\u064e\u0627 \u0627\u0644'
            '\u0652\u0623\u064e\u0639\u0652\u0645\u064e\u0627\u0644\u064f '
            '\u0628\u0650\u0627\u0644\u0646\u0651\u0650\u064a\u0651\u064e\u0627'
            '\u062a\u0650',
        english: 'Actions are judged by intentions.',
        ref: 'Nawawi 40',
      );
    case HomeWidgetKind.quranWord:
      return const WidgetPreviewCopy(
        kicker: 'Quran word',
        arabic: '\u0627\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f',
        english: 'All praise',
        ref: 'Al-Fatihah 1:2',
      );
    case HomeWidgetKind.arabicWord:
      return const WidgetPreviewCopy(
        kicker: 'Arabic word',
        arabic: '\u0645\u064e\u0627\u0621',
        english: 'water',
        ref: 'noun',
      );
  }
}
