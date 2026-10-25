import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../focus/focus_mode_screen.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';
import '../share/ayah_share_sheet.dart';
import '../tadbeer/tadbeer_model.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';
import '../../core/design_system/app_icons.dart';

/// اختيار آية اليوم: ثابتة طوال اليوم وتتغير يومياً، من آيات متوسطة الطول.
class AyahOfTheDay {
  AyahOfTheDay._();

  static List<Ayah>? _pool;

  /// Verses short enough to read at a glance but long enough to reflect on.
  static List<Ayah> get pool => _pool ??= QuranRepository.instance.allAyahs
      .where((a) => a.rawText.length >= 60 && a.rawText.length <= 220)
      .toList();

  /// آية اليوم المحدد.
  static Ayah forDay(DateTime day) {
    final p = pool;
    final daysSinceEpoch = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2020)).inDays;
    // A large prime stride spreads consecutive days across the Mushaf.
    return p[(daysSinceEpoch * 7919) % p.length];
  }

  /// سؤال التدبر لهذا اليوم.
  static String questionForDay(DateTime day) =>
      TadbeerItem.questions[day.day % TadbeerItem.questions.length];
}

/// بطاقة آية اليوم في الرئيسية.
class AyahOfTheDayCard extends StatelessWidget {
  /// ينشئ بطاقة آية اليوم.
  const AyahOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final ayah = AyahOfTheDay.forDay(now);
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gold = Color(0xFFD9B566);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withValues(
              alpha: isDark ? 0.4 : 0.25,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => FocusModeScreen.open(context, ayah),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.sunFill, color: gold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.ayahOfTheDay,
                      style: const TextStyle(
                        color: gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Long surah names shrink instead of overflowing.
                    Expanded(
                      child: Text(
                        l10n.ayahReference(surah.name, ayah.ayahNumber),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${ayah.text} ﴿${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}﴾',
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: UserDataStore.instance.quranFontFamily,
                    fontSize: 21,
                    height: 2,
                    color: const Color(0xFFF2EEE4),
                  ),
                ),
                const SizedBox(height: 8),
                // Shows a check once today's verse has been reflected on.
                ListenableBuilder(
                  listenable: UserDataStore.instance,
                  builder: (context, _) {
                    final done =
                        UserDataStore.instance.getTadbeer(
                          ayah.surahNumber,
                          ayah.ayahNumber,
                        ) !=
                        null;
                    return done
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                AppIcons.checkCircleFill,
                                color: gold,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.reflectedToday,
                                style: const TextStyle(
                                  color: gold,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            AyahOfTheDay.questionForDay(now),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: gold,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                  },
                ),
                const SizedBox(height: 6),
                // Wraps on narrow phones instead of overflowing.
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    _Action(
                      icon: AppIcons.flowerLotusFill,
                      label: l10n.reflectOnIt,
                      onTap: () => TadbeerPauseSheet.show(context, ayah),
                    ),
                    _Action(
                      icon: AppIcons.export,
                      label: l10n.share,
                      onTap: () => AyahShareSheet.show(context, ayah),
                    ),
                    _Action(
                      icon: AppIcons.personSimpleTaiChi,
                      label: l10n.focusMode,
                      onTap: () => FocusModeScreen.open(context, ayah),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
