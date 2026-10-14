import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'adhkar_repository.dart';
import 'ahlulbayt_duas_repository.dart';
import 'ahlulbayt_duas_screen.dart';
import 'general_duas_list_screen.dart';
import 'morning_evening_adhkar_screen.dart';
import 'quran_duas_repository.dart';
import 'quran_duas_screen.dart';
import 'sunnah_duas_repository.dart';

/// الشاشة الرئيسية لقسم الأدعية والأذكار في تطبيق تدبير.
///
/// تم تنظيم وترتيب قسم الأدعية ليكون بسيطاً وشاملاً:
/// 1. أدعية من القرآن الكريم (88 دعاء قرآني موثق مع أرقام الآيات والسور)
/// 2. أذكار الصباح والمساء (حصن المسلم وأذكار اليوم والليلة مع عدادات تفاعلية)
/// 3. أدعية مأثورة عن أهل البيت (مكارم الأخلاق، الثغور، كميل، الندبة، التوسل، عرفة، الجوشن الكبير...)
/// 4. أدعية من السنة النبوية (أدعية نبوية صحيحة جامعة)
/// 5. جوامع الدعاء والرجاء (أدعية الصلاح والعافية وخيري الدنيا والآخرة)
class DuasScreen extends StatelessWidget {
  /// ينشئ الشاشة الرئيسية للأدعية.
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalQuranDuas = QuranDuasRepository.instance.getDuas().length;
    final totalAdhkar = AdhkarRepository.morningAdhkar.length +
        AdhkarRepository.eveningAdhkar.length;
    final totalAhlulbaytDuas = AhlulbaytDuasRepository.defaultDuas.length;
    final totalSunnahDuas = SunnahDuasRepository.sunnahDuas.length;
    final totalJawamiDuas = SunnahDuasRepository.jawamiDuas.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: Text(
            l10n.duas,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
            // الآية القرآنية في فضل الدعاء
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '﴿ وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ ﴾',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 18,
                      height: 1.8,
                      color: isDark
                          ? AppColors.darkAccentGold
                          : AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سورة غافر · الآية ٦٠',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // القسم 1: أدعية من القرآن الكريم
            _DuaCategoryCard(
              icon: FlutterIslamicIcons.quran,
              title: 'أدعية من القرآن',
              subtitle:
                  'أدعية الأنبياء والصالحين وخواتيم السور المأثورة في كتاب الله',
              countBadge:
                  '${ArabicSearchNormalizer.toArabicDigits(totalQuranDuas)} دعاء',
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuranDuasScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // القسم 2: أذكار الصباح والمساء
            _DuaCategoryCard(
              icon: Icons.wb_sunny_outlined,
              title: 'أذكار الصباح والمساء',
              subtitle: 'حصن المسلم وأذكار اليوم والليلة مع عدادات تفاعلية مريحة',
              countBadge:
                  '${ArabicSearchNormalizer.toArabicDigits(totalAdhkar)} ذكر',
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MorningEveningAdhkarScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // القسم 3: أدعية مأثورة عن أهل البيت والصحيفة السجادية
            _DuaCategoryCard(
              icon: FlutterIslamicIcons.prayer,
              title: 'أدعية مأثورة عن أهل البيت',
              subtitle:
                  'مكارم الأخلاق، الثغور، كميل، الندبة، التوسل، عرفة، الجوشن الكبير، ومناجاة الأئمة',
              countBadge:
                  '${ArabicSearchNormalizer.toArabicDigits(totalAhlulbaytDuas)} دعاء',
              isAvailable: true,
              isFeatured: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AhlulbaytDuasScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // القسم 4: أدعية من السنة النبوية
            _DuaCategoryCard(
              icon: Icons.auto_awesome_outlined,
              title: 'أدعية من السنة النبوية',
              subtitle:
                  'أدعية مأثورة وصحيحة عن النبي ﷺ لكشف الكرب وتفريج الهم وقضاء الدين',
              countBadge:
                  '${ArabicSearchNormalizer.toArabicDigits(totalSunnahDuas)} أدعية',
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeneralDuasListScreen(
                      title: 'أدعية من السنة النبوية',
                      items: SunnahDuasRepository.sunnahDuas,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // القسم 5: جوامع الدعاء والرجاء
            _DuaCategoryCard(
              icon: Icons.favorite_border_rounded,
              title: 'جوامع الدعاء والرجاء',
              subtitle:
                  'أدعية جامعة لخيري الدنيا والآخرة والهدى والتقى والعفاف والغنى',
              countBadge:
                  '${ArabicSearchNormalizer.toArabicDigits(totalJawamiDuas)} أدعية',
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeneralDuasListScreen(
                      title: 'جوامع الدعاء والرجاء',
                      items: SunnahDuasRepository.jawamiDuas,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
}

/// بطاقة عرض قسم فرعي من أقسام الأدعية مع الأيقونة وشارة العدد.
class _DuaCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String countBadge;
  final bool isAvailable;
  final bool isFeatured;
  final VoidCallback onTap;

  const _DuaCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.countBadge,
    required this.isAvailable,
    this.isFeatured = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFeatured
                  ? (isDark
                      ? AppColors.darkAccentGold.withValues(alpha: 0.6)
                      : AppColors.olive.withValues(alpha: 0.5))
                  : isAvailable
                      ? (isDark
                          ? AppColors.darkAccentGold.withValues(alpha: 0.35)
                          : AppColors.lightAccentGold.withValues(alpha: 0.4))
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isFeatured ? 1.5 : (isAvailable ? 1.2 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isFeatured
                      ? (isDark
                          ? AppColors.darkAccentGold.withValues(alpha: 0.2)
                          : AppColors.olive.withValues(alpha: 0.15))
                      : isAvailable
                          ? (isDark
                              ? AppColors.darkPrimary.withValues(alpha: 0.35)
                              : AppColors.lightPrimary.withValues(alpha: 0.12))
                          : (isDark
                              ? Colors.grey.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 24,
                  color: isFeatured
                      ? (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.oliveDark)
                      : isAvailable
                          ? (isDark
                              ? AppColors.darkAccentGold
                              : AppColors.lightPrimary)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                ),
              ),

              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? (isDark
                                    ? AppColors.darkPrimary.withValues(
                                        alpha: 0.3,
                                      )
                                    : AppColors.lightPrimary.withValues(
                                        alpha: 0.08,
                                      ))
                                : (isDark ? Colors.black26 : Colors.black12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countBadge,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? (isDark
                                      ? AppColors.darkAccentGold
                                      : AppColors.lightPrimary)
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow Forward Icon
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: isAvailable
                    ? (isDark
                        ? AppColors.darkAccentGold
                        : AppColors.lightPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                        : AppColors.lightTextSecondary.withValues(
                            alpha: 0.5,
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
