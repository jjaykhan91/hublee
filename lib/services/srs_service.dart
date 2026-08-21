/// SuperMemo-2 spaced repetition for Arabic study cards.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Again / Hard / Good / Easy, mapped onto SM-2 quality 1, 3, 4, 5.
enum SrsRating { again, hard, good, easy }

/// One study card in the Quranic or Modern Arabic deck.
@immutable
class SrsCard {
  const SrsCard({
    required this.id,
    required this.deck,
    required this.arabic,
    required this.english,
    this.root,
    this.pos,
    this.repetitions = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    required this.due,
  });

  /// `quran` or `msa`.
  final String deck;
  final String id;
  final String arabic;
  final String english;
  final String? root;
  final String? pos;
  final int repetitions;
  final double ease;
  final int intervalDays;
  final DateTime due;

  bool isDueAt(DateTime now) => !due.isAfter(now);

  SrsCard copyWith({
    int? repetitions,
    double? ease,
    int? intervalDays,
    DateTime? due,
  }) => SrsCard(
    id: id,
    deck: deck,
    arabic: arabic,
    english: english,
    root: root,
    pos: pos,
    repetitions: repetitions ?? this.repetitions,
    ease: ease ?? this.ease,
    intervalDays: intervalDays ?? this.intervalDays,
    due: due ?? this.due,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deck': deck,
    'arabic': arabic,
    'english': english,
    'root': root,
    'pos': pos,
    'repetitions': repetitions,
    'ease': ease,
    'intervalDays': intervalDays,
    'due': due.toIso8601String(),
  };

  factory SrsCard.fromJson(Map<String, dynamic> json) => SrsCard(
    id: json['id'] as String,
    deck: json['deck'] as String,
    arabic: json['arabic'] as String,
    english: json['english'] as String,
    root: json['root'] as String?,
    pos: json['pos'] as String?,
    repetitions: json['repetitions'] as int? ?? 0,
    ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
    intervalDays: json['intervalDays'] as int? ?? 0,
    due: DateTime.parse(json['due'] as String),
  );

  static String cardId({
    required String deck,
    required String arabic,
    required String english,
  }) => '$deck:${arabic.trim()}:${english.trim().toLowerCase()}';
}

/// Applies the SuperMemo-2 interval update.
///
/// Quality: Again=1, Hard=3, Good=4, Easy=5. Interval is in whole days.
SrsCard applySm2(SrsCard card, SrsRating rating, {DateTime? now}) {
  final moment = now ?? DateTime.now();
  final quality = switch (rating) {
    SrsRating.again => 1,
    SrsRating.hard => 3,
    SrsRating.good => 4,
    SrsRating.easy => 5,
  };

  var repetitions = card.repetitions;
  var interval = card.intervalDays;
  var ease = card.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  ease = min(2.8, max(1.3, ease));

  if (quality < 3) {
    repetitions = 0;
    interval = 1;
  } else {
    if (repetitions == 0) {
      interval = 1;
    } else if (repetitions == 1) {
      interval = rating == SrsRating.easy ? 8 : 6;
    } else {
      interval = max(1, (interval * ease).round());
      if (rating == SrsRating.hard) {
        interval = max(1, (interval * 0.8).round());
      } else if (rating == SrsRating.easy) {
        interval = max(interval + 1, (interval * 1.3).round());
      }
    }
    repetitions += 1;
  }

  return card.copyWith(
    repetitions: repetitions,
    ease: ease,
    intervalDays: interval,
    due: DateTime(
      moment.year,
      moment.month,
      moment.day,
    ).add(Duration(days: interval)),
  );
}

/// Persists SM-2 cards locally.
class SrsService extends ChangeNotifier {
  static const _kCards = 'srs_cards_v1';

  final Map<String, SrsCard> _cards = {};

  List<SrsCard> get cards => List.unmodifiable(_cards.values);

  int dueCount({String? deck, DateTime? now}) {
    final moment = now ?? DateTime.now();
    return _cards.values
        .where((card) => deck == null || card.deck == deck)
        .where((card) => card.isDueAt(moment))
        .length;
  }

  List<SrsCard> dueCards({String? deck, DateTime? now}) {
    final moment = now ?? DateTime.now();
    final due =
        _cards.values
            .where((card) => deck == null || card.deck == deck)
            .where((card) => card.isDueAt(moment))
            .toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    return due;
  }

  bool contains(String id) => _cards.containsKey(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCards);
    _cards.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final card = SrsCard.fromJson(item);
        _cards[card.id] = card;
      }
    }
    notifyListeners();
  }

  Future<void> ensure(SrsCard card) async {
    if (_cards.containsKey(card.id)) return;
    _cards[card.id] = card;
    notifyListeners();
    await _persist();
  }

  Future<void> review(String id, SrsRating rating, {DateTime? now}) async {
    final current = _cards[id];
    if (current == null) return;
    _cards[id] = applySm2(current, rating, now: now);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _cards.remove(id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCards,
      jsonEncode(_cards.values.map((card) => card.toJson()).toList()),
    );
  }
}
