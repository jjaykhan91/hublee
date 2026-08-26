/// Maps friendly names to Google Play track ids.
library;

/// Play Console "Closed testing" is the `alpha` track unless the app
/// created extra closed tracks with custom ids.
const playTrackAliases = <String, String>{
  'closed': 'alpha',
  'closed-testing': 'alpha',
  'closed_testing': 'alpha',
  'internal-testing': 'internal',
  'internal_testing': 'internal',
  'qa': 'internal',
  'open': 'beta',
  'open-testing': 'beta',
  'open_testing': 'beta',
  'prod': 'production',
};

/// Returns the Play API track id for [raw] (case-insensitive).
///
/// Unknown names are kept as-is so a custom closed track still works.
String resolvePlayTrack(String raw) {
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) {
    throw const FormatException('empty Play track name');
  }
  return playTrackAliases[key] ?? key;
}

/// Splits a comma-separated track list and de-duplicates resolved ids.
List<String> parsePlayTracks(String csv) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in csv.split(',')) {
    if (part.trim().isEmpty) {
      continue;
    }
    final track = resolvePlayTrack(part);
    if (seen.add(track)) {
      out.add(track);
    }
  }
  if (out.isEmpty) {
    throw const FormatException('need at least one Play track');
  }
  return out;
}
