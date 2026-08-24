/// Streams one reciter's ayah audio and reports a clean offline error.
///
/// Audio is not bundled. Hublee plays Mishary Rashid Alafasy from
/// Quran.com's CDN (with fallbacks) when a connection is available.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Shown when ayah audio cannot be fetched (offline or blocked).
const kRecitationOfflineMessage =
    'Recitation needs a connection. Audio is not stored on this device.';

/// Shown when the native player was not compiled into this process.
///
/// Hot reload / hot restart cannot register [audioplayers]. Stop the
/// app and run it again.
const kRecitationPluginMissingMessage =
    'Restart the app fully so recitation can load. Hot reload is not enough.';

/// Reciter streamed for the ayah play button.
const kRecitationReciterName = 'Mishary Rashid Alafasy';

/// One ayah currently loaded in the player.
@immutable
class RecitationPassage {
  const RecitationPassage({required this.surahId, required this.ayah});

  final int surahId;
  final int ayah;

  bool matches(int surahId, int ayah) =>
      this.surahId == surahId && this.ayah == ayah;
}

/// Plays a remote MP3 URL. Tests inject a fake.
abstract class RecitationPlayback {
  Future<void> playUrl(String url);
  Future<void> stop();
  void dispose();
}

/// Default playback via [AudioPlayer].
class AudioplayersRecitationPlayback implements RecitationPlayback {
  AudioplayersRecitationPlayback({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  void dispose() {
    _player.dispose();
  }
}

/// One-reciter ayah player used by the surah reader.
class RecitationService extends ChangeNotifier {
  RecitationService({RecitationPlayback? playback})
    : _playback = playback ?? AudioplayersRecitationPlayback();

  final RecitationPlayback _playback;

  RecitationPassage? _current;
  bool _playing = false;
  String? _lastError;

  RecitationPassage? get current => _current;
  bool get isPlaying => _playing;
  String? get lastError => _lastError;

  /// Primary Alafasy URL for [surahId]:[ayah] on Quran.com's CDN.
  static String urlFor({required int surahId, required int ayah}) {
    return urlsFor(surahId: surahId, ayah: ayah).first;
  }

  /// Stream URLs to try in order until one plays.
  static List<String> urlsFor({required int surahId, required int ayah}) {
    final surah = surahId.toString().padLeft(3, '0');
    final verse = ayah.toString().padLeft(3, '0');
    final padded = '$surah$verse';
    return [
      'https://audio.qurancdn.com/Alafasy/mp3/$padded.mp3',
      'https://verses.quran.com/Alafasy/mp3/$padded.mp3',
      'https://everyayah.com/data/Alafasy_128kbps/$padded.mp3',
    ];
  }

  /// Whether this ayah is the one currently playing.
  bool isPlayingPassage(int surahId, int ayah) {
    return _playing && (_current?.matches(surahId, ayah) ?? false);
  }

  /// Plays [surahId]:[ayah], or stops if that ayah is already playing.
  ///
  /// Returns an error message when the stream cannot start.
  Future<String?> toggle({required int surahId, required int ayah}) async {
    if (isPlayingPassage(surahId, ayah)) {
      await stop();
      return null;
    }
    return play(surahId: surahId, ayah: ayah);
  }

  /// Starts [surahId]:[ayah]. Stops any previous ayah first.
  Future<String?> play({required int surahId, required int ayah}) async {
    _lastError = null;
    _current = RecitationPassage(surahId: surahId, ayah: ayah);
    _playing = false;
    notifyListeners();

    Object? lastError;
    for (final url in urlsFor(surahId: surahId, ayah: ayah)) {
      try {
        await _playback.playUrl(url);
        _playing = true;
        notifyListeners();
        return null;
      } catch (error, stack) {
        lastError = error;
        debugPrint('Recitation failed for $url: $error\n$stack');
        if (error is MissingPluginException) break;
      }
    }

    _playing = false;
    _lastError = _messageFor(lastError);
    notifyListeners();
    return _lastError;
  }

  /// Stops playback without clearing [current] identity.
  Future<void> stop() async {
    try {
      await _playback.stop();
    } catch (_) {}
    _playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }
}

String _messageFor(Object? error) {
  if (error is MissingPluginException) {
    return kRecitationPluginMissingMessage;
  }
  return kRecitationOfflineMessage;
}
