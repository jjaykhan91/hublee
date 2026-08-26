/// Parses Hublee's `version: x.y.z+build` line from pubspec.yaml.
library;

/// Marketing version (`1.0.1`) and Play version code (`2`).
class AppVersion {
  const AppVersion({required this.name, required this.code});

  /// Marketing version shown in Play Console (before `+`).
  final String name;

  /// Integer Play version code (after `+`). Must increase every upload.
  final int code;
}

/// Reads `version: 1.0.1+2` from [yaml].
///
/// Throws [FormatException] if the line is missing or not `name+code`.
AppVersion parsePubspecVersion(String yaml) {
  final match = RegExp(
    r'^version:\s*([^+\s#]+)\+(\d+)\s*(?:#.*)?$',
    multiLine: true,
  ).firstMatch(yaml);
  if (match == null) {
    throw const FormatException(
      'pubspec.yaml needs a line like version: 1.0.1+2',
    );
  }
  return AppVersion(name: match.group(1)!, code: int.parse(match.group(2)!));
}
