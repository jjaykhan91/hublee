/// Checks the 30-day lunar plan reads every surah once, in order.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/lunar_month_schedule.dart';

void main() {
  test('has 30 days, numbered 1 to 30', () {
    expect(lunarMonthSchedule.map((d) => d.day), [
      for (var day = 1; day <= 30; day++) day,
    ]);
  });

  test('covers surahs 2 to 114 once each, in mushaf order', () {
    final surahs = [for (final day in lunarMonthSchedule) ...day.surahs];
    expect(surahs, [for (var id = 2; id <= 114; id++) id]);
    expect(lunarOpeningSurah, 1);
  });

  test('matches the published surah counts per day', () {
    int count(int day) => lunarMonthSchedule[day - 1].surahs.length;
    for (var day = 1; day <= 6; day++) {
      expect(count(day), 1, reason: 'day $day');
    }
    expect(lunarMonthSchedule[6].surahs, [8, 9]);
    expect(lunarMonthSchedule[14].surahs, [23, 24]);
    expect(count(17), 3);
    expect(count(22), 5);
    expect(count(25), 10);
    expect(count(28), 9);
    expect(count(29), 9);
    expect(count(30), 17);
  });
}
