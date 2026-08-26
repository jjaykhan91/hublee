/// Finds the Hublee app root (the folder whose pubspec is `name: hublee`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks [start] and its parents until `pubspec.yaml` named `hublee`.
///
/// [start] defaults to the process working directory.
Directory findHubleeRepoRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 10; i++) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (RegExp(r'^name:\s*hublee\s*$', multiLine: true).hasMatch(text)) {
        return dir;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  throw StateError(
    'Run this from the Hublee repo (or tools/play_release). '
    'Could not find pubspec.yaml with name: hublee.',
  );
}
