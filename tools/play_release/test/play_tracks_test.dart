/// Checks Play track aliases used by the upload CLI.
library;

import 'package:play_release/play_tracks.dart';
import 'package:test/test.dart';

void main() {
  test('maps closed testing to the default alpha track', () {
    expect(resolvePlayTrack('closed'), 'alpha');
    expect(resolvePlayTrack('Closed-Testing'), 'alpha');
  });

  test('maps internal and open aliases', () {
    expect(resolvePlayTrack('internal'), 'internal');
    expect(resolvePlayTrack('qa'), 'internal');
    expect(resolvePlayTrack('open'), 'beta');
    expect(resolvePlayTrack('prod'), 'production');
  });

  test('keeps a custom closed-track id', () {
    expect(resolvePlayTrack('fold-testers'), 'fold-testers');
  });

  test('parses a csv list and drops duplicates', () {
    expect(parsePlayTracks('internal, closed, alpha'), ['internal', 'alpha']);
  });

  test('throws on an empty list', () {
    expect(() => parsePlayTracks(' , '), throwsFormatException);
  });
}
