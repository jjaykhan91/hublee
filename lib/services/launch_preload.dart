/// Warms session caches during splash so the first real screen is ready.
library;

import 'dart:async';

import '../quran/quran_chapters_repository.dart';
import 'daily_content_service.dart';
import 'hadith_search_service.dart';
import 'home_widget_sync.dart';
import 'quran_search_service.dart';

/// Loads chapter metadata and daily verse/hadith in parallel.
///
/// Chapter load populates [QuranChaptersRepository]'s session cache.
/// Daily verse decode also warms the 4.27 MB mushaf JSON used on Home.
/// Search indexes start in the background so the first query is not a
/// multi-second wait; splash does not wait for them.
Future<void> warmLaunchCaches() {
  startSearchIndexWarmup();
  return Future.wait([
    const QuranChaptersRepository().loadChapters(),
    DailyContentService.loadVerseOfTheDay(),
    DailyContentService.loadHadithOfTheDay(),
  ]).whenComplete(() {
    unawaited(HomeWidgetSync.syncAll());
  });
}

/// Starts Quran and Hadith search indexes without blocking the UI.
///
/// First global search is otherwise a multi-second wait while every
/// surah and hadith book is decoded.
void startSearchIndexWarmup() {
  unawaited(_warmSearchIndexes());
}

Future<void> _warmSearchIndexes() async {
  try {
    await Future.wait([
      const QuranSearchService().warmIndex(),
      const HadithSearchService().warmIndex(),
    ]);
  } catch (_) {
    // Search will build the index on demand if warmup fails.
  }
}
