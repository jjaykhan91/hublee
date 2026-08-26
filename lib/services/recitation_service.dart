/// Streams ayah recitation, with an optional on-device surah cache.
///
/// Audio is not bundled. Hublee streams from Quran.com's CDN and
/// EveryAyah, and can download every ayah of a surah for later play.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recitation_cache.dart';
import 'recitation_fetcher.dart';
import 'reciters.dart';

/// Shown when ayah audio cannot be fetched (offline or blocked).
const kRecitationOfflineMessage =
    'Recitation needs a connection. Download this surah to play it offline.';

/// Shown when the native player was not compiled into this process.
///
/// Hot reload / hot restart cannot register [audioplayers]. Stop the
/// app and run it again.
const kRecitationPluginMissingMessage =
    'Restart the app fully so recitation can load. Hot reload is not enough.';

/// Shown when download is requested on web.
const kRecitationDownloadWebMessage =
    'Surah download is not available on web. Use the installed app.';

/// Prefs key for the selected reciter id.
const kRecitationReciterPrefKey = 'recitation.reciterId';

/// Prefs key for looping the current ayah (memorization).
const kRecitationRepeatPrefKey = 'recitation.repeatAyah';

/// Prefs key for playing the next ayah when the current one ends.
const kRecitationContinuePrefKey = 'recitation.continueToNext';

/// Reciter streamed for the ayah play button when none is saved.
const kRecitationReciterName = 'Mishary Rashid Alafasy';

/// Shown when a second download is requested while one is running.
const kRecitationDownloadBusyMessage =
    'Wait for the current download to finish, or cancel it.';

/// How many ayah files to fetch at once.
const kRecitationDownloadConcurrency = 3;

/// Progress of a surah or full-reciter download.
@immutable
class RecitationDownloadProgress {
  const RecitationDownloadProgress({
    required this.surahId,
    required this.reciterId,
    required this.done,
    required this.total,
    this.surahIndex = 1,
    this.surahCount = 1,
  });

  final int surahId;
  final String reciterId;
  final int done;
  final int total;
  final int surahIndex;
  final int surahCount;

  double? get fraction {
    if (total <= 0) return null;
    return done / total;
  }

  /// Whether this job covers more than one surah.
  bool get isFullReciter => surahCount > 1;
}

/// One surah to download for a reciter.
@immutable
class RecitationSurahJob {
  const RecitationSurahJob({required this.surahId, required this.verseCount});

  final int surahId;
  final int verseCount;
}

/// Ping-able listenable used so ayah chips do not rebuild on download ticks.
class RecitationListenable extends ChangeNotifier {
  /// Notifies listeners.
  void emit() => notifyListeners();
}

/// One ayah currently loaded in the player.
@immutable
class RecitationPassage {
  const RecitationPassage({required this.surahId, required this.ayah});

  final int surahId;
  final int ayah;

  bool matches(int surahId, int ayah) =>
      this.surahId == surahId && this.ayah == ayah;
}

/// Plays a remote MP3 URL or a local file. Tests inject a fake.
abstract class RecitationPlayback {
  Future<void> playUrl(String url);
  Future<void> playFile(String path);
  Future<void> stop();

  /// When true, the current ayah restarts when it ends.
  Future<void> setLooping(bool looping);

  /// Called when the current file finishes (not used while looping).
  VoidCallback? onComplete;

  void dispose();
}

