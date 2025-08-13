import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalArabicRepository {
  Future<Map<String, String>> loadArabicForSurah(int surahId) async {
    final path = 'assets/quran/ar/$surahId.json';
    final raw = await rootBundle.loadString(path);
    final m = json.decode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
