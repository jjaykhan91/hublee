/// Sticky recitation chrome: reciter, repeat ayah, continue to next.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/recitation_scope.dart';
import '../../services/recitation_service.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'reciter_picker.dart';

/// Compact play/pause + reciter + repeat/continue for the current ayah.
class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.verseCount,
    required this.onJumpToAyah,
  });

  final int surahId;
  final String surahName;
  final int verseCount;
  final void Function(int ayah) onJumpToAyah;

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  RecitationService? _recitation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = RecitationScope.maybeOf(context);
    if (!identical(next, _recitation)) {
      _recitation?.playbackListenable.removeListener(_onPlayback);
      _recitation = next;
      _recitation?.playbackListenable.addListener(_onPlayback);
    }
  }

  @override
  void dispose() {
    _recitation?.playbackListenable.removeListener(_onPlayback);
    super.dispose();
  }

  void _onPlayback() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final recitation = _recitation;
    final current = recitation?.current;
    if (recitation == null ||
        current == null ||
        current.surahId != widget.surahId) {
      return const SizedBox.shrink();
    }

    final playing = recitation.isPlaying;
    final colorScheme = Theme.of(context).colorScheme;
    final label = '${widget.surahName} ${current.ayah}';
    final reciter = recitation.reciter.chipLabel;
    final repeating = recitation.repeatAyah;
    final continuing = recitation.continueToNext;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        key: const Key('now-playing-bar'),
        color: colorScheme.surfaceContainerHighest,
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: Theme.of(context).brightness == Brightness.dark
              ? BorderSide(color: colorScheme.outline)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: playing ? 'Pause' : 'Play',
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  unawaited(
                    recitation.toggle(
                      surahId: current.surahId,
                      ayah: current.ayah,
                      verseCount: widget.verseCount,
                    ),
                  );
                  widget.onJumpToAyah(current.ayah);
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    widget.onJumpToAyah(current.ayah);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playing ? 'Playing $label' : 'Paused $label',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      InkWell(
                        key: const Key('now-playing-reciter'),
                        onTap: () {
                          AppHaptics.selection();
                          showReciterPickerSheet(
                            context,
                            surahId: widget.surahId,
                            surahName: widget.surahName,
                            verseCount: widget.verseCount,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  reciter,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more_rounded,
                                size: 16,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('now-playing-repeat'),
                tooltip: repeating
                    ? 'Stop repeating this ayah'
                    : 'Repeat this ayah',
                icon: Icon(
                  repeating ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  color: repeating ? colorScheme.primary : null,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  unawaited(
                    recitation.toggleRepeat(
                      surahId: current.surahId,
                      ayah: current.ayah,
                    ),
                  );
                  widget.onJumpToAyah(current.ayah);
                },
              ),
              IconButton(
                key: const Key('now-playing-continue'),
                tooltip: continuing
                    ? 'Stop after this ayah'
                    : 'Continue to next ayahs',
                icon: Icon(
                  Icons.playlist_play_rounded,
                  color: continuing ? colorScheme.primary : null,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  unawaited(recitation.setContinueToNext(!continuing));
                  widget.onJumpToAyah(current.ayah);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
