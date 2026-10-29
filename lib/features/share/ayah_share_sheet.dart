import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_logo.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../quran/qcf/qcf_fonts.dart';
import '../quran/qcf/qcf_layout.dart';
import '../../data/models/user_settings_model.dart';
import '../../core/design_system/app_icons.dart';

/// مقاس بطاقة المشاركة.
enum AyahCardFormat {
  /// مربع للمنشورات (1:1).
  square,

  /// طولي للقصص (9:16).
  story,
}

/// ألوان البطاقة، من الثيم المختار.
enum AyahCardStyle {
  /// خلفية داكنة من لون الثيم بإطار ذهبي.
  dark,

  /// خلفية فاتحة كورق الثيم بنص من لونه.
  light,
}

/// نتيجة حفظ البطاقة في الصور.
enum _SaveState { idle, saving, saved, denied, failed }

/// لوحة تعرض بطاقة الآية وتشاركها صورة عالية الدقة.
class AyahShareSheet extends StatefulWidget {
  final Ayah ayah;

  const AyahShareSheet._(this.ayah);

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
  AyahCardStyle _style = AyahCardStyle.dark;
  bool _sharing = false;
  _SaveState _save = _SaveState.idle;

  /// عرض البطاقة المنطقي.
  static const double _cardWidth = 360;

  /// عرض الصورة المحفوظة والمشاركة بالبكسل: واضحة عند التكبير أو الطباعة.
  static const double imageWidth = 2160;

  String get _fileName =>
      'tadbeer_${widget.ayah.surahNumber}_${widget.ayah.ayahNumber}';

