import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const HubleeApp());
}

class HubleeApp extends StatelessWidget {
  const HubleeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hublee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),   // ✅ back to HomePage
    );
  }
}
