/// Publishes one version code to one or more Google Play tracks.
library;

import 'dart:io';

import 'package:googleapis/androidpublisher/v3.dart';

/// Inputs for a single Play Console edit (upload + track assign + commit).
class PlayPublishRequest {
  const PlayPublishRequest({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.tracks,
    required this.status,
    required this.notes,
    this.aab,
    this.notesLanguage = 'en-US',
  });

  /// Application id, e.g. `com.hublee.app`.
  final String packageName;

  /// Marketing version (`1.0.1`).
  final String versionName;

  /// Play version code. Used when [aab] is omitted; overwritten by upload.
  final int versionCode;

  /// Play track ids (`internal`, `alpha`, …).
  final List<String> tracks;

  /// `completed`, `draft`, or `halted`.
  final String status;

  /// "What's new" text for [notesLanguage].
  final String notes;

  /// Signed AAB to upload. Null means assign an already-uploaded code.
  final File? aab;

  /// Play listing locale for release notes.
  final String notesLanguage;
}

/// Opens an edit, optionally uploads [PlayPublishRequest.aab], assigns every
/// track, and commits.
///
/// [log] receives progress lines (no secrets).
Future<int> publishAppBundle({
  required AndroidPublisherApi api,
  required PlayPublishRequest request,
  void Function(String message)? log,
}) async {
  void say(String message) => log?.call(message);

  final edit = await api.edits.insert(AppEdit(), request.packageName);
  final editId = edit.id;
  if (editId == null || editId.isEmpty) {
    throw StateError('Play API returned an edit with no id');
  }
  say('Opened Play edit $editId');

  var versionCode = request.versionCode;
  final aab = request.aab;
  if (aab != null) {
    final length = aab.lengthSync();
    say('Uploading ${aab.path} ($length bytes)');
    final media = Media(aab.openRead(), length);
    final bundle = await api.edits.bundles.upload(
      request.packageName,
      editId,
      uploadMedia: media,
    );
    versionCode = bundle.versionCode ?? versionCode;
    say('Uploaded version code $versionCode');
  } else {
    say('Skipping AAB upload; assigning version code $versionCode');
  }

  for (final trackId in request.tracks) {
    say('Assigning version $versionCode to $trackId (${request.status})');
    await api.edits.tracks.update(
      Track(
        track: trackId,
        releases: [
          TrackRelease(
            name: request.versionName,
            status: request.status,
            versionCodes: ['$versionCode'],
            releaseNotes: [
              LocalizedText(
                language: request.notesLanguage,
                text: request.notes,
              ),
            ],
          ),
        ],
      ),
      request.packageName,
      editId,
      trackId,
    );
  }

  await api.edits.commit(request.packageName, editId);
  say('Committed Play edit $editId');
  return versionCode;
}
