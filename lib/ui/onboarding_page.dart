/// First-run intro: appearance, Arabic font, and tajweed colours.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/app_scope.dart';
import '../services/onboarding_service.dart';
import '../services/settings_controller.dart';
import '../services/settings_scope.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_haptics.dart';
import 'widgets/appearance_chips.dart';
import 'widgets/arabic_text.dart';
import 'widgets/tajweed.dart';

const _sampleAyah =
    '\u0628\u0650\u0633\u0652\u0645\u0650 '
    '\u0671\u0644\u0644\u0651\u064E\u0647\u0650 '
    '\u0671\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0640\u0670\u0646\u0650 '
    '\u0671\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

/// Full-screen first-run pages shown once after splash.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  var _index = 0;

  static const _pageCount = 3;

  Future<void> _finish() async {
    await OnboardingService.complete();
    if (!mounted) return;
    context.go(AppRoute.home);
  }

  void _next() {
    AppHaptics.selection();
    if (_index >= _pageCount - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final last = _index == _pageCount - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _finish();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [TextButton(onPressed: _finish, child: const Text('Skip'))],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (value) => setState(() => _index = value),
                children: const [_LookPage(), _FontPage(), _TajweedPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: i == _index ? 22 : 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.minTouchTarget,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(last ? 'Start reading' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookPage extends StatelessWidget {
  const _LookPage();

  @override
  Widget build(BuildContext context) {
    final appearance = AppScope.of(context).appearance;
    return _IntroFrame(
      title: 'Choose a look',
      subtitle:
          'Light, dark, or a warm paper theme. You can change this later '
          'in Settings.',
      child: AppearanceChips(
        value: appearance,
        onChanged: AppScope.of(context).setAppearance,
      ),
    );
  }
}

class _FontPage extends StatelessWidget {
  const _FontPage();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _IntroFrame(
      title: 'Arabic typeface',
      subtitle:
          'Uthmanic matches a printed mushaf. The other faces use standard '
          'Unicode and work with tajweed colours.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Card(
            child: Padding(
              padding: AppSpacing.card,
              child: ArabicText(
                _sampleAyah,
                tajweed: false,
                fontSize: 28,
                align: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final font in ArabicFontOption.values)
                ChoiceChip(
                  label: Text(font.label),
                  selected: font == settings.arabicFont,
                  onSelected: (_) {
                    AppHaptics.selection();
                    settings.arabicFont = font;
                  },
                  selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TajweedPage extends StatelessWidget {
  const _TajweedPage();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return _IntroFrame(
      title: 'Tajweed colours',
      subtitle:
          'Letters are coloured for recitation rules, using the Madani '
          'mushaf scheme. Turn this off anytime while reading.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show tajweed colours'),
            value: settings.tajweedEnabled,
            onChanged: (value) {
              AppHaptics.selection();
              settings.tajweedEnabled = value;
            },
          ),
          const SizedBox(height: 8),
          _LegendRow(
            color: kNotPronouncedColor(brightness),
            label: 'Silent / not pronounced',
          ),
          const _LegendRow(
            color: kNormalMaadColor,
            label: 'Normal madd (2 counts)',
          ),
          const _LegendRow(color: kGhunnahColor, label: 'Ghunnah / ikhfa'),
          const _LegendRow(color: kQalqalaColor, label: 'Qalqala (echo)'),
          const _LegendRow(
            color: kMaadLongColor,
            label: 'Necessary madd (6 counts)',
          ),
          const SizedBox(height: 8),
          Text(
            'A full legend is in Settings and on the reader toolbar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.badge,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
