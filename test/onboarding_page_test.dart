/// Tests for first-run intro routing and the onboarding pages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/services/app_scope.dart';
import 'package:hublee/services/onboarding_service.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/services/settings_scope.dart';
import 'package:hublee/theme/app_appearance.dart';
import 'package:hublee/ui/onboarding_page.dart';
import 'package:hublee/ui/splash_page.dart';
import 'package:hublee/ui/widgets/arabic_font_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OnboardingService.resetCache();
  });

  test('nextRoute is onboarding until complete', () async {
    expect(await OnboardingService.isCompleted(), isFalse);
    expect(await OnboardingService.nextRoute(), AppRoute.onboarding);

    await OnboardingService.complete();
    expect(await OnboardingService.isCompleted(), isTrue);
    expect(await OnboardingService.nextRoute(), AppRoute.home);
  });

  testWidgets('splash opens onboarding when intro is unfinished', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoute.splash,
      routes: [
        GoRoute(
          path: AppRoute.splash,
          builder: (_, _) => SplashPage(
            preload: () async {},
            minDisplay: const Duration(milliseconds: 20),
            maxWait: const Duration(seconds: 2),
          ),
        ),
        GoRoute(
          path: AppRoute.onboarding,
          builder: (_, _) => const Text('INTRO'),
        ),
        GoRoute(path: AppRoute.home, builder: (_, _) => const Text('HOME')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    await tester.pump();
    expect(find.text('INTRO'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('Skip finishes intro and goes home', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.onboarding,
      routes: [
        GoRoute(
          path: AppRoute.onboarding,
          builder: (_, _) => const OnboardingPage(),
        ),
        GoRoute(path: AppRoute.home, builder: (_, _) => const Text('HOME')),
      ],
    );
    addTearDown(router.dispose);

    final settings = SettingsController();
    await settings.load();

    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: AppScope(
          appearance: AppAppearance.system,
          setAppearance: (_) {},
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    expect(find.text('Choose a look'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
    expect(await OnboardingService.isCompleted(), isTrue);
  });

  testWidgets('Next reaches tajweed page then Start reading', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.onboarding,
      routes: [
        GoRoute(
          path: AppRoute.onboarding,
          builder: (_, _) => const OnboardingPage(),
        ),
        GoRoute(path: AppRoute.home, builder: (_, _) => const Text('HOME')),
      ],
    );
    addTearDown(router.dispose);

    final settings = SettingsController();
    await settings.load();

    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: AppScope(
          appearance: AppAppearance.system,
          setAppearance: (_) {},
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Arabic typeface'), findsOneWidget);
    expect(find.byType(ArabicFontList), findsOneWidget);
    await tester.tap(find.text('Noto Naskh'));
    await tester.pump();
    expect(settings.arabicFont, ArabicFontOption.notoNaskh);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Tajweed colours'), findsOneWidget);
    expect(find.text('Show tajweed colours'), findsOneWidget);

    await tester.tap(find.text('Start reading'));
    await tester.pump();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
  });
}
