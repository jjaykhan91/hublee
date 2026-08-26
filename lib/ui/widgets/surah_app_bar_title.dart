/// Tappable calligraphic surah name in the reader app bar.
library;

import 'package:flutter/material.dart';

import '../../quran/models.dart';
import '../../quran/surah_title_cycle.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

/// Cycles Arabic calligraphy → English name → meaning → revelation city.
class SurahAppBarTitle extends StatefulWidget {
  const SurahAppBarTitle({
    super.key,
    required this.chapter,
    this.compact = false,
  });

  final ChapterMeta chapter;
  final bool compact;

  @override
  State<SurahAppBarTitle> createState() => _SurahAppBarTitleState();
}

class _SurahAppBarTitleState extends State<SurahAppBarTitle> {
  SurahTitleCycle _cycle = SurahTitleCycle.arabic;

  @override
  void didUpdateWidget(covariant SurahAppBarTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.id != widget.chapter.id) {
      _cycle = SurahTitleCycle.arabic;
    }
  }

  void _advance() {
    AppHaptics.selection();
    setState(() => _cycle = _cycle.next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapter = widget.chapter;
    final accent = chapter.isMeccan
        ? AppColors.meccanAccent
        : AppColors.medinanAccent;
    final latin = _cycle.displayText(chapter);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontFamily: latin == null ? AppFonts.surahName : null,
      fontWeight: FontWeight.w600,
      fontSize: widget.compact
          ? (latin == null ? 20 : 16)
          : (latin == null ? 24 : 18),
      color: accent,
      height: 1.3,
    );

    return Tooltip(
      message: 'Tap to cycle Arabic, English, meaning, and city',
      child: GestureDetector(
        key: const Key('surah-app-bar-title'),
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: Semantics(
          button: true,
          label: _cycle.semanticsLabel(chapter),
          child: ExcludeSemantics(
            child: Text(
              latin ?? surahNameLigature(chapter.id),
              style: style,
              textDirection: latin == null
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: latin == null ? TextAlign.start : TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
