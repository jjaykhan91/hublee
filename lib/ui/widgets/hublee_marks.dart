/// Hublee identity marks: eight-point star, twisted rope, and
/// a faint star lattice used on Home.
///
/// These are geometric, not mushaf notation — they do not use the
/// rub-el-hizb mark (۞) as decoration.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App-bar wordmark: eight-point star beside the name Hublee.
class HubleeWordmark extends StatelessWidget {
  const HubleeWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return Semantics(
      header: true,
      label: 'Hublee',
      child: ExcludeSemantics(
        child: Row(
          key: const Key('hublee-wordmark'),
          mainAxisSize: MainAxisSize.min,
          children: [
            HubleeStarMark(
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Hublee', style: style.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// An eight-point Islamic star (architectural khatam).
class HubleeStarMark extends StatelessWidget {
  const HubleeStarMark({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(color: resolved),
      ),
    );
  }
}

/// Two intertwining strands — a modern “rope” (habl) motif.
class HubleeRopeMark extends StatelessWidget {
  const HubleeRopeMark({
    super.key,
    this.width = 48,
    this.height = 14,
    this.colorA,
    this.colorB,
  });

  final double width;
  final double height;
  final Color? colorA;
  final Color? colorB;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: HubleeRopePainter(
          colorA: colorA ?? scheme.primary,
          colorB: colorB ?? scheme.tertiary,
        ),
      ),
    );
  }
}

/// Repeating eight-point stars. Use at very low alpha as a wash.
class IslamicStarLatticePainter extends CustomPainter {
  IslamicStarLatticePainter({required this.color, this.step = 56});

  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || color.a == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var row = 0; ; row++) {
      final y = step / 2 + row * step;
      if (y > size.height + step) break;
      final inset = row.isOdd ? step / 2 : 0.0;
      for (var x = step / 2 + inset; x < size.width + step; x += step) {
        paintEightPointStar(canvas, Offset(x, y), 6.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicStarLatticePainter old) =>
      old.color != color || old.step != step;
}

/// Twisted two-strand rope across [size].
class HubleeRopePainter extends CustomPainter {
  HubleeRopePainter({
    required this.colorA,
    required this.colorB,
    this.strokeWidth = 2.1,
    this.coils = 3.2,
  });

  final Color colorA;
  final Color colorB;
  final double strokeWidth;
  final double coils;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pathA = Path();
    final pathB = Path();
    final mid = size.height / 2;
    final amp = size.height * 0.34;
    const samples = 72;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = t * size.width;
      final phase = t * coils * 2 * math.pi;
      final yA = mid + amp * math.sin(phase);
      final yB = mid + amp * math.sin(phase + math.pi);
      if (i == 0) {
        pathA.moveTo(x, yA);
        pathB.moveTo(x, yB);
      } else {
        pathA.lineTo(x, yA);
        pathB.lineTo(x, yB);
      }
    }
    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(pathA, paintA);
    canvas.drawPath(pathB, paintB);
  }

  @override
  bool shouldRepaint(covariant HubleeRopePainter old) =>
      old.colorA != colorA ||
      old.colorB != colorB ||
      old.strokeWidth != strokeWidth ||
      old.coils != coils;
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    paintEightPointStar(
      canvas,
      center,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}

/// Draws an eight-pointed star centred at [center].
void paintEightPointStar(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint,
) {
  if (radius <= 0) return;
  final path = Path();
  const points = 8;
  final inner = radius * 0.4;
  for (var i = 0; i < points; i++) {
    final outerAngle = i * math.pi / 4 - math.pi / 2;
    final innerAngle = outerAngle + math.pi / 8;
    final ox = center.dx + radius * math.cos(outerAngle);
    final oy = center.dy + radius * math.sin(outerAngle);
    final ix = center.dx + inner * math.cos(innerAngle);
    final iy = center.dy + inner * math.sin(innerAngle);
    if (i == 0) {
      path.moveTo(ox, oy);
    } else {
      path.lineTo(ox, oy);
    }
    path.lineTo(ix, iy);
  }
  path.close();
  canvas.drawPath(path, paint);
}
