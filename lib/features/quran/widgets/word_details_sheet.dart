import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';

/// لوحة بتفاصيل الكلمة: معناها وموضعها ومصدرها.
void showWordDetailsSheet(
  BuildContext context,
  QuranWordMeaning item,
  String surahName,
  bool isDark,
) {
  final l10n = context.l10n;
  final isArabic = context.currentLanguage == AppLanguage.arabic;
  final ayahDigits = isArabic
      ? ArabicSearchNormalizer.toArabicDigits(item.ayah)
      : item.ayah;
  final pageDigits = isArabic
      ? ArabicSearchNormalizer.toArabicDigits(item.page)
      : item.page;

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: context.currentLanguage.direction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.word,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.olive,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.olive : AppColors.oliveLight)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.surahAyahPageReference(
                          surahName,
                          ayahDigits,
                          pageDigits,
                        ),
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.lexicalMeaningTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meaning,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      AppIcons.bookOpenFill,
                      size: 16,
                      color: isDark ? AppColors.oliveLight : AppColors.olive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.sourceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    if (item.sourceUrl != null)
                      Text(
                        l10n.verifiedDocumentation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
