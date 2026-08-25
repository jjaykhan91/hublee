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
    return response.bodyBytes;
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

/// Thrown when a recitation URL is not HTTP 200 with a body.
class RecitationFetchException implements Exception {
  RecitationFetchException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'RecitationFetchException($statusCode)';
}
