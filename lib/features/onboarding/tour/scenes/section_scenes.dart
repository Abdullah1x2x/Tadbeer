part of '../tour_scenes.dart';

/// صف في وسط المشهد، يصغر مع النص الكبير بدل أن يفيض.
class _FitRow extends StatelessWidget {
  final List<Widget> children;

  const _FitRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// السبحة: كل لمسة تقدّم حبة ويزيد العدّاد حتى يكتمل الهدف.
class TasbeehScene extends StatelessWidget {
  final double t;

  const TasbeehScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final progress = phase(t, 0.08, 0.86, Curves.linear);
    final count = (33 * progress).round();
    final done = phase(t, 0.86, 1, Curves.easeOutBack);
    final beat = (progress * 33) % 1;
    return _Canvas(
      children: [
        Center(
          child: Transform.scale(
            scale: 1 + 0.03 * math.sin(beat * math.pi),
            child: SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: _BeadRingPainter(
                  filled: count,
                  gold: c.gold,
                  empty: c.muted.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.digits(count),
                        style: _ui(38, c.primary, bold: true),
                      ),
                      Text(l10n.dhikrSubhanAllah, style: _ui(12, c.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 160 - 16,
          top: 196,
          child: popIn(
            done,
            Icon(AppIcons.sparkleFill, size: 24, color: c.gold),
          ),
        ),
      ],
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  final int filled;
  final Color gold;
  final Color empty;

  _BeadRingPainter({
    required this.filled,
    required this.gold,
    required this.empty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    for (var i = 0; i < 33; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 33;
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * radius,
        i < filled ? 6 : 5,
        Paint()..color = i < filled ? gold : empty,
      );
    }
  }

  @override
  bool shouldRepaint(_BeadRingPainter old) => old.filled != filled;
}

/// أقسام الأدعية تتوالى، ثم يظهر دعاء من القرآن بخط المصحف.
class DuasScene extends StatelessWidget {
  final double t;

  const DuasScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final labels = [l10n.tourDuaQuran, l10n.tourDuaSunnah, l10n.tourDuaAdhkar];
    final card = phase(t, 0.38, 0.62);
    final sample = _ayahWords(2, 201, 3, 14);
    return _Canvas(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 8,
          child: _FitRow(
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: popIn(
                    phase(t, i * 0.1, 0.16 + i * 0.1, Curves.easeOutBack),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: i == 0 ? c.primary : c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: c.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: _ui(
                          11,
                          i == 0 ? Colors.white : c.text,
                          bold: true,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 54,
          child: riseIn(
            card,
            _card(
              c,
              child: Column(
                children: [
                  Icon(AppIcons.handHeartFill, size: 22, color: c.gold),
                  const SizedBox(height: 4),
                  Text(
                    sample,
                    textAlign: TextAlign.center,
                    style: _quran(16, c.text),
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

/// الآية تُخفى ليختبر القارئ حفظه، ثم تظهر ويُسجَّل أنه تذكّرها.
class MemorizeScene extends StatelessWidget {
  final double t;

  const MemorizeScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final hide = phase(t, 0.12, 0.28);
    final show = phase(t, 0.42, 0.56);
    final veil = (hide - show).clamp(0.0, 1.0);
    final press = math.sin(phase(t, 0.62, 0.72) * math.pi);
    final picked = phase(t, 0.68, 0.76);
    final next = phase(t, 0.76, 0.92, Curves.easeOutBack);
    return _Canvas(
      children: [
        Positioned(
          left: 24,
          right: 24,
          top: 12,
          child: _card(
            c,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _ayahText(94, 5, ''),
                  textAlign: TextAlign.center,
                  style: _quran(21, c.text),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: veil,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(AppIcons.brainFill, size: 30, color: c.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 112,
          child: _FitRow(
            children: [
              Transform.scale(
                scale: 1 - 0.08 * press,
                child: _pill(
                  Color.lerp(c.primary, c.gold, picked)!,
                  l10n.tourRemembered,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: 1 - 0.5 * picked,
                child: _pill(c.surface, l10n.tourForgot, c.text),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 168,
          child: popIn(
            next,
            _FitRow(
              children: [
                Icon(AppIcons.check, size: 16, color: c.gold),
                const SizedBox(width: 6),
                Text(l10n.tourNextReview, style: _ui(13, c.text, bold: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(Color color, String label, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x33B8923A)),
    ),
    child: Text(label, style: _ui(13, text, bold: true)),
  );
}

/// خاطرة تُكتب على آية، ثم تنطوي في بطاقة تحفظها.
class NotesScene extends StatelessWidget {
  final double t;

  const NotesScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ayah = phase(t, 0.0, 0.2);
    final typing = phase(t, 0.2, 0.68, Curves.linear);
    final saved = phase(t, 0.72, 0.86, Curves.easeOutBack);
    return _Canvas(
      children: [
        Positioned(
          left: 24,
          right: 24,
          top: 16,
          child: riseIn(
            ayah,
            _card(
              c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    child: Text(
                      _ayahWords(65, 2, 26, 32),
                      style: _quran(17, c.text),
                    ),
                  ),
                  const Divider(height: 14),
                  Row(
                    children: [
                      Icon(AppIcons.notePencil, size: 15, color: c.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _typed(
                          l10n.tourSampleNote,
                          typing,
                          _ui(13, c.primary, bold: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 150,
          child: popIn(
            saved,
            _FitRow(
              children: [
                Icon(AppIcons.check, size: 16, color: c.gold),
                const SizedBox(width: 6),
                Text(l10n.save, style: _ui(13, c.text, bold: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// كلمة من الآية تُضاء، فيظهر معناها تحتها.
class MeaningsScene extends StatelessWidget {
  final double t;

  const MeaningsScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final light = phase(t, 0.2, 0.36);
    final bubble = phase(t, 0.36, 0.56, Curves.easeOutBack);
    final lead = _ayahWords(1, 4, 0, 2);
    final word = _ayahWords(1, 4, 2, 3);
    return _Canvas(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 26,
          child: _FitRow(
            children: [
              Text(lead, style: _quran(27, c.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.28 * light),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(word, style: _quran(27, c.text)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 56,
          right: 56,
          top: 112,
          child: popIn(
            bubble,
            _card(
              c,
              child: Column(
                children: [
                  Text(
                    l10n.tourMeaningLabel,
                    style: _ui(11, c.gold, bold: true),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sampleMeaning(),
                    textAlign: TextAlign.center,
                    style: _ui(15, c.text, bold: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// معنى «الدين» كما في ملف المعاني، فالشرح يعرض ما سيجده القارئ.
  String _sampleMeaning() {
    try {
      return QuranRepository.instance
          .getWordMeaningsForPage(1)
          .firstWhere((m) => m.surah == 1 && m.ayah == 4)
          .meaning;
    } on Object {
      return '';
    }
  }
}

/// كتاب يخرج من الرف، ويُفتح على صفحة مقروءة.
class BooksScene extends StatelessWidget {
  final double t;

  const BooksScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final pull = phase(t, 0.14, 0.36);
    final open = phase(t, 0.4, 0.66);
    final colors = [c.primary, c.gold, c.muted, c.primary, c.gold];
    return _Canvas(
      children: [
        // الرف.
        Positioned(
          left: 56,
          right: 56,
          top: 124,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        for (var i = 0; i < colors.length; i++)
          Positioned(
            left: 76 + i * 36.0,
            top: 34 - (i == 2 ? 26 * pull : 0),
            child: Opacity(
              opacity: i == 2 ? 1 - open : 1 - 0.65 * open,
              child: Container(
                width: 30,
                height: 90,
                decoration: BoxDecoration(
                  color: colors[i].withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  AppIcons.bookOpenTextFill,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        Positioned(
          left: 76,
          right: 76,
          top: 36,
          child: popIn(
            open,
            _card(
              c,
              child: Column(
                children: [
                  Text(
                    l10n.tourBookSample,
                    style: _ui(13, c.primary, bold: true),
                  ),
                  const SizedBox(height: 8),
                  for (final w in const [1.0, 0.9, 1.0, 0.65])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: FractionallySizedBox(
                        widthFactor: w,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.muted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
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
