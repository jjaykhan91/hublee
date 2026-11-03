/// Tests that recitation downloads only accept MP3 bodies.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hublee/services/recitation_fetcher.dart';

HttpRecitationFetcher _fetcherReturning(int status, List<int> body) {
  return HttpRecitationFetcher(
    client: MockClient((_) async => http.Response.bytes(body, status)),
  );
}

void main() {
  group('looksLikeMp3', () {
    test('accepts an ID3 tag and an MPEG frame sync', () {
      expect(looksLikeMp3([0x49, 0x44, 0x33, 0x04]), isTrue);
      expect(looksLikeMp3([0xFF, 0xFB, 0x90, 0x00]), isTrue);
    });

    test('rejects HTML and short bodies', () {
      expect(looksLikeMp3(utf8.encode('<!doctype html>')), isFalse);
      expect(looksLikeMp3([0xFF]), isFalse);
      expect(looksLikeMp3([]), isFalse);
    });
  });

  group('HttpRecitationFetcher', () {
    test('returns MP3 bytes', () async {
      final bytes = [0x49, 0x44, 0x33, 0x04, 0x00];
      expect(await _fetcherReturning(200, bytes).getBytes('u'), bytes);
    });

    test('rejects a 200 HTML page such as a captive portal', () async {
      final fetcher = _fetcherReturning(
        200,
        utf8.encode('<html><body>Sign in to Wi-Fi</body></html>'),
      );
      await expectLater(
        fetcher.getBytes('u'),
        throwsA(
          isA<RecitationFetchException>().having(
            (e) => e.notAudio,
            'notAudio',
            isTrue,
          ),
        ),
      );
    });

    test('rejects a non-200 status', () async {
      await expectLater(
        _fetcherReturning(404, [0x49, 0x44, 0x33]).getBytes('u'),
        throwsA(
          isA<RecitationFetchException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });
}
