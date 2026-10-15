import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/screens/quran_screen.dart';
import 'quran_dua.dart';

/// بطاقة عرض الدعاء القرآني الموثق مع أزرار النسخ والانتقال المباشر للمصحف.
///
/// Card widget displaying an authentic Quranic supplication with direct Mushaf navigation.
///
/// EDUCATIONAL NOTE:
/// Quranic Presentation & Purity:
/// 1. Verbatim Text: Renders authentic Quranic text in AmiriQuran font with full diacritics.
/// 2. Clear Separation: Title, category, and contextual notes are strictly separated from
///    the sacred Quranic text.
/// 3. Accurate Copying: Copying copies exclusively the Quranic text without titles or alerts.
/// 4. Direct Reader Navigation: Tapping 'عرض الآية' opens [QuranScreen] at the exact page
///    and navigates to the target ayah.
class QuranDuaCard extends StatelessWidget {
  /// بيانات الدعاء القرآني المعروض في البطاقة.
  final QuranDua dua;

  /// ينشئ بطاقة عرض الدعاء القرآني.
  const QuranDuaCard({super.key, required this.dua});

  /// يبني واجهة بطاقة الدعاء القرآني مع التصنيف والنص وأزرار الإجراءات.
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
          // 1. Header Row: Category Badge & Dua Number
          Row(
            children: [
              // Category Chip
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
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.lightPrimary,
                  ),
                ),
              ),

              const Spacer(),
              // Dua Sequential Number
              Text(
                '#${ArabicSearchNormalizer.toArabicDigits(dua.id)}',
                style: TextStyle(
                  fontFamily: 'Amiri',
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
                fontFamily: 'Amiri',
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
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.amber[300] : Colors.amber[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isArabic ? 'تنبيه: ${dua.alert}' : 'Note: ${dua.alert}',
                      textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'Amiri',
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

          // 2. النص القرآني
          if (!dua.isMultiAyah)
            Text(
              '﴿ ${dua.duaText} ﴾',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 20,
                height: 1.85,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            )
          else
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 20,
                  height: 1.85,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                children: [
                  for (int i = 0; i < dua.verses.length; i++) ...[
                    TextSpan(text: dua.verses[i].text),
                    TextSpan(
                      text:
                          ' ﴿${ArabicSearchNormalizer.toArabicDigits(dua.verses[i].ayahNumber)}﴾',
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
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
            ),

          const SizedBox(height: 14),

          // Divider decoration
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

          // 3. اسم السورة
          Center(
            child: Text(
              l10n.isArabic ? 'سورة ${dua.surahName}' : 'Surah ${dua.surahName}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.lightPrimary,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 4. رقم الآية (SurahNumber : AyahDisplay)
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
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. أزرار الإجراءات (عرض الآية + نسخ الدعاء)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر "عرض الآية"
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
                  Icons.menu_book_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.lightPrimary,
                ),
                label: Text(
                  l10n.viewAyah,
                  style: TextStyle(
                    fontFamily: 'Amiri',
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

              // زر "نسخ"
              OutlinedButton.icon(
                onPressed: () {
                  // Rule 11: Only copy the pure Quranic text without titles or alerts
                  // For multi-ayah: copies verses with authentic ayah end markers
                  // For single-ayah: copies verbatim duaText
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
                          fontFamily: 'Amiri',
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
                  Icons.copy_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                label: Text(
                  l10n.copy,
                  style: TextStyle(
                    fontFamily: 'Amiri',
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
