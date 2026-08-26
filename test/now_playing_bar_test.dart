/// Widget tests for the sticky now-playing ayah bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/recitation_scope.dart';
import 'package:hublee/services/recitation_service.dart';
import 'package:hublee/ui/widgets/now_playing_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingPlayback implements RecitationPlayback {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hides when nothing is playing', (tester) async {
    final service = RecitationService(playback: _RecordingPlayback());
    addTearDown(service.dispose);

    await tester.pumpWidget(
      RecitationScope(
        service: service,
        child: MaterialApp(
          home: Scaffold(
            body: NowPlayingBar(
              surahId: 1,
              surahName: 'Al-Fatiha',
              verseCount: 7,
              onJumpToAyah: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('now-playing-bar')), findsNothing);
  });

  testWidgets('shows the playing ayah and jumps on tap', (tester) async {
    final service = RecitationService(playback: _RecordingPlayback());
    addTearDown(service.dispose);
    var jumped = 0;

    await tester.pumpWidget(
      RecitationScope(
        service: service,
        child: MaterialApp(
          home: Scaffold(
            body: NowPlayingBar(
              surahId: 1,
              surahName: 'Al-Fatiha',
              verseCount: 7,
              onJumpToAyah: (ayah) => jumped = ayah,
            ),
          ),
        ),
      ),
    );

    await service.play(surahId: 1, ayah: 5);
    await tester.pump();

    expect(find.byKey(const Key('now-playing-bar')), findsOneWidget);
    expect(find.text('Playing Al-Fatiha 5'), findsOneWidget);
    expect(find.byKey(const Key('now-playing-reciter')), findsOneWidget);
    expect(find.byKey(const Key('now-playing-continue')), findsOneWidget);

    await tester.tap(find.text('Playing Al-Fatiha 5'));
    await tester.pump();
    expect(jumped, 5);

    await tester.tap(find.byKey(const Key('now-playing-continue')));
    await tester.pump();
    expect(service.continueToNext, isFalse);

    await tester.tap(find.byKey(const Key('now-playing-repeat')));
    await tester.pump();
    expect(service.repeatAyah, isTrue);
  });
}
