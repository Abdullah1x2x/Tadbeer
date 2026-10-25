import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';

/// مقاس بطاقة المشاركة.
enum AyahCardFormat {
  /// مربع للمنشورات (1:1).
  square,

  /// طولي للقصص (9:16).
  story,
}

/// نمط ألوان بطاقة المشاركة.
enum AyahCardStyle {
  /// خلفية كحلية ليلية بإطار ذهبي.
  night,

  /// خلفية ورق المصحف بنص كحلي.
  paper,
}

/// لوحة سفلية تعرض معاينة بطاقة الآية وتشاركها كصورة عالية الدقة.
class AyahShareSheet extends StatefulWidget {
  /// الآية المراد مشاركتها.
  final Ayah ayah;

  const AyahShareSheet._(this.ayah);

  /// يفتح لوحة مشاركة الآية كبطاقة مصممة.
  static Future<void> show(BuildContext context, Ayah ayah) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AyahShareSheet._(ayah),
    );
  }

  @override
  State<AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends State<AyahShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  AyahCardFormat _format = AyahCardFormat.square;
  AyahCardStyle _style = AyahCardStyle.night;
  bool _sharing = false;

  /// Logical width of the card; captured at 3x for a 1080 px wide image.
  static const double _cardWidth = 360;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1080 / _cardWidth);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final ayah = widget.ayah;
      final file = File(
        '${dir.path}/tadbeer_${ayah.surahNumber}_${ayah.ayahNumber}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '﴿${ayah.text}﴾ [${surah.name}: ${ayah.ayahNumber}]',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aspect = _format == AyahCardFormat.square ? 1.0 : 9 / 16;
    final previewHeight = MediaQuery.sizeOf(context).height * 0.5;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shareAsImage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            // The preview is the exact widget that gets captured, scaled to fit.
            SizedBox(
              height: previewHeight,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: AyahCard(
                      key: ValueKey('$_format-$_style'),
                      ayah: widget.ayah,
                      style: _style,
                      width: _cardWidth,
                      height: _cardWidth / aspect,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<AyahCardFormat>(
              segments: [
                ButtonSegment(
                  value: AyahCardFormat.square,
                  icon: const Icon(Icons.crop_square_rounded),
                  label: Text(l10n.cardSquare),
                ),
                ButtonSegment(
                  value: AyahCardFormat.story,
                  icon: const Icon(Icons.crop_portrait_rounded),
                  label: Text(l10n.cardStory),
                ),
              ],
              selected: {_format},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() => _format = s.first);
              },
            ),
            const SizedBox(height: 10),
            SegmentedButton<AyahCardStyle>(
              segments: [
                ButtonSegment(
                  value: AyahCardStyle.night,
                  icon: const Icon(Icons.nights_stay_rounded),
                  label: Text(l10n.cardNight),
                ),
                ButtonSegment(
                  value: AyahCardStyle.paper,
                  icon: const Icon(Icons.description_rounded),
                  label: Text(l10n.cardPaper),
                ),
              ],
              selected: {_style},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() => _style = s.first);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(l10n.shareImage),
            ),
          ],
        ),
      ),
    );
  }
}

/// البطاقة المصممة للآية: إطار ذهبي مزدوج، ونقش هندسي خفيف، واسم السورة،
/// ونص الآية بخط المصحف المختار، وتوقيع التطبيق.
class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final AyahCardStyle style;
  final double width;
  final double height;

  /// ينشئ بطاقة الآية بالمقاس والنمط المحددين.
  const AyahCard({
    super.key,
    required this.ayah,
    required this.style,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final night = style == AyahCardStyle.night;
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final quranFont = UserDataStore.instance.quranFontFamily;
    const gold = Color(0xFFD9B566);
    final textColor = night
        ? const Color(0xFFF2EEE4)
        : AppColors.lightPrimaryDark;
    final metaColor = night ? gold : AppColors.lightAccentGold;
    final ayahNumber = ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: night
                ? const RadialGradient(
                    center: Alignment(0, -0.35),
                    radius: 1.2,
                    colors: [Color(0xFF26497A), Color(0xFF0B1220)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFBF7EC), Color(0xFFF1E8D2)],
                  ),
          ),
          child: CustomPaint(
            painter: _CardOrnamentPainter(
              gold: gold.withValues(alpha: night ? 1 : 0.85),
              patternAlpha: night ? 0.06 : 0.08,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 34, 34, 26),
              child: Column(
                children: [
                  // Surah title between ornamental rules.
                  Row(
                    children: [
                      Expanded(child: _Rule(color: metaColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'سُورَةُ ${surah.name}',
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: metaColor,
                          ),
                        ),
                      ),
                      Expanded(child: _Rule(color: metaColor, flip: true)),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: width - 68),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: ayah.text),
                                TextSpan(
                                  text: ' ﴿$ayahNumber﴾',
                                  style: TextStyle(color: metaColor),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: quranFont,
                              // Taller story cards have room for larger text.
                              fontSize: height > width ? 28 : 24,
                              height: 2.0,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // App signature.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          width: 22,
                          height: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تَدْبِير',
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// خط زخرفي رفيع يتلاشى نحو الأطراف وينتهي بمعيّن صغير.
class _Rule extends StatelessWidget {
  final Color color;
  final bool flip;

  const _Rule({required this.color, this.flip = false});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: flip
                ? [color, color.withValues(alpha: 0)]
                : [color.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
    final diamond = Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: 5, height: 5, color: color),
    );
    return Row(
      children: flip
          ? [diamond, const SizedBox(width: 4), line]
          : [line, const SizedBox(width: 4), diamond],
    );
  }
}

/// يرسم إطاراً ذهبياً مزدوجاً بزوايا مزخرفة ونقشاً هندسياً خفيفاً من النجوم الثمانية.
class _CardOrnamentPainter extends CustomPainter {
  final Color gold;
  final double patternAlpha;

  _CardOrnamentPainter({required this.gold, required this.patternAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    // Faint eight-pointed star lattice in the background.
    final pattern = Paint()
      ..color = gold.withValues(alpha: patternAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const step = 44.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        _star(canvas, Offset(x, y), 9, pattern);
      }
    }

    // Double frame.
    final outer = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = Paint()
      ..color = gold.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final r1 = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final r2 = r1.deflate(5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r1, const Radius.circular(10)),
      outer,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r2, const Radius.circular(7)),
      inner,
    );

    // Corner stars.
    final corner = Paint()..color = gold;
    for (final c in [r1.topLeft, r1.topRight, r1.bottomLeft, r1.bottomRight]) {
      _star(canvas, c, 6, corner..style = PaintingStyle.fill);
    }
  }

  /// Eight-pointed star made of two overlapping squares.
  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    for (final angle in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = angle + i * math.pi / 2;
        final p = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardOrnamentPainter old) =>
      old.gold != gold || old.patternAlpha != patternAlpha;
}
