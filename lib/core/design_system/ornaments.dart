import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Builds an eight-pointed star (two overlapping squares) centred on [c].
Path eightPointStar(Offset c, double radius) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final r = i.isEven ? radius : radius * 0.72;
    final a = -math.pi / 2 + i * math.pi / 8;
    final p = c + Offset(r * math.cos(a), r * math.sin(a));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// A faint lattice of eight-pointed stars behind a screen's content.
///
/// The pattern is strongest at the top and fades out by mid-screen, so it
/// decorates the header without competing with cards or text.
class PatternBackground extends StatelessWidget {
  final Widget child;

  /// How far down the screen the pattern reaches, as a fraction of height.
  final double reach;

  const PatternBackground({super.key, required this.child, this.reach = 0.45});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        (isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold)
            .withValues(alpha: isDark ? 0.07 : 0.09);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _StarLatticePainter(color, reach)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StarLatticePainter extends CustomPainter {
  final Color color;
  final double reach;

  const _StarLatticePainter(this.color, this.reach);

  static const _cell = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint();
    final end = size.height * reach;
    // Centred horizontally so the lattice is symmetric in both directions.
    final columns = (size.width / _cell).ceil() + 1;
    final startX = (size.width - (columns - 1) * _cell) / 2;
    for (var row = 0; row * _cell < end; row++) {
      // Each row is fainter than the one above, gone by [reach].
      final fade = 1 - (row * _cell) / end;
      paint.color = color.withValues(alpha: color.a * fade);
      dot.color = paint.color;
      for (var col = 0; col < columns; col++) {
        final c = Offset(startX + col * _cell, _cell / 2 + row * _cell);
        canvas.drawPath(eightPointStar(c, _cell * 0.3), paint);
        // Small diamonds where four cells meet.
        canvas.drawCircle(c + const Offset(_cell / 2, _cell / 2), 1.4, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_StarLatticePainter old) =>
      old.color != color || old.reach != reach;
}

/// A thin gold line with a small star in the middle, used under headers and
/// between sections.
class OrnamentDivider extends StatelessWidget {
  final double width;
  final double starSize;

  const OrnamentDivider({super.key, this.width = 140, this.starSize = 9});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold;
    Widget line(Alignment from) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: from,
            end: from == Alignment.centerLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.6)],
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: starSize * 2,
        child: Row(
          children: [
            line(Alignment.centerLeft),
            const SizedBox(width: 6),
            OrnamentStar(size: starSize * 2),
            const SizedBox(width: 6),
            line(Alignment.centerRight),
          ],
        ),
      ),
    );
  }
}

/// A small gold eight-pointed star with a hollow centre.
class OrnamentStar extends StatelessWidget {
  final double size;

  const OrnamentStar({super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(
          isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold,
          Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final Color hole;

  const _StarPainter(this.color, this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(
      eightPointStar(c, size.width / 2),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c, size.width * 0.12, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.hole != hole;
}
