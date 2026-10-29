import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_logo.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../app/main_shell.dart';
import '../../core/motion/app_motion.dart';

/// شاشة الترحيب: آية في التدبر، وخيار إخفاء الشاشة نهائياً.
class TadbeerIntroScreen extends StatefulWidget {
  const TadbeerIntroScreen({super.key});

  @override
  State<TadbeerIntroScreen> createState() => _TadbeerIntroScreenState();
}

/// الاسم القديم، يبقى للتوافق.
typedef TadabburIntroScreen = TadbeerIntroScreen;

class _TadbeerIntroScreenState extends State<TadbeerIntroScreen>
    with SingleTickerProviderStateMixin {
  /// آيات الترحيب (سورة، آية)؛ تُختار واحدة عشوائياً عند كل فتح.
  static const List<(int, int)> _tadbeerAyahRefs = [
    (47, 24),
    (4, 82),
    (38, 29),
    (23, 68),
    (59, 21),
    (88, 17),
    (50, 6),
    (6, 50),
    (30, 8),
    (10, 24),
  ];

  late final (int, int) _chosenRef;

  bool _doNotShowAgain = false;

  /// يحرّك الترحيب: الشعار، ثم الاسم والآية والزر واحداً بعد الآخر.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.isDismissed) {
      // يظهر فوراً حين يطلب القارئ تقليل الحركة من النظام.
      AppMotion.shouldAnimate(context)
          ? _entrance.forward()
          : _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// يعطي كل عنصر دخولاً متأخراً عن سابقه، والأول (الشعار) يكبر أيضاً إلى
  /// مكانه.
  List<Widget> _staggered(List<Widget> children) {
    final out = <Widget>[];
    var order = 0;
    for (final child in children) {
      if (child is SizedBox) {
        out.add(child);
        continue;
      }
      final start = (order * 0.12).clamp(0.0, 0.55);
      out.add(
        _Entrance(
          animation: CurvedAnimation(
            parent: _entrance,
            curve: Interval(start, start + 0.45, curve: Curves.easeOutCubic),
          ),
          grow: order == 0,
          child: child,
        ),
      );
      order++;
    }
    return out;
  }

  @override
  void initState() {
    super.initState();

    final random = Random();

    _chosenRef = _tadbeerAyahRefs[random.nextInt(_tadbeerAyahRefs.length)];
  }

  /// يحفظ "لا تظهر مرة أخرى" إن اختير، ثم ينتقل إلى الرئيسية.
  Future<void> _handleContinue() async {
    final navigator = Navigator.of(context);

    if (_doNotShowAgain) {
      // تُؤخذ الإعدادات الحالية كي لا يُمسح غيرها.
      final settings = UserDataStore.instance.settings;

      await UserDataStore.instance.updateSettings(
        settings.copyWith(hideTadbeerIntroPermanently: true),
      );
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final repo = QuranRepository.instance;

    Ayah? currentAyah;
    Surah? currentSurah;

    if (repo.isLoaded) {
      try {
        currentAyah = repo.getAyah(_chosenRef.$1, _chosenRef.$2);

        currentSurah = repo.getSurah(_chosenRef.$1);
      } catch (_) {
        // عند الخطأ تبقى القيم فارغة، ويُستخدم النص الاحتياطي.
      }
    }

    final verseText = currentAyah?.text ?? l10n.tadbeerVerse;

    final verseRef = (currentSurah != null && currentAyah != null)
        ? l10n.ayahReference(
            currentSurah.name,
            context.currentLanguage == AppLanguage.arabic
                ? ArabicSearchNormalizer.toArabicDigits(currentAyah.ayahNumber)
                : currentAyah.ayahNumber,
          )
        : l10n.tadbeerVerseRef;

    return Directionality(
      textDirection: context.currentLanguage.direction,

      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.comsilkLight,

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final isCompact = h < 720;
              final isVeryCompact = h < 640;

              // مقاسات تتكيّف مع حجم الشاشة.
              final horizontalPadding = isVeryCompact
                  ? 16.0
                  : (isCompact ? 20.0 : 28.0);
              final verticalPadding = isVeryCompact
                  ? 10.0
                  : (isCompact ? 14.0 : 22.0);
              final logoSize = isVeryCompact ? 54.0 : (isCompact ? 64.0 : 74.0);
              final spaceAfterLogo = isVeryCompact
                  ? 8.0
                  : (isCompact ? 12.0 : 16.0);
              final appTitleSize = isVeryCompact
                  ? 26.0
                  : (isCompact ? 28.0 : 32.0);
              final taglineSize = isVeryCompact ? 12.0 : 13.0;
              final spaceBeforeVerse = isVeryCompact
                  ? 12.0
                  : (isCompact ? 16.0 : 22.0);

              final verseCardPaddingH = isVeryCompact
                  ? 16.0
                  : (isCompact ? 20.0 : 24.0);
              final verseCardPaddingV = isVeryCompact
                  ? 12.0
                  : (isCompact ? 16.0 : 20.0);
              final verseFontSize = isVeryCompact
                  ? 17.0
                  : (isCompact ? 19.0 : 21.0);
              final verseHeight = isVeryCompact ? 1.75 : 1.9;
              final verseRefSize = isVeryCompact ? 11.5 : 12.5;
              final spaceAfterVerse = isVeryCompact
                  ? 10.0
                  : (isCompact ? 14.0 : 18.0);

              final messageFontSize = isVeryCompact
                  ? 12.0
                  : (isCompact ? 12.8 : 13.5);
              final messageHeight = isVeryCompact ? 1.5 : 1.6;
              final spaceBeforeButton = isVeryCompact
                  ? 12.0
                  : (isCompact ? 16.0 : 22.0);
              final buttonPaddingV = isVeryCompact
                  ? 10.0
                  : (isCompact ? 12.0 : 13.5);
              final buttonFontSize = isVeryCompact ? 15.0 : 16.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (verticalPadding * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _staggered([
                          Center(child: AppLogo(size: logoSize)),
                          SizedBox(height: spaceAfterLogo),

                          Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: appTitleSize,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: isDark
                                  ? AppColors.comsilk
                                  : AppColors.oliveDark,
                            ),
                          ),
                          const SizedBox(height: 2),

                          Text(
                            l10n.appTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: taglineSize,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                          SizedBox(height: spaceBeforeVerse),

                          // صندوق الآية.
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: verseCardPaddingH,
                              vertical: verseCardPaddingV,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.comsilk,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '﴿ $verseText ﴾',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'ScheherazadeNew',
                                    fontSize: verseFontSize,
                                    height: verseHeight,
                                    color: isDark
                                        ? AppColors.nightQuranText
                                        : AppColors.dayQuranText,
                                  ),
                                ),
                                SizedBox(height: isVeryCompact ? 6 : 10),
                                Text(
                                  verseRef,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: verseRefSize,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.oliveSoft
                                        : AppColors.olive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spaceAfterVerse),

                          // فكرة التدبر.
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVeryCompact ? 6.0 : 12.0,
                            ),
                            child: Text(
                              l10n.tadbeerMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: messageFontSize,
                                height: messageHeight,
                                color: isDark
                                    ? AppColors.nightSubtitle
                                    : AppColors.daySubtitle,
                              ),
                            ),
                          ),
                          SizedBox(height: spaceBeforeButton),

                          ElevatedButton(
                            onPressed: _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.olive,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: buttonPaddingV,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.continueLabel,
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // خيار عدم الإظهار مرة أخرى.
                          InkWell(
                            onTap: () {
                              setState(() {
                                _doNotShowAgain = !_doNotShowAgain;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _doNotShowAgain,
                                    activeColor: AppColors.olive,
                                    visualDensity: isVeryCompact
                                        ? VisualDensity.compact
                                        : VisualDensity.standard,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _doNotShowAgain = val ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.doNotShowAgain,
                                      style: TextStyle(
                                        fontSize: isVeryCompact ? 12.5 : 13.5,
                                        color: isDark
                                            ? AppColors.nightQuranText
                                            : AppColors.dayQuranText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
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

/// يُظهر العنصر بتلاشٍ وهو يرتفع إلى مكانه، والشعار يكبر أيضاً.
class _Entrance extends StatelessWidget {
  final Animation<double> animation;
  final bool grow;
  final Widget child;

  const _Entrance({
    required this.animation,
    required this.grow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final moved = SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(animation),
      child: grow
          ? ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(animation),
              child: child,
            )
          : child,
    );
    return FadeTransition(opacity: animation, child: moved);
  }
}
