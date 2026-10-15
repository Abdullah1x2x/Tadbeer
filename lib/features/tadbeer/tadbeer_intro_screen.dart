import 'dart:math';

// مكتبة Flutter الأساسية التي أستخدمها لبناء واجهة الشاشة
import 'package:flutter/material.dart';

// هذه الملفات أرجع لها حسب الوظيفة التي أحتاجها في الشاشة
import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/quran/data/quran_models.dart';
import '../../features/quran/data/quran_repository.dart';
import '../home/home_screen.dart';

/// شاشة الترحيب التي تظهر عند تشغيل التطبيق.
///
/// هنا أضع آية مرتبطة بالتدبر، وأعطي المستخدم خيار
/// إخفاء شاشة الترحيب نهائيًا.
class TadbeerIntroScreen extends StatefulWidget {
  /// ينشئ شاشة الترحيب بالتدبر.
  const TadbeerIntroScreen({super.key});

  /// ينشئ حالة شاشة الترحيب.
  @override
  State<TadbeerIntroScreen> createState() => _TadbeerIntroScreenState();
}

/// اسم بديل متوافق مع الإصدارات السابقة لشاشة الترحيب.
///
/// Compatibility alias
typedef TadabburIntroScreen = TadbeerIntroScreen;

/// الحالة الداخلية لشاشة الترحيب واختيار آية التدبر العشوائية.
class _TadbeerIntroScreenState extends State<TadbeerIntroScreen> {
  // هنا خزنت أرقام السور والآيات التي أريد استخدامها في شاشة الترحيب.
  // الرقم الأول = رقم السورة
  // الرقم الثاني = رقم الآية
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

  // هذا المتغير سأضع فيه الآية التي تم اختيارها عند فتح الشاشة.
  // late يعني أنني سأعطيه قيمة قبل استخدامه.
  late final (int, int) _chosenRef;

  // false في البداية لأن الـ Checkbox غير محدد.
  bool _doNotShowAgain = false;

  /// يختار مرجع آية تدبرية عشوائية عند تهيئة الشاشة.
  @override
  void initState() {
    super.initState();

    // أختار آية عشوائية من القائمة عند فتح الشاشة.
    // بعد الاختيار تبقى نفس الآية طالما الشاشة مفتوحة.
    final random = Random();

    _chosenRef = _tadbeerAyahRefs[random.nextInt(_tadbeerAyahRefs.length)];
  }

