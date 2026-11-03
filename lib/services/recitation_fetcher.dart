/// Downloads ayah MP3 bytes. Tests inject a fake.
library;

import 'package:http/http.dart' as http;

/// Fetches remote audio for recitation download.
abstract class RecitationFetcher {
  /// GET [url] and return the body bytes.
  Future<List<int>> getBytes(String url);

  /// Releases the underlying client.
  void dispose() {}
}

/// Default fetcher using `package:http`.
class HttpRecitationFetcher implements RecitationFetcher {
  HttpRecitationFetcher({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<List<int>> getBytes(String url) async {
    final response = await _client.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw RecitationFetchException(response.statusCode);
    }
    // A captive portal answers 200 with HTML; never store that as audio.
    if (!looksLikeMp3(response.bodyBytes)) {
      throw RecitationFetchException(response.statusCode, notAudio: true);
    }
    return response.bodyBytes;
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

/// Whether [bytes] start like an MP3: an ID3v2 tag or an MPEG frame sync.
bool looksLikeMp3(List<int> bytes) {
  if (bytes.length < 3) return false;
  final id3 = bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
  final frameSync = bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
  return id3 || frameSync;
}

/// Thrown when a recitation URL is not HTTP 200 with an MP3 body.
class RecitationFetchException implements Exception {
  RecitationFetchException(this.statusCode, {this.notAudio = false});

  final int statusCode;

  /// True when the server answered 200 but the body was not audio.
  final bool notAudio;

  @override
  String toString() => notAudio
      ? 'RecitationFetchException($statusCode, not audio)'
      : 'RecitationFetchException($statusCode)';
}
