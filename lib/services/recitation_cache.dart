/// Local ayah MP3 cache used for offline surah playback.
library;

/// Stores per-ayah MP3 bytes for a reciter + surah.
abstract class RecitationCache {
  /// File path when that ayah is on disk; otherwise null.
  Future<String?> pathIfPresent({
    required String reciterId,
    required int surahId,
    required int ayah,
  });

  /// Writes [bytes] for one ayah.
  Future<void> write({
    required String reciterId,
    required int surahId,
    required int ayah,
    required List<int> bytes,
  });

  /// Deletes every cached ayah for [surahId] under [reciterId].
  Future<void> deleteSurah({required String reciterId, required int surahId});

  /// Ayah numbers present for [surahId].
  Future<Set<int>> downloadedAyahs({
    required String reciterId,
    required int surahId,
  });
}

/// Cache that never stores files. Used on web and as the default in
/// tests that only exercise streaming.
class NoopRecitationCache implements RecitationCache {
  const NoopRecitationCache();

  @override
  Future<String?> pathIfPresent({
    required String reciterId,
    required int surahId,
    required int ayah,
  }) async => null;

  @override
  Future<void> write({
    required String reciterId,
    required int surahId,
    required int ayah,
    required List<int> bytes,
  }) async {}

  @override
  Future<void> deleteSurah({
    required String reciterId,
    required int surahId,
  }) async {}

  @override
  Future<Set<int>> downloadedAyahs({
    required String reciterId,
    required int surahId,
  }) async => {};
}

/// In-memory cache for unit tests. [pathIfPresent] returns a synthetic
/// path so playback fakes can assert local play without touching disk.
class MemoryRecitationCache implements RecitationCache {
  MemoryRecitationCache();

  final Map<String, List<int>> files = {};

  String _key(String reciterId, int surahId, int ayah) {
    return '$reciterId/$surahId/$ayah';
  }

  /// Synthetic path recorded by [RecitationPlayback.playFile].
  String memoryPath(String reciterId, int surahId, int ayah) {
    return 'memory:${_key(reciterId, surahId, ayah)}';
  }

  @override
  Future<String?> pathIfPresent({
    required String reciterId,
    required int surahId,
    required int ayah,
  }) async {
    final key = _key(reciterId, surahId, ayah);
    if (!files.containsKey(key)) return null;
    return memoryPath(reciterId, surahId, ayah);
  }

  @override
  Future<void> write({
    required String reciterId,
    required int surahId,
    required int ayah,
    required List<int> bytes,
  }) async {
    files[_key(reciterId, surahId, ayah)] = bytes;
  }

  @override
  Future<void> deleteSurah({
    required String reciterId,
    required int surahId,
  }) async {
    final prefix = '$reciterId/$surahId/';
    files.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<Set<int>> downloadedAyahs({
    required String reciterId,
    required int surahId,
  }) async {
    final prefix = '$reciterId/$surahId/';
    final ayahs = <int>{};
    for (final key in files.keys) {
      if (!key.startsWith(prefix)) continue;
      ayahs.add(int.parse(key.substring(prefix.length)));
    }
    return ayahs;
  }
}
