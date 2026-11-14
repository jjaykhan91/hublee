/// Contrast contract for the colour tokens in `lib/theme/app_tokens.dart`.
///
/// Every text role must meet WCAG AA (4.5:1) on each surface it can sit on,
/// and control borders must meet the 3:1 non-text minimum. Changing a
/// palette value that breaks either fails here rather than on a device.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/theme/app_tokens.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

const _textMinimum = 4.5;
const _nonTextMinimum = 3.0;

void main() {
  const palettes = <String, AppPalette>{
    'light': AppPalette.light,
    'dark': AppPalette.dark,
    'paper': AppPalette.paper,
  };

  for (final MapEntry(key: name, value: p) in palettes.entries) {
    group('$name palette', () {
      final surfaces = <String, Color>{
        'canvas': p.canvas,
        'surface': p.surface,
        'surfaceLow': p.surfaceLow,
        'surfaceMid': p.surfaceMid,
        'surfaceHigh': p.surfaceHigh,
        'surfaceHighest': p.surfaceHighest,
      };

      void expectText(String label, Color foreground, Color background) {
        expect(
          contrast(foreground, background),
          greaterThanOrEqualTo(_textMinimum),
          reason: '$name: $label',
        );
      }

      test('text roles meet AA on every surface step', () {
        final textRoles = <String, Color>{
          'ink': p.ink,
          'inkMuted': p.inkMuted,
          'primary': p.primary,
          'secondary': p.secondary,
          'accent': p.accent,
          'meccan': p.meccan,
          'medinan': p.medinan,
          'error': p.error,
        };
        for (final role in textRoles.entries) {
          for (final surface in surfaces.entries) {
            expectText(
              '${role.key} on ${surface.key}',
              role.value,
              surface.value,
            );
          }
        }
      });

      test('on-colours meet AA on their fills', () {
        expectText('onPrimary', p.onPrimary, p.primary);
        expectText('onPrimaryTint', p.onPrimaryTint, p.primaryTint);
        expectText('onSecondary', p.onSecondary, p.secondary);
        expectText('onSecondaryTint', p.onSecondaryTint, p.secondaryTint);
        expectText('onAccent', p.onAccent, p.accent);
        expectText('onAccentTint', p.onAccentTint, p.accentTint);
        expectText('onError', p.onError, p.error);
        expectText('onErrorTint', p.onErrorTint, p.errorTint);
        expectText('onInverseSurface', p.onInverseSurface, p.inverseSurface);
        expectText('inversePrimary', p.inversePrimary, p.inverseSurface);
      });

      test('control borders meet 3:1 on canvas and surface', () {
        for (final background in [p.canvas, p.surface]) {
          expect(
            contrast(p.outline, background),
            greaterThanOrEqualTo(_nonTextMinimum),
            reason: '$name: outline',
          );
        }
      });

      test('every colour is opaque', () {
        // Contrast is only meaningful for opaque colours.
        final scheme = _themeFor(name).colorScheme;
        for (final color in [
          ...surfaces.values,
          p.ink,
          p.inkMuted,
          p.outline,
          p.hairline,
          scheme.primary,
          scheme.onSurface,
        ]) {
          expect(color.a, 1.0);
        }
      });
    });
  }

  group('theme wiring', () {
    for (final name in palettes.keys) {
      test('$name colour scheme is the palette', () {
        final p = palettes[name]!;
        final theme = _themeFor(name);
        final scheme = theme.colorScheme;

        expect(theme.extension<AppPalette>(), same(p));
        expect(theme.brightness, p.brightness);
        expect(theme.scaffoldBackgroundColor, p.canvas);
        expect(scheme.surface, p.surface);
        expect(scheme.onSurface, p.ink);
        expect(scheme.onSurfaceVariant, p.inkMuted);
        expect(scheme.primary, p.primary);
        expect(scheme.onPrimary, p.onPrimary);
        expect(scheme.primaryContainer, p.primaryTint);
        expect(scheme.tertiary, p.accent);
        expect(scheme.error, p.error);
        expect(scheme.outline, p.outline);
        expect(scheme.outlineVariant, p.hairline);
        expect(scheme.surfaceContainerHighest, p.surfaceHighest);
        expect(scheme.inverseSurface, p.inverseSurface);
      });
    }

    testWidgets('AppPalette.of reads the active theme', (tester) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPaperTheme(),
          home: Builder(
            builder: (context) {
              seen = AppPalette.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(AppPalette.paper));
    });

    testWidgets('AppPalette.of falls back by brightness', (tester) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              seen = AppPalette.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(AppPalette.dark));
    });

    test('palettes interpolate role by role', () {
      final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
      expect(
        mid.canvas,
        Color.lerp(AppPalette.light.canvas, AppPalette.dark.canvas, 0.5),
      );
      expect(
        AppPalette.light.lerp(AppPalette.dark, 0).ink,
        AppPalette.light.ink,
      );
      expect(
        AppPalette.light.lerp(AppPalette.dark, 1).ink,
        AppPalette.dark.ink,
      );
      expect(AppPalette.light.lerp(null, 0.5), same(AppPalette.light));
    });
  });
}

ThemeData _themeFor(String name) => switch (name) {
  'dark' => buildDarkTheme(),
  'paper' => buildPaperTheme(),
  _ => buildLightTheme(),
};
