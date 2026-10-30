part of '../tour_scenes.dart';

/// بطاقة الوقفة: تُكتب أسئلتها الأربعة سطراً بعد سطر.
///
/// مع [answer] تمتلئ إجابة السؤال الثاني ويُضغط الحفظ، وإلا تنكمش البطاقة إلى
/// عقدة تجتمع حولها آيتان في شبكة.
class ReflectScene extends StatelessWidget {
  final double t;
  final bool answer;

  const ReflectScene({super.key, required this.t, this.answer = false});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    const questions = TadbeerItem.questions;
    final typing = answer ? phase(t, 0.0, 0.42) : phase(t, 0.0, 0.55);
    final shrink = answer ? 0.0 : phase(t, 0.74, 0.8);
    final answerType = answer ? phase(t, 0.45, 0.72) : 0.0;
    final savePress = answer ? math.sin(phase(t, 0.78, 0.86) * math.pi) : 0.0;
    final saved = answer ? phase(t, 0.86, 0.94) : 0.0;

    final card = _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(AppIcons.flowerLotusFill, size: 16, color: c.gold),
              const SizedBox(width: 6),
              Text(l10n.tadbeerPause, style: _ui(12, c.text, bold: true)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < questions.length; i++) ...[
            _typed(
              questions[i],
              phase(typing, i * 0.25, (i + 1) * 0.25),
              _ui(10.5, c.text),
            ),
            if (answer && i == 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 10, top: 2),
                child: _typed(
                  l10n.tourSampleAnswer,
                  answerType,
                  _ui(10, c.primary, bold: true),
                ),
              ),
            const SizedBox(height: 3),
          ],
          if (answer)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Transform.scale(
                scale: 1 - 0.1 * savePress,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(c.primary, c.gold, saved),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (saved > 0)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: popIn(
                            saved,
                            const Icon(
                              AppIcons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(l10n.save, style: _ui(10, Colors.white, bold: true)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return _Canvas(
      children: [
        Positioned(
          left: 34,
          right: 34,
          top: 6,
          child: Opacity(
            opacity: 1 - shrink,
            child: Transform.scale(scale: 1 - 0.7 * shrink, child: card),
          ),
        ),
        if (!answer && shrink > 0)
          Positioned.fill(
            child: LinkNetwork(
              t: phase(t, 0.76, 1),
              centreLabel: l10n.tourSampleLink,
            ),
          ),
        if (answer)
          _finger(
            c,
            _lerp(
              const Offset(260, 210),
              const Offset(64, 196),
              phase(t, 0.7, 0.78),
            ),
            savePress,
            opacity: phase(t, 0.68, 0.72) * (1 - phase(t, 0.9, 0.95)),
          ),
      ],
    );
  }
}

/// نص يُكتب من اليمين بقدر [p].
Widget _typed(String text, double p, TextStyle style) {
  return ClipRect(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: p.clamp(0.0, 1.0),
      child: Text(text, style: style, maxLines: 1, softWrap: false),
    ),
  );
}

/// وقفاتي: وقفة جديدة تنزلق إلى أول القائمة وعليها زهرة التدبّر.
class ReflectionsListScene extends StatelessWidget {
  final double t;

  const ReflectionsListScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final slide = phase(t, 0.1, 0.45, Curves.easeOutBack);
    final glow = math.sin(phase(t, 0.5, 0.8) * math.pi);
    Widget row(int surah, int ayah, String text, {double opacity = 1}) {
      return Opacity(
        opacity: opacity,
        child: _card(
          c,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(AppIcons.flowerLotusFill, size: 18, color: c.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ref(context, surah, ayah),
                      style: _ui(11, c.text, bold: true),
                    ),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ui(9.5, c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Canvas(
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: 8,
          child: Row(
            children: [
              Icon(AppIcons.flowerLotus, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text(l10n.myReflections, style: _ui(13, c.text, bold: true)),
            ],
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 40 + 56 * slide,
          child: row(94, 5, l10n.tourSampleAnswer2, opacity: 0.55),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 96 + 56 * slide,
          child: row(
            13,
            28,
            l10n.tourSampleAnswer3,
            opacity: 0.4 * (1 - slide),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 40,
          child: Opacity(
            opacity: slide.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -24 * (1 - slide)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: c.gold.withValues(alpha: 0.45 * glow),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: row(2, 153, l10n.tourSampleAnswer),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
