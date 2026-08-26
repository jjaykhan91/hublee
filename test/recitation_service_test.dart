/// Tests for the ayah recitation player, reciters, and surah download.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/services/recitation_cache.dart';
import 'package:hublee/services/recitation_fetcher.dart';
import 'package:hublee/services/recitation_service.dart';
import 'package:hublee/services/reciters.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MissingPluginPlayback implements RecitationPlayback {
  @override
  Future<void> playUrl(String url) {
    throw MissingPluginException('create');
  }

  @override
  Future<void> playFile(String path) {
    throw MissingPluginException('create');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  VoidCallback? onComplete;

  @override
  void dispose() {}
}

class _RecordingPlayback implements RecitationPlayback {
  final urls = <String>[];
  final files = <String>[];
  var stops = 0;
  var looping = false;
  var failUrls = false;
  var failFiles = false;

  @override
  Future<void> playUrl(String url) async {
    if (failUrls) throw Exception('offline');
    urls.add(url);
  }

  @override
  Future<void> playFile(String path) async {
    if (failFiles) throw Exception('bad file');
    files.add(path);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> setLooping(bool value) async {
    looping = value;
  }

  @override
  VoidCallback? onComplete;

  void complete() => onComplete?.call();

  @override
  void dispose() {}
}

class _MapFetcher implements RecitationFetcher {
  _MapFetcher(this.bodies);

  final Map<String, List<int>> bodies;
  final requested = <String>[];

  @override
  Future<List<int>> getBytes(String url) async {
    requested.add(url);
    final body = bodies[url];
    if (body == null) throw RecitationFetchException(404);
    return body;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('builds Alafasy stream URLs', () {
    final reciter = reciterById('alafasy');
    expect(
      recitationUrlsFor(reciter: reciter, surahId: 1, ayah: 1).first,
      'https://audio.qurancdn.com/Alafasy/mp3/001001.mp3',
    );
    expect(recitationUrlsFor(reciter: reciter, surahId: 2, ayah: 255), [
      'https://audio.qurancdn.com/Alafasy/mp3/002255.mp3',
      'https://verses.quran.com/Alafasy/mp3/002255.mp3',
      'https://everyayah.com/data/Alafasy_128kbps/002255.mp3',
      'https://mirrors.quranicaudio.com/everyayah/'
          'Alafasy_128kbps/002255.mp3',
    ]);
  });

  test('Husary has no qurancdn folder and uses EveryAyah first', () {
    final urls = recitationUrlsFor(
      reciter: reciterById('husary'),
      surahId: 1,
      ayah: 1,
    );
    expect(urls.first, contains('everyayah.com/data/Husary_128kbps'));
    expect(urls.any((url) => url.contains('audio.qurancdn.com')), isFalse);
  });

  test('Sudais uses the Quran.com CDN folder from the public API', () {
    expect(
      recitationUrlsFor(
        reciter: reciterById('sudais'),
        surahId: 1,
        ayah: 1,
      ).first,
      'https://audio.qurancdn.com/Sudais/mp3/001001.mp3',
    );
  });

  test('Nasser Al-Qatami uses the EveryAyah Hafs folder', () {
    final urls = recitationUrlsFor(
      reciter: reciterById('qatami'),
      surahId: 1,
      ayah: 1,
    );
    expect(
      urls.first,
      'https://everyayah.com/data/Nasser_Alqatami_128kbps/001001.mp3',
    );
  });

  test('Ahmed ibn Ali al-Ajamy uses the EveryAyah Hafs folder', () {
    final urls = recitationUrlsFor(
      reciter: reciterById('ajamy'),
      surahId: 1,
      ayah: 1,
    );
    expect(
      urls.first,
      'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps/001001.mp3',
    );
  });

  test('unknown reciter id falls back to Alafasy', () {
    expect(reciterById('not-a-reciter').id, kDefaultReciterId);
  });

  test('chipLabel includes style when the reciter has one', () {
    expect(reciterById('alafasy').chipLabel, 'Alafasy');
    expect(
      reciterById('abdulbaset-mujawwad').chipLabel,
      'AbdulBaset · Mujawwad',
    );
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
    final playback = _RecordingPlayback()..failUrls = true;
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

  test('play prefers a cached file over streaming', () async {
    final playback = _RecordingPlayback();
    final cache = MemoryRecitationCache();
    await cache.write(
      reciterId: kDefaultReciterId,
      surahId: 1,
      ayah: 1,
      bytes: [1, 2, 3],
    );
    final service = RecitationService(playback: playback, cache: cache);

    expect(await service.play(surahId: 1, ayah: 1), isNull);
    expect(playback.files, [cache.memoryPath(kDefaultReciterId, 1, 1)]);
    expect(playback.urls, isEmpty);
    service.dispose();
  });

  test(
    'downloadSurah writes every ayah and skips files already kept',
    () async {
      final cache = MemoryRecitationCache();
      await cache.write(
        reciterId: kDefaultReciterId,
        surahId: 112,
        ayah: 1,
        bytes: [9],
      );
      const alafasy001 = 'https://audio.qurancdn.com/Alafasy/mp3/112002.mp3';
      const alafasy002 = 'https://audio.qurancdn.com/Alafasy/mp3/112003.mp3';
      const alafasy003 = 'https://audio.qurancdn.com/Alafasy/mp3/112004.mp3';
      final fetcher = _MapFetcher({
        alafasy001: [2],
        alafasy002: [3],
        alafasy003: [4],
      });
      final service = RecitationService(
        playback: _RecordingPlayback(),
        cache: cache,
        fetcher: fetcher,
      );

      expect(await service.downloadSurah(surahId: 112, verseCount: 4), isNull);
      expect(service.isSurahDownloaded(112, 4), isTrue);
      expect(fetcher.requested.any((url) => url.contains('112001')), isFalse);
      expect(cache.files.length, 4);
      service.dispose();
    },
  );

  test('downloadSurah returns offline when every URL fails', () async {
    final service = RecitationService(
      playback: _RecordingPlayback(),
      cache: MemoryRecitationCache(),
      fetcher: _MapFetcher({}),
    );

    expect(
      await service.downloadSurah(surahId: 1, verseCount: 1),
      kRecitationOfflineMessage,
    );
    service.dispose();
  });

  test('setReciter persists and changes stream URLs', () async {
    final service = RecitationService(playback: _RecordingPlayback());
    await service.setReciter(reciterById('sudais'));
    expect(service.reciter.id, 'sudais');
    expect(
      service.urlFor(surahId: 1, ayah: 1),
      'https://audio.qurancdn.com/Sudais/mp3/001001.mp3',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kRecitationReciterPrefKey), 'sudais');
    service.dispose();
  });

  test('toggleRepeat plays the ayah and loops it', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);

    expect(await service.toggleRepeat(surahId: 1, ayah: 1), isNull);
    expect(service.repeatAyah, isTrue);
    expect(service.isRepeatingPassage(1, 1), isTrue);
    expect(service.isPlayingPassage(1, 1), isTrue);
    expect(playback.looping, isTrue);
    expect(playback.urls, [
      'https://audio.qurancdn.com/Alafasy/mp3/001001.mp3',
    ]);

    expect(await service.toggleRepeat(surahId: 1, ayah: 1), isNull);
    expect(service.repeatAyah, isFalse);
    expect(playback.looping, isFalse);
    expect(service.isPlaying, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kRecitationRepeatPrefKey), isFalse);
    service.dispose();
  });

