/// Checks that we locate the Hublee app root from a nested cwd.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:play_release/repo_root.dart';
import 'package:test/test.dart';

void main() {
  test('finds hublee from this package directory', () {
    final here = Directory.current;
    final root = findHubleeRepoRoot(here);
    expect(
      File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
      contains('name: hublee'),
    );
  });
}
