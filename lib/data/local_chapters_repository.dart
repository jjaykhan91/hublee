import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

class LocalChaptersRepository {
  List<Chapter>? _cache;

  Future<List<Chapter>> loadChapters() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/quran/chapters.min.json');
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(Chapter.fromJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return _cache!;
  }
}
