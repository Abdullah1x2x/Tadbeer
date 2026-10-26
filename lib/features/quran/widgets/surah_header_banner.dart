import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';

/// ترويسة السورة على طراز ترويسات مصحف المدينة.
///
/// A band with pointed ends and a double rule in the theme's frame colour
/// fills the line it is given; the surah name sits in a central cartouche, its number in an
/// eight-pointed rosette on one side and its type and length on the other.
/// Everything is sized from the band's height, so it looks the same on any
/// screen and at any zoom.
class SurahHeaderBanner extends StatelessWidget {
  final Surah surah;

  /// ينشئ ترويسة السورة.
  const SurahHeaderBanner({super.key, required this.surah});

  /// Band height relative to its width.
  static const _aspect = 0.13;

  /// Tallest the band gets, on wide screens.
  static const _maxHeight = 72.0;

  /// Width of each side panel relative to the band's height.
  static const _panel = 1.35;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = MushafPalette.of(
      isDark: isDark,
      tone: UserDataStore.instance.settings.mushafPaperTone,
    );
    final gold = palette.frame;
    final meta = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    // Sized from the width it is given (AspectRatio needs nothing from its
    // child, so this also works inside IntrinsicHeight), never taller than
    // _maxHeight; the contents then scale from the actual height.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: AspectRatio(
          aspectRatio: 1 / _aspect,
          child: LayoutBuilder(
            builder: (context, box) {
              final height = box.maxHeight;
              final panel = height * _panel;
              return CustomPaint(
                painter: _SurahBandPainter(
                  gold: gold,
                  band: palette.band,
                  page: palette.page,
                  panel: panel,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      SizedBox(
                        width: panel,
                        child: Center(
                          child: Text(
                            ArabicSearchNormalizer.toArabicDigits(surah.number),
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: height * 0.25,
                              fontWeight: FontWeight.bold,
                              color: gold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.62,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'سُورَةُ ${surah.name}',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: height * 0.42,
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panel,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  surah.isMeccan ? 'مكية' : 'مدنية',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: height * 0.2,
                                    fontWeight: FontWeight.bold,
                                    color: meta,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  '${ArabicSearchNormalizer.toArabicDigits(surah.ayahCount)} آيات',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: height * 0.18,
                                    color: meta,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Paints the header band, the central cartouche, the number rosette and
/// the star ornaments between them.
class _SurahBandPainter extends CustomPainter {
  final Color gold;
  final Color band;
  final Color page;
  final double panel;

  const _SurahBandPainter({
    required this.gold,
    required this.band,
    required this.page,
    required this.panel,
  });

  /// The band: a bar whose ends come to a point, inset by [inset].
  Path _bandPath(Size size, double inset) {
    final w = size.width, h = size.height;
    final tip = h * 0.32;
    return Path()
      ..moveTo(tip + inset, inset)
      ..lineTo(w - tip - inset, inset)
      ..lineTo(w - inset, h / 2)
      ..lineTo(w - tip - inset, h - inset)
      ..lineTo(tip + inset, h - inset)
      ..lineTo(inset, h / 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold;

    // Band with a soft wash of the frame colour and a double rule.
    final outer = _bandPath(size, 1);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(band, gold, 0.18)!,
            band,
            Color.lerp(band, gold, 0.18)!,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(outer, stroke..strokeWidth = 1.4);
    canvas.drawPath(
      _bandPath(size, h * 0.09),
      stroke
        ..strokeWidth = 0.7
        ..color = gold.withValues(alpha: 0.7),
    );

    // Central cartouche on paper, with crests above and below.
    final cw = (w - 2 * panel) * 0.72;
    final cartouche = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: cw, height: h * 0.7),
      Radius.circular(h * 0.35),
    );
    canvas.drawRRect(cartouche, Paint()..color = page);
    canvas.drawRRect(
      cartouche,
      stroke
        ..strokeWidth = 1.2
        ..color = gold,
    );
    canvas.drawRRect(
      cartouche.deflate(h * 0.06),
      stroke
        ..strokeWidth = 0.6
        ..color = gold.withValues(alpha: 0.6),
    );
    final crest = Paint()..color = gold;
    for (final y in [h * 0.15, h * 0.85]) {
      canvas.drawPath(eightPointStar(Offset(w / 2, y), h * 0.07), crest);
    }

    // Number rosette in the right panel (the start side in Arabic).
    final rosette = Offset(w - panel / 2, h / 2);
    canvas.drawPath(eightPointStar(rosette, h * 0.36), Paint()..color = page);
    canvas.drawPath(
      eightPointStar(rosette, h * 0.36),
      stroke
        ..strokeWidth = 1.1
        ..color = gold,
    );
    canvas.drawCircle(
      rosette,
      h * 0.2,
      stroke
        ..strokeWidth = 0.6
        ..color = gold.withValues(alpha: 0.6),
    );

    // Small stars between the side panels and the cartouche.
    final star = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = gold.withValues(alpha: 0.55);
    final step = h * 0.42;
    final left = cartouche.left;
    for (var x = left - step * 0.8; x > panel + step * 0.3; x -= step) {
      canvas.drawPath(eightPointStar(Offset(x, h / 2), h * 0.1), star);
      canvas.drawPath(eightPointStar(Offset(w - x, h / 2), h * 0.1), star);
    }
  }

  @override
  bool shouldRepaint(_SurahBandPainter old) =>
      old.gold != gold ||
      old.band != band ||
      old.page != page ||
      old.panel != panel;
}

/// Decorative Basmalah banner shown between Surahs (except Surah 1 & 9).
/// لافتة البسملة التي تعرض في مطلع السور (باستثناء سورتي الفاتحة والتوبة).
class BismillahBanner extends StatelessWidget {
  /// ينشئ ودجت لافتة البسملة.
  const BismillahBanner({super.key});

  /// يبني نص البسملة متمركزاً بالخط القرآني المختار.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = UserDataStore.instance.quranFontFamily;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            color: MushafPalette.of(
              isDark: isDark,
              tone: UserDataStore.instance.settings.mushafPaperTone,
            ).text,
          ),
        ),
      ),
    );
  }
}