  /// البطاقة كما تظهر، مرسومة بعرض [imageWidth] بكسل.
  Future<Uint8List?> _capture() async {
    // خطوط مصحف المدينة تُحمّل مع صفحتها؛ ننتظرها كي لا تلتقط الصورة الخط
    // البديل.
    final page = widget.ayah.page;
    if (UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah &&
        !(QcfLayout.instance.isReady && QcfFonts.instance.isPageLoaded(page))) {
      await QcfLayout.instance.init();
      if (await QcfFonts.instance.ensurePage(page)) {
        // إطار واحد لترسم الخطوط مكان البديل.
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {},
        );
      }
      if (!mounted) return null;
    }
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: imageWidth / _cardWidth);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _saveToPhotos() async {
    setState(() => _save = _SaveState.saving);
    var result = _SaveState.failed;
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        result = _SaveState.denied;
      } else {
        final bytes = await _capture();
        if (bytes != null) {
          await Gal.putImageBytes(bytes, name: _fileName);
          result = _SaveState.saved;
        }
      }
    } on GalException catch (e) {
      debugPrint('Saving the ayah card failed: ${e.type}');
      result = e.type == GalExceptionType.accessDenied
          ? _SaveState.denied
          : _SaveState.failed;
    }
    if (mounted) setState(() => _save = result);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final ayah = widget.ayah;
      final file = File('${dir.path}/$_fileName.png');
      await file.writeAsBytes(bytes);

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

  String? _saveMessage(AppStrings l10n) => switch (_save) {
    _SaveState.saved => l10n.cardSaved,
    _SaveState.denied => l10n.cardSaveDenied,
    _SaveState.failed => l10n.cardSaveFailed,
    _SaveState.idle || _SaveState.saving => null,
  };

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
            // المعاينة هي نفس الواجهة التي تُلتقط، مصغّرة لتتسع.
            SizedBox(
              height: previewHeight,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: AyahCard(
                      key: ValueKey('$_format-$_style-${AppColors.theme}'),
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
                  icon: const Icon(AppIcons.square),
                  label: Text(l10n.cardSquare),
                ),
                ButtonSegment(
                  value: AyahCardFormat.story,
                  // طولية، بشكل القصة.
                  icon: const RotatedBox(
                    quarterTurns: 1,
                    child: Icon(AppIcons.rectangle),
                  ),
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
                  value: AyahCardStyle.dark,
                  icon: const Icon(AppIcons.moonStars),
                  label: Text(l10n.cardDark),
                ),
                ButtonSegment(
                  value: AyahCardStyle.light,
                  icon: const Icon(AppIcons.fileTextFill),
                  label: Text(l10n.cardLight),
                ),
              ],
              selected: {_style},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() {
                  _style = s.first;
                  _save = _SaveState.idle;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const _Spinner()
                        : const Icon(AppIcons.export),
                    label: Text(l10n.shareImage),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _save == _SaveState.saving
                        ? null
                        : _saveToPhotos,
                    icon: switch (_save) {
                      _SaveState.saving => const _Spinner(),
                      _SaveState.saved => const Icon(AppIcons.checkCircleFill),
                      _ => const Icon(AppIcons.downloadSimple),
                    },
                    label: Text(l10n.saveToPhotos),
                  ),
                ),
              ],
            ),
            // نتيجة الحفظ تحت الأزرار، لا في رسالة تختفي خلف اللوحة.
            if (_saveMessage(l10n) case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _save == _SaveState.saved
                        ? AppColors.primary(context)
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// دائرة تقدّم صغيرة بحجم أيقونة الزر.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

/// بطاقة الآية: إطار ذهبي مزدوج، ونقش هندسي خفيف، واسم السورة، ونص الآية بخط
/// المصحف المختار، وتوقيع التطبيق.
class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final AyahCardStyle style;
  final double width;
  final double height;

  /// الثيم الذي تأخذ البطاقة ألوانه؛ المختار إن لم يُحدَّد.
  final AppColorTheme? colorTheme;

  const AyahCard({
    super.key,
    required this.ayah,
    required this.style,
    required this.width,
    required this.height,
    this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final night = style == AyahCardStyle.dark;
    final p = ThemePalette.of(colorTheme ?? AppColors.theme);
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final quranFont = UserDataStore.instance.quranFontFamily;
    const gold = Color(0xFFD9B566);
    final textColor = night ? const Color(0xFFF2EEE4) : p.lightPrimaryDark;
    final metaColor = night ? gold : p.lightAccentGold;
    final ayahNumber = ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber);
    // بطاقة القصة الأطول تتسع لنص أكبر.
    final verseSize = height > width ? 28.0 : 24.0;
    final madinah =
        UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah;
    final flowing = Text.rich(
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
        fontSize: verseSize,
        height: 2.0,
        color: textColor,
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // لون الثيم يتوهج من خلفيته الليلية، أو ورقه مع لمسة من لونه في
            // الأسفل.
            gradient: night
                ? RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 1.2,
                    colors: [p.heroLightStart, p.darkBackground],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(p.lightBackground, Colors.white, 0.45)!,
                      Color.lerp(p.lightBackground, p.heroLightStart, 0.08)!,
                    ],
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
                  // اسم السورة بين خطين زخرفيين.
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
                          // بخط المصحف الذي اختاره القارئ: صفحات المدينة بعلامة
                          // آيتها، أو خط النص المتدفق.
                          child: madinah
                              ? QcfAyahText(
                                  ayah: ayah,
                                  fontSize: verseSize,
                                  height: 2.0,
                                  color: textColor,
                                  fallback: flowing,
                                )
                              : flowing,
                        ),
                      ),
                    ),
                  ),
                  // توقيع التطبيق.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(size: 22, elevated: false),
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

/// إطار ذهبي مزدوج بزوايا مزخرفة، ونقش خفيف من النجوم الثمانية.
class _CardOrnamentPainter extends CustomPainter {
  final Color gold;
  final double patternAlpha;

  _CardOrnamentPainter({required this.gold, required this.patternAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    // شبكة نجوم خافتة في الخلفية.
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

    // الإطار المزدوج.
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

    // نجوم الزوايا.
    final corner = Paint()..color = gold;
    for (final c in [r1.topLeft, r1.topRight, r1.bottomLeft, r1.bottomRight]) {
      _star(canvas, c, 6, corner..style = PaintingStyle.fill);
    }
  }

  /// نجمة ثمانية من مربعين متداخلين.
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