  test('setReciter while playing restarts that ayah', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);
    expect(await service.play(surahId: 1, ayah: 2), isNull);

    await service.setReciter(reciterById('sudais'));
    expect(service.isPlayingPassage(1, 2), isTrue);
    expect(
      playback.urls.last,
      'https://audio.qurancdn.com/Sudais/mp3/001002.mp3',
    );
    service.dispose();
  });

  test('downloadSurah can target a reciter that is not selected', () async {
    final cache = MemoryRecitationCache();
    const sudaisUrl = 'https://audio.qurancdn.com/Sudais/mp3/001001.mp3';
    final fetcher = _MapFetcher({
      sudaisUrl: [1],
    });
    final service = RecitationService(
      playback: _RecordingPlayback(),
      cache: cache,
      fetcher: fetcher,
    );

    expect(service.reciter.id, kDefaultReciterId);
    expect(
      await service.downloadSurah(
        surahId: 1,
        verseCount: 1,
        reciter: reciterById('sudais'),
      ),
      isNull,
    );
    expect(service.reciter.id, kDefaultReciterId);
    expect(cache.files.containsKey('sudais/1/1'), isTrue);
    service.dispose();
  });

  test('downloadSurahs walks every requested surah', () async {
    final cache = MemoryRecitationCache();
    final fetcher = _MapFetcher({
      'https://audio.qurancdn.com/Alafasy/mp3/112001.mp3': [1],
      'https://audio.qurancdn.com/Alafasy/mp3/108001.mp3': [2],
    });
    final service = RecitationService(
      playback: _RecordingPlayback(),
      cache: cache,
      fetcher: fetcher,
    );

    expect(
      await service.downloadSurahs(
        reciter: reciterById('alafasy'),
        surahs: const [
          RecitationSurahJob(surahId: 112, verseCount: 1),
          RecitationSurahJob(surahId: 108, verseCount: 1),
        ],
      ),
      isNull,
    );
    expect(cache.files.length, 2);
    expect(cache.files.containsKey('alafasy/112/1'), isTrue);
    expect(cache.files.containsKey('alafasy/108/1'), isTrue);
    service.dispose();
  });

  test('complete advances to the next ayah when continue is on', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);

    expect(await service.play(surahId: 1, ayah: 1, verseCount: 7), isNull);
    expect(service.continueToNext, isTrue);
    playback.complete();
    await Future<void>.delayed(Duration.zero);

    expect(service.isPlayingPassage(1, 2), isTrue);
    expect(playback.urls.length, 2);
    service.dispose();
  });

  test('complete stops on the last ayah even when continue is on', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);

    expect(await service.play(surahId: 1, ayah: 7, verseCount: 7), isNull);
    playback.complete();
    await Future<void>.delayed(Duration.zero);

    expect(service.isPlaying, isFalse);
    expect(service.current?.ayah, 7);
    service.dispose();
  });

  test('repeat ayah does not advance on complete', () async {
    final playback = _RecordingPlayback();
    final service = RecitationService(playback: playback);
    await service.setRepeatAyah(true);
    expect(await service.play(surahId: 1, ayah: 1, verseCount: 7), isNull);
    playback.complete();
    await Future<void>.delayed(Duration.zero);

    expect(service.isPlayingPassage(1, 1), isTrue);
    expect(playback.urls.length, 1);
    service.dispose();
  });
}
