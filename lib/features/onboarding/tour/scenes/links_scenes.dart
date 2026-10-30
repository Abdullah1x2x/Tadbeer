part of '../tour_scenes.dart';

/// شبكة روابط عن أبواب الرزق: ثلاث آيات تنضم إلى الموضوع، ولكل منها ملاحظة.
///
/// الطلاق ٢-٣ (التقوى)، ونوح ١٠-١١ (الاستغفار)، وإبراهيم ٧ (الشكر)؛ فتصل فكرة
/// الربط: آيات من سور متفرقة تهدف إلى معنى واحد ويدعم بعضها بعضاً.
class LinkNetwork extends StatelessWidget {
  final double t;
  final String centreLabel;
  final IconData centreIcon;

  /// كم آية تنضم؛ وأولها يظهر أولاً.
  final int verses;

  /// هل تظهر ملاحظة كل آية تحتها.
  final bool notes;

  const LinkNetwork({
    super.key,
    required this.t,
    required this.centreLabel,
    this.centreIcon = AppIcons.graphFill,
    this.verses = 3,
    this.notes = false,
  });

  static const _centre = Offset(160, 104);
  static const _spots = [Offset(72, 40), Offset(248, 40), Offset(160, 184)];

  static String _verse(int i, AppStrings l10n) {
    final text = switch (i) {
      0 =>
        '${_ayahWords(65, 2, 26, 32)} ۝ '
            '${_ayahWords(65, 3, 0, 5)}',
      1 =>
        '${_ayahWords(71, 10, 1, 3)} ۝ '
            '${_ayahWords(71, 11, 0, 4)}',
      _ => _ayahWords(14, 7, 3, 6),
    };
    return text.trim() == '۝' ? '' : text;
  }

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final noteTexts = [
      l10n.tourLinkNote1,
      l10n.tourLinkNote2,
      l10n.tourLinkNote3,
    ];
    final n = verses.clamp(1, _spots.length);
    final join = [
      for (var i = 0; i < n; i++)
        phase(t, i * 0.22, 0.24 + i * 0.22, Curves.easeOutBack),
    ];
    final noteIn = [
      for (var i = 0; i < n; i++) phase(t, 0.1 + i * 0.22, 0.3 + i * 0.22),
    ];
    final lines = [
      for (var i = 0; i < n; i++) phase(t, 0.16 + i * 0.22, 0.36 + i * 0.22),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ThreadsPainter(
              centre: _centre,
              spots: _spots.take(n).toList(),
              progress: lines,
              color: c.gold,
            ),
          ),
        ),
        for (var i = 0; i < n; i++)
          Positioned(
            left: _spots[i].dx - _nodeWidth(i) / 2,
            top: i == 2 ? _spots[i].dy - 22 : 2,
            child: popIn(
              join[i],
              Container(
                width: _nodeWidth(i),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.gold.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: c.dark ? 0.3 : 0.06,
                      ),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _verse(i, l10n),
                      textAlign: TextAlign.center,
                      style: _quran(10, c.text).copyWith(height: 1.55),
                    ),
                    if (notes)
                      Opacity(
                        opacity: noteIn[i],
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            noteTexts[i],
                            textAlign: TextAlign.center,
                            style: _ui(8.5, c.primary, bold: true),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: _centre.dx - 34,
          top: _centre.dy - 34,
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary,
              border: Border.all(color: c.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: c.gold.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(centreIcon, size: 18, color: c.gold),
                Text(
                  centreLabel,
                  maxLines: 1,
                  style: _ui(10, Colors.white, bold: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _nodeWidth(int i) => i == 2 ? 150 : 136;

class _ThreadsPainter extends CustomPainter {
  final Offset centre;
  final List<Offset> spots;
  final List<double> progress;
  final Color color;

  _ThreadsPainter({
    required this.centre,
    required this.spots,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < spots.length; i++) {
      final p = progress[i];
      if (p <= 0) continue;
      canvas.drawLine(centre, Offset.lerp(centre, spots[i], p)!, paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadsPainter old) =>
      old.progress != progress || old.color != color;
}

/// إنشاء رابط: يُكتب عنوانه ويُضغط «إنشاء» فتولد عقدته.
class CreateLinkScene extends StatelessWidget {
  final double t;

  const CreateLinkScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final type = phase(t, 0.1, 0.4);
    final press = math.sin(phase(t, 0.48, 0.56) * math.pi);
    final morph = phase(t, 0.58, 0.75);
    return _Canvas(
      children: [
        Positioned(
          left: 50,
          right: 50,
          top: 24,
          child: Opacity(
            opacity: 1 - morph,
            child: Transform.scale(
              scale: 1 - 0.5 * morph,
              child: _card(
                c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.tourCreateLink,
                      style: _ui(12, c.text, bold: true),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: _typed(
                        l10n.tourSampleLink,
                        type,
                        _ui(12, c.text, bold: true),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Transform.scale(
                        scale: 1 - 0.1 * press,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.create,
                            style: _ui(10.5, Colors.white, bold: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (morph > 0)
          Positioned.fill(
            child: Opacity(
              opacity: morph,
              child: LinkNetwork(
                t: 0,
                verses: 1,
                centreLabel: l10n.tourSampleLink,
              ),
            ),
          ),
        _finger(
          c,
          _lerp(
            const Offset(250, 200),
            const Offset(84, 124),
            phase(t, 0.4, 0.48),
          ),
          press,
          opacity: phase(t, 0.38, 0.42) * (1 - phase(t, 0.6, 0.66)),
        ),
      ],
    );
  }
}

/// تنضم ثلاث آيات عن الصبر إلى الرابط، ولكل منها ملاحظة، وتُرسم خيوطها.
class AddVersesScene extends StatelessWidget {
  final double t;

  const AddVersesScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return _Canvas(
      children: [
        Positioned.fill(
          child: LinkNetwork(
            t: t,
            notes: true,
            centreLabel: context.l10n.tourSampleLink,
          ),
        ),
      ],
    );
  }
}

/// الشبكة تكتمل آية بعد آية، ولكل آية ملاحظتها.
class WholeNetworkScene extends StatelessWidget {
  final double t;

  const WholeNetworkScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return _Canvas(
      children: [
        Positioned.fill(
          child: LinkNetwork(
            t: t,
            notes: true,
            centreLabel: context.l10n.tourSampleLink,
          ),
        ),
      ],
    );
  }
}
