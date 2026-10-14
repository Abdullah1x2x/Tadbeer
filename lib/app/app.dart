import 'package:flutter/material.dart';

import '../core/storage/user_data_store.dart';
import '../features/home/home_screen.dart';
import '../features/tadbeer/tadbeer_intro_screen.dart';
import 'localization.dart';
import 'theme.dart';

/// مفتاح التنقل العام للتطبيق لفتح الشاشات عند النقر على الإشعارات أو المنبهات.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Root application widget for Tadbeer.
///
/// EDUCATIONAL NOTE:
/// Listens to [UserDataStore] to reactively update themes, font scales,
/// or language settings without restarting the application.
class TadbeerApp extends StatefulWidget {
  const TadbeerApp({super.key});

  @override
  State<TadbeerApp> createState() => _TadbeerAppState();
}

/// حالة التطبيق الجذرية المسؤولة عن اللغة المفعّلة وشاشة البداية.
class _TadbeerAppState extends State<TadbeerApp> {
  late AppLanguage _currentLanguage;
  late bool _initialHideIntro;

  /// تهيئة لغة التطبيق وحالة إخفاء الشاشة الترحيبية من الإعدادات المحفوظة.
  @override
  void initState() {
    super.initState();
    final savedCode = UserDataStore.instance.settings.languageCode;
    _currentLanguage = AppLanguage.fromCode(savedCode);
    _initialHideIntro =
        UserDataStore.instance.settings.hideTadbeerIntroPermanently;
  }

  /// تحديث لغة واجهة التطبيق عند تغييرها من قِبل المستخدم.
  void _onLanguageChanged(AppLanguage newLang) {
    setState(() {
      _currentLanguage = newLang;
    });
  }

  /// بناء شجرة التطبيق مع ربط السمة واللغة المحددة.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserDataStore.instance.settingsNotifier,
      builder: (context, _) {
        final settings = UserDataStore.instance.settingsNotifier.value;

        return AppLocalizationScope(
          currentLanguage: _currentLanguage,
          strings: AppStrings(_currentLanguage),
          onLanguageChanged: _onLanguageChanged,
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'تَدْبِير · Tadbeer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: Locale(_currentLanguage.code),
            builder: (context, child) {
              return Directionality(
                textDirection: _currentLanguage.direction,
                child: child!,
              );
            },
            home: _initialHideIntro
                ? const HomeScreen()
                : const TadbeerIntroScreen(),
          ),
        );
      },
    );
  }
}