/// Default playback via [AudioPlayer].
class AudioplayersRecitationPlayback implements RecitationPlayback {
  AudioplayersRecitationPlayback({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _completeSub = _player.onPlayerComplete.listen((_) {
      onComplete?.call();
    });
  }

  final AudioPlayer _player;
  StreamSubscription<void>? _completeSub;

  @override
  VoidCallback? onComplete;

  @override
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  @override
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setLooping(bool looping) {
    return _player.setReleaseMode(
      looping ? ReleaseMode.loop : ReleaseMode.release,
    );
  }

  @override
  void dispose() {
    unawaited(_completeSub?.cancel());
    _player.dispose();
  }
}

/// Ayah player with reciter selection and optional surah download.
class RecitationService extends ChangeNotifier {
  RecitationService({
    RecitationPlayback? playback,
    RecitationCache? cache,
    RecitationFetcher? fetcher,
    Reciter? reciter,
  }) : _playback = playback ?? AudioplayersRecitationPlayback(),
       _cache = cache ?? const NoopRecitationCache(),
       _fetcher = fetcher ?? HttpRecitationFetcher(),
       _reciter = reciter ?? reciterById(kDefaultReciterId) {
    _playback.onComplete = () => unawaited(_onPlaybackComplete());
  }

  final RecitationPlayback _playback;
  final RecitationCache _cache;
  final RecitationFetcher _fetcher;

  /// Play, pause, reciter, and repeat. Ayah chips listen here.
  final playbackListenable = RecitationListenable();

  Reciter _reciter;
  RecitationPassage? _current;
  bool _playing = false;
  bool _repeatAyah = false;
  bool _continueToNext = true;
  int? _verseCount;
  bool _advancing = false;
  String? _lastError;
  RecitationDownloadProgress? _downloadProgress;
  bool _downloadCancelled = false;
  final Set<int> _downloadedAyahs = {};
  int? _downloadedSurahId;
  String? _downloadedReciterId;
  DateTime _lastDownloadNotify = DateTime.fromMillisecondsSinceEpoch(0);

  Reciter get reciter => _reciter;

  RecitationPassage? get current => _current;
  bool get isPlaying => _playing;

  /// Whether the current ayah should loop for memorization.
  bool get repeatAyah => _repeatAyah;

  /// Whether playback should continue into the next ayah.
  bool get continueToNext => _continueToNext;

  String? get lastError => _lastError;
  RecitationDownloadProgress? get downloadProgress => _downloadProgress;

  /// Whether a download is in flight.
  bool get isDownloading => _downloadProgress != null;

  /// Restores the saved reciter and repeat mode from [SharedPreferences].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(kRecitationReciterPrefKey);
    _reciter = reciterById(id);
    _repeatAyah = prefs.getBool(kRecitationRepeatPrefKey) ?? false;
    _continueToNext = prefs.getBool(kRecitationContinuePrefKey) ?? true;
    await _trySetLooping(_repeatAyah);
    notifyListeners();
    playbackListenable.emit();
  }

