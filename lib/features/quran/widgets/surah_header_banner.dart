import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../qcf/qcf_page_body.dart';

/// ترويسة السورة على طراز مصحف المدينة.
///
/// شريط مدبّب الطرفين بخط مزدوج بلون إطار الثيم يملأ سطره؛ اسم السورة بخط
/// المصحف في خرطوشة وسطه بين غصنين، ورقمها في وردة ثمانية على جانب، ونوعها
/// وعدد آياتها وجزؤها على الآخر. كل شيء
/// يُقاس من ارتفاع الشريط، فيبدو نفسه في أي شاشة وأي تكبير.
class SurahHeaderBanner extends StatelessWidget {
  final Surah surah;

  const SurahHeaderBanner({super.key, required this.surah});

  /// ارتفاع الشريط نسبةً إلى عرضه.
  static const _aspect = 0.13;

  /// أقصى ارتفاع، في الشاشات العريضة.
  static const _maxHeight = 72.0;

  /// عرض كل جانب نسبةً إلى ارتفاع الشريط.
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
    final juz = QuranRepository.instance.getAyah(surah.number, 1)?.juz;

    // الحجم من العرض المعطى (AspectRatio لا يحتاج شيئاً من ابنه، فيعمل داخل
    // IntrinsicHeight أيضاً)، دون تجاوز _maxHeight؛ ثم يتحجّم المحتوى من
    // الارتفاع الفعلي.
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
                          // داخل الخرطوشة بحشوة، وبمقاييس الخط الطبيعية التي
                          // تتسع للتشكيل، فلا يخرج شيء من حدودها.
                          child: SizedBox(
                            width:
                                _SurahBandPainter.cartoucheWidth(
                                  box.maxWidth,
                                  height,
                                  panel,
                                ) -
                                height * 0.6,
                            height: height * 0.62,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                // بخط المصحف المعروض، فيتناسق مع نص الصفحة.
                                'سُورَةُ ${surah.name}',
                                style: QcfPageBody.scriptStyle(
                                  fontSize: height * 0.34,
                                  color: palette.text,
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
                                  ayahCountLabel(surah.ayahCount),
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: height * 0.18,
                                    color: meta,
                                    height: 1.1,
                                  ),
                                ),
                                if (juz != null)
                                  Text(
                                    'الجزء ${ArabicSearchNormalizer.toArabicDigits(juz)}',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: height * 0.18,
                                      color: gold,
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

/// عدد الآيات بتمييزه: آية، آيتان، ٣ آيات، ١١ آية.
String ayahCountLabel(int n) {
  if (n == 1) return 'آية';
  if (n == 2) return 'آيتان';
  final digits = ArabicSearchNormalizer.toArabicDigits(n);
  return n % 100 >= 3 && n % 100 <= 10 ? '$digits آيات' : '$digits آية';
}

/// يرسم الشريط والخرطوشة ووردة الرقم والنجوم بينها.
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

  /// عرض الخرطوشة في شريط بعرض [w] وارتفاع [h]؛ يقرؤه النص ليبقى داخلها.
  static double cartoucheWidth(double w, double h, double panel) =>
      (w - 2 * panel) * 0.62;

  /// الشريط: قضيب مدبّب الطرفين، مُزاح للداخل بـ[inset].
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

    // الشريط بلمسة خفيفة من لون الإطار وخط مزدوج.
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

    // الخرطوشة على لون الورق، مع نجمة عند كل طرف.
    final cw = cartoucheWidth(w, h, panel);
    final cartouche = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: cw, height: h * 0.8),
      Radius.circular(h * 0.4),
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
    for (final x in [cartouche.left, cartouche.right]) {
      canvas.drawPath(eightPointStar(Offset(x, h / 2), h * 0.08), crest);
    }

    // وردة الرقم في الجانب الأيمن (بداية القراءة بالعربية).
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

    // غصن نباتي بين كل جانب والخرطوشة، والأيمن صورة الأيسر في المرآة.
    final from = panel + h * 0.08, to = cartouche.left - h * 0.12;
    if (to - from > h * 0.3) {
      _vine(canvas, from, to, h);
      canvas
        ..save()
        ..translate(w, 0)
        ..scale(-1, 1);
      _vine(canvas, from, to, h);
      canvas.restore();
    }
  }

  /// غصن يتموّج من [from] إلى [to] على منتصف الشريط، بورقة عند كل قمة وبرعم
  /// في طرفه.
  void _vine(Canvas canvas, double from, double to, double h) {
    final cy = h / 2, amp = h * 0.13;
    final waves = math.max(2, ((to - from) / (h * 0.5)).round());
    final step = (to - from) / waves;
    final stem = Path()..moveTo(from, cy);
    final leaf = Paint()..color = gold.withValues(alpha: 0.5);
    void leafAt(double x, double y, double angle, double size) {
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(angle);
      canvas.drawPath(_leaf(size), leaf);
      canvas.restore();
    }

    for (var i = 0; i < waves; i++) {
      final x0 = from + step * i, dir = i.isEven ? -1.0 : 1.0;
      stem.cubicTo(
        x0 + step * 0.3,
        cy + amp * dir,
        x0 + step * 0.7,
        cy + amp * dir,
        x0 + step,
        cy,
      );
      // ورقة كبيرة من قمة الموجة إلى الخارج، وصغيرة تقابلها.
      leafAt(x0 + step / 2, cy + amp * 0.75 * dir, dir * -2.2, h * 0.24);
      leafAt(x0 + step * 0.8, cy + amp * 0.35 * dir, dir * 0.9, h * 0.15);
    }
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round
        ..color = gold.withValues(alpha: 0.6),
    );
    canvas.drawCircle(Offset(from, cy), h * 0.04, leaf);
  }

  /// ورقة لوزية من الأصل باتجاه x الموجب بطول [size].
  static Path _leaf(double size) => Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(size * 0.5, -size * 0.38, size, 0)
    ..quadraticBezierTo(size * 0.5, size * 0.38, 0, 0)
    ..close();

  @override
  bool shouldRepaint(_SurahBandPainter old) =>
      old.gold != gold ||
      old.band != band ||
      old.page != page ||
      old.panel != panel;
}

/// البسملة في مطلع السور، إلا الفاتحة والتوبة.
class BismillahBanner extends StatelessWidget {
  const BismillahBanner({super.key});

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
