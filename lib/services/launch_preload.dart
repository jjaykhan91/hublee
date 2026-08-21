/// Warms session caches during splash so the first real screen is ready.
library;

import '../quran/quran_chapters_repository.dart';
import 'daily_content_service.dart';

/// Loads chapter metadata and daily verse/hadith in parallel.
///
/// Chapter load populates [QuranChaptersRepository]'s session cache.
/// Daily verse decode also warms the 4.27 MB mushaf JSON used on Home.
Future<void> warmLaunchCaches() {
  return Future.wait([
    const QuranChaptersRepository().loadChapters(),
    DailyContentService.loadVerseOfTheDay(),
    DailyContentService.loadHadithOfTheDay(),
  ]);
}
