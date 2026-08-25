/// Reciter picker with per-voice surah and full-Quran download.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../quran/quran_chapters_repository.dart';
import '../../quran/models.dart';
import '../../services/recitation_scope.dart';
import '../../services/recitation_service.dart';
import '../../services/reciters.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

/// Opens a scrollable list of Hafs reciters.
void showReciterPickerSheet(
  BuildContext context, {
  required int surahId,
  required String surahName,
  required int verseCount,
}) {
  final recitation = RecitationScope.maybeOf(context);
  if (recitation == null) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReciterPickerSheet(
      recitation: recitation,
      surahId: surahId,
      surahName: surahName,
      verseCount: verseCount,
    ),
  );
}

class _ReciterPickerSheet extends StatefulWidget {
  const _ReciterPickerSheet({
    required this.recitation,
    required this.surahId,
    required this.surahName,
    required this.verseCount,
  });

  final RecitationService recitation;
  final int surahId;
  final String surahName;
  final int verseCount;

  @override
  State<_ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<_ReciterPickerSheet> {
  Map<String, int> _savedAyahs = {};
  List<ChapterMeta> _chapters = const [];
  var _wasDownloading = false;

  RecitationService get _recitation => widget.recitation;

  @override
  void initState() {
    super.initState();
    _wasDownloading = _recitation.isDownloading;
    _recitation.addListener(_onRecitation);
    unawaited(_loadCounts());
  }

  @override
  void dispose() {
    _recitation.removeListener(_onRecitation);
    super.dispose();
  }

  void _onRecitation() {
    final downloading = _recitation.isDownloading;
    if (_wasDownloading && !downloading) {
      unawaited(_loadCounts());
    }
    _wasDownloading = downloading;
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await Future.wait([
        for (final reciter in kReciters)
          _recitation.cachedAyahCount(
            reciter: reciter,
            surahId: widget.surahId,
          ),
      ]);
      final chapters = await const QuranChaptersRepository().loadChapters();
      if (!mounted) return;
      setState(() {
        _savedAyahs = {
          for (var i = 0; i < kReciters.length; i++) kReciters[i].id: counts[i],
        };
        _chapters = chapters;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      borderRadius: AppRadius.sheetTop,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reciter',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                        ),
                        Text(
                          '${widget.surahName} · ${widget.verseCount} ayahs',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _recitation,
                builder: (context, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                    itemCount: kReciters.length,
                    itemBuilder: (context, index) {
                      final reciter = kReciters[index];
                      return _ReciterTile(
                        reciter: reciter,
                        selected: reciter.id == _recitation.reciter.id,
                        savedAyahs: _savedAyahs[reciter.id] ?? 0,
                        verseCount: widget.verseCount,
                        surahId: widget.surahId,
                        surahName: widget.surahName,
                        chapters: _chapters,
                        recitation: _recitation,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.selected,
    required this.savedAyahs,
    required this.verseCount,
    required this.surahId,
    required this.surahName,
    required this.chapters,
    required this.recitation,
  });

  final Reciter reciter;
  final bool selected;
  final int savedAyahs;
  final int verseCount;
  final int surahId;
  final String surahName;
  final List<ChapterMeta> chapters;
  final RecitationService recitation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = recitation.downloadProgress;
    final downloadingThis =
        progress != null && progress.reciterId == reciter.id;
    final surahSaved = verseCount > 0 && savedAyahs >= verseCount;
    final styleName = reciter.style;

    return ListTile(
      key: Key('reciter-${reciter.id}'),
      selected: selected,
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
        color: selected
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.45),
      ),
      title: Text(reciter.name, overflow: TextOverflow.ellipsis),
      subtitle: downloadingThis
          ? _downloadLabel(progress)
          : (styleName == null ? null : Text(styleName)),
      trailing: kIsWeb
          ? null
          : _ReciterDownloadButton(
              reciter: reciter,
              surahId: surahId,
              surahName: surahName,
              verseCount: verseCount,
              surahSaved: surahSaved,
              downloadingThis: downloadingThis,
              progress: progress,
              chapters: chapters,
              recitation: recitation,
            ),
      onTap: () {
        AppHaptics.selection();
        Navigator.of(context).pop();
        unawaited(recitation.setReciter(reciter));
      },
    );
  }

  Widget _downloadLabel(RecitationDownloadProgress progress) {
    final percent = ((progress.fraction ?? 0) * 100).round();
    if (progress.isFullReciter) {
      return Text(
        'All surahs · ${progress.surahIndex}/${progress.surahCount} · '
        '$percent%',
      );
    }
    return Text('Downloading $surahName · $percent%');
  }
}

class _ReciterDownloadButton extends StatelessWidget {
  const _ReciterDownloadButton({
    required this.reciter,
    required this.surahId,
    required this.surahName,
    required this.verseCount,
    required this.surahSaved,
    required this.downloadingThis,
    required this.progress,
    required this.chapters,
    required this.recitation,
  });

  final Reciter reciter;
  final int surahId;
  final String surahName;
  final int verseCount;
  final bool surahSaved;
  final bool downloadingThis;
  final RecitationDownloadProgress? progress;
  final List<ChapterMeta> chapters;
  final RecitationService recitation;

  @override
  Widget build(BuildContext context) {
    if (downloadingThis) {
      return IconButton(
        key: Key('reciter-cancel-${reciter.id}'),
        tooltip: 'Cancel download',
        onPressed: recitation.cancelDownload,
        icon: SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                value: progress?.fraction,
              ),
              Icon(
                Icons.close_rounded,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<_DownloadChoice>(
      key: Key('reciter-download-${reciter.id}'),
      tooltip: 'Download ${reciter.shortName}',
      icon: Icon(
        surahSaved ? Icons.download_done_rounded : Icons.download_rounded,
        color: surahSaved
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
      onSelected: (choice) {
        AppHaptics.selection();
        unawaited(_onChoice(context, choice));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _DownloadChoice.surah,
          child: Text(
            surahSaved
                ? 'Remove $surahName'
                : 'Download $surahName ($verseCount ayahs)',
          ),
        ),
        PopupMenuItem(
          value: _DownloadChoice.all,
          child: Text('Download all 114 surahs (${reciter.shortName})'),
        ),
      ],
    );
  }

  Future<void> _onChoice(BuildContext context, _DownloadChoice choice) async {
    if (choice == _DownloadChoice.surah && surahSaved) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Remove download?'),
            content: Text(
              'Delete saved audio for $surahName (${reciter.label})?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          );
        },
      );
      if (remove == true) {
        await recitation.deleteSurah(
          surahId: surahId,
          verseCount: verseCount,
          reciter: reciter,
        );
      }
      return;
    }

    if (choice == _DownloadChoice.surah) {
      final error = await recitation.downloadSurah(
        surahId: surahId,
        verseCount: verseCount,
        reciter: reciter,
      );
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (choice == _DownloadChoice.all) {
      var chapters = this.chapters;
      if (chapters.isEmpty) {
        chapters = await const QuranChaptersRepository().loadChapters();
      }
      if (chapters.isEmpty) return;
      if (!context.mounted) return;
      final ayahTotal = chapters.fold<int>(
        0,
        (sum, chapter) => sum + chapter.versesCount,
      );
      final go = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Download all 114 surahs?'),
            content: Text(
              'Save every ayah of the Quran by ${reciter.label} '
              '($ayahTotal ayahs). This can take several minutes and uses '
              'a few hundred megabytes. You can cancel anytime; ayahs '
              'already saved are kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Download'),
              ),
            ],
          );
        },
      );
      if (go != true) return;
      final error = await recitation.downloadSurahs(
        reciter: reciter,
        surahs: [
          for (final chapter in chapters)
            RecitationSurahJob(
              surahId: chapter.id,
              verseCount: chapter.versesCount,
            ),
        ],
      );
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

enum _DownloadChoice { surah, all }
