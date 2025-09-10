import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/theme_mode_service.dart';
import 'ui/home_page.dart';

// REAL pages to satisfy Navigator routes, even though HomePage uses MaterialPageRoute:
import 'ui/global_search_page.dart';
import 'ui/surah_list_page.dart';
import 'ui/hadith_collections_page.dart';

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
  ThemeMode _mode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _modeSvc.load().then((m) => setState(() => _mode = m));
  }

  void _toggleTheme() async {
    final next = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _mode = next);
    await _modeSvc.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hublee',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _mode,
      home: HomePage(onToggleTheme: _toggleTheme),

      // Optional named routes (not used by HomePage anymore, but handy elsewhere)
      routes: {
        '/search': (_) => const GlobalSearchPage(),
        '/quran':  (_) => const SurahListPage(),
        '/hadith': (_) => const HadithCollectionsPage(),
      },
    );
  }
}
