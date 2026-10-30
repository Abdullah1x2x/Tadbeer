part of '../tour_scenes.dart';

/// أيقونة القسم في هالة ذهبية، تدور حولها نجوم صغيرة.
class IconScene extends StatelessWidget {
  final double t;
  final IconData icon;

  const IconScene({super.key, required this.t, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final appear = phase(t, 0.0, 0.3, Curves.easeOutBack);
    final orbit = t * 2 * math.pi;
    return _Canvas(
      children: [
        for (var i = 0; i < 6; i++)
          () {
            final a = orbit + i * math.pi / 3;
            final r = 74.0 + 6 * math.sin(orbit * 2 + i);
            return Positioned(
              left: 160 + r * math.cos(a) - 5,
              top: 110 + r * math.sin(a) * 0.8 - 5,
              child: Opacity(
                opacity: 0.35 + 0.4 * appear.clamp(0.0, 1.0),
                child: Icon(AppIcons.sparkleFill, size: 10, color: c.gold),
              ),
            );
          }(),
        Positioned(
          left: 160 - 46,
          top: 110 - 46,
          child: popIn(
            appear,
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary,
                border: Border.all(color: c.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: c.gold.withValues(alpha: 0.4),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: c.gold),
            ),
          ),
        ),
      ],
    );
  }
}
