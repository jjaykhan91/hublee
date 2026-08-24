/// Tests for the ayah recitation player.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/recitation_service.dart';

class _MissingPluginPlayback implements RecitationPlayback {
  @override
  Future<void> playUrl(String url) {
    throw MissingPluginException('create');
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

class _RecordingPlayback implements RecitationPlayback {
  final urls = <String>[];
  var stops = 0;
  var fail = false;

  @override
  Future<void> playUrl(String url) async {
    if (fail) throw Exception('offline');
    urls.add(url);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  void dispose() {}
}

void main() {
  test('builds Alafasy stream URLs', () {
    expect(
      RecitationService.urlFor(surahId: 1, ayah: 1),
      'https://audio.qurancdn.com/Alafasy/mp3/001001.mp3',
    );
    expect(RecitationService.urlsFor(surahId: 2, ayah: 255), [
      'https://audio.qurancdn.com/Alafasy/mp3/002255.mp3',
      'https://verses.quran.com/Alafasy/mp3/002255.mp3',
      'https://everyayah.com/data/Alafasy_128kbps/002255.mp3',
    ]);
  });

  test('toggle plays then pauses the same ayah', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);

    expect(await service.toggle(surahId: 1, ayah: 1), isNull);
    expect(service.isPlayingPassage(1, 1), isTrue);
    expect(playback.urls, [
      'https://audio.qurancdn.com/Alafasy/mp3/001001.mp3',
    ]);

    expect(await service.toggle(surahId: 1, ayah: 1), isNull);
    expect(service.isPlaying, isFalse);
    expect(playback.stops, 1);
    service.dispose();
  });

  test('failed stream returns a clean offline message', () async {
    final playback = _RecordingPlayback()..fail = true;
    final service = RecitationService(playback: playback);

    final error = await service.play(surahId: 1, ayah: 2);
    expect(error, kRecitationOfflineMessage);
    expect(service.isPlaying, isFalse);
    expect(service.lastError, kRecitationOfflineMessage);
    service.dispose();
  });

  test('missing native plugin asks for a full restart', () async {
    final playback = _MissingPluginPlayback();
    final service = RecitationService(playback: playback);

    final error = await service.play(surahId: 1, ayah: 1);
    expect(error, kRecitationPluginMissingMessage);
    expect(service.isPlaying, isFalse);
    service.dispose();
  });
}
