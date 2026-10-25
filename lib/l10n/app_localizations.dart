import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'تَدْبِير'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'قراءة وتدبّر القرآن الكريم'**
  String get appTagline;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get quran;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get notes;

  /// No description provided for @bookmarks.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get bookmarks;

  /// No description provided for @highlights.
  ///
  /// In ar, this message translates to:
  /// **'المميزة'**
  String get highlights;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @reminders.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get reminders;

  /// No description provided for @ayahLinks.
  ///
  /// In ar, this message translates to:
  /// **'روابط الآيات'**
  String get ayahLinks;

  /// No description provided for @backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backup;

  /// No description provided for @duas.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get duas;

  /// No description provided for @quranDuas.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من القرآن'**
  String get quranDuas;

  /// No description provided for @tasbeehAndIstighfar.
  ///
  /// In ar, this message translates to:
  /// **'استغفار وتسبيح'**
  String get tasbeehAndIstighfar;

  /// No description provided for @tasbeehSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سبحة إلكترونية وأوراد الاستغفار والتسبيح'**
  String get tasbeehSubtitle;

  /// No description provided for @booksAndBooklets.
  ///
  /// In ar, this message translates to:
  /// **'كتب وملازم'**
  String get booksAndBooklets;

  /// No description provided for @booksSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الملازم التدبرية ومختصرات علوم القرآن'**
  String get booksSubtitle;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'عن تَدْبِير'**
  String get about;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @tadbeerVerseRef.
  ///
  /// In ar, this message translates to:
  /// **'سورة محمد · آية ٢٤'**
  String get tadbeerVerseRef;

  /// No description provided for @tadbeerMessage.
  ///
  /// In ar, this message translates to:
  /// **'عِش مع القرآن، وتأمّل آياته، وتدبّر معانيها، واربط بين الآيات، ودوّن خواطرك، واستلهم هدايته.'**
  String get tadbeerMessage;

  /// No description provided for @surahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get surahs;

  /// No description provided for @juzs.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get juzs;

  /// No description provided for @jumpToPage.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال إلى صفحة'**
  String get jumpToPage;

  /// No description provided for @go.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get go;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @options.
  ///
  /// In ar, this message translates to:
  /// **'خيارات'**
  String get options;

  /// No description provided for @mushafMap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المصحف'**
  String get mushafMap;

  /// No description provided for @mapTab.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get mapTab;

  /// No description provided for @reflectionLog.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدبر'**
  String get reflectionLog;

  /// No description provided for @noReflectionsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وقفات تدبر بعد'**
  String get noReflectionsYet;

  /// No description provided for @reflectionsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على آية واختر «وقفة تدبر» لتبدأ سجلك.'**
  String get reflectionsEmptyHint;

  /// No description provided for @guidedPathways.
  ///
  /// In ar, this message translates to:
  /// **'مسارات التدبر'**
  String get guidedPathways;

  /// No description provided for @guidedPathwaysHint.
  ///
  /// In ar, this message translates to:
  /// **'رحلات قصيرة: آية كل يوم مع إضاءة وسؤال تدبر. أتمّ اليوم ليُفتح التالي.'**
  String get guidedPathwaysHint;

  /// No description provided for @completeDay.
  ///
  /// In ar, this message translates to:
  /// **'أتممت اليوم'**
  String get completeDay;

  /// No description provided for @pathwayUnlockHint.
  ///
  /// In ar, this message translates to:
  /// **'أتمّ يوم اليوم ليُفتح الذي بعده'**
  String get pathwayUnlockHint;

  /// No description provided for @pathwayComplete.
  ///
  /// In ar, this message translates to:
  /// **'أتممت المسار، بارك الله فيك'**
  String get pathwayComplete;

  /// No description provided for @memorization.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ والمراجعة'**
  String get memorization;

  /// No description provided for @memorizationHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة: تظهر الآية مخفية إلا كلمتها الأولى، استحضرها ثم اكشفها وقيّم نفسك. نعيد عليك ما تحتاجه في الوقت المناسب.'**
  String get memorizationHint;

  /// No description provided for @nothingDueToday.
  ///
  /// In ar, this message translates to:
  /// **'لا مراجعة مستحقة اليوم'**
  String get nothingDueToday;

  /// No description provided for @chooseSurahToMemorize.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة للحفظ'**
  String get chooseSurahToMemorize;

  /// No description provided for @tapToReveal.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لكشف الآية'**
  String get tapToReveal;

  /// No description provided for @needsReview.
  ///
  /// In ar, this message translates to:
  /// **'أحتاج مراجعة'**
  String get needsReview;

  /// No description provided for @mastered.
  ///
  /// In ar, this message translates to:
  /// **'أتقنتها'**
  String get mastered;

  /// No description provided for @sessionDone.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! انتهت الجلسة'**
  String get sessionDone;

  /// No description provided for @ayahOfTheDay.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get ayahOfTheDay;

  /// No description provided for @reflectOnIt.
  ///
  /// In ar, this message translates to:
  /// **'تدبّرها'**
  String get reflectOnIt;

  /// No description provided for @continueReadingFromHere.
  ///
  /// In ar, this message translates to:
  /// **'أكمل القراءة من هنا'**
  String get continueReadingFromHere;

  /// No description provided for @fromMushafStart.
  ///
  /// In ar, this message translates to:
  /// **'من أول المصحف'**
  String get fromMushafStart;

  /// No description provided for @setKhatmaPosition.
  ///
  /// In ar, this message translates to:
  /// **'تعديل موضعي في الختمة'**
  String get setKhatmaPosition;

  /// No description provided for @pageNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة'**
  String get pageNumberLabel;

  /// No description provided for @markPortionDone.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ورد اليوم'**
  String get markPortionDone;

  /// No description provided for @moveKhatmaHere.
  ///
  /// In ar, this message translates to:
  /// **'انقل الختمة'**
  String get moveKhatmaHere;

  /// No description provided for @reflectionsThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'تدبرات هذا الشهر'**
  String get reflectionsThisMonth;

  /// No description provided for @portionReminderPrompt.
  ///
  /// In ar, this message translates to:
  /// **'متى نذكّرك بوردك يومياً؟'**
  String get portionReminderPrompt;

  /// No description provided for @portionReminderSet.
  ///
  /// In ar, this message translates to:
  /// **'سنذكّرك بوردك كل يوم'**
  String get portionReminderSet;

  /// No description provided for @reflectedToday.
  ///
  /// In ar, this message translates to:
  /// **'تدبّرتها اليوم، بارك الله فيك'**
  String get reflectedToday;

  /// No description provided for @addToMemorization.
  ///
  /// In ar, this message translates to:
  /// **'أضف للحفظ'**
  String get addToMemorization;

  /// No description provided for @removeFromMemorization.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من الحفظ'**
  String get removeFromMemorization;

  /// No description provided for @journeyBackupSection.
  ///
  /// In ar, this message translates to:
  /// **'الختمة والإحصاءات والحفظ والمسارات'**
  String get journeyBackupSection;

  /// No description provided for @dailyJourney.
  ///
  /// In ar, this message translates to:
  /// **'رحلة يومية'**
  String get dailyJourney;

  /// No description provided for @adhkarReminders.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الأذكار'**
  String get adhkarReminders;

  /// No description provided for @morningAdhkarReminder.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get morningAdhkarReminder;

  /// No description provided for @eveningAdhkarReminder.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get eveningAdhkarReminder;

  /// No description provided for @monthlyReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الشهر'**
  String get monthlyReport;

  /// No description provided for @activeDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'يوم نشاط'**
  String get activeDaysLabel;

  /// No description provided for @reflectionsLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقفة تدبر'**
  String get reflectionsLabel;

  /// No description provided for @memorizedLabel.
  ///
  /// In ar, this message translates to:
  /// **'آية محفوظة'**
  String get memorizedLabel;

  /// No description provided for @groupKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جماعية'**
  String get groupKhatma;

  /// No description provided for @groupKhatmaHint.
  ///
  /// In ar, this message translates to:
  /// **'وزّع الأجزاء الثلاثين على العائلة أو الأصدقاء، وشارك الرمز معهم. كل شخص يلصق الرمز ويختار اسمه ويتابع أجزاءه، دون إنترنت.'**
  String get groupKhatmaHint;

  /// No description provided for @createGroupKhatma.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ختمة جماعية'**
  String get createGroupKhatma;

  /// No description provided for @groupKhatmaTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختمة'**
  String get groupKhatmaTitle;

  /// No description provided for @participantNames.
  ///
  /// In ar, this message translates to:
  /// **'أسماء المشاركين'**
  String get participantNames;

  /// No description provided for @oneNamePerLine.
  ///
  /// In ar, this message translates to:
  /// **'اسم في كل سطر'**
  String get oneNamePerLine;

  /// No description provided for @distributeJuz.
  ///
  /// In ar, this message translates to:
  /// **'وزّع الأجزاء'**
  String get distributeJuz;

  /// No description provided for @joinWithCode.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام برمز'**
  String get joinWithCode;

  /// No description provided for @pasteGroupCode.
  ///
  /// In ar, this message translates to:
  /// **'الصق رمز الختمة'**
  String get pasteGroupCode;

  /// No description provided for @invalidGroupCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح'**
  String get invalidGroupCode;

  /// No description provided for @join.
  ///
  /// In ar, this message translates to:
  /// **'انضم'**
  String get join;

  /// No description provided for @whoAreYou.
  ///
  /// In ar, this message translates to:
  /// **'اختر اسمك'**
  String get whoAreYou;

  /// No description provided for @readJuz.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الجزء'**
  String get readJuz;

  /// No description provided for @everyonesJuz.
  ///
  /// In ar, this message translates to:
  /// **'توزيع الجميع'**
  String get everyonesJuz;

  /// No description provided for @showQr.
  ///
  /// In ar, this message translates to:
  /// **'عرض رمز QR'**
  String get showQr;

  /// No description provided for @leaveGroupKhatma.
  ///
  /// In ar, this message translates to:
  /// **'مغادرة الختمة'**
  String get leaveGroupKhatma;

  /// No description provided for @groupCodeIntro.
  ///
  /// In ar, this message translates to:
  /// **'للانضمام: افتح تدبير ← المزيد ← ختمة جماعية، والصق هذا الرمز:'**
  String get groupCodeIntro;

  /// No description provided for @continueWhereYouLeft.
  ///
  /// In ar, this message translates to:
  /// **'أكمل من حيث توقفت'**
  String get continueWhereYouLeft;

  /// No description provided for @adhkarKind.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get adhkarKind;

  /// No description provided for @weeklyGoals.
  ///
  /// In ar, this message translates to:
  /// **'أهداف الأسبوع'**
  String get weeklyGoals;

  /// No description provided for @editGoals.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الأهداف'**
  String get editGoals;

  /// No description provided for @pagesGoal.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get pagesGoal;

  /// No description provided for @reflectionsGoal.
  ///
  /// In ar, this message translates to:
  /// **'وقفات تدبر'**
  String get reflectionsGoal;

  /// No description provided for @focusMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التأمل'**
  String get focusMode;

  /// No description provided for @breathe.
  ///
  /// In ar, this message translates to:
  /// **'تنفّس بهدوء'**
  String get breathe;

  /// No description provided for @breatheIn.
  ///
  /// In ar, this message translates to:
  /// **'شهيق…'**
  String get breatheIn;

  /// No description provided for @breatheOut.
  ///
  /// In ar, this message translates to:
  /// **'زفير…'**
  String get breatheOut;

  /// No description provided for @swipeForNextAyah.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للآية التالية'**
  String get swipeForNextAyah;

  /// No description provided for @myJourney.
  ///
  /// In ar, this message translates to:
  /// **'رحلتي مع القرآن'**
  String get myJourney;

  /// No description provided for @startKhatmaTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمتك'**
  String get startKhatmaTitle;

  /// No description provided for @startKhatmaHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدة، وسنقسّم المصحف إلى ورد يومي ونتابع تقدمك تلقائياً.'**
  String get startKhatmaHint;

  /// No description provided for @startKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الختمة'**
  String get startKhatma;

  /// No description provided for @cancelKhatma.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الختمة'**
  String get cancelKhatma;

  /// No description provided for @cancelKhatmaConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف تقدم هذه الختمة، ويبقى سجل قراءتك وإحصاءاتك.'**
  String get cancelKhatmaConfirm;

  /// No description provided for @onTrack.
  ///
  /// In ar, this message translates to:
  /// **'ملتزم بالخطة'**
  String get onTrack;

  /// No description provided for @todayPortion.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get todayPortion;

  /// No description provided for @keepReading.
  ///
  /// In ar, this message translates to:
  /// **'واصل القراءة'**
  String get keepReading;

  /// No description provided for @streakDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام متتالية'**
  String get streakDays;

  /// No description provided for @totalPagesRead.
  ///
  /// In ar, this message translates to:
  /// **'صفحة مقروءة'**
  String get totalPagesRead;

  /// No description provided for @khatmasLabel.
  ///
  /// In ar, this message translates to:
  /// **'ختمات'**
  String get khatmasLabel;

  /// No description provided for @lastSevenDays.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٧ أيام'**
  String get lastSevenDays;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @clearText.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearText;

  /// No description provided for @decrease.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get increase;

  /// No description provided for @sajdah.
  ///
  /// In ar, this message translates to:
  /// **'سجدة تلاوة'**
  String get sajdah;

  /// No description provided for @addNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get addNote;

  /// No description provided for @saveBookmark.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الحفظ'**
  String get removeBookmark;

  /// No description provided for @highlight.
  ///
  /// In ar, this message translates to:
  /// **'تمييز'**
  String get highlight;

  /// No description provided for @removeHighlight.
  ///
  /// In ar, this message translates to:
  /// **'إزالة التمييز'**
  String get removeHighlight;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @shareAsImage.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الآية كبطاقة'**
  String get shareAsImage;

  /// No description provided for @shareImage.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الصورة'**
  String get shareImage;

  /// No description provided for @cardSquare.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get cardSquare;

  /// No description provided for @cardStory.
  ///
  /// In ar, this message translates to:
  /// **'قصة'**
  String get cardStory;

  /// No description provided for @cardNight.
  ///
  /// In ar, this message translates to:
  /// **'كحلي'**
  String get cardNight;

  /// No description provided for @cardPaper.
  ///
  /// In ar, this message translates to:
  /// **'ورقي'**
  String get cardPaper;

  /// No description provided for @copiedToClipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الآية إلى الحافظة'**
  String get copiedToClipboard;

  /// No description provided for @newNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get newNote;

  /// No description provided for @newFreeNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة حرة'**
  String get newFreeNote;

  /// No description provided for @noteTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الملاحظة'**
  String get noteTitle;

  /// No description provided for @noteContent.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تدبرك أو ملاحظتك هنا...'**
  String get noteContent;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في الحذف؟ لا يمكن التراجع عن هذا الإجراء.'**
  String get deleteConfirmMessage;

  /// No description provided for @exportPdf.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPdf;

  /// No description provided for @noNotesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بعد'**
  String get noNotesYet;

  /// No description provided for @freeNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة حرة'**
  String get freeNoteLabel;

  /// No description provided for @ayahNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'تدبر آية'**
  String get ayahNoteLabel;

  /// No description provided for @goToAyah.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب إلى الآية'**
  String get goToAyah;

  /// No description provided for @noBookmarksYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات محفوظة بعد'**
  String get noBookmarksYet;

  /// No description provided for @noHighlightsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات مميزة بعد'**
  String get noHighlightsYet;

  /// No description provided for @bookmarksEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على أي آية في المصحف واختر «حفظ» لتجدها هنا.'**
  String get bookmarksEmptyHint;

  /// No description provided for @highlightsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على أي آية في المصحف واختر «تمييز» لتلوينها.'**
  String get highlightsEmptyHint;

  /// No description provided for @openMushaf.
  ///
  /// In ar, this message translates to:
  /// **'فتح المصحف'**
  String get openMushaf;

  /// No description provided for @searchGlobalPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في القرآن، الملاحظات، التدبر، والمزيد...'**
  String get searchGlobalPlaceholder;

  /// No description provided for @searchAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get searchAll;

  /// No description provided for @searchBookmarksHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الآيات المحفوظة...'**
  String get searchBookmarksHint;

  /// No description provided for @searchHighlightsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الآيات المميزة...'**
  String get searchHighlightsHint;

  /// No description provided for @searchRemindersHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في التنبيهات...'**
  String get searchRemindersHint;

  /// No description provided for @searchNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الملاحظات...'**
  String get searchNotesHint;

  /// No description provided for @tadbeerSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'التدبر'**
  String get tadbeerSectionTitle;

  /// No description provided for @wordMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات'**
  String get wordMeanings;

  /// No description provided for @wordMeaningsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاني كلمات القرآن'**
  String get wordMeaningsScreenTitle;

  /// No description provided for @approvedSourcesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادر المعتمدة'**
  String get approvedSourcesTitle;

  /// No description provided for @searchInAllSections.
  ///
  /// In ar, this message translates to:
  /// **'البحث في جميع الأقسام'**
  String get searchInAllSections;

  /// No description provided for @filterSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفية نطاق البحث'**
  String get filterSearchTitle;

  /// No description provided for @selectSearchSection.
  ///
  /// In ar, this message translates to:
  /// **'اختر القسم المطلوب للبحث فيه مباشرة'**
  String get selectSearchSection;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noSearchResults;

  /// No description provided for @addReminder.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تنبيه'**
  String get addReminder;

  /// No description provided for @editReminder.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التنبيه'**
  String get editReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التنبيه (اختياري)'**
  String get reminderTitle;

  /// No description provided for @defaultReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد القرآن الكريم'**
  String get defaultReminderTitle;

  /// No description provided for @reminderTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التنبيه'**
  String get reminderTime;

  /// No description provided for @repeatDaily.
  ///
  /// In ar, this message translates to:
  /// **'تكرار يومي'**
  String get repeatDaily;

  /// No description provided for @repeatOnce.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get repeatOnce;

  /// No description provided for @selectDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام التكرار'**
  String get selectDays;

  /// No description provided for @noRemindersYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات قراءة مضافة'**
  String get noRemindersYet;

  /// No description provided for @remindersEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف تنبيهاً يذكّرك بوِردك اليومي من زر «إضافة تنبيه» في الأسفل.'**
  String get remindersEmptyHint;

  /// No description provided for @newAyahLink.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط آيات'**
  String get newAyahLink;

  /// No description provided for @addToAyahLink.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى رابط آيات'**
  String get addToAyahLink;

  /// No description provided for @networkView.
  ///
  /// In ar, this message translates to:
  /// **'شبكة'**
  String get networkView;

  /// No description provided for @orderedView.
  ///
  /// In ar, this message translates to:
  /// **'مرتب'**
  String get orderedView;

  /// No description provided for @autoLayout.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الترتيب تلقائيًا'**
  String get autoLayout;

  /// No description provided for @linkTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الرابط / الفكرة'**
  String get linkTitle;

  /// No description provided for @linkTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: الصبر عند الشدة'**
  String get linkTitleHint;

  /// No description provided for @linkDescription.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة العامة / الفكرة (اختيارية)'**
  String get linkDescription;

  /// No description provided for @linkDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'سجل تأملك أو الفكرة التي تجمع هذه الآيات...'**
  String get linkDescriptionHint;

  /// No description provided for @addVerse.
  ///
  /// In ar, this message translates to:
  /// **'إضافة آية'**
  String get addVerse;

  /// No description provided for @resetToCenter.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الوسط'**
  String get resetToCenter;

  /// No description provided for @noAyahLinksYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد روابط آيات بعد'**
  String get noAyahLinksYet;

  /// No description provided for @ayahLinksSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة شخصية لربط الآيات واستكشاف العلاقات التدبرية'**
  String get ayahLinksSubtitle;

  /// No description provided for @exportBackup.
  ///
  /// In ar, this message translates to:
  /// **'تصدير نسخة احتياطية'**
  String get exportBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In ar, this message translates to:
  /// **'استعادة نسخة احتياطية'**
  String get restoreBackup;

  /// No description provided for @restoreWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه هام قبل الاستعادة'**
  String get restoreWarningTitle;

  /// No description provided for @restoreWarningMessage.
  ///
  /// In ar, this message translates to:
  /// **'استعادة النسخة الاحتياطية ستستبدل بياناتك الحالية بالكامل ولن تدمجها. هل ترغب بالاستمرار؟'**
  String get restoreWarningMessage;

  /// No description provided for @confirmRestore.
  ///
  /// In ar, this message translates to:
  /// **'استبدال واستعادة'**
  String get confirmRestore;

  /// No description provided for @saveToDeviceFiles.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في ملفات الجهاز'**
  String get saveToDeviceFiles;

  /// No description provided for @shareViaApps.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة عبر التطبيقات'**
  String get shareViaApps;

  /// No description provided for @backupSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ النسخة الاحتياطية في الملفات بنجاح'**
  String get backupSavedSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة البيانات بنجاح'**
  String get restoreSuccess;

  /// No description provided for @corruptBackupError.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير صالح أو كلمة المرور غير صحيحة. تم إلغاء الاستعادة لحماية بياناتك.'**
  String get corruptBackupError;

  /// No description provided for @dataSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ بعض بياناتك على الجهاز. أعد المحاولة، وإن تكررت المشكلة فصدّر نسخة احتياطية.'**
  String get dataSaveFailed;

  /// No description provided for @dataLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة بعض بياناتك المحفوظة. لم يُحذف شيء؛ صدّر نسخة احتياطية احتياطاً.'**
  String get dataLoadFailed;

  /// No description provided for @corruptItemsSkipped.
  ///
  /// In ar, this message translates to:
  /// **'تم تخطي عناصر محفوظة تالفة ولم تُحذف من الجهاز.'**
  String get corruptItemsSkipped;

  /// No description provided for @enterBackupPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور التشفير (بدونها يستطيع أي شخص فتح الملف)'**
  String get enterBackupPassword;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In ar, this message translates to:
  /// **'السمة'**
  String get themeMode;

  /// No description provided for @light.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي (حسب النظام)'**
  String get system;

  /// No description provided for @languageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// No description provided for @fontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط المصحف'**
  String get fontSize;

  /// No description provided for @mushafPaperTone.
  ///
  /// In ar, this message translates to:
  /// **'لون ورق المصحف'**
  String get mushafPaperTone;

  /// No description provided for @paperClassic.
  ///
  /// In ar, this message translates to:
  /// **'كلاسيكي'**
  String get paperClassic;

  /// No description provided for @paperSepia.
  ///
  /// In ar, this message translates to:
  /// **'سيبيا دافئ'**
  String get paperSepia;

  /// No description provided for @aboutContent.
  ///
  /// In ar, this message translates to:
  /// **'تدبير مشروع قرآني يهدف إلى تعزيز التدبّر في آيات الله، ومساعدة المسلم على التأمل في معاني القرآن الكريم، والتفكّر في هداياته، واستحضار أثر آياته في الحياة والعمل بها، لتكون علاقتنا بالقرآن قائمة على التدبّر والفهم والاهتداء، لا على التلاوة وحدها.'**
  String get aboutContent;

  /// No description provided for @resumeReading.
  ///
  /// In ar, this message translates to:
  /// **'استئناف القراءة'**
  String get resumeReading;

  /// No description provided for @additionalTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات إضافية'**
  String get additionalTools;

  /// No description provided for @quranAndSunnahDuas.
  ///
  /// In ar, this message translates to:
  /// **'أدعية الكتاب والسنة'**
  String get quranAndSunnahDuas;

  /// No description provided for @quranDuasTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من القرآن'**
  String get quranDuasTitle;

  /// No description provided for @quranDuasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية الأنبياء والصالحين وخواتيم السور المأثورة في كتاب الله'**
  String get quranDuasSubtitle;

  /// No description provided for @morningEveningAdhkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح والمساء'**
  String get morningEveningAdhkarTitle;

  /// No description provided for @morningEveningAdhkarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار اليوم والليلة وحصن المسلم مع عدادات تفاعلية'**
  String get morningEveningAdhkarSubtitle;

  /// No description provided for @ahlulbaytDuasTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية مأثورة عن أهل البيت'**
  String get ahlulbaytDuasTitle;

  /// No description provided for @ahlulbaytDuasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الصحيفة السجادية ومناجاة وأدعية الأئمة الأطهار'**
  String get ahlulbaytDuasSubtitle;

  /// No description provided for @sunnahDuasTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من السنة النبوية'**
  String get sunnahDuasTitle;

  /// No description provided for @sunnahDuasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية مأثورة وصحيحة عن النبي ﷺ لكشف الكرب'**
  String get sunnahDuasSubtitle;

  /// No description provided for @jawamiDuasTitle.
  ///
  /// In ar, this message translates to:
  /// **'جوامع الدعاء والرجاء'**
  String get jawamiDuasTitle;

  /// No description provided for @jawamiDuasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية جامعة لخيري الدنيا والآخرة والهدى والعافية'**
  String get jawamiDuasSubtitle;

  /// No description provided for @wordsOfQuran.
  ///
  /// In ar, this message translates to:
  /// **'غريب ألفاظ القرآن'**
  String get wordsOfQuran;

  /// No description provided for @yourThoughtsAndReflections.
  ///
  /// In ar, this message translates to:
  /// **'خواطرك وتدبراتك'**
  String get yourThoughtsAndReflections;

  /// No description provided for @connectionsAndThemes.
  ///
  /// In ar, this message translates to:
  /// **'الربط والعلاقات'**
  String get connectionsAndThemes;

  /// No description provided for @dailyPortion.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي'**
  String get dailyPortion;

  /// No description provided for @tadbeerLibrary.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المتدبر'**
  String get tadbeerLibrary;

  /// No description provided for @offlineQuranAndReflection.
  ///
  /// In ar, this message translates to:
  /// **'مصحف وتدبّر بدون إنترنت'**
  String get offlineQuranAndReflection;

  /// No description provided for @meccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get medinan;

  /// No description provided for @searchSurahsHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في السور...'**
  String get searchSurahsHint;

  /// No description provided for @searchWordMeaningsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن كلمة قرآنية أو معناها...'**
  String get searchWordMeaningsHint;

  /// No description provided for @allSurahsWithCount.
  ///
  /// In ar, this message translates to:
  /// **'جميع السور (١١٤ سورة)'**
  String get allSurahsWithCount;

  /// No description provided for @noWordsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كلمات مطابقة لبحثك'**
  String get noWordsFound;

  /// No description provided for @noWordsFoundSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'جرب البحث بكلمة أخرى أو قم بإلغاء التصفية لتصفح جميع الكلمات.'**
  String get noWordsFoundSubtitle;

  /// No description provided for @lexicalMeaningTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعنى اللغوي المعجمي:'**
  String get lexicalMeaningTitle;

  /// No description provided for @verifiedDocumentation.
  ///
  /// In ar, this message translates to:
  /// **'توثيق معتمد'**
  String get verifiedDocumentation;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @editNote.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get editNote;

  /// No description provided for @tadbeerPause.
  ///
  /// In ar, this message translates to:
  /// **'وقفة تدبر'**
  String get tadbeerPause;

  /// No description provided for @ayahLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط آيات'**
  String get ayahLink;

  /// No description provided for @exportTadbeerJournal.
  ///
  /// In ar, this message translates to:
  /// **'تصدير دفتر التدبر والخواطر'**
  String get exportTadbeerJournal;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @doNotShowAgain.
  ///
  /// In ar, this message translates to:
  /// **'لا تظهر لي هذه النافذة مرة أخرى'**
  String get doNotShowAgain;

  /// No description provided for @curatedPathways.
  ///
  /// In ar, this message translates to:
  /// **'المسارات التدبرية المقترحة'**
  String get curatedPathways;

  /// No description provided for @importFromQrCode.
  ///
  /// In ar, this message translates to:
  /// **'استيراد رابط آيات عبر الرمز'**
  String get importFromQrCode;

  /// No description provided for @searchAyahLinksHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في روابط الآيات أو السور...'**
  String get searchAyahLinksHint;

  /// No description provided for @noAyahLinkSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة لبحثك'**
  String get noAyahLinkSearchResults;

  /// No description provided for @tryAnotherAyahLinkSearch.
  ///
  /// In ar, this message translates to:
  /// **'جرّب البحث بكلمة أخرى أو اسم سورة'**
  String get tryAnotherAyahLinkSearch;

  /// No description provided for @importPathway.
  ///
  /// In ar, this message translates to:
  /// **'استيراد المسار'**
  String get importPathway;

  /// No description provided for @editTitleAndDescription.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان والوصف'**
  String get editTitleAndDescription;

  /// No description provided for @deleteAyahLink.
  ///
  /// In ar, this message translates to:
  /// **'حذف الرابط'**
  String get deleteAyahLink;

  /// No description provided for @typographyAndReading.
  ///
  /// In ar, this message translates to:
  /// **'الخط والقراءة'**
  String get typographyAndReading;

  /// No description provided for @quranFontFamily.
  ///
  /// In ar, this message translates to:
  /// **'نوع خط المصحف'**
  String get quranFontFamily;

  /// No description provided for @resetToDefault.
  ///
  /// In ar, this message translates to:
  /// **'إعادة للوضع الافتراضي'**
  String get resetToDefault;

  /// No description provided for @applicationSection.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get applicationSection;

  /// No description provided for @dataSection.
  ///
  /// In ar, this message translates to:
  /// **'البيانات'**
  String get dataSection;

  /// No description provided for @dailyRemindersSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الورد اليومي ومواعيد القراءة'**
  String get dailyRemindersSubtitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تصدير واستعادة ملفات مشفرة بدون اتصال'**
  String get backupSubtitle;

  /// No description provided for @resetData.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين البيانات'**
  String get resetData;

  /// No description provided for @resetDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظات والمحفوظات والتمييزات واستعادة الإعدادات الأصلية'**
  String get resetDataSubtitle;

  /// No description provided for @confirmReset.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إعادة التعيين'**
  String get confirmReset;

  /// No description provided for @resetSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة تعيين البيانات بنجاح'**
  String get resetSuccess;

  /// No description provided for @resetWarningMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في حذف جميع الملاحظات والمحفوظات والتمييزات واستعادة الإعدادات الأصلية للتطبيق؟\n\nلا يمكن التراجع عن هذا الإجراء إلا إذا كانت لديك نسخة احتياطية سابقة.'**
  String get resetWarningMessage;

  /// No description provided for @versionInfo.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار ١.٠.٠ · مجاني وبدون إعلانات أو إنترنت'**
  String get versionInfo;

  /// No description provided for @sourcesAndCredits.
  ///
  /// In ar, this message translates to:
  /// **'المصادر والتوثيق المعتمد:'**
  String get sourcesAndCredits;

  /// No description provided for @openSourceLicenses.
  ///
  /// In ar, this message translates to:
  /// **'تراخيص المصادر المفتوحة'**
  String get openSourceLicenses;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In ar, this message translates to:
  /// **'ميثاق الخصوصية والأمان'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'التزام مطلق بحماية بياناتك بدون خوادم أو تتبع (100% أوفلاين)'**
  String get privacyPolicySubtitle;

  /// No description provided for @alertType.
  ///
  /// In ar, this message translates to:
  /// **'طريقة التنبيه:'**
  String get alertType;

  /// No description provided for @notificationAlert.
  ///
  /// In ar, this message translates to:
  /// **'إشعار'**
  String get notificationAlert;

  /// No description provided for @notificationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعار عادي في الشريط'**
  String get notificationSubtitle;

  /// No description provided for @alarmAlert.
  ///
  /// In ar, this message translates to:
  /// **'منبه'**
  String get alarmAlert;

  /// No description provided for @alarmSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رنين مستمر كالمنبه'**
  String get alarmSubtitle;

  /// No description provided for @repeatMode.
  ///
  /// In ar, this message translates to:
  /// **'نوع التكرار:'**
  String get repeatMode;

  /// No description provided for @daySat.
  ///
  /// In ar, this message translates to:
  /// **'سبت'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In ar, this message translates to:
  /// **'أحد'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In ar, this message translates to:
  /// **'إثنين'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثاء'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ar, this message translates to:
  /// **'أربعاء'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ar, this message translates to:
  /// **'خميس'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ar, this message translates to:
  /// **'جمعة'**
  String get dayFri;

  /// No description provided for @testAlertTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تجربة الإشعار أو المنبه الآن'**
  String get testAlertTooltip;

  /// No description provided for @testNotificationNow.
  ///
  /// In ar, this message translates to:
  /// **'تجربة إشعار الآن'**
  String get testNotificationNow;

  /// No description provided for @testAlarmNow.
  ///
  /// In ar, this message translates to:
  /// **'تجربة منبه الآن'**
  String get testAlarmNow;

  /// No description provided for @testAlarmSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إطلاق منبه تجريبي الآن — تفقد الإشعارات لإيقافه'**
  String get testAlarmSentSuccess;

  /// No description provided for @testNotificationSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال إشعار تجريبي الآن — تفقد شريط الإشعارات'**
  String get testNotificationSentSuccess;

  /// No description provided for @testAlertPermissionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال التنبيه، يرجى التأكد من تفعيل أذونات الإشعارات في إعدادات الجهاز'**
  String get testAlertPermissionError;

  /// No description provided for @specificDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام محددة'**
  String get specificDays;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر البيانات التي ترغب بتضمينها في النسخة المشفرة (.quranbackup):'**
  String get exportBackupSubtitle;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة البيانات من ملف .quranbackup محفوظ سابقًا. تُستبدل البيانات الحالية بالكامل بعد التحقق من سلامة التشفير وصحة الملف.'**
  String get restoreBackupSubtitle;

  /// No description provided for @restoreFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت الاستعادة'**
  String get restoreFailed;

  /// No description provided for @selectBackupLocation.
  ///
  /// In ar, this message translates to:
  /// **'اختر موقع حفظ النسخة الاحتياطية'**
  String get selectBackupLocation;

  /// No description provided for @backupCreateFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء النسخة الاحتياطية'**
  String get backupCreateFailed;

  /// No description provided for @viewAyah.
  ///
  /// In ar, this message translates to:
  /// **'عرض الآية'**
  String get viewAyah;

  /// No description provided for @duaCopiedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ نص الدعاء بنجاح'**
  String get duaCopiedSuccess;

  /// No description provided for @searchDuasHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في أدعية القرآن الكريم بالكلمة أو السورة...'**
  String get searchDuasHint;

  /// No description provided for @noDuasFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدعية مطابقة لبحثك'**
  String get noDuasFound;

  /// No description provided for @allDuasFilter.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allDuasFilter;

  /// No description provided for @morningAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get morningAdhkar;

  /// No description provided for @eveningAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get eveningAdhkar;

  /// No description provided for @resetCounters.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط العدادات'**
  String get resetCounters;

  /// No description provided for @adhkarCountersResetSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة ضبط عدادات الأذكار'**
  String get adhkarCountersResetSuccess;

  /// No description provided for @dhikrCopiedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ نص الذكر الشريف بنجاح'**
  String get dhikrCopiedSuccess;

  /// No description provided for @copyDhikr.
  ///
  /// In ar, this message translates to:
  /// **'نسخ نص الذكر'**
  String get copyDhikr;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل'**
  String get completed;

  /// No description provided for @once.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get once;

  /// No description provided for @searchAhlulbaytHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في أدعية أهل البيت والصحيفة السجادية...'**
  String get searchAhlulbaytHint;

  /// No description provided for @ahlulbaytDuasScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية أهل البيت عليهم السلام'**
  String get ahlulbaytDuasScreenTitle;

  /// No description provided for @copyFullDua.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الدعاء كاملاً'**
  String get copyFullDua;

  /// No description provided for @fullDuaCopiedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ نص الدعاء كاملاً إلى الحافظة'**
  String get fullDuaCopiedSuccess;

  /// No description provided for @decreaseFontSize.
  ///
  /// In ar, this message translates to:
  /// **'تصغير الخط'**
  String get decreaseFontSize;

  /// No description provided for @increaseFontSize.
  ///
  /// In ar, this message translates to:
  /// **'تكبير الخط'**
  String get increaseFontSize;

  /// No description provided for @fullAuthenticText.
  ///
  /// In ar, this message translates to:
  /// **'نص كامل ومأثور'**
  String get fullAuthenticText;

  /// No description provided for @copyDuaTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ نص الدعاء'**
  String get copyDuaTooltip;

  /// No description provided for @tableOfContents.
  ///
  /// In ar, this message translates to:
  /// **'فهرس المباحث'**
  String get tableOfContents;

  /// No description provided for @previousSection.
  ///
  /// In ar, this message translates to:
  /// **'المبحث السابق'**
  String get previousSection;

  /// No description provided for @nextSection.
  ///
  /// In ar, this message translates to:
  /// **'المبحث التالي'**
  String get nextSection;

  /// No description provided for @previousDua.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء السابق'**
  String get previousDua;

  /// No description provided for @nextDua.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء التالي'**
  String get nextDua;

  /// No description provided for @shareFile.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الملف'**
  String get shareFile;

  /// No description provided for @copyContent.
  ///
  /// In ar, this message translates to:
  /// **'نسخ المحتوى'**
  String get copyContent;

  /// No description provided for @preparingDocument.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز وعرض الملزمة...'**
  String get preparingDocument;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @openAndReadPdf.
  ///
  /// In ar, this message translates to:
  /// **'فتح ومطالعة ملف PDF'**
  String get openAndReadPdf;

  /// No description provided for @noTextContentAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يتوفر محتوى نصي لهذه الملزمة حالياً.'**
  String get noTextContentAvailable;

  /// No description provided for @verifiedPamphletPdf.
  ///
  /// In ar, this message translates to:
  /// **'ملزمة موثقة • PDF'**
  String get verifiedPamphletPdf;

  /// No description provided for @directTextReading.
  ///
  /// In ar, this message translates to:
  /// **'قراءة نصية مباشرة'**
  String get directTextReading;

  /// No description provided for @textCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ النص إلى الحافظة بنجاح.'**
  String get textCopied;

  /// No description provided for @fileNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير موجود على الجهاز.'**
  String get fileNotFound;

  /// No description provided for @noTextContent.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى نصي.'**
  String get noTextContent;

  /// No description provided for @textFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف نصي'**
  String get textFile;

  /// No description provided for @openInQuran.
  ///
  /// In ar, this message translates to:
  /// **'فتح في المصحف'**
  String get openInQuran;

  /// No description provided for @editVerseNote.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get editVerseNote;

  /// No description provided for @removeVerseFromLink.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من الرابط'**
  String get removeVerseFromLink;

  /// No description provided for @removeAyahFromLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الآية من الرابط'**
  String get removeAyahFromLinkTitle;

  /// No description provided for @reflectionNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة التدبر'**
  String get reflectionNote;

  /// No description provided for @reflectionNoteColon.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة التدبر:'**
  String get reflectionNoteColon;

  /// No description provided for @ayahReflectionNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة التدبر على الآية'**
  String get ayahReflectionNoteTitle;

  /// No description provided for @ayahReflectionNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تدبرك أو الرابط الذي لاحظته...'**
  String get ayahReflectionNoteHint;

  /// No description provided for @noAyahsAddedToLink.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي آيات لهذا الرابط بعد'**
  String get noAyahsAddedToLink;

  /// No description provided for @addAyahsToBuildMap.
  ///
  /// In ar, this message translates to:
  /// **'أضف الآيات التي لاحظت ارتباطها لبناء خريطتك التدبرية'**
  String get addAyahsToBuildMap;

  /// No description provided for @addAyah.
  ///
  /// In ar, this message translates to:
  /// **'إضافة آية'**
  String get addAyah;

  /// No description provided for @previous.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategories;

  /// No description provided for @istighfar.
  ///
  /// In ar, this message translates to:
  /// **'الاستغفار'**
  String get istighfar;

  /// No description provided for @tasbeeh.
  ///
  /// In ar, this message translates to:
  /// **'التسبيح'**
  String get tasbeeh;

  /// No description provided for @browseAllFormulas.
  ///
  /// In ar, this message translates to:
  /// **'استعراض كل الصيغ'**
  String get browseAllFormulas;

  /// No description provided for @resetCycleCounter.
  ///
  /// In ar, this message translates to:
  /// **'تصفير عداد الدورة'**
  String get resetCycleCounter;

  /// No description provided for @resetCycleCounterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفير عداد الدورة؟'**
  String get resetCycleCounterTitle;

  /// No description provided for @resetCycleCounterConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إعادة عداد الدورة الحالية إلى الصفر مع الحفاظ التام على مجموعك الإجمالي المحفوظ.'**
  String get resetCycleCounterConfirm;

  /// No description provided for @resetCycleAction.
  ///
  /// In ar, this message translates to:
  /// **'تصفير الدورة'**
  String get resetCycleAction;

  /// No description provided for @tapAnywhereToCount.
  ///
  /// In ar, this message translates to:
  /// **'انقر في أي مكان للعدّ'**
  String get tapAnywhereToCount;

  /// No description provided for @freeCount.
  ///
  /// In ar, this message translates to:
  /// **'عدّ حر'**
  String get freeCount;

  /// No description provided for @countSettings.
  ///
  /// In ar, this message translates to:
  /// **'ضبط العدّ'**
  String get countSettings;

  /// No description provided for @freeCountOpen.
  ///
  /// In ar, this message translates to:
  /// **'عدّ حر (مفتوح)'**
  String get freeCountOpen;

  /// No description provided for @autoAdvanceUponCompletion.
  ///
  /// In ar, this message translates to:
  /// **'التبديل التلقائي عند اكتمال الورد'**
  String get autoAdvanceUponCompletion;

  /// No description provided for @lifetimeTotalCount.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الكلي المحفوظ'**
  String get lifetimeTotalCount;

  /// No description provided for @copyDhikrTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ نص الذكر'**
  String get copyDhikrTooltip;

  /// No description provided for @dhikrCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ نص الذكر إلى الحافظة بنجاح.'**
  String get dhikrCopied;

  /// No description provided for @tasbeehAndIstighfarFormulas.
  ///
  /// In ar, this message translates to:
  /// **'صيغ الاستغفار والتسبيح'**
  String get tasbeehAndIstighfarFormulas;

  /// No description provided for @searchDhikrHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في نصوص الأذكار...'**
  String get searchDhikrHint;

  /// No description provided for @noMatchingFormulas.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صيغ مطابقة للبحث'**
  String get noMatchingFormulas;

  /// No description provided for @swipeOrTapToChange.
  ///
  /// In ar, this message translates to:
  /// **'اسحب أفقياً أو انقر للتبديل'**
  String get swipeOrTapToChange;

  /// No description provided for @nextDhikr.
  ///
  /// In ar, this message translates to:
  /// **'الذكر التالي'**
  String get nextDhikr;

  /// No description provided for @previousDhikr.
  ///
  /// In ar, this message translates to:
  /// **'الذكر السابق'**
  String get previousDhikr;

  /// No description provided for @autoCount.
  ///
  /// In ar, this message translates to:
  /// **'عدّ تلقائي'**
  String get autoCount;

  /// No description provided for @stopAutoCount.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stopAutoCount;

  /// No description provided for @decreasePace.
  ///
  /// In ar, this message translates to:
  /// **'تسريع الوتيرة'**
  String get decreasePace;

  /// No description provided for @increasePace.
  ///
  /// In ar, this message translates to:
  /// **'إبطاء الوتيرة'**
  String get increasePace;

  /// No description provided for @booksSectionEmpty.
  ///
  /// In ar, this message translates to:
  /// **'قسم الكتب والملازم فارغ حالياً'**
  String get booksSectionEmpty;

  /// No description provided for @booksSectionEmptyDescription.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي أقسام أو كتب في ملفات التطبيق حتى الآن.'**
  String get booksSectionEmptyDescription;

  /// No description provided for @pageNumber.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page}'**
  String pageNumber(String page);

  /// No description provided for @juzNumber.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {juz}'**
  String juzNumber(String juz);

  /// No description provided for @hizbNumber.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {hizb}'**
  String hizbNumber(String hizb);

  /// No description provided for @pagesTouched.
  ///
  /// In ar, this message translates to:
  /// **'صفحات لك فيها أثر: {n} من ٦٠٤'**
  String pagesTouched(String n);

  /// No description provided for @daysOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'{a} / {b} أيام'**
  String daysOfTotal(String a, String b);

  /// No description provided for @dayN.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {n}'**
  String dayN(String n);

  /// No description provided for @versesMemorized.
  ///
  /// In ar, this message translates to:
  /// **'آيات محفوظة: {n}'**
  String versesMemorized(String n);

  /// No description provided for @reviewToday.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة اليوم ({n})'**
  String reviewToday(String n);

  /// No description provided for @versesOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'{a} / {b}'**
  String versesOfTotal(String a, String b);

  /// No description provided for @sessionSummary.
  ///
  /// In ar, this message translates to:
  /// **'أتقنت {a} من {b} آية. سنعيد عليك الباقي غداً.'**
  String sessionSummary(String a, String b);

  /// No description provided for @readingPositionMoved.
  ///
  /// In ar, this message translates to:
  /// **'أصبحت صفحة {page} موضع قراءتك'**
  String readingPositionMoved(String page);

  /// No description provided for @pageCounted.
  ///
  /// In ar, this message translates to:
  /// **'احتُسبت صفحة {page}'**
  String pageCounted(String page);

  /// No description provided for @fromMyPosition.
  ///
  /// In ar, this message translates to:
  /// **'من موضعي (ص {page})'**
  String fromMyPosition(String page);

  /// No description provided for @reachedPage.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى صفحة {page}'**
  String reachedPage(String page);

  /// No description provided for @khatmaElsewhere.
  ///
  /// In ar, this message translates to:
  /// **'موضع قراءتك صفحة {page}؛ انقل الختمة إليه؟'**
  String khatmaElsewhere(String page);

  /// No description provided for @portionReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة: {pages} صفحة'**
  String portionReminderTitle(String pages);

  /// No description provided for @juzLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {juz}'**
  String juzLabel(String juz);

  /// No description provided for @myJuzTitle.
  ///
  /// In ar, this message translates to:
  /// **'أجزاء {name}'**
  String myJuzTitle(String name);

  /// No description provided for @chapterN.
  ///
  /// In ar, this message translates to:
  /// **'الفصل {n}'**
  String chapterN(String n);

  /// No description provided for @daysCount.
  ///
  /// In ar, this message translates to:
  /// **'{d} يوماً'**
  String daysCount(String d);

  /// No description provided for @pagesPerDayHint.
  ///
  /// In ar, this message translates to:
  /// **'وردك اليومي: {n} صفحة'**
  String pagesPerDayHint(String n);

  /// No description provided for @completedKhatmas.
  ///
  /// In ar, this message translates to:
  /// **'أتممت {n} ختمة، بارك الله فيك'**
  String completedKhatmas(String n);

  /// No description provided for @behindBy.
  ///
  /// In ar, this message translates to:
  /// **'متأخر {n} صفحة'**
  String behindBy(String n);

  /// No description provided for @khatmaInDays.
  ///
  /// In ar, this message translates to:
  /// **'ختمة في {n} يوماً'**
  String khatmaInDays(String n);

  /// No description provided for @pagesOfMushaf.
  ///
  /// In ar, this message translates to:
  /// **'{n} من ٦٠٤ صفحة'**
  String pagesOfMushaf(String n);

  /// No description provided for @dayOfPlan.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {d} من {total}'**
  String dayOfPlan(String d, String total);

  /// No description provided for @pagesOfTarget.
  ///
  /// In ar, this message translates to:
  /// **'{a} / {b} صفحة'**
  String pagesOfTarget(String a, String b);

  /// No description provided for @continueFromPage.
  ///
  /// In ar, this message translates to:
  /// **'أكمل من صفحة {p}'**
  String continueFromPage(String p);

  /// No description provided for @ayahCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String ayahCount(String count);

  /// No description provided for @versesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات'**
  String versesCount(String count);

  /// No description provided for @duasCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} دعاء'**
  String duasCountBadge(String count);

  /// No description provided for @adhkarCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} ذكر'**
  String adhkarCountBadge(String count);

  /// No description provided for @readingPosition.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahName} · صفحة {page}'**
  String readingPosition(String surahName, String page);

  /// No description provided for @ayahReference.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahName} · الآية {ayahNumber}'**
  String ayahReference(String surahName, String ayahNumber);

  /// No description provided for @surahTitle.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahName}'**
  String surahTitle(String surahName);

  /// No description provided for @ayahTitle.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayahNumber}'**
  String ayahTitle(String ayahNumber);

  /// No description provided for @pageAbbr.
  ///
  /// In ar, this message translates to:
  /// **'ص {page}'**
  String pageAbbr(String page);

  /// No description provided for @juzAbbr.
  ///
  /// In ar, this message translates to:
  /// **'ج {juz}'**
  String juzAbbr(String juz);

  /// No description provided for @ayahsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String ayahsCount(String count);

  /// No description provided for @wordSearchResultsCount.
  ///
  /// In ar, this message translates to:
  /// **'النتائج: {count} كلمة'**
  String wordSearchResultsCount(String count);

  /// No description provided for @surahAyahPageReference.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahName} · آية {ayahNumber} · ص {page}'**
  String surahAyahPageReference(
    String surahName,
    String ayahNumber,
    String page,
  );

  /// No description provided for @linkedAyahsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات مرتبطة'**
  String linkedAyahsCount(String count);

  /// No description provided for @fontSizePoints.
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة'**
  String fontSizePoints(String points);

  /// No description provided for @resetToDefaultWithVal.
  ///
  /// In ar, this message translates to:
  /// **'إعادة للوضع الافتراضي ({val})'**
  String resetToDefaultWithVal(String val);

  /// No description provided for @reminderScheduledSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ وجدولة التنبيه ({mode}) بنجاح'**
  String reminderScheduledSuccess(String mode);

  /// No description provided for @errorSavingFile.
  ///
  /// In ar, this message translates to:
  /// **'خطأ أثناء حفظ الملف: {err}'**
  String errorSavingFile(String err);

  /// No description provided for @dhikrIndex.
  ///
  /// In ar, this message translates to:
  /// **'ذكر {index}'**
  String dhikrIndex(String index);

  /// No description provided for @remainingCount.
  ///
  /// In ar, this message translates to:
  /// **'باقٍ {count}'**
  String remainingCount(String count);

  /// No description provided for @ahlulbaytDuasCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} دعاء مأثور'**
  String ahlulbaytDuasCountBadge(String count);

  /// No description provided for @searchGeneralDuasHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في {title}...'**
  String searchGeneralDuasHint(String title);

  /// No description provided for @generalDuasCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} دعاء مبارك'**
  String generalDuasCountBadge(String count);

  /// No description provided for @duaIndex.
  ///
  /// In ar, this message translates to:
  /// **'دعاء {index}'**
  String duaIndex(String index);

  /// No description provided for @bookIndexPrefix.
  ///
  /// In ar, this message translates to:
  /// **'فهرس: {title}'**
  String bookIndexPrefix(String title);

  /// No description provided for @pageOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page} من {total}'**
  String pageOfTotal(String page, String total);

  /// No description provided for @sectionOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'المبحث {section} من {total}'**
  String sectionOfTotal(String section, String total);

  /// No description provided for @searchSectionHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في محتويات وعناوين {name}...'**
  String searchSectionHint(String name);

  /// No description provided for @fullSectionsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مباحث كاملة'**
  String fullSectionsCount(String count);

  /// No description provided for @fileShareError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر مشاركة أو فتح الملف: {error}'**
  String fileShareError(String error);

  /// No description provided for @pdfReadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة ملف الـ PDF: {error}'**
  String pdfReadError(String error);

  /// No description provided for @fileContentReadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة محتوى الملف: {error}'**
  String fileContentReadError(String error);

  /// No description provided for @removeAyahFromLinkConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إزالة الآية {ayah} من سورة {surah} من هذا الرابط؟'**
  String removeAyahFromLinkConfirm(String ayah, String surah);

  /// No description provided for @targetCount.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: {target}'**
  String targetCount(String target);

  /// No description provided for @countTimes.
  ///
  /// In ar, this message translates to:
  /// **'{count} مرة'**
  String countTimes(String count);

  /// No description provided for @formulaXOfY.
  ///
  /// In ar, this message translates to:
  /// **'صيغة {current} من {total}'**
  String formulaXOfY(String current, String total);

  /// No description provided for @allFormulasCount.
  ///
  /// In ar, this message translates to:
  /// **'كل الصيغ ({total})'**
  String allFormulasCount(String total);

  /// No description provided for @targetReachedAuto.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! أتممت الورد ({target}). تم الانتقال تلقائياً إلى الذكر التالي.'**
  String targetReachedAuto(String target);

  /// No description provided for @targetReached.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! أتممت الورد المستهدف ({target}) بنجاح.'**
  String targetReached(String target);

  /// No description provided for @smartPaceSeconds.
  ///
  /// In ar, this message translates to:
  /// **'إيقاع {seconds} ث'**
  String smartPaceSeconds(String seconds);

  /// No description provided for @portionLeftTitle.
  ///
  /// In ar, this message translates to:
  /// **'بقي من وردك اليوم {pages} صفحة'**
  String portionLeftTitle(String pages);

  /// No description provided for @portionLeftBody.
  ///
  /// In ar, this message translates to:
  /// **'أكمل ختمتك من حيث توقفت'**
  String get portionLeftBody;

  /// No description provided for @adhkarSetCompleted.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الأذكار، واحتُسب يومك في رحلتك'**
  String get adhkarSetCompleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
