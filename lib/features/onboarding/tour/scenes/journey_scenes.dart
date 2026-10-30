part of '../tour_scenes.dart';

/// يوم القارئ في بطاقة واحدة: ورد يكتمل، وأيام الأسبوع تُضاء، وسلسلة تزيد.
class JourneyScene extends StatelessWidget {
  final double t;

  const JourneyScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ring = phase(t, 0.05, 0.42);
    final week = phase(t, 0.42, 0.74, Curves.linear);
    final flame = phase(t, 0.74, 0.88, Curves.easeOutBack);
    return _Canvas(
      children: [
        Positioned(
          left: 22,
          right: 22,
          top: 8,
          child: _card(
            c,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CustomPaint(
                        painter: _RingPainter(0.8 * ring, c.gold, c.muted),
                        child: Center(
                          child: Text(
                            '${l10n.digits((80 * ring).round())}٪',
                            style: _ui(16, c.text, bold: true),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tourTodayPortion,
                            style: _ui(16, c.text, bold: true),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.tourPagesToday, style: _ui(12, c.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FitRow(
                  children: [
                    for (var i = 0; i < 7; i++)
                      _day(
                        c,
                        phase(week, i / 7, (i + 1) / 7, Curves.easeOutBack),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _FitRow(
                  children: [
                    Transform.scale(
                      scale: 0.8 + 0.2 * flame,
                      child: const Icon(
                        AppIcons.fire,
                        size: 22,
                        color: Color(0xFFE0782E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.digits((7 * week).ceil())} ${l10n.tourStreak}',
                      style: _ui(13, c.text, bold: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// يوم في الأسبوع: دائرة تمتلئ ذهباً ويظهر عليها الصح.
  Widget _day(_Palette c, double p) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(c.surface, c.gold, p.clamp(0.0, 1.0)),
        border: Border.all(color: c.gold.withValues(alpha: 0.6)),
      ),
      child: popIn(
        p,
        const Icon(AppIcons.check, size: 15, color: Colors.white),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _RingPainter(this.value, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    paint.color = track.withValues(alpha: 0.18);
    canvas.drawArc(rect.deflate(5), 0, 2 * math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(
      rect.deflate(5),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}