  /// Switches reciter and persists the choice.
  ///
  /// Replays the current ayah with the new voice when it was playing.
  Future<void> setReciter(Reciter reciter) async {
    if (reciter.id == _reciter.id) return;
    final replay = _current;
    final wasPlaying = _playing;
    await stop();
    _reciter = reciter;
    _downloadedAyahs.clear();
    _downloadedSurahId = null;
    _downloadedReciterId = null;
    notifyListeners();
    playbackListenable.emit();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kRecitationReciterPrefKey, reciter.id);
    if (wasPlaying && replay != null) {
      await play(surahId: replay.surahId, ayah: replay.ayah);
    }
  }

  /// Primary stream URL for [surahId]:[ayah] with the current reciter.
  String urlFor({required int surahId, required int ayah}) {
    return urlsFor(surahId: surahId, ayah: ayah).first;
  }

  /// Stream URLs to try in order until one plays.
  List<String> urlsFor({
    required int surahId,
    required int ayah,
    Reciter? reciter,
  }) {
    return recitationUrlsFor(
      reciter: reciter ?? _reciter,
      surahId: surahId,
      ayah: ayah,
    );
  }

  /// Whether this ayah is the one currently playing.
  bool isPlayingPassage(int surahId, int ayah) {
    return _playing && (_current?.matches(surahId, ayah) ?? false);
  }

  /// Whether this ayah will loop when it ends.
  bool isRepeatingPassage(int surahId, int ayah) {
    return _repeatAyah && (_current?.matches(surahId, ayah) ?? false);
  }

  /// Turns ayah looping on or off and persists the choice.
  Future<void> setRepeatAyah(bool value) async {
    if (_repeatAyah == value) {
      await _trySetLooping(value);
      return;
    }
    _repeatAyah = value;
    await _trySetLooping(value);
    notifyListeners();
    playbackListenable.emit();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRecitationRepeatPrefKey, value);
  }

  /// Turns auto-advance on or off and persists the choice.
  Future<void> setContinueToNext(bool value) async {
    if (_continueToNext == value) return;
    _continueToNext = value;
    notifyListeners();
    playbackListenable.emit();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRecitationContinuePrefKey, value);
  }

  /// Loops [surahId]:[ayah] for memorization, or turns looping off.
  ///
  /// Starts playback when that ayah is not already playing.
  Future<String?> toggleRepeat({
    required int surahId,
    required int ayah,
  }) async {
    if (_repeatAyah && (_current?.matches(surahId, ayah) ?? false)) {
      await setRepeatAyah(false);
      return null;
    }
    await setRepeatAyah(true);
    if (isPlayingPassage(surahId, ayah)) return null;
    return play(surahId: surahId, ayah: ayah);
  }

  /// Whether every ayah of [surahId] is on disk for the current reciter.
  bool isSurahDownloaded(int surahId, int verseCount) {
    if (verseCount <= 0) return false;
    if (_downloadedReciterId != _reciter.id) return false;
    if (_downloadedSurahId != surahId) return false;
    return _downloadedAyahs.length >= verseCount;
  }

  /// How many ayahs of [surahId] are already cached.
  int downloadedAyahCount(int surahId) {
    if (_downloadedReciterId != _reciter.id) return 0;
    if (_downloadedSurahId != surahId) return 0;
    return _downloadedAyahs.length;
  }

  /// Refreshes the in-memory download set for [surahId].
  Future<void> refreshDownloadState({
    required int surahId,
    required int verseCount,
  }) async {
    final ayahs = await _cache.downloadedAyahs(
      reciterId: _reciter.id,
      surahId: surahId,
    );
    _downloadedAyahs
      ..clear()
      ..addAll(ayahs);
    _downloadedSurahId = surahId;
    _downloadedReciterId = _reciter.id;
    notifyListeners();
  }

  /// How many ayahs of [surahId] are on disk for [reciter].
  Future<int> cachedAyahCount({
    required Reciter reciter,
    required int surahId,
  }) async {
    final ayahs = await _cache.downloadedAyahs(
      reciterId: reciter.id,
      surahId: surahId,
    );
    return ayahs.length;
  }

  /// Plays [surahId]:[ayah], or stops if that ayah is already playing.
  ///
  /// Returns an error message when the stream cannot start.
  Future<String?> toggle({
    required int surahId,
    required int ayah,
    int? verseCount,
  }) async {
    if (isPlayingPassage(surahId, ayah)) {
      await stop();
      return null;
    }
    return play(surahId: surahId, ayah: ayah, verseCount: verseCount);
  }

  /// Starts [surahId]:[ayah]. Stops any previous ayah first.
  Future<String?> play({
    required int surahId,
    required int ayah,
    int? verseCount,
  }) async {
    _lastError = null;
    if (verseCount != null) {
      _verseCount = verseCount;
    } else if (_current?.surahId != surahId) {
      _verseCount = null;
    }
    _current = RecitationPassage(surahId: surahId, ayah: ayah);
    _playing = false;
    _emitPlayback();

    await _trySetLooping(_repeatAyah);

    final local = await _cache.pathIfPresent(
      reciterId: _reciter.id,
      surahId: surahId,
      ayah: ayah,
    );
    if (local != null) {
      try {
        await _playback.playFile(local);
        _playing = true;
        _emitPlayback();
        return null;
      } catch (error, stack) {
        debugPrint('Recitation local play failed: $error\n$stack');
        if (error is MissingPluginException) {
          _playing = false;
          _lastError = kRecitationPluginMissingMessage;
          _emitPlayback();
          return _lastError;
        }
      }
    }

    Object? lastError;
    for (final url in urlsFor(surahId: surahId, ayah: ayah)) {
      try {
        await _playback.playUrl(url);
        _playing = true;
        _emitPlayback();
        return null;
      } catch (error, stack) {
        lastError = error;
        debugPrint('Recitation failed for $url: $error\n$stack');
        if (error is MissingPluginException) break;
      }
    }

    _playing = false;
    _lastError = _messageFor(lastError);
    _emitPlayback();
    return _lastError;
  }

  /// Downloads every ayah of [surahId].
  ///
  /// Uses [reciter] when given; otherwise the selected reciter.
  /// Skips ayahs already on disk.
  Future<String?> downloadSurah({
    required int surahId,
    required int verseCount,
    Reciter? reciter,
  }) {
    return downloadSurahs(
      reciter: reciter ?? _reciter,
      surahs: [RecitationSurahJob(surahId: surahId, verseCount: verseCount)],
    );
  }

  /// Downloads each job in [surahs] for [reciter], skipping files kept.
  Future<String?> downloadSurahs({
    required Reciter reciter,
    required List<RecitationSurahJob> surahs,
  }) async {
    if (kIsWeb) return kRecitationDownloadWebMessage;
    if (isDownloading) return kRecitationDownloadBusyMessage;
    if (surahs.isEmpty) return null;

    final total = surahs.fold<int>(0, (sum, job) => sum + job.verseCount);
    if (total <= 0) return null;

    _downloadCancelled = false;
    var done = 0;
    _setDownloadProgress(
      reciter: reciter,
      surahId: surahs.first.surahId,
      done: 0,
      total: total,
      surahIndex: 1,
      surahCount: surahs.length,
      force: true,
    );

    try {
      for (var i = 0; i < surahs.length; i++) {
        if (_downloadCancelled) break;
        final job = surahs[i];
        final error = await _downloadOneSurah(
          reciter: reciter,
          surahId: job.surahId,
          verseCount: job.verseCount,
          done: done,
          total: total,
          surahIndex: i + 1,
          surahCount: surahs.length,
          onProgress: (value) => done = value,
        );
        if (error != null) return error;
      }
    } finally {
      _downloadProgress = null;
      notifyListeners();
    }
    return null;
  }

  Future<String?> _downloadOneSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
    required int done,
    required int total,
    required int surahIndex,
    required int surahCount,
    required void Function(int done) onProgress,
  }) async {
    final existing = await _cache.downloadedAyahs(
      reciterId: reciter.id,
      surahId: surahId,
    );
    final missing = <int>[
      for (var ayah = 1; ayah <= verseCount; ayah++)
        if (!existing.contains(ayah)) ayah,
    ];
    var nextDone = done + (verseCount - missing.length);
    _markCachedAyahs(reciter: reciter, surahId: surahId, ayahs: existing);
    _setDownloadProgress(
      reciter: reciter,
      surahId: surahId,
      done: nextDone,
      total: total,
      surahIndex: surahIndex,
      surahCount: surahCount,
    );
    onProgress(nextDone);
    if (missing.isEmpty) return null;

    String? firstError;
    var cursor = 0;
    final workers = kRecitationDownloadConcurrency < missing.length
        ? kRecitationDownloadConcurrency
        : missing.length;

    Future<void> worker() async {
      while (true) {
        if (_downloadCancelled || firstError != null) return;
        if (cursor >= missing.length) return;
        final ayah = missing[cursor++];
        final error = await _fetchAndStoreAyah(
          reciter: reciter,
          surahId: surahId,
          ayah: ayah,
        );
        if (error != null) {
          firstError = error;
          return;
        }
        nextDone++;
        _markCachedAyahs(reciter: reciter, surahId: surahId, ayahs: {ayah});
        _setDownloadProgress(
          reciter: reciter,
          surahId: surahId,
          done: nextDone,
          total: total,
          surahIndex: surahIndex,
          surahCount: surahCount,
        );
        onProgress(nextDone);
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    if (firstError != null) {
      _lastError = firstError;
      notifyListeners();
    }
    return firstError;
  }

  Future<String?> _fetchAndStoreAyah({
    required Reciter reciter,
    required int surahId,
    required int ayah,
  }) async {
    Object? lastError;
    for (final url in urlsFor(surahId: surahId, ayah: ayah, reciter: reciter)) {
      try {
        final bytes = await _fetcher.getBytes(url);
        await _cache.write(
          reciterId: reciter.id,
          surahId: surahId,
          ayah: ayah,
          bytes: bytes,
        );
        return null;
      } catch (error, stack) {
        lastError = error;
        debugPrint('Recitation download failed for $url: $error\n$stack');
      }
    }
    return _messageFor(lastError);
  }

  void _markCachedAyahs({
    required Reciter reciter,
    required int surahId,
    required Set<int> ayahs,
  }) {
    if (reciter.id != _reciter.id) return;
    if (_downloadedSurahId == null && _downloadedReciterId == null) {
      _downloadedSurahId = surahId;
      _downloadedReciterId = reciter.id;
    }
    if (_downloadedReciterId != reciter.id || _downloadedSurahId != surahId) {
      return;
    }
    _downloadedAyahs.addAll(ayahs);
  }

  void _setDownloadProgress({
    required Reciter reciter,
    required int surahId,
    required int done,
    required int total,
    required int surahIndex,
    required int surahCount,
    bool force = false,
  }) {
    _downloadProgress = RecitationDownloadProgress(
      surahId: surahId,
      reciterId: reciter.id,
      done: done,
      total: total,
      surahIndex: surahIndex,
      surahCount: surahCount,
    );
    final now = DateTime.now();
    if (!force &&
        done < total &&
        now.difference(_lastDownloadNotify) <
            const Duration(milliseconds: 160)) {
      return;
    }
    _lastDownloadNotify = now;
    notifyListeners();
  }

  /// Stops an in-flight download. Already-saved ayahs are kept.
  void cancelDownload() {
    _downloadCancelled = true;
  }

  /// Removes cached ayahs for [surahId] and [reciter] or the current reciter.
  Future<void> deleteSurah({
    required int surahId,
    required int verseCount,
    Reciter? reciter,
  }) async {
    final target = reciter ?? _reciter;
    await _cache.deleteSurah(reciterId: target.id, surahId: surahId);
    if (_downloadedSurahId == surahId && _downloadedReciterId == target.id) {
      _downloadedAyahs.clear();
    }
    notifyListeners();
  }

  /// Stops playback without clearing [current] identity.
  Future<void> stop() async {
    try {
      await _playback.stop();
    } catch (_) {}
    _playing = false;
    _emitPlayback();
  }

  void _emitPlayback() {
    notifyListeners();
    playbackListenable.emit();
  }

  Future<void> _onPlaybackComplete() async {
    if (_advancing || !_playing) return;
    if (_repeatAyah) return;
    final current = _current;
    final verseCount = _verseCount;
    if (current != null &&
        _continueToNext &&
        verseCount != null &&
        current.ayah < verseCount) {
      _advancing = true;
      try {
        await play(
          surahId: current.surahId,
          ayah: current.ayah + 1,
          verseCount: verseCount,
        );
      } finally {
        _advancing = false;
      }
      return;
    }
    _playing = false;
    _emitPlayback();
  }

  Future<void> _trySetLooping(bool looping) async {
    try {
      await _playback.setLooping(looping);
    } catch (_) {}
  }

  @override
  void dispose() {
    _fetcher.dispose();
    _playback.dispose();
    playbackListenable.dispose();
    super.dispose();
  }
}

String _messageFor(Object? error) {
  if (error is MissingPluginException) {
    return kRecitationPluginMissingMessage;
  }
  return kRecitationOfflineMessage;
}
