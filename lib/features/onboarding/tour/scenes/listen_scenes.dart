part of '../tour_scenes.dart';

/// تلاوة سورة الإخلاص: الضوء ينتقل من آية لأخرى، ثم يُختار «آية واحدة».
class ListenScene extends StatelessWidget {
  final double t;

  const ListenScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final current = t < 0.2 ? 0 : (t < 0.4 ? 1 : 2);
    final toggled = t >= 0.5;
    final finished = t >= 0.74;
    final press = math.sin(phase(t, 0.44, 0.52) * math.pi);
    const fallback = [
      'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      'ٱللَّهُ ٱلصَّمَدُ',
      'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    ];
    return _Canvas(
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: 4,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: c.gold.withValues(
                      alpha: i == current && !finished ? 0.24 : 0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _ayahText(112, i + 1, fallback[i]),
                          maxLines: 1,
                          style: _quran(18, c.text),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ayahMarker(c, i + 1, size: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 4,
          child: _card(
            c,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(AppIcons.skipBackFill, size: 16, color: c.text),
                const SizedBox(width: 6),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    finished ? AppIcons.playFill : AppIcons.pauseFill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(AppIcons.skipForwardFill, size: 16, color: c.text),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 1 + 0.25 * press,
                  child: Icon(
                    toggled ? AppIcons.repeatOnce : AppIcons.repeat,
                    size: 18,
                    color: toggled ? c.gold : c.text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _ref(context, 112, current + 1),
                        maxLines: 1,
                        style: _ui(10, c.text, bold: true),
                      ),
                      Text(
                        finished ? l10n.ayahFinished : l10n.tourSampleReciter,
                        maxLines: 1,
                        style: _ui(9, finished ? c.gold : c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _finger(
          c,
          _lerp(
            const Offset(250, 120),
            const Offset(205, 194),
            phase(t, 0.36, 0.44),
          ),
          press,
          opacity: phase(t, 0.34, 0.38) * (1 - phase(t, 0.56, 0.62)),
        ),
      ],
    );
  }
}
