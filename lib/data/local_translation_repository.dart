import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalTranslationRepository {
  Future<Map<String, String>> loadClearQuranForSurah(int surahId) async {
    final path = 'assets/quran/en.clearquran/$surahId.json';
    final raw = await rootBundle.loadString(path);
    final m = json.decode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
