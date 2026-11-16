/// Small line illustrations for empty states, the error page, and the
/// first-run pages.
///
/// Drawn in code, like the hadith book covers, so they stay sharp at any
/// size, follow light, dark, and paper, and add nothing to the download.
/// None of them draws lettering or a living being.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'hublee_marks.dart';
import 'tajweed.dart';

/// Which illustration a [SpotIllustration] draws.
enum SpotArt {
  /// Open book with a ribbon marker and a star above.
  savedAyahs,

  /// Ruled sheet with a reed pen resting across it.
  notes,

  /// Closed book with a lattice cover and a blank title panel.
  savedHadiths,

  /// Two stacked blank cards with a star in the corner.
  savedWords,

  /// Magnifier over a star lattice with one tile missing.
  noResults,

  /// Arch doorway with a path that stops short of it.
  notFound,

  /// Three overlapping tiles, one per theme.
  look,

  /// A pen resting on a baseline.
  typeface,

  /// Four tajweed colour dots on a line.
  tajweed,
}

/// A square line illustration in the app's gold accent.
class SpotIllustration extends StatelessWidget {
  const SpotIllustration(this.art, {super.key, this.size = 160});

  final SpotArt art;

  /// Width and height in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SpotPainter(art, AppPalette.of(context)),
      ),
    );
  }
}

class _SpotPainter extends CustomPainter {
  _SpotPainter(this.art, this.palette);

  final SpotArt art;
  final AppPalette palette;

