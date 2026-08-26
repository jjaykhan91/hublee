/// Widget tests for the ayah play control.
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
  VoidCallback? onComplete;

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('play button starts recitation for that ayah', (tester) async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      RecitationScope(
        service: service,
        child: const MaterialApp(
          home: Scaffold(
            body: AyahRecitationBar(surahId: 1, ayah: 1, verseCount: 7),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('ayah-play-1-1')));
    await tester.pump();
    expect(service.isPlayingPassage(1, 1), isTrue);
    expect(playback.urls, isNotEmpty);
  });
}
