import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/storage/user_data_store.dart';
import '../../quran/qcf/qcf_ayah_text.dart';
import '../../quran/screens/quran_screen.dart';
import '../data/quran_dua_model.dart';
import '../../../core/design_system/app_icons.dart';

/// بطاقة دعاء قرآني، مع نسخه وفتحه في المصحف.
///
/// النص القرآني بخط المصحف المختار، ومنفصل عن العنوان والتصنيف والتنبيه.
/// والنسخ ينسخ النص القرآني وحده، و'عرض الآية' يفتح المصحف على الآية.
class QuranDuaCard extends StatelessWidget {
  final QuranDua dua;

  const QuranDuaCard({super.key, required this.dua});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ١. التصنيف ورقم الدعاء.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.25)
                      : AppColors.lightPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  dua.category,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.lightPrimary,
                  ),
                ),
              ),

              const Spacer(),
              Text(
                '#${ArabicSearchNormalizer.toArabicDigits(dua.id)}',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),

          if (dua.title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              dua.title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.lightPrimary,
              ),
            ),
          ],

          if (dua.alert != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppIcons.info,
                    size: 16,
                    color: isDark ? Colors.amber[300] : Colors.amber[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.duaAlert(dua.alert!),
                      textDirection: l10n.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ٢. النص القرآني بخط المصحف المختار.
          _DuaText(dua: dua),

          const SizedBox(height: 14),

          Center(
            child: Container(
              width: 48,
              height: 2,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkAccentGold.withValues(alpha: 0.4)
                    : AppColors.lightAccentGold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ٣. اسم السورة.
          Center(
            child: Text(
              l10n.surahTitle(dua.surahName),
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.lightPrimary,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ٤. رقم الآية (سورة : آيات).
          Center(
            child: Text(
              l10n.isArabic
                  ? (dua.ayahDisplay.contains('–')
                        ? 'الآيات ${ArabicSearchNormalizer.convertDigits(dua.ayahDisplay)}'
                        : 'الآية ${ArabicSearchNormalizer.convertDigits(dua.ayahDisplay)}')
                  : (dua.ayahDisplay.contains('–')
                        ? 'Verses ${dua.ayahDisplay}'
                        : 'Verse ${dua.ayahDisplay}'),
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ٥. عرض الآية ونسخ الدعاء.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuranScreen(
                        initialPage: dua.page,
                        targetSurahNumber: dua.surahNumber,
                        targetAyahNumber: dua.ayahNumber,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  AppIcons.bookOpenFill,
                  size: 16,
                  color: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.lightPrimary,
                ),
                label: Text(
                  l10n.viewAyah,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.lightPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkAccentGold.withValues(alpha: 0.6)
                        : AppColors.lightPrimary.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.15)
                      : AppColors.lightPrimary.withValues(alpha: 0.05),
                ),
              ),

              const SizedBox(width: 10),

              OutlinedButton.icon(
                onPressed: () {
                  // ينسخ النص القرآني وحده دون عنوان أو تنبيه؛ ومتعدد الآيات
                  // بأرقام آياته.
                  final textToCopy = dua.isMultiAyah
                      ? dua.formattedTextWithMarkers
                      : dua.duaText;
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      content: Text(
                        l10n.duaCopiedSuccess,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  AppIcons.copy,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                label: Text(
                  l10n.copy,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// نص الدعاء بخط المصحف الذي اختاره القارئ.
///
/// مع مصحف المدينة يُرسم بخطوط مجمع الملك فهد متى كانت آيات الدعاء كاملة؛
/// فالمقطع من آية لا رموز له وحده، فيُكتب كله بالخط المتدفق المختار بدل خلط
/// خطين في دعاء واحد.
class _DuaText extends StatefulWidget {
  final QuranDua dua;

  const _DuaText({required this.dua});

  @override
  State<_DuaText> createState() => _DuaTextState();
}

class _DuaTextState extends State<_DuaText> {
  List<QcfGlyphs>? _glyphs;

  @override
  void initState() {
    super.initState();
    _loadGlyphs();
  }

  Future<void> _loadGlyphs() async {
    if (UserDataStore.instance.settings.mushafStyle != MushafStyle.madinah) {
      return;
    }
    final glyphs = <QcfGlyphs>[];
    for (final v in widget.dua.verses) {
      final ayah = QuranRepository.instance.getAyah(
        widget.dua.surahNumber,
        v.ayahNumber,
      );
      if (ayah == null || !await QcfGlyphs.prepare(ayah)) return;
      final part = QcfGlyphs.ofExcerpt(ayah, v.text);
      if (part == null) return;
      glyphs.add(part);
    }
    if (mounted) setState(() => _glyphs = glyphs);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final glyphs = _glyphs;
    if (glyphs != null) {
      return Text.rich(
        TextSpan(
          children: [
            for (final g in glyphs)
              TextSpan(
                text: g.text,
                style: g.style(fontSize: 22, height: 1.9, color: color),
              ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      );
    }
    final font = UserDataStore.instance.quranFontFamily;
    final dua = widget.dua;
    final style = TextStyle(
      fontFamily: font,
      fontSize: 20,
      height: 1.85,
      color: color,
    );
    if (!dua.isMultiAyah) {
      return Text(
        '﴿ ${dua.duaText} ﴾',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (int i = 0; i < dua.verses.length; i++) ...[
            TextSpan(text: dua.verses[i].text),
            TextSpan(
              text:
                  ' ﴿${ArabicSearchNormalizer.toArabicDigits(dua.verses[i].ayahNumber)}﴾',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.lightPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (i < dua.verses.length - 1) const TextSpan(text: ' '),
          ],
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
  }
}