  // Everything is drawn on a 100 × 100 grid and scaled to the widget.
  late final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = palette.accent;
  late final Paint _faint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = palette.outline.withValues(alpha: 0.55);
  late final Paint _tint = Paint()..color = palette.accentTint;
  late final Paint _surface = Paint()..color = palette.surface;
  late final Paint _gold = Paint()..color = palette.accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 100);
    switch (art) {
      case SpotArt.savedAyahs:
        _savedAyahs(canvas);
      case SpotArt.notes:
        _notes(canvas);
      case SpotArt.savedHadiths:
        _savedHadiths(canvas);
      case SpotArt.savedWords:
        _savedWords(canvas);
      case SpotArt.noResults:
        _noResults(canvas);
      case SpotArt.notFound:
        _notFound(canvas);
      case SpotArt.look:
        _look(canvas);
      case SpotArt.typeface:
        _typeface(canvas);
      case SpotArt.tajweed:
        _tajweed(canvas);
    }
    canvas.restore();
  }

  void _savedAyahs(Canvas canvas) {
    paintEightPointStar(canvas, const Offset(50, 17), 8, _gold);

    Path page(double sign) => Path()
      ..moveTo(50, 44)
      ..quadraticBezierTo(50 + sign * 16, 34, 50 + sign * 34, 40)
      ..lineTo(50 + sign * 34, 76)
      ..quadraticBezierTo(50 + sign * 16, 70, 50, 80)
      ..close();
    for (final sign in [-1.0, 1.0]) {
      final p = page(sign);
      canvas.drawPath(p, _tint);
      canvas.drawPath(p, _line);
      for (var i = 0; i < 3; i++) {
        final y = 50.0 + i * 8;
        canvas.drawLine(
          Offset(50 + sign * 9, y - 1),
          Offset(50 + sign * 27, y - 3),
          _faint,
        );
      }
    }
    // Ribbon marker hanging from the spine.
    final ribbon = Path()
      ..moveTo(47, 44)
      ..lineTo(53, 44)
      ..lineTo(53, 92)
      ..lineTo(50, 88)
      ..lineTo(47, 92)
      ..close();
    canvas.drawPath(ribbon, _gold);
  }

  void _notes(Canvas canvas) {
    final sheet = Path()
      ..moveTo(24, 14)
      ..lineTo(60, 14)
      ..lineTo(72, 26)
      ..lineTo(72, 86)
      ..lineTo(24, 86)
      ..close();
    canvas.drawPath(sheet, _surface);
    canvas.drawPath(sheet, _line);
    canvas.drawPath(
      Path()
        ..moveTo(60, 14)
        ..lineTo(60, 26)
        ..lineTo(72, 26),
      _line,
    );
    for (var y = 38.0; y <= 74; y += 12) {
      canvas.drawLine(Offset(32, y), Offset(64, y), _faint);
    }
    // Reed pen resting across the sheet, nib down-left.
    canvas.save();
    canvas.translate(40, 78);
    canvas.rotate(-math.pi / 4);
    final body = RRect.fromLTRBR(8, -3.2, 60, 3.2, const Radius.circular(3.2));
    canvas.drawRRect(body, _tint);
    canvas.drawRRect(body, _line);
    canvas.drawPath(
      Path()
        ..moveTo(8, -3.2)
        ..lineTo(0, 0)
        ..lineTo(8, 3.2)
        ..close(),
      _gold,
    );
    canvas.restore();
  }

  void _savedHadiths(Canvas canvas) {
    const cover = Rect.fromLTRB(28, 12, 74, 88);
    final rr = RRect.fromRectAndRadius(cover, const Radius.circular(3));
    canvas.drawRRect(rr, _tint);

    // Lattice pressed into the cover.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(36, 12, 74, 88));
    for (var d = -80.0; d < 80; d += 11) {
      canvas.drawLine(Offset(36 + d, 12), Offset(36 + d + 76, 88), _faint);
      canvas.drawLine(Offset(36 + d, 88), Offset(36 + d + 76, 12), _faint);
    }
    canvas.restore();

    canvas.drawRRect(rr, _line);
    canvas.drawLine(const Offset(36, 12), const Offset(36, 88), _line);

    // Blank title panel.
    final panel = RRect.fromLTRBR(42, 40, 68, 60, const Radius.circular(2));
    canvas.drawRRect(panel, _surface);
    canvas.drawRRect(panel, _line);
  }

  void _savedWords(Canvas canvas) {
    canvas.save();
    canvas.translate(50, 54);
    canvas.rotate(-0.16);
    final back = RRect.fromLTRBR(-26, -24, 26, 14, const Radius.circular(5));
    canvas.drawRRect(back, _tint);
    canvas.drawRRect(back, _line);
    canvas.restore();

    final front = RRect.fromLTRBR(24, 36, 78, 78, const Radius.circular(5));
    canvas.drawRRect(front, _surface);
    canvas.drawRRect(front, _line);
    paintEightPointStar(canvas, const Offset(68, 46), 5.5, _gold);
    canvas.drawLine(const Offset(33, 58), const Offset(60, 58), _faint);
    canvas.drawLine(const Offset(33, 67), const Offset(52, 67), _faint);
  }

  void _noResults(Canvas canvas) {
    final tile = Paint()..color = palette.outline.withValues(alpha: 0.5);
    const missing = Offset(52, 46);
    for (var x = 20.0; x <= 84; x += 16) {
      for (var y = 30.0; y <= 62; y += 16) {
        final c = Offset(x, y);
        if (c == missing) continue;
        paintEightPointStar(canvas, c, 5, tile);
      }
    }
    // The missing tile, marked by a dotted ring.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        missing + Offset(math.cos(a), math.sin(a)) * 5,
        0.8,
        _gold,
      );
    }
    canvas.drawCircle(missing, 19, _line..strokeWidth = 2.4);
    canvas.drawLine(
      const Offset(66, 60),
      const Offset(84, 80),
      _line..strokeWidth = 4,
    );
    _line.strokeWidth = 1.8;
  }

  void _notFound(Canvas canvas) {
    Path arch(double w, double top) => Path()
      ..moveTo(50 - w, 58)
      ..lineTo(50 - w, 36)
      ..quadraticBezierTo(50 - w, top + 8, 50, top)
      ..quadraticBezierTo(50 + w, top + 8, 50 + w, 36)
      ..lineTo(50 + w, 58);
    final inner = arch(11, 18)..close();
    canvas.drawPath(inner, _tint);
    canvas.drawPath(arch(16, 11), _faint);
    canvas.drawPath(inner, _line);
    canvas.drawLine(const Offset(28, 58), const Offset(72, 58), _line);

    // A path that winds toward the door and stops short of it.
    final path = Path()
      ..moveTo(30, 94)
      ..cubicTo(34, 84, 62, 88, 56, 78)
      ..cubicTo(52, 72, 49, 74, 50, 68);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = palette.accent;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 3, metric.length)),
          dash,
        );
      }
    }
  }

  void _look(Canvas canvas) {
    void tile(double left, double top, Color fill, Color bar) {
      final r = RRect.fromLTRBR(
        left,
        top,
        left + 40,
        top + 52,
        const Radius.circular(6),
      );
      canvas.drawRRect(r, Paint()..color = fill);
      canvas.drawRRect(r, _line);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = bar;
      canvas.drawLine(
        Offset(left + 8, top + 14),
        Offset(left + 26, top + 14),
        stroke,
      );
      canvas.drawLine(
        Offset(left + 8, top + 24),
        Offset(left + 20, top + 24),
        stroke..color = bar.withValues(alpha: 0.5),
      );
    }

    tile(12, 18, AppPalette.dark.canvas, AppPalette.dark.ink);
    tile(30, 24, AppPalette.paper.canvas, AppPalette.paper.ink);
    tile(48, 30, AppPalette.light.canvas, AppPalette.light.ink);
  }

  void _typeface(Canvas canvas) {
    canvas.drawLine(const Offset(14, 70), const Offset(86, 70), _faint);
    // Ink already laid along the baseline.
    canvas.drawLine(
      const Offset(20, 70),
      const Offset(38, 70),
      _line..strokeWidth = 3,
    );
    _line.strokeWidth = 1.8;

    // Pen, nib on the baseline.
    canvas.save();
    canvas.translate(38, 70);
    canvas.rotate(-math.pi / 3.4);
    final body = RRect.fromLTRBR(9, -4, 58, 4, const Radius.circular(4));
    canvas.drawRRect(body, _tint);
    canvas.drawRRect(body, _line);
    canvas.drawPath(
      Path()
        ..moveTo(9, -4)
        ..lineTo(0, 0)
        ..lineTo(9, 4)
        ..close(),
      _gold,
    );
    canvas.restore();
  }

  void _tajweed(Canvas canvas) {
    canvas.drawLine(const Offset(12, 50), const Offset(88, 50), _faint);
    const colours = [
      kNormalMaadColor,
      kGhunnahColor,
      kQalqalaColor,
      kMaadLongColor,
    ];
    for (var i = 0; i < colours.length; i++) {
      canvas.drawCircle(
        Offset(23.0 + i * 18, 50),
        6.5,
        Paint()..color = colours[i],
      );
    }
  }

  @override
  bool shouldRepaint(_SpotPainter old) =>
      old.art != art || old.palette != palette;
}
