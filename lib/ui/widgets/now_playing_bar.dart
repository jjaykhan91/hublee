/// Sticky recitation chrome so the playing ayah stays visible while
/// the reader is scrolled elsewhere in the surah.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/recitation_scope.dart';
import '../../services/recitation_service.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

/// Compact play/pause + jump control for the ayah currently playing.
class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.onJumpToAyah,
  });

  final int surahId;
  final String surahName;
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

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        key: const Key('now-playing-bar'),
        color: colorScheme.surfaceContainerHighest,
        elevation: 1,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () {
            AppHaptics.selection();
            widget.onJumpToAyah(current.ayah);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
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
                      ),
                    );
                  },
                ),
                Expanded(
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
                      Text(
                        reciter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Jump',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
