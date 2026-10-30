/// مشاهد الجولة وشروحات الأقسام: قصص قصيرة مرسومة من عناصر التطبيق نفسها.
///
/// كل مشهد يُبنى من تقدّم قصته [t] (انظر [SceneStory])، على لوحة ثابتة المقاس
/// تتسع للشاشة، فتبقى المواضع محسوبة على أي هاتف. ونصوص الآيات من ملف المصحف.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/tadbeer_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/storage/user_data_store.dart';
import 'scene_story.dart';

part 'scenes/mushaf_scenes.dart';
part 'scenes/reflect_scenes.dart';
part 'scenes/section_scenes.dart';
part 'scenes/links_scenes.dart';
part 'scenes/pathways_scenes.dart';
part 'scenes/listen_scenes.dart';
part 'scenes/journey_scenes.dart';
part 'scenes/companion_scenes.dart';
part 'scenes/icon_scenes.dart';

/// عرض اللوحة وارتفاعها المنطقيان؛ تُكبَّر أو تُصغَّر لتملأ مكانها.
const _w = 320.0;
const _h = 220.0;

/// لوحة المشهد: مقاس ثابت يتسع لمكانه، باتجاه من اليمين لليسار.
class _Canvas extends StatelessWidget {
  final List<Widget> children;

  const _Canvas({required this.children});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _w / _h,
      child: FittedBox(
        child: SizedBox(
          width: _w,
          height: _h,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        ),
      ),
    );
  }
}

/// ألوان المشهد من الثيم المختار.
class _Palette {
  final Color primary;
  final Color gold;
  final Color surface;
  final Color text;
  final Color muted;
  final bool dark;

  _Palette(BuildContext context)
    : primary = Theme.of(context).colorScheme.primary,
      gold = AppColors.accentGold(context),
      surface = AppColors.surface(context),
      text = AppColors.textPrimary(context),
      muted = AppColors.textSecondary(context),
      dark = Theme.of(context).brightness == Brightness.dark;
}

/// نص الآية من ملف المصحف، أو نص احتياطي إن لم يُحمَّل بعد.
String _ayahText(int surah, int ayah, String fallback) {
  try {
    return QuranRepository.instance.getAyah(surah, ayah)?.text ?? fallback;
  } on Object {
    return fallback;
  }
}

/// «السورة رقم» مختصراً.
String _ref(BuildContext context, int surah, int ayah) {
  try {
    final name = QuranRepository.instance.getSurah(surah).name;
    return '$name ${context.l10n.digits(ayah)}';
  } on Object {
    return context.l10n.digits(ayah);
  }
}

/// كلمات من [start] إلى ما قبل [end] من الآية، فيبقى رسمها كما في المصحف.
String _ayahWords(int surah, int ayah, int start, int end) {
  final words = _ayahText(surah, ayah, '').split(' ');
  return end > words.length ? '' : words.sublist(start, end).join(' ');
}

/// الآية التي تفتتح الجولة: غاية التطبيق بلفظ القرآن.
String tourOpeningAyah(String fallback) {
  final words = _ayahWords(38, 29, 0, 6);
  return words.isEmpty ? fallback : '﴿$words﴾';
}

TextStyle _quran(double size, Color color) => TextStyle(
  fontFamily: UserDataStore.instance.quranFontFamily,
  fontSize: size,
  height: 1.7,
  color: color,
);

TextStyle _ui(double size, Color color, {bool bold = false}) => TextStyle(
  fontFamily: AppTheme.appFontFamily,
  fontSize: size,
  height: 1.3,
  color: color,
  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
);

/// بطاقة المشهد: سطح التطبيق بإطار ذهبي خفيف.
Widget _card(_Palette c, {required Widget child, EdgeInsets? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: c.gold.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: c.dark ? 0.35 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// إصبع يلمس الشاشة: دائرة شفافة تنكمش عند الضغط.
Widget _finger(_Palette c, Offset at, double press, {double opacity = 1}) {
  final size = 34.0 * (1 - 0.22 * press);
  return Positioned(
    left: at.dx - size / 2,
    top: at.dy - size / 2,
    child: IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: c.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: c.gold.withValues(alpha: 0.5 * press),
                blurRadius: 16,
                spreadRadius: 4 * press,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// نقطة على خط مستقيم بين [a] و[b] عند [p].
Offset _lerp(Offset a, Offset b, double p) => Offset.lerp(a, b, p)!;

/// علامة رقم الآية: دائرة ذهبية برقمها.
Widget _ayahMarker(_Palette c, int n, {double size = 26}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: c.gold, width: 1.6),
    ),
    child: Text(
      ArabicSearchNormalizer.toArabicDigits(n),
      style: _ui(size * 0.42, c.gold, bold: true),
    ),
  );
}
