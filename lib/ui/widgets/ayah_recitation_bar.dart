/// Compact play, reciter, and ayah-repeat controls for one verse.
library;

import 'package:flutter/material.dart';

import '../../services/recitation_scope.dart';
import '../../services/recitation_service.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'reciter_picker.dart';

/// Header-sized recitation cluster: play/pause, reciter chip, and repeat.
class AyahRecitationBar extends StatefulWidget {
  const AyahRecitationBar({
    super.key,
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.verseCount,
  });

  final int surahId;
  final int ayah;
  final String surahName;
  final int verseCount;

  @override
  State<AyahRecitationBar> createState() => _AyahRecitationBarState();
}

class _AyahRecitationBarState extends State<AyahRecitationBar> {
  RecitationService? _recitation;
  var _playing = false;
  var _repeating = false;
  var _reciterId = '';

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
    _repeating = recitation.isRepeatingPassage(widget.surahId, widget.ayah);
    _reciterId = recitation.reciter.id;
  }

  void _onPlayback() {
    final recitation = _recitation;
    if (recitation == null || !mounted) return;
    final playing = recitation.isPlayingPassage(widget.surahId, widget.ayah);
    final repeating = recitation.isRepeatingPassage(
      widget.surahId,
      widget.ayah,
    );
    final reciterId = recitation.reciter.id;
    if (playing == _playing &&
        repeating == _repeating &&
        reciterId == _reciterId) {
      return;
    }
    setState(() {
      _playing = playing;
      _repeating = repeating;
      _reciterId = reciterId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recitation = _recitation;
    if (recitation == null) return const SizedBox.shrink();

    return _AyahRecitationBarBody(
      recitation: recitation,
      surahId: widget.surahId,
      ayah: widget.ayah,
      surahName: widget.surahName,
      verseCount: widget.verseCount,
      playing: _playing,
      repeating: _repeating,
    );
  }
}

class _AyahRecitationBarBody extends StatelessWidget {
  const _AyahRecitationBarBody({
    required this.recitation,
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.verseCount,
    required this.playing,
    required this.repeating,
  });

  final RecitationService recitation;
  final int surahId;
  final int ayah;
  final String surahName;
  final int verseCount;
  final bool playing;
  final bool repeating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reciter = recitation.reciter;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: playing
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: AppRadius.badge,
            border: Border.all(
              color: playing
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                key: Key('ayah-play-$surahId-$ayah'),
                tooltip: playing ? 'Pause recitation' : 'Play ${reciter.label}',
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: colorScheme.primary,
                onPressed: () => _togglePlay(context),
              ),
              InkWell(
                key: Key('ayah-reciter-$surahId-$ayah'),
                borderRadius: AppRadius.badge,
                onTap: () {
                  AppHaptics.selection();
                  showReciterPickerSheet(
                    context,
                    surahId: surahId,
                    surahName: surahName,
                    verseCount: verseCount,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 104),
                        child: Text(
                          reciter.chipLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          key: Key('ayah-repeat-$surahId-$ayah'),
          tooltip: repeating ? 'Stop repeating this ayah' : 'Repeat this ayah',
          icon: repeating ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          color: repeating ? colorScheme.primary : null,
          onPressed: () => _toggleRepeat(context),
        ),
      ],
    );
  }

  Future<void> _togglePlay(BuildContext context) async {
    AppHaptics.selection();
    final error = await recitation.toggle(surahId: surahId, ayah: ayah);
    if (!context.mounted) return;
    _showError(context, error);
  }

  Future<void> _toggleRepeat(BuildContext context) async {
    AppHaptics.selection();
    final error = await recitation.toggleRepeat(surahId: surahId, ayah: ayah);
    if (!context.mounted) return;
    _showError(context, error);
  }

  void _showError(BuildContext context, String? error) {
    if (error == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// 36px icon button matching the ayah number badge.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
