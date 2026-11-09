/// A small bound-book cover, for hadith books and the Learn tools: coloured leather, a
/// tooled gold pattern and frame, and the book's Arabic name.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../hadith/hadith_book_art.dart';
import '../../services/settings_controller.dart';
import 'arabic_text.dart';
import 'hublee_marks.dart';

/// Cover for the hadith book in [file]. Decorative: the book's English
/// title is always shown beside it, so the cover is hidden from screen
/// readers.
class HadithBookCover extends StatelessWidget {
  const HadithBookCover({
    super.key,
    required this.file,
    required this.width,
    required this.height,
    this.fullTitle = false,
  });

  final String file;
  final double width;
  final double height;

  /// Show the full Arabic title, for covers wide enough to hold it.
  final bool fullTitle;

  @override
  Widget build(BuildContext context) {
    return BookCover(
      key: Key('hadith-cover-$file'),
      art: hadithBookArt(file),
      width: width,
      height: height,
      fullTitle: fullTitle,
    );
  }
}

/// A bound-book cover drawn from [art]. Decorative, so it is hidden from
/// screen readers; show the title in text beside it.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.art,
    required this.width,
    required this.height,
    this.fullTitle = false,
  });

  final BookArt art;
  final double width;
  final double height;

  /// Show [BookArt.arabicTitle] rather than the short name.
  final bool fullTitle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(math.min(width, height) * 0.12);
    final spine = math.max(3.0, width * 0.09);

    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: art.dark.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            painter: _CoverPainter(art: art, spine: spine),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spine + width * 0.1,
                height * 0.12,
                width * 0.1,
                height * 0.12,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ArabicText(
                    fullTitle ? art.arabicTitle : art.arabicName,
                    fontOverride: ArabicFontOption.amiri,
                    fontSize: 22,
                    weight: FontWeight.w700,
                    align: TextAlign.center,
                    color: bookCoverGold,
                    tajweed: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter({required this.art, required this.spine});

  final BookArt art;
  final double spine;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Leather, lit from the fore-edge.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [art.dark, art.light, art.dark.withValues(alpha: 0.95)],
          stops: const [0, 0.7, 1],
        ).createShader(rect),
    );

    // Tooled pattern.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(spine, 0, size.width, size.height));
    final tool = bookCoverGold.withValues(alpha: 0.16);
    switch (art.pattern) {
      case BookPattern.stars:
        _stars(canvas, size, tool);
      case BookPattern.lattice:
        _lattice(canvas, size, tool);
      case BookPattern.diamonds:
        _diamonds(canvas, size, tool);
    }
    canvas.restore();

    // Spine, with a gold band.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, spine, size.height),
      Paint()..color = art.dark.withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(spine - 1, 0, 1, size.height),
      Paint()..color = bookCoverGold.withValues(alpha: 0.55),
    );

    // Double gold frame.
    final inset = math.max(3.0, size.shortestSide * 0.07);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..color = bookCoverGold.withValues(alpha: 0.85)
      ..strokeWidth = 1;
    final outer = Rect.fromLTRB(
      spine + inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    canvas.drawRect(outer, frame);
    if (outer.shortestSide > 24) {
      canvas.drawRect(
        outer.deflate(2.5),
        frame..color = bookCoverGold.withValues(alpha: 0.45),
      );
    }

    // Corner stars on larger covers.
    if (outer.shortestSide > 40) {
      final corner = Paint()..color = bookCoverGold.withValues(alpha: 0.85);
      final r = outer.shortestSide * 0.06;
      for (final c in [
        outer.topLeft,
        outer.topRight,
        outer.bottomLeft,
        outer.bottomRight,
      ]) {
        paintEightPointStar(canvas, c, r, corner);
      }
    }
  }

  void _stars(Canvas canvas, Size size, Color color) {
    final paint = Paint()..color = color;
    final step = math.max(10.0, size.shortestSide * 0.32);
    for (var row = 0; row * step / 2 < size.height + step; row++) {
      final y = row * step / 2;
      final shift = row.isOdd ? step / 2 : 0.0;
      for (var x = spine + shift; x < size.width + step; x += step) {
        paintEightPointStar(canvas, Offset(x, y), step * 0.18, paint);
      }
    }
  }

  void _lattice(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final step = math.max(8.0, size.shortestSide * 0.24);
    for (var d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        paint,
      );
    }
    for (var y = step / 2; y < size.height; y += step) {
      canvas.drawCircle(Offset(size.width / 2, y), step * 0.12, paint);
    }
  }

  void _diamonds(Canvas canvas, Size size, Color color) {
    final paint = Paint()..color = color;
    final step = math.max(9.0, size.shortestSide * 0.28);
    for (var row = 0; row * step / 2 < size.height + step; row++) {
      final y = row * step / 2;
      final shift = row.isOdd ? step / 2 : 0.0;
      for (var x = spine + shift; x < size.width + step; x += step) {
        final h = step * 0.22;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - h)
            ..lineTo(x + h * 0.7, y)
            ..lineTo(x, y + h)
            ..lineTo(x - h * 0.7, y)
            ..close(),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPainter old) =>
      old.art != art || old.spine != spine;
}
