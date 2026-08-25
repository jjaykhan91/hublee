/// Widget tests for the ayah play, reciter, and repeat controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/recitation_scope.dart';
import 'package:hublee/services/recitation_service.dart';
import 'package:hublee/ui/widgets/ayah_recitation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingPlayback implements RecitationPlayback {
  final urls = <String>[];

  @override
  Future<void> playUrl(String url) async {
    urls.add(url);
  }

  @override
  Future<void> playFile(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ayah bar shows reciter and opens the picker', (tester) async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      RecitationScope(
        service: service,
        child: const MaterialApp(
          home: Scaffold(
            body: AyahRecitationBar(
              surahId: 1,
              ayah: 1,
              surahName: 'Al-Fatiha',
              verseCount: 7,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alafasy'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ayah-reciter-1-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reciter-download-alafasy')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reciter-abdulbaset-mujawwad')));
    await tester.pumpAndSettle();

    expect(service.reciter.id, 'abdulbaset-mujawwad');
    expect(find.text('AbdulBaset · Mujawwad'), findsOneWidget);
  });

  testWidgets('play and repeat buttons drive the recitation service', (
    tester,
  ) async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      RecitationScope(
        service: service,
        child: const MaterialApp(
          home: Scaffold(
            body: AyahRecitationBar(
              surahId: 1,
              ayah: 1,
              surahName: 'Al-Fatiha',
              verseCount: 7,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('ayah-play-1-1')));
    await tester.pump();
    expect(service.isPlayingPassage(1, 1), isTrue);
    expect(playback.urls, isNotEmpty);

    await tester.tap(find.byKey(const Key('ayah-repeat-1-1')));
    await tester.pump();
    expect(service.repeatAyah, isTrue);
    expect(service.isRepeatingPassage(1, 1), isTrue);
  });
}
