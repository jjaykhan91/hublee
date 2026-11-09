/// Reading the whole Quran once a lunar month, in whole surahs.
///
/// The day-by-day plan is from Sheikh Imran Hosein's book The Qur'an and
/// the Moon. Each day is a run of complete surahs in mushaf order, so a
/// reader never stops partway through a surah at a juz boundary. Long
/// surahs come first, so the daily portion shrinks as the moon wanes.
library;

/// One day of the month: the surahs read that day, and an optional note.
class LunarReadingDay {
  const LunarReadingDay(this.day, this.surahs, {this.note});

  /// Day of the lunar month, 1 to 30.
  final int day;

  /// Surah ids, in mushaf order.
  final List<int> surahs;

  /// What the Sheikh marks about this day, if anything.
  final String? note;
}

/// Al-Fatihah sits before Day 1; the schedule starts at Al-Baqarah.
const lunarOpeningSurah = 1;

/// The 30-day plan, covering surahs 2 to 114 exactly once.
const lunarMonthSchedule = <LunarReadingDay>[
  LunarReadingDay(1, [2], note: 'First of six days of creation'),
  LunarReadingDay(2, [3]),
  LunarReadingDay(3, [4]),
  LunarReadingDay(4, [5]),
  LunarReadingDay(5, [6]),
  LunarReadingDay(6, [7], note: 'Last single-surah day'),
  LunarReadingDay(7, [8, 9], note: 'End of the first week'),
  LunarReadingDay(8, [10, 11]),
  LunarReadingDay(9, [12, 13]),
  LunarReadingDay(10, [14, 15]),
  LunarReadingDay(11, [16]),
  LunarReadingDay(12, [17, 18]),
  LunarReadingDay(13, [19, 20]),
  LunarReadingDay(14, [21, 22]),
  LunarReadingDay(15, [23, 24], note: 'Full moon, halfway'),
  LunarReadingDay(16, [25, 26]),
  LunarReadingDay(17, [27, 28, 29]),
  LunarReadingDay(18, [30, 31, 32, 33]),
  LunarReadingDay(19, [34, 35, 36, 37]),
  LunarReadingDay(20, [38, 39, 40]),
  LunarReadingDay(21, [41, 42, 43, 44]),
  LunarReadingDay(22, [45, 46, 47, 48, 49]),
  LunarReadingDay(23, [50, 51, 52, 53, 54]),
  LunarReadingDay(24, [55, 56, 57, 58]),
  LunarReadingDay(25, [59, 60, 61, 62, 63, 64, 65, 66, 67, 68]),
  LunarReadingDay(26, [69, 70, 71, 72, 73, 74]),
  LunarReadingDay(27, [75, 76, 77, 78, 79]),
  LunarReadingDay(28, [80, 81, 82, 83, 84, 85, 86, 87, 88]),
  LunarReadingDay(29, [
    89, 90, 91, 92, 93, 94, 95, 96, 97, //
  ], note: 'Look for the new crescent after sunset'),
  LunarReadingDay(30, [
    98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, //
    112, 113, 114,
  ], note: 'Read on night 29 if the crescent is seen'),
];
