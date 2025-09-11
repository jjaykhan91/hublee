import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/theme_mode_service.dart';
import 'ui/home_page.dart';

// REAL pages to satisfy Navigator routes
import 'ui/global_search_page.dart';
import 'ui/surah_list_page.dart';
import 'ui/hadith_collections_page.dart';

import 'services/settings_controller.dart';
import 'services/settings_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HubleeApp());
}

class HubleeApp extends StatefulWidget {
  const HubleeApp({super.key});
  @override
  State<HubleeApp> createState() => _HubleeAppState();
}

class _HubleeAppState extends State<HubleeApp> {
  final _modeSvc = ThemeModeService();
  final _settings = SettingsController();

  ThemeMode _mode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _modeSvc.load().then((m) => setState(() => _mode = m));
    _settings.load(); // load zooms
  }

  void _toggleTheme() async {
    final next = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _mode = next);
    await _modeSvc.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: _settings,
      child: MaterialApp(
        title: 'Hublee',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: _mode,
        home: HomePage(onToggleTheme: _toggleTheme),

        routes: {
          '/search': (_) => const GlobalSearchPage(),
          '/quran' : (_) => const SurahListPage(),
          '/hadith': (_) => const HadithCollectionsPage(),
        },
      ),
    );
  }
}
