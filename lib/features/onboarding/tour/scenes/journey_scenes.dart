part of '../tour_scenes.dart';

/// الختمة تتقدّم، والسلسلة تزيد يوماً، والسبحة تكمل ثلاثاً وثلاثين، والودجت
/// يظهر على شاشة الهاتف.
class JourneyScene extends StatelessWidget {
  final double t;

  const JourneyScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ring = phase(t, 0.0, 0.35);
    final flip = phase(t, 0.32, 0.46);
    final beads = phase(t, 0.42, 0.66);
    final count = 30 + (3 * beads).round();
    final sparkle = phase(t, 0.64, 0.74, Curves.easeOutBack);
    final phone = phase(t, 0.66, 0.84);
    return _Canvas(
      children: [
        // حلقة الختمة.
        Positioned(
          right: 18,
          top: 20,
          child: Column(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _RingPainter(0.4 * ring, c.gold, c.muted),
                  child: Center(
                    child: Text(
                      '${l10n.digits((40 * ring).round())}٪',
                      style: _ui(16, c.text, bold: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.tourKhatma, style: _ui(10, c.muted)),
            ],
          ),
        ),
        // السلسلة.
        Positioned(
          right: 128,
          top: 30,
          child: Column(
            children: [
              Icon(
                AppIcons.fire,
                size: 30 + 6 * math.sin(flip * math.pi),
                color: const Color(0xFFE0782E),
              ),
              SizedBox(
                height: 24,
                width: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 1 - flip,
                      child: Transform.translate(
                        offset: Offset(0, -12 * flip),
                        child: Text(
                          l10n.digits(6),
                          style: _ui(18, c.text, bold: true),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: flip,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - flip)),
                        child: Text(
                          l10n.digits(7),
                          style: _ui(18, c.text, bold: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(l10n.tourStreak, style: _ui(10, c.muted)),
            ],
          ),
        ),
        // السبحة.
        Positioned(
          right: 26,
          top: 130,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: beads * math.pi * 0.6,
                  child: CustomPaint(
                    size: const Size(76, 76),
                    painter: _BeadsPainter(c.primary, c.gold),
                  ),
                ),
                Text(l10n.digits(count), style: _ui(15, c.text, bold: true)),
                Positioned(
                  top: 0,
                  right: 0,
                  child: popIn(
                    sparkle,
                    Icon(AppIcons.sparkleFill, size: 18, color: c.gold),
                  ),
                ),
              ],
            ),
          ),
        ),
        // الهاتف والودجت.
        Positioned(
          left: 22 - 60 * (1 - phone),
          top: 24,
          child: Opacity(
            opacity: phone,
            child: Container(
              width: 112,
              height: 182,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.dark
                    ? const Color(0xFF0E1622)
                    : const Color(0xFF1B2535),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.gold.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.widgetAyahTitle,
                          style: _ui(7, c.gold, bold: true),
                        ),
                        Text(
                          _ayahText(
                            13,
                            28,
                            'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: _quran(9, Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

class _BeadsPainter extends CustomPainter {
  final Color bead;
  final Color accent;

  _BeadsPainter(this.bead, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      canvas.drawCircle(
        c + Offset(r * math.cos(a), r * math.sin(a)),
        4.2,
        Paint()..color = i == 0 ? accent : bead.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) => old.bead != bead;
}
