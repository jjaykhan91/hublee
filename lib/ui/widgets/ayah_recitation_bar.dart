/// Compact play/pause control for one ayah. Reciter, repeat, and
/// continue live on the sticky player bar.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/recitation_scope.dart';
import '../../services/recitation_service.dart';
import 'app_haptics.dart';

/// Play button that starts recitation for [ayah] and opens the player.
class AyahRecitationBar extends StatefulWidget {
  const AyahRecitationBar({
    super.key,
    required this.surahId,
    required this.ayah,
    required this.verseCount,
    this.onPlay,
  });

  final int surahId;
  final int ayah;
  final int verseCount;

  /// Called before playback so the reader can follow this ayah.
  final VoidCallback? onPlay;

  @override
  State<AyahRecitationBar> createState() => _AyahRecitationBarState();
}

class _AyahRecitationBarState extends State<AyahRecitationBar> {
  RecitationService? _recitation;
  var _playing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = RecitationScope.maybeOf(context);
    if (!identical(next, _recitation)) {
      _recitation?.playbackListenable.removeListener(_onPlayback);
      _recitation = next;
      _recitation?.playbackListenable.addListener(_onPlayback);
      _syncFromService();
    }
  }

  @override
  void didUpdateWidget(AyahRecitationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId || oldWidget.ayah != widget.ayah) {
      _syncFromService();
    }
  }

  @override
  void dispose() {
    _recitation?.playbackListenable.removeListener(_onPlayback);
    super.dispose();
  }

  void _syncFromService() {
    final recitation = _recitation;
    if (recitation == null) return;
    _playing = recitation.isPlayingPassage(widget.surahId, widget.ayah);
  }

  void _onPlayback() {
    final recitation = _recitation;
    if (recitation == null || !mounted) return;
    final playing = recitation.isPlayingPassage(widget.surahId, widget.ayah);
    if (playing == _playing) return;
    setState(() => _playing = playing);
  }

  Future<void> _toggle() async {
    final recitation = _recitation;
    if (recitation == null) return;
    AppHaptics.selection();
    widget.onPlay?.call();
    final error = await recitation.toggle(
      surahId: widget.surahId,
      ayah: widget.ayah,
      verseCount: widget.verseCount,
    );
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final recitation = _recitation;
    if (recitation == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      key: Key('ayah-play-${widget.surahId}-${widget.ayah}'),
      tooltip: _playing ? 'Pause recitation' : 'Play this ayah',
      onPressed: () => unawaited(_toggle()),
      icon: Icon(
        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 22,
        color: _playing
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.55),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}
