/// Shared widgets take their colours and sizes from the theme tokens in
/// every appearance, with no per-widget overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hublee/theme/app_appearance.dart';
import 'package:hublee/theme/app_theme.dart';
import 'package:hublee/theme/app_tokens.dart';
import 'package:hublee/ui/app_shell.dart';
import 'package:hublee/ui/widgets/appearance_chips.dart';
import 'package:hublee/ui/widgets/hublee_card.dart';
import 'package:hublee/ui/widgets/section_header.dart';

GoRouter _shellRouter() {
  return GoRouter(
    initialLocation: '/tab0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          for (var i = 0; i < 6; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tab$i',
                  builder: (context, state) => Center(child: Text('tab $i')),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  ThemeData theme, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: theme,
      routerConfig: _shellRouter(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'paper': buildPaperTheme(),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final palette = theme.extension<AppPalette>()!;

    group('$name appearance', () {
      testWidgets('navigation bar is flat, on the canvas, under a hairline', (
        tester,
      ) async {
        await _pumpShell(tester, theme, size: const Size(400, 800));

        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.backgroundColor, isNull);
        expect(bar.indicatorColor, isNull);
        expect(bar.height, isNull);

        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(NavigationBar),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, palette.canvas);
        expect(material.elevation, 0);

        final divider = find.byType(Divider);
        expect(divider, findsOneWidget);
        expect(
          tester.getBottomLeft(divider).dy,
          tester.getTopLeft(find.byType(NavigationBar)).dy,
        );
        expect(
          DividerTheme.of(tester.element(divider)).color,
          palette.hairline,
        );
      });

      testWidgets('navigation rail sits on the canvas', (tester) async {
        await _pumpShell(tester, theme, size: const Size(1200, 800));

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.backgroundColor, isNull);
        expect(find.byType(NavigationBar), findsNothing);
        expect(theme.navigationRailTheme.backgroundColor, palette.canvas);
      });

      testWidgets('appearance chips follow the chip theme', (tester) async {
        AppAppearance? picked;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: AppearanceChips(
                value: AppAppearance.dark,
                onChanged: (choice) => picked = choice,
              ),
            ),
          ),
        );

        for (final chip in tester.widgetList<ChoiceChip>(
          find.byType(ChoiceChip),
        )) {
          expect(chip.selectedColor, isNull);
          expect(chip.labelStyle, isNull);
        }

        Color? labelColor(AppAppearance choice) {
          final text = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.widgetWithText(ChoiceChip, choice.label),
              matching: find.text(choice.label),
            ),
          );
          return text.text.style?.color;
        }

        expect(labelColor(AppAppearance.dark), palette.onPrimaryTint);
        expect(labelColor(AppAppearance.light), palette.ink);

        final target = tester.getSize(
          find.widgetWithText(ChoiceChip, AppAppearance.light.label),
        );
        expect(target.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));

        await tester.tap(find.text(AppAppearance.paper.label));
        expect(picked, AppAppearance.paper);
      });

      testWidgets('section header uses the brand colour and spacing tokens', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: SectionHeader('Quran', icon: Icons.menu_book_rounded),
            ),
          ),
        );

        final title = tester.widget<Text>(find.text('Quran'));
        expect(title.style!.color, palette.primary);
        expect(title.style!.fontSize, AppType.label.fontSize);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.menu_book_rounded)).color,
          palette.primary,
        );
        expect(
          tester.getTopLeft(find.byIcon(Icons.menu_book_rounded)).dx,
          AppSpacing.xs,
        );
      });

      testWidgets('card fills its slot with a hairline edge and no shadow', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 300,
                  child: HubleeCard(
                    onTap: () => taps++,
                    child: const Text('Al-Fatiha'),
                  ),
                ),
              ),
            ),
          ),
        );

        // No margin: the card is exactly as wide as the slot it is given.
        expect(tester.getSize(find.byType(Card)).width, 300);
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(Card),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, palette.surface);
        expect(material.elevation, 0);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.side.color, palette.hairline);

        await tester.tap(find.text('Al-Fatiha'));
        expect(taps, 1);
      });
    });
  }

  testWidgets('six tabs fit a 320dp phone at double text size', (tester) async {
    await _pumpShell(
      tester,
      buildLightTheme(),
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationDestination), findsNWidgets(6));

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('tab 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
