part of '../tour_scenes.dart';

/// أقسام التطبيق تجتمع حول نجمة ذهبية: كل ما يحتاجه القارئ في مكان واحد.
class CompanionScene extends StatelessWidget {
  final double t;

  const CompanionScene({super.key, required this.t});

  static const _centre = Offset(160, 110);
  static const _icons = [
    AppIcons.bookOpenTextFill,
    AppIcons.flowerLotusFill,
    AppIcons.graphFill,
    AppIcons.handHeartFill,
    AppIcons.sparkleFill,
    AppIcons.books,
  ];

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final star = phase(t, 0.5, 0.7, Curves.easeOutBack);
    final pulse = math.sin(phase(t, 0.7, 0.95) * math.pi);
    return _Canvas(
      children: [
        for (var i = 0; i < _icons.length; i++)
          () {
            final p = phase(t, i * 0.07, 0.3 + i * 0.07, Curves.easeOutCubic);
            final angle = -math.pi / 2 + i * math.pi / 3;
            // تأتي من بعيد ثم تستقر في مدار حول النجمة.
            final radius = 150 - 66 * p;
            final at =
                _centre +
                Offset(
                  radius * math.cos(angle) * 1.25,
                  radius * math.sin(angle),
                );
            return Positioned(
              left: at.dx - 21,
              top: at.dy - 21,
              child: Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.gold.withValues(alpha: 0.7)),
                  ),
                  child: Icon(_icons[i], size: 21, color: c.primary),
                ),
              ),
            );
          }(),
        Positioned(
          left: _centre.dx - 40,
          top: _centre.dy - 40,
          child: popIn(
            star,
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.gold.withValues(alpha: 0.3 + 0.4 * pulse),
                    blurRadius: 16 + 14 * pulse,
                    spreadRadius: 2 * pulse,
                  ),
                ],
              ),
              child: CustomPaint(painter: _StarPainter(c.gold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;

  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.width / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
