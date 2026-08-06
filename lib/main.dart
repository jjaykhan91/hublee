/// Application entry point for Hublee.
///
/// Initializes the Flutter app with theme, settings, bookmarks,
/// and go_router navigation.
library;

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'services/theme_mode_service.dart';
import 'services/settings_controller.dart';
import 'services/settings_scope.dart';
import 'services/app_scope.dart';
import 'services/bookmark_service.dart';
import 'services/bookmark_scope.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeModeService.load().then((mode) => setState(() => _themeMode = mode));
    _settingsController.load();
    _bookmarkService.load();
  }

  /// Toggles between light and dark theme, then persists the choice.
  void _toggleTheme() async {
    final nextMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() => _themeMode = nextMode);
    await _themeModeService.save(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the app in scoped providers so any descendant can access
    // settings, bookmarks, and the theme toggle.
    return SettingsScope(
      controller: _settingsController,
      child: BookmarkScope(
        service: _bookmarkService,
        child: AppScope(
          toggleTheme: _toggleTheme,
          child: MaterialApp.router(
            title: 'Hublee',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: _themeMode,
            routerConfig: appRouter,
          ),
        ),
      ),
    );
  }
}
