import 'package:flutter/material.dart';
import 'ui/surah_list_page.dart';

void main() {
  runApp(const HubleeApp());
}

class HubleeApp extends StatelessWidget {
  const HubleeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hublee',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const SurahListPage(),
    );
  }
}
