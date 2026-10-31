part of '../tour_scenes.dart';

/// ضغطة مطوّلة على آية تفتح القائمة الدائرية؛ ثم يختار القارئ منها.
///
/// مع [pickCenter] يضغط وسط القائمة («وقفة تدبر»)، وإلا اختار الحفظ فطارت
/// أيقونته إلى رقم الآية.
class MushafScene extends StatelessWidget {
  final double t;
  final bool pickCenter;

  const MushafScene({super.key, required this.t, this.pickCenter = false});

  static const _centre = Offset(160, 128);
  static const _ring = 62.0;
  static const _marker = Offset(46, 52);

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final approach = phase(t, 0.0, 0.16);
    final press = phase(t, 0.16, 0.24) * (1 - phase(t, 0.26, 0.3));
    final open = phase(t, 0.28, 0.48);
    final toPetal = phase(t, 0.5, 0.6);
    final pick = phase(t, 0.6, 0.65) * (1 - phase(t, 0.67, 0.7));
    final close = phase(t, 0.68, 0.76);
    final fly = phase(t, 0.74, 0.88, Curves.easeInOutCubic);
    final pulse = math.sin(phase(t, 0.88, 0.97) * math.pi);

    final petals = <(IconData, String)>[
      (AppIcons.notePencil, l10n.addNote),
      (AppIcons.headphones, l10n.listen),
      (AppIcons.brain, l10n.addToMemorization),
      (AppIcons.bookmarkSimple, l10n.markAyah),
      (AppIcons.graph, l10n.ayahLinks),
    ];
    Offset petalAt(int i) {
      final a = -math.pi / 2 + i * 2 * math.pi / petals.length;
      return _centre + Offset(_ring * math.cos(a), _ring * math.sin(a));
    }

    const brain = 2;
    final target = pickCenter ? _centre : petalAt(brain);
    final fingerStart = const Offset(280, 210);
    final fingerAt = t < 0.5
        ? _lerp(fingerStart, const Offset(200, 52), approach)
        : _lerp(const Offset(200, 52), target, toPetal);
    final fingerOpacity = 1 - close;
    final ringOpacity = open * (1 - close);
    final highlight = phase(t, 0.2, 0.3) * (1 - fly * 0.6);

    return _Canvas(
      children: [
        Positioned(
          left: 8,
          right: 8,
          top: 18,
          child: _card(
            c,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.22 * highlight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ayahText(1, 2, 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: _quran(22, c.text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ayahMarker(c, 2),
              ],
            ),
          ),
        ),
        // علامة الحفظ تستقر فوق رقم الآية.
        if (!pickCenter && fly > 0)
          Positioned(
            left: _lerp(petalAt(brain), _marker, fly).dx - 10,
            top: _lerp(petalAt(brain), _marker, fly).dy - 10 - 12 * fly,
            child: Transform.scale(
              scale: 1 + 0.35 * pulse,
              child: Icon(AppIcons.brainFill, size: 20, color: c.gold),
            ),
          ),
        if (ringOpacity > 0)
          Positioned.fill(
            child: Opacity(
              opacity: ringOpacity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _centre.dx - _ring - 26,
                    top: _centre.dy - _ring - 26,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * open,
                      child: Container(
                        width: (_ring + 26) * 2,
                        height: (_ring + 26) * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primary.withValues(alpha: 0.92),
                          border: Border.all(color: c.gold, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < petals.length; i++)
                    _petal(
                      c,
                      petalAt(i),
                      petals[i].$1,
                      phase(open, i * 0.12, 0.5 + i * 0.12),
                      picked: !pickCenter && i == brain ? pick : 0,
                    ),
                  Positioned(
                    left: _centre.dx - 30,
                    top: _centre.dy - 30,
                    child: Transform.scale(
                      scale: 1 - 0.12 * (pickCenter ? pick : 0),
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          border: Border.all(color: c.gold, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.flowerLotusFill,
                              size: 18,
                              color: c.primary,
                            ),
                            Text(
                              l10n.tadbeerPause,
                              style: _ui(7.5, c.text, bold: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _finger(c, fingerAt, math.max(press, pick), opacity: fingerOpacity),
      ],
    );
  }

  Widget _petal(
    _Palette c,
    Offset at,
    IconData icon,
    double p, {
    double picked = 0,
  }) {
    return Positioned(
      left: at.dx - 17,
      top: at.dy - 17,
      child: popIn(
        p,
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.14),
              c.gold,
              picked,
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}
