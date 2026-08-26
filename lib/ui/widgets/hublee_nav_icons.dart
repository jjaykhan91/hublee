/// Bottom-nav icons unique to Hublee: dome-home, mushaf, Madinah
/// mosque, and library. Colour follows [IconTheme] so the bar can
/// tint selected vs unselected.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which custom tab mark to paint.
enum HubleeNavKind { home, quran, hadith, learn }

/// 24 dp tab icon. [filled] is the selected (solid) variant.
class HubleeNavIcon extends StatelessWidget {
  const HubleeNavIcon({super.key, required this.kind, this.filled = false});

  final HubleeNavKind kind;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = theme.color ?? Theme.of(context).colorScheme.onSurface;
    final size = theme.size ?? 24;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _HubleeNavPainter(kind: kind, filled: filled, color: color),
      ),
    );
  }
}

class _HubleeNavPainter extends CustomPainter {
  _HubleeNavPainter({
    required this.kind,
    required this.filled,
    required this.color,
  });

  final HubleeNavKind kind;
  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || color.a == 0) return;
    canvas.save();
    final s = math.min(size.width, size.height);
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s / 24);
    switch (kind) {
      case HubleeNavKind.home:
        _paintHome(canvas);
      case HubleeNavKind.quran:
        _paintQuran(canvas);
      case HubleeNavKind.hadith:
        _paintHadith(canvas);
      case HubleeNavKind.learn:
        _paintLearn(canvas);
    }
    canvas.restore();
  }

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = filled ? 1.35 : 1.55
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// House with a dome roof and a rope arch over the door.
  void _paintHome(Canvas canvas) {
    final body = Path()
      ..moveTo(4.4, 12.6)
      ..cubicTo(4.4, 4.2, 19.6, 4.2, 19.6, 12.6)
      ..lineTo(19.6, 20.4)
      ..quadraticBezierTo(12, 22.4, 4.4, 20.4)
      ..close();
    final door = RRect.fromLTRBR(
      9.6,
      14.6,
      14.4,
      21.0,
      const Radius.circular(1.6),
    );
    final doorPath = Path()..addRRect(door);

    if (filled) {
      final cut = Path.combine(PathOperation.difference, body, doorPath);
      canvas.drawPath(cut, _fill);
    } else {
      canvas.drawPath(body, _stroke);
      canvas.drawRRect(door, _stroke);
    }

    // Rope-made arch over the door (two strands).
    final rope = Path()
      ..moveTo(8.2, 16.4)
      ..quadraticBezierTo(12, 12.6, 15.8, 16.4);
    canvas.drawPath(rope, _stroke);
    canvas.save();
    canvas.translate(0, 1.15);
    canvas.drawPath(rope, _stroke);
    canvas.restore();

    // Finial on the dome.
    canvas.drawCircle(const Offset(12, 3.4), filled ? 1.15 : 1.05, _fill);
  }

  /// Open mushaf on a rehal (book stand) — a Quran, not a notebook.
  void _paintQuran(Canvas canvas) {
    final left = Path()
      ..moveTo(11.4, 6.8)
      ..lineTo(4.6, 9.0)
      ..lineTo(4.8, 16.2)
      ..quadraticBezierTo(11.4, 14.8, 11.4, 14.8)
      ..close();
    final right = Path()
      ..moveTo(12.6, 6.8)
      ..lineTo(19.4, 9.0)
      ..lineTo(19.2, 16.2)
      ..quadraticBezierTo(12.6, 14.8, 12.6, 14.8)
      ..close();

    if (filled) {
      canvas.drawPath(left, _fill);
      canvas.drawPath(right, _fill);
    } else {
      canvas.drawPath(left, _stroke);
      canvas.drawPath(right, _stroke);
    }

    // Rehal (X stand).
    canvas.drawLine(const Offset(7.2, 21.4), const Offset(16.8, 16.0), _stroke);
    canvas.drawLine(const Offset(16.8, 21.4), const Offset(7.2, 16.0), _stroke);
  }

  /// Masjid an-Nabawi silhouette: large dome, tall minaret, arcade.
  void _paintHadith(Canvas canvas) {
    final dome = Path()
      ..moveTo(3.6, 14.2)
      ..cubicTo(3.6, 5.0, 16.6, 5.0, 16.6, 14.2)
      ..close();
    final base = RRect.fromLTRBR(
      3.4,
      13.8,
      21.0,
      21.4,
      const Radius.circular(1.2),
    );
    final minaret = RRect.fromLTRBR(
      17.8,
      4.2,
      20.6,
      21.4,
      const Radius.circular(0.7),
    );

    if (filled) {
      canvas.drawPath(dome, _fill);
      canvas.drawRRect(base, _fill);
      canvas.drawRRect(minaret, _fill);
    } else {
      canvas.drawPath(dome, _stroke);
      canvas.drawRRect(base, _stroke);
      canvas.drawRRect(minaret, _stroke);
    }

    // Minaret balcony and cap.
    canvas.drawRRect(
      RRect.fromLTRBR(17.1, 8.0, 21.3, 10.2, const Radius.circular(0.6)),
      filled ? _fill : _stroke,
    );
    final cap = Path()
      ..moveTo(17.8, 4.4)
      ..lineTo(19.2, 2.2)
      ..lineTo(20.6, 4.4)
      ..close();
    canvas.drawPath(cap, filled ? _fill : _stroke);

    // Arcade arches read on the outline; fill stays a silhouette.
    if (!filled) {
      for (final cx in [6.6, 10.2, 13.8]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, 18.8), width: 2.6, height: 3.8),
          math.pi,
          math.pi,
          false,
          _stroke,
        );
      }
    }
  }

  /// Three books on a shelf — a library, not a classroom cap.
  void _paintLearn(Canvas canvas) {
    final books = <RRect>[
      RRect.fromLTRBR(4.0, 10.2, 8.4, 20.6, const Radius.circular(0.7)),
      RRect.fromLTRBR(9.2, 6.6, 13.8, 20.6, const Radius.circular(0.7)),
      RRect.fromLTRBR(14.6, 11.0, 19.8, 20.6, const Radius.circular(0.7)),
    ];
    for (final book in books) {
      canvas.drawRRect(book, filled ? _fill : _stroke);
    }
    canvas.drawLine(const Offset(3.2, 21.4), const Offset(20.8, 21.4), _stroke);
  }

  @override
  bool shouldRepaint(covariant _HubleeNavPainter old) =>
      old.kind != kind || old.filled != filled || old.color != color;
}
