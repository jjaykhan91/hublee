/// CLI for Google Play Android Publisher uploads (service-account JSON).
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/io_client.dart';
import 'package:path/path.dart' as p;
import 'package:play_release/app_version.dart';
import 'package:play_release/play_publisher.dart';
import 'package:play_release/play_tracks.dart';
import 'package:play_release/repo_root.dart';

const _defaultJsonName = 'play-service-account.json';
const _defaultPackage = 'com.hublee.app';
const _defaultTracks = 'internal,alpha';
const _allowedStatus = {'completed', 'draft', 'halted'};

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print usage and how to create the service account.',
    )
    ..addOption('json', help: 'Service-account JSON path (gitignored).')
    ..addOption(
      'aab',
      help: 'Signed app bundle. Ignored when --skip-upload is set.',
    )
    ..addOption(
      'package',
      defaultsTo: _defaultPackage,
      help: 'Play application id.',
    )
    ..addOption(
      'tracks',
      defaultsTo: _defaultTracks,
      help: 'Comma-separated tracks (internal, closed/alpha, open/beta).',
    )
    ..addOption(
      'notes',
      help: "What's new (en-US). Defaults to a short version line.",
    )
    ..addOption(
      'notes-file',
      help: 'Read release notes from this file instead of --notes.',
    )
    ..addOption(
      'status',
      defaultsTo: 'completed',
      help: 'completed, draft, or halted.',
    )
    ..addOption(
      'version-code',
      help: 'Override Play version code (default: pubspec +build).',
    )
    ..addFlag(
      'skip-upload',
      negatable: false,
      help: 'Do not upload an AAB; assign an existing version code.',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Resolve paths and print the plan; no network.',
    );

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln(_usage(parser));
    stdout.writeln();
    stdout.writeln(_setupHelp);
    return;
  }

  final status = (args['status'] as String).trim().toLowerCase();
  if (!_allowedStatus.contains(status)) {
    stderr.writeln(
      '--status must be completed, draft, or halted (got $status)',
    );
    exitCode = 64;
    return;
  }

  late final Directory repo;
  try {
    repo = findHubleeRepoRoot();
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 66;
    return;
  }

  final pubspec = File(p.join(repo.path, 'pubspec.yaml'));
  late final AppVersion version;
  try {
    version = parsePubspecVersion(pubspec.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
    return;
  }

  final versionCode = _parseVersionCode(
    args['version-code'] as String?,
    version.code,
  );
  if (versionCode == null) {
    stderr.writeln('--version-code must be a positive integer');
    exitCode = 64;
    return;
  }

  late final List<String> tracks;
  try {
    tracks = parsePlayTracks(args['tracks'] as String);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  final jsonPath =
      args['json'] as String? ?? p.join(repo.path, 'android', _defaultJsonName);
  final jsonFile = File(jsonPath);
  final skipUpload = args['skip-upload'] as bool;
  final aabPath =
      args['aab'] as String? ??
      p.join(
        repo.path,
        'build',
        'app',
        'outputs',
        'bundle',
        'release',
        'app-release.aab',
      );
  final aabFile = skipUpload ? null : File(aabPath);
  final notes = _readNotes(
    notes: args['notes'] as String?,
    notesFile: args['notes-file'] as String?,
    versionName: version.name,
  );
  if (notes == null) {
    exitCode = 65;
    return;
  }

  stdout.writeln('Package:  ${args['package']}');
  stdout.writeln('Version:  ${version.name}+$versionCode');
  stdout.writeln('Tracks:   ${tracks.join(', ')}');
  stdout.writeln('Status:   $status');
  stdout.writeln('JSON:     ${jsonFile.path}');
  stdout.writeln(skipUpload ? 'AAB:      (skipped)' : 'AAB:      $aabPath');

  if (args['dry-run'] as bool) {
    stdout.writeln('Dry run: not calling the Play API.');
    return;
  }

  if (!jsonFile.existsSync()) {
    stderr.writeln('No service-account JSON at ${jsonFile.path}');
    stderr.writeln();
    stderr.writeln(_setupHelp);
    exitCode = 78;
    return;
  }

  if (aabFile != null && !aabFile.existsSync()) {
    stderr.writeln('AAB not found: ${aabFile.path}');
    stderr.writeln('Build with: flutter build appbundle --release');
    exitCode = 66;
    return;
  }

  final credentials = ServiceAccountCredentials.fromJson(
    jsonDecode(jsonFile.readAsStringSync()),
  );
  stdout.writeln('Account:  ${credentials.email}');

  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(minutes: 15);
  final baseClient = IOClient(httpClient);
  final authClient = await clientViaServiceAccount(credentials, [
    AndroidPublisherApi.androidpublisherScope,
  ], baseClient: baseClient);

  try {
    final code = await publishAppBundle(
      api: AndroidPublisherApi(authClient),
      request: PlayPublishRequest(
        packageName: args['package'] as String,
        versionName: version.name,
        versionCode: versionCode,
        tracks: tracks,
        status: status,
        notes: notes,
        aab: aabFile,
      ),
      log: stdout.writeln,
    );
    stdout.writeln('Done. Testers get version code $code.');
  } catch (error) {
    stderr.writeln('Play API failed: $error');
    stderr.writeln(
      'If that version code is already on Play, retry with '
      '--skip-upload --version-code $versionCode',
    );
    exitCode = 1;
  } finally {
    authClient.close();
    // We own this HttpClient (passed in as baseClient). Leaving it
    // open keeps the isolate alive until idleTimeout.
    httpClient.close(force: true);
  }
}

int? _parseVersionCode(String? raw, int fromPubspec) {
  if (raw == null || raw.trim().isEmpty) {
    return fromPubspec;
  }
  final value = int.tryParse(raw.trim());
  if (value == null || value < 1) {
    return null;
  }
  return value;
}

String? _readNotes({
  required String? notes,
  required String? notesFile,
  required String versionName,
}) {
  if (notes != null && notesFile != null) {
    stderr.writeln('Use either --notes or --notes-file, not both');
    return null;
  }
  if (notesFile != null) {
    final file = File(notesFile);
    if (!file.existsSync()) {
      stderr.writeln('Notes file not found: $notesFile');
      return null;
    }
    final text = file.readAsStringSync().trim();
    if (text.isEmpty) {
      stderr.writeln('Notes file is empty: $notesFile');
      return null;
    }
    return text;
  }
  if (notes != null) {
    final text = notes.trim();
    if (text.isEmpty) {
      stderr.writeln('--notes is empty');
      return null;
    }
    return text;
  }
  return 'Hublee $versionName';
}

String _usage(ArgParser parser) =>
    '''
Upload a signed AAB to Google Play (service account, not a Google login).

  dart pub get -C tools/play_release
  Set-Location tools/play_release
  dart run bin/upload.dart

${parser.usage}
''';

const _setupHelp = '''
Play has no email/password API login. "Setup → API access" was
removed. Use a Cloud service account, then invite it in Play:

1. Create a Cloud project:
   https://console.cloud.google.com/projectcreate
2. Enable Google Play Android Developer API:
   https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com
3. Create a service account and download a JSON key:
   https://console.cloud.google.com/iam-admin/serviceaccounts
4. Invite that email (…@….iam.gserviceaccount.com) here:
   https://play.google.com/console/users-and-permissions
   App permissions → Hublee → Release apps to testing tracks.
5. Save the JSON as android/play-service-account.json (gitignored).
6. Permissions can take a few minutes (rarely up to 24h) to apply.

Do not commit the JSON. Same rule as android/key.properties.
''';
