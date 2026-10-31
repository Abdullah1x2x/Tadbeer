import 'package:flutter/material.dart';

import '../data/storage/user_data_store.dart';
import '../data/storage/user_database.dart';
import 'main_shell.dart';
import '../features/tadbeer/tadbeer_intro_screen.dart';
import 'localization.dart';
import '../core/theme/theme.dart';
import '../l10n/app_localizations.dart';
import '../features/onboarding/theme_picker_screen.dart';
import '../features/onboarding/name_screen.dart';
import '../features/onboarding/tour/tour_screen.dart';

/// يفتح الشاشات من خارج شجرة الواجهة، كالنقر على إشعار.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// يعرض رسائل عامة من أي مكان، كفشل حفظ البيانات.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// جذر التطبيق: يطبّق الثيم واللغة المحفوظين ويتبعهما دون إعادة تشغيل.
class TadbeerApp extends StatefulWidget {
  const TadbeerApp({super.key});

  @override
  State<TadbeerApp> createState() => _TadbeerAppState();
}

class _TadbeerAppState extends State<TadbeerApp> {
  late AppLanguage _currentLanguage;
  late bool _initialHideIntro;
  late bool _initialThemeChosen;

  /// الشاشة التالية لاختيار الثيم: الترحيب، أو الشاشة الرئيسية لمن أخفاه.
  Widget _afterThemePicker(BuildContext context) =>
      _initialHideIntro ? const MainShell() : const TadbeerIntroScreen();

  @override
  void initState() {
    super.initState();
    final savedCode = UserDataStore.instance.settings.languageCode;
    _currentLanguage = AppLanguage.fromCode(savedCode);
    _initialHideIntro =
        UserDataStore.instance.settings.hideTadbeerIntroPermanently;
    _initialThemeChosen = UserDataStore.instance.settings.themeChosen;
    UserDatabase.instance.lastIssue.addListener(_scheduleDatabaseIssue);
    // مشكلات حدثت أثناء الإقلاع، قبل وجود هذه الواجهة.
    if (UserDatabase.instance.lastIssue.value != null) {
      _scheduleDatabaseIssue();
    }
  }

  /// يؤجّل رسالة قاعدة البيانات إلى ما بعد الإطار الحالي، فلا تتعارض مع البناء.
  void _scheduleDatabaseIssue() {
    if (UserDatabase.instance.lastIssue.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onDatabaseIssue();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    UserDatabase.instance.lastIssue.removeListener(_scheduleDatabaseIssue);
    super.dispose();
  }

  /// يُعلم المستخدم بفشل حفظ البيانات أو قراءتها بدل أن يفشل بصمت.
  void _onDatabaseIssue() {
    final issue = UserDatabase.instance.lastIssue.value;
    final messenger = appScaffoldMessengerKey.currentState;
    if (issue == null || messenger == null) return;
    final strings = AppStrings(_currentLanguage);
    final message = switch (issue.kind) {
      UserDatabaseIssueKind.writeFailed => strings.dataSaveFailed,
      UserDatabaseIssueKind.readFailed => strings.dataLoadFailed,
      UserDatabaseIssueKind.corruptRowsSkipped => strings.corruptItemsSkipped,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    UserDatabase.instance.lastIssue.value = null;
  }

  /// يعيد بناء الشجرة كلها مع الحفاظ على حالتها.
  void _rebuildAll(BuildContext context) {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  void _onLanguageChanged(AppLanguage newLang) {
    setState(() {
      _currentLanguage = newLang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserDataStore.instance.settingsNotifier,
      builder: (context, _) {
        final settings = UserDataStore.instance.settingsNotifier.value;
        // ألوان الثيم تُقرأ مباشرة من [AppColors]، فتغييرها يتطلب إعادة بناء
        // الشجرة كلها مرة واحدة.
        if (AppColors.use(settings.colorTheme)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _rebuildAll(this.context);
          });
        }

        return AppLocalizationScope(
          currentLanguage: _currentLanguage,
          strings: AppStrings(_currentLanguage),
          onLanguageChanged: _onLanguageChanged,
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            scaffoldMessengerKey: appScaffoldMessengerKey,
            title: 'تَدْبِير · Tadbeer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: Locale(_currentLanguage.code),
            // العربية والإنجليزية لنصوص التطبيق ولعناصر Material نفسها (منتقي
            // الوقت والحوارات).
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              return Directionality(
                textDirection: _currentLanguage.direction,
                child: child!,
              );
            },
            home: _initialThemeChosen
                ? _afterThemePicker(context)
                // الإقلاع الأول: اسم القارئ، ثم اختيار الثيم.
                : NameScreen(
                    next: (_) => ThemePickerScreen(
                      // جولة التعريف بالتطبيق، بألوان الثيم الذي اختاره للتو.
                      next: (_) => TourScreen(next: _afterThemePicker),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
