/// Saved Quranic words for learning, persisted locally.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One word or phrase the reader starred to learn.
@immutable
class VocabEntry {
  const VocabEntry({
    required this.arabic,
    required this.gloss,
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.createdAt,
  });

  final String arabic;
  final String gloss;
  final int surahId;
  final int ayah;
  final String surahName;
  final DateTime createdAt;

  /// Stable id so the same meaning is not saved twice from different ayahs.
  String get id => vocabId(arabic, gloss);

  static String vocabId(String arabic, String gloss) {
    return 'vocab:${_fold(arabic)}:${gloss.trim().toLowerCase()}';
  }

  Map<String, dynamic> toJson() => {
    'arabic': arabic,
    'gloss': gloss,
    'surahId': surahId,
    'ayah': ayah,
    'surahName': surahName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VocabEntry.fromJson(Map<String, dynamic> json) => VocabEntry(
    arabic: json['arabic'] as String,
    gloss: json['gloss'] as String,
    surahId: json['surahId'] as int,
    ayah: json['ayah'] as int,
    surahName: json['surahName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  factory VocabEntry.fromReader({
    required String arabic,
    required String gloss,
    required int surahId,
    required int ayah,
    required String surahName,
  }) => VocabEntry(
    arabic: arabic,
    gloss: gloss,
    surahId: surahId,
    ayah: ayah,
    surahName: surahName,
    createdAt: DateTime.now(),
  );
}

String _fold(String arabic) {
  return arabic
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .trim();
}

/// Favorites list for Quranic words. Local only.
class VocabService extends ChangeNotifier {
  static const _kVocab = 'vocab_favorites';

  List<VocabEntry> _entries = [];
  final Set<String> _ids = {};

  List<VocabEntry> get entries => List.unmodifiable(_entries);

  bool isSaved(String id) => _ids.contains(id);

  bool isSavedWord(String arabic, String gloss) =>
      isSaved(VocabEntry.vocabId(arabic, gloss));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVocab);
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List<dynamic>;
    _entries = list
        .whereType<Map<String, dynamic>>()
        .map(VocabEntry.fromJson)
        .toList();
    _ids
      ..clear()
      ..addAll(_entries.map((e) => e.id));
    notifyListeners();
  }

  Future<void> toggle(VocabEntry entry) async {
    if (_ids.contains(entry.id)) {
      _entries.removeWhere((e) => e.id == entry.id);
      _ids.remove(entry.id);
    } else {
      _entries.insert(0, entry);
      _ids.add(entry.id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _ids.remove(id);
    notifyListeners();
    await _persist();
  }

  Future<void> restore(VocabEntry entry, {int index = 0}) async {
    if (_ids.contains(entry.id)) return;
    final at = index.clamp(0, _entries.length);
    _entries.insert(at, entry);
    _ids.add(entry.id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kVocab,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
