import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/quran/ui/surah_list_page.dart';

class HubleeApp extends StatelessWidget {
  const HubleeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Hublee',
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: const SurahListPage(),
      ),
    );
  }
}
