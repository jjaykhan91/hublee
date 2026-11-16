/// Widget tests that the surah reader follows the playing ayah.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/quran/word_by_word_repository.dart';
import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
import 'package:hublee/services/recitation_scope.dart';
import 'package:hublee/services/recitation_service.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/services/settings_scope.dart';
import 'package:hublee/services/vocab_scope.dart';
import 'package:hublee/services/vocab_service.dart';
import 'package:hublee/ui/surah_reader_page.dart';

class _FakePlayback implements RecitationPlayback {
  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<void> playFile(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  VoidCallback? onComplete;

  @override
  void dispose() {}
}

Future<void> _pumpUntilReaderLoaded(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    // Surah data decodes off the fake clock; give it real time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(const Key('surah-details-header')).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('surah reader stayed on its loading spinner');
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranChaptersRepository.resetCache();
    QuranArabicRepository.resetCache();
    QuranTranslationRepository.resetCache();
    WordByWordRepository.resetCache();
    rootBundle.clear();
  });

  Future<(RecitationService, _FakePlayback)> pumpReader(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final playback = _FakePlayback();
    final recitation = RecitationService(playback: playback);
    // Not disposed: the reader stops playback asynchronously on unmount.

    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: BookmarkScope(
          service: BookmarkService(),
          child: VocabScope(
            service: VocabService(),
            child: RecitationScope(
              service: recitation,
              child: const MaterialApp(home: SurahReaderPage(surahId: 2)),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilReaderLoaded(tester);
    return (recitation, playback);
  }

  // The play button sits in each card's footer. The ayah is at the top
  // when its own footer is on screen and the previous ayah's is above it.
  bool atTop(WidgetTester tester, int ayah) {
    double? footer(int a) {
      final f = find.byKey(Key('ayah-play-2-$a'));
      return f.evaluate().isEmpty ? null : tester.getTopLeft(f).dy;
    }

    final own = footer(ayah);
    final previous = footer(ayah - 1);
    return own != null &&
        own > 0 &&
        own < 700 &&
        (previous == null || previous < 0);
  }

  testWidgets('a drag while reading along does not stop following', (
    tester,
  ) async {
    final (recitation, playback) = await pumpReader(tester);

    await recitation.play(surahId: 2, ayah: 4, verseCount: 286);
    await _settle(tester);
    expect(atTop(tester, 4), isTrue);

    // A small nudge keeps ayah 4 on screen.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -60));
    await _settle(tester);

    playback.onComplete!();
    await _settle(tester);
    expect(recitation.current?.ayah, 5);
    expect(atTop(tester, 5), isTrue);
  });

  testWidgets('scrolling far away is left alone', (tester) async {
    final (recitation, playback) = await pumpReader(tester);

    await recitation.play(surahId: 2, ayah: 4, verseCount: 286);
    await _settle(tester);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await _settle(tester);
    }
    expect(find.byKey(const Key('ayah-play-2-4')), findsNothing);

    playback.onComplete!();
    await _settle(tester);
    expect(recitation.current?.ayah, 5);
    expect(find.byKey(const Key('ayah-play-2-5')), findsNothing);
  });
}
