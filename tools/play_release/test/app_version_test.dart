/// Checks pubspec version parsing used before a Play upload.
library;

import 'package:play_release/app_version.dart';
import 'package:test/test.dart';

void main() {
  test('reads name and code from a Flutter version line', () {
    const yaml = '''
name: hublee
version: 1.0.1+2
''';
    final version = parsePubspecVersion(yaml);
    expect(version.name, '1.0.1');
    expect(version.code, 2);
  });

  test('allows an inline comment after the version', () {
    final version = parsePubspecVersion('version: 2.0.0+9 # play\n');
    expect(version.name, '2.0.0');
    expect(version.code, 9);
  });

  test('throws when the +build is missing', () {
    expect(
      () => parsePubspecVersion('version: 1.0.1\n'),
      throwsFormatException,
    );
  });
}
