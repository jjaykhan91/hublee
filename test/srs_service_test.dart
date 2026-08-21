/// Tests for SuperMemo-2 interval updates.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/srs_service.dart';

void main() {
  final start = DateTime(2026, 8, 21);

  SrsCard card() => SrsCard(
    id: 'msa:x:y',
    deck: 'msa',
    arabic: 'ماء',
    english: 'water',
    due: start,
  );

  test('Again resets repetitions and schedules tomorrow', () {
    final next = applySm2(card(), SrsRating.again, now: start);
    expect(next.repetitions, 0);
    expect(next.intervalDays, 1);
    expect(next.due, DateTime(2026, 8, 22));
  });

  test('first Good is due in one day', () {
    final next = applySm2(card(), SrsRating.good, now: start);
    expect(next.repetitions, 1);
    expect(next.intervalDays, 1);
  });

  test('second Good is due in six days', () {
    final first = applySm2(card(), SrsRating.good, now: start);
    final second = applySm2(first, SrsRating.good, now: start);
    expect(second.repetitions, 2);
    expect(second.intervalDays, 6);
  });
}
