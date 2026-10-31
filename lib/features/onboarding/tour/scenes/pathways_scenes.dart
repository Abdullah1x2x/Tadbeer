part of '../tour_scenes.dart';

/// مسار من سبعة أيام: يُضاء يومه الأول ثم الذي بعده.
class PathwayDaysScene extends StatelessWidget {
  final double t;

  /// كم يوماً أُنجز في آخر المشهد.
  final int done;

  const PathwayDaysScene({super.key, required this.t, this.done = 1});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final appear = phase(t, 0.0, 0.25);
    final advance = phase(t, 0.35, 0.7);
    const days = 7;
    return _Canvas(
      children: [
        Positioned(
          left: 18,
          right: 18,
          top: 30,
          child: riseIn(
            appear,
            _card(
              c,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.path, size: 18, color: c.gold),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tourSamplePathway,
                        style: _ui(13, c.text, bold: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.tourSamplePathwayHint, style: _ui(10, c.muted)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var d = 0; d < days; d++) ...[
                        if (d > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: d <= done - 1 + advance
                                  ? c.gold
                                  : c.muted.withValues(alpha: 0.25),
                            ),
                          ),
                        _day(c, d, done, advance),
                      ],
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

  Widget _day(_Palette c, int d, int done, double advance) {
    final isDone = d < done - 1 || (d == done - 1 && advance > 0.5);
    final isNext = d == done - 1 + (advance > 0.5 ? 1 : 0);
    final glow = isNext ? math.sin(advance * math.pi) : 0.0;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? c.gold : (isNext ? c.primary : c.surface),
        border: Border.all(
          color: isDone || isNext ? c.gold : c.muted.withValues(alpha: 0.4),
          width: 1.6,
        ),
        boxShadow: [
          if (isNext)
            BoxShadow(
              color: c.gold.withValues(alpha: 0.5 * (0.4 + glow)),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: isDone
          ? const Icon(AppIcons.check, size: 14, color: Colors.white)
          : Text(
              ArabicSearchNormalizer.toArabicDigits(d + 1),
              style: _ui(10, isNext ? Colors.white : c.muted, bold: true),
            ),
    );
  }
}

/// آية اليوم، ثم يطفو سؤالها تحتها.
class TodayAyahScene extends StatelessWidget {
  final double t;

  const TodayAyahScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ayah = phase(t, 0.0, 0.3);
    final question = phase(t, 0.35, 0.6);
    return _Canvas(
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 14,
          child: riseIn(
            ayah,
            _card(
              c,
              child: Column(
                children: [
                  Text(l10n.tourDayOne, style: _ui(10, c.gold, bold: true)),
                  const SizedBox(height: 4),
                  Text(
                    _ayahText(
                      2,
                      153,
                      'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _quran(15, c.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 40,
          right: 40,
          bottom: 8,
          child: riseIn(
            question,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.lightbulbFill, size: 16, color: c.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.tourSampleQuestion,
                      style: _ui(10.5, Colors.white, bold: true),
                    ),
                  ),
                ],
              ),
            ),
            distance: 24,
          ),
        ),
      ],
    );
  }
}
