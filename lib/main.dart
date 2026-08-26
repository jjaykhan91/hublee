/// Application entry point for Hublee.
///
/// Initializes the Flutter app with theme, settings, bookmarks,
/// and go_router navigation.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/app_appearance.dart';
import 'services/theme_mode_service.dart';
import 'services/settings_controller.dart';
import 'services/settings_scope.dart';
import 'services/app_scope.dart';
import 'services/bookmark_service.dart';
import 'services/bookmark_scope.dart';
import 'services/vocab_service.dart';
import 'services/vocab_scope.dart';
import 'services/recitation_service.dart';
import 'services/recitation_scope.dart';
import 'services/recitation_cache.dart';
import 'services/recitation_cache_factory.dart';
import 'services/app_metrics.dart';
import 'services/launch_preload.dart';
import 'services/home_widget_sync.dart';
import 'router.dart';
import 'router_paths.dart';
import 'ui/widgets/metrics_hud.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(HomeWidgetSync.captureLaunch());
  runApp(const HubleeApp());
}

/// Root widget that wires up all services and scopes.
///
/// Provides [SettingsScope], [BookmarkScope], and [AppScope]
/// to the entire widget tree, then delegates routing to [appRouter].
class HubleeApp extends StatefulWidget {
  const HubleeApp({super.key});

  @override
  State<HubleeApp> createState() => _HubleeAppState();
}

class _HubleeAppState extends State<HubleeApp> {
  final _themeModeService = ThemeModeService();
  final _settingsController = SettingsController();
  final _bookmarkService = BookmarkService();
  final _vocabService = VocabService();
  final _recitationService = RecitationService(
    cache: kIsWeb ? const NoopRecitationCache() : createRecitationCache(),
  );

  AppAppearance _appearance = AppAppearance.system;
  bool _overlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _themeModeService.load().then(
      (appearance) => setState(() => _appearance = appearance),
    );
    _settingsController.load();
    _bookmarkService.load();
    _vocabService.load();
    _recitationService.load();
    AppMetrics.instance.attachFrameTiming();
    AppMetrics.instance.addListener(_onOverlay);
    HomeWidgetSync.bindNavigation(
      currentLocation: () {
        try {
          return appRouter.routerDelegate.currentConfiguration.uri.path;
        } catch (_) {
          return '';
        }
      },
      openPath: (path) {
        appRouter.go(AppRoute.home);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.push(path);
        });
      },
    );
    appRouter.routerDelegate.addListener(_onRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startSearchIndexWarmup();
      unawaited(HomeWidgetSync.registerBackgroundWork());
    });
  }

  void _onOverlay() {
    final next = AppMetrics.instance.overlayEnabled;
    if (next == _overlayEnabled) return;
    setState(() => _overlayEnabled = next);
  }

  void _onRoute() {
    AppMetrics.instance.recordNav(
      appRouter.routerDelegate.currentConfiguration.uri.toString(),
    );
  }

  @override
  void dispose() {
    AppMetrics.instance.removeListener(_onOverlay);
    appRouter.routerDelegate.removeListener(_onRoute);
    _settingsController.dispose();
    _vocabService.dispose();
    _recitationService.dispose();
    super.dispose();
  }

  /// Applies and persists [appearance].
  void _setAppearance(AppAppearance appearance) async {
    setState(() => _appearance = appearance);
    AppMetrics.instance.recordUi('theme', detail: {'mode': appearance.name});
    await _themeModeService.save(appearance);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: _settingsController,
      child: BookmarkScope(
        service: _bookmarkService,
        child: VocabScope(
          service: _vocabService,
          child: RecitationScope(
            service: _recitationService,
            child: AppScope(
              appearance: _appearance,
              setAppearance: _setAppearance,
              child: MaterialApp.router(
                title: 'Hublee',
                debugShowCheckedModeBanner: false,
                showPerformanceOverlay: _overlayEnabled,
                theme: _appearance == AppAppearance.paper
                    ? buildPaperTheme()
                    : buildLightTheme(),
                darkTheme: buildDarkTheme(),
                themeMode: _appearance.themeMode,
                routerConfig: appRouter,
                builder: (context, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child ?? const SizedBox.shrink(),
                      if (!kReleaseMode)
                        const Positioned(
                          left: 8,
                          bottom: 88,
                          child: MetricsHud(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