  /// يحفظ تفضيل عدم الإظهار مجدداً إن حُدد وينتقل إلى الشاشة الرئيسية.
  // هذه الدالة تعمل عندما أضغط على زر "متابعة".
  Future<void> _handleContinue() async {
    // أحصل على Navigator حتى أستطيع الانتقال إلى الصفحة التالية.
    final navigator = Navigator.of(context);

    // إذا كان المستخدم فعل خيار عدم إظهار الشاشة مرة أخرى...
    if (_doNotShowAgain) {
      // أجيب الإعدادات الحالية حتى لا أمسح باقي الإعدادات.
      final settings = UserDataStore.instance.settings;

      // أحفظ فقط أن شاشة الترحيب لا تظهر مرة أخرى.
      await UserDataStore.instance.updateSettings(
        settings.copyWith(hideTadbeerIntroPermanently: true),
      );
    }

    // بعد الضغط على متابعة أنتقل إلى الصفحة الرئيسية.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// يبني واجهة شاشة الترحيب مع شعار التطبيق وآية التدبر المختارة وزر المتابعة.
  @override
  Widget build(BuildContext context) {
    // هذا يعطيني النصوص حسب اللغة الحالية للتطبيق.
    final l10n = context.l10n;

    // أعرف من هنا هل التطبيق حاليًا في الوضع الداكن.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // هذا هو المصدر الذي أجيب منه بيانات القرآن.
    final repo = QuranRepository.instance;

    // سأضع هنا الآية والسورة بعد البحث عنها.
    Ayah? currentAyah;
    Surah? currentSurah;

    // أتأكد أولًا أن بيانات القرآن تم تحميلها.
    if (repo.isLoaded) {
      try {
        // أجيب الآية باستخدام رقم السورة ورقم الآية
        // اللذين اخترتهما سابقًا.
        currentAyah = repo.getAyah(_chosenRef.$1, _chosenRef.$2);

        // أجيب معلومات السورة نفسها.
        currentSurah = repo.getSurah(_chosenRef.$1);
      } catch (_) {
        // إذا حصل خطأ أترك القيم فارغة
        // وسيتم استخدام النص الاحتياطي الموجود أسفل.
      }
    }

    // إذا وجدت الآية أستخدمها، وإذا لم أجدها أستخدم النص الاحتياطي.
    final verseText = currentAyah?.text ?? l10n.tadbeerVerse;

    // أجهز اسم السورة ورقم الآية حتى أعرضهما تحت النص.
    final verseRef = (currentSurah != null && currentAyah != null)
        ? l10n.ayahReference(
            currentSurah.name,
            context.currentLanguage == AppLanguage.arabic
                ? ArabicSearchNormalizer.toArabicDigits(currentAyah.ayahNumber)
                : currentAyah.ayahNumber,
          )
        : l10n.tadbeerVerseRef;

    return Directionality(
      // اتجاه الشاشة يتغير حسب اللغة.
      textDirection: context.currentLanguage.direction,

      child: Scaffold(
        // أغير لون الخلفية حسب الوضع الداكن أو الفاتح.
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.comsilkLight,

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final isCompact = h < 720;
              final isVeryCompact = h < 640;

              // مقاسات واستجابات متكيفة بحسب حجم الشاشة
              final horizontalPadding = isVeryCompact ? 16.0 : (isCompact ? 20.0 : 28.0);
              final verticalPadding = isVeryCompact ? 10.0 : (isCompact ? 14.0 : 22.0);
              final logoSize = isVeryCompact ? 54.0 : (isCompact ? 64.0 : 74.0);
              final spaceAfterLogo = isVeryCompact ? 8.0 : (isCompact ? 12.0 : 16.0);
              final appTitleSize = isVeryCompact ? 26.0 : (isCompact ? 28.0 : 32.0);
              final taglineSize = isVeryCompact ? 12.0 : 13.0;
              final spaceBeforeVerse = isVeryCompact ? 12.0 : (isCompact ? 16.0 : 22.0);

              final verseCardPaddingH = isVeryCompact ? 16.0 : (isCompact ? 20.0 : 24.0);
              final verseCardPaddingV = isVeryCompact ? 12.0 : (isCompact ? 16.0 : 20.0);
              final verseFontSize = isVeryCompact ? 17.0 : (isCompact ? 19.0 : 21.0);
              final verseHeight = isVeryCompact ? 1.75 : 1.9;
              final verseRefSize = isVeryCompact ? 11.5 : 12.5;
              final spaceAfterVerse = isVeryCompact ? 10.0 : (isCompact ? 14.0 : 18.0);

              final messageFontSize = isVeryCompact ? 12.0 : (isCompact ? 12.8 : 13.5);
              final messageHeight = isVeryCompact ? 1.5 : 1.6;
              final spaceBeforeButton = isVeryCompact ? 12.0 : (isCompact ? 16.0 : 22.0);
              final buttonPaddingV = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 13.5);
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
                        children: [
                              // شعار التطبيق (اللوقو)
                              Center(
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(logoSize * 0.28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.olive.withValues(alpha: 0.22),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkSurfaceVariant
                                          : AppColors.olive.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/icons/app_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: spaceAfterLogo),

                              // اسم التطبيق
                              Text(
                                l10n.appName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: appTitleSize,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                  color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // الوصف القصير تحت اسم التطبيق
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

                              // صندوق الآية
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
                                    // نص الآية
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
                                    // مرجع الآية
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

                              // الرسالة التوضيحية عن فكرة التدبر
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

                              // زر متابعة
                              ElevatedButton(
                                onPressed: _handleContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.olive,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: buttonPaddingV),
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

                              // خيار عدم إظهار الشاشة مرة أخرى
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
                            ],
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
