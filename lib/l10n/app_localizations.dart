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

  /// No description provided for @booksAndBooklets.
  ///
  /// In ar, this message translates to:
  /// **'كتب وملازم'**
  String get booksAndBooklets;

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

  /// No description provided for @reflectOnIt.
  ///
  /// In ar, this message translates to:
  /// **'تدبّرها'**
  String get reflectOnIt;

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

  /// No description provided for @memorizedDone.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get memorizedDone;

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

  /// No description provided for @cardDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get cardDark;

  /// No description provided for @cardLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get cardLight;

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

  /// No description provided for @portionReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة: {pages} صفحة'**
  String portionReminderTitle(String pages);

  /// No description provided for @chapterN.
  ///
  /// In ar, this message translates to:
  /// **'الفصل {n}'**
  String chapterN(String n);

  /// No description provided for @daysCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{يوم واحد} =2{يومان} few{{d} أيام} many{{d} يومًا} other{{d} يوم}}'**
  String daysCount(int count, String d);

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
  /// **'ختمة في {count, plural, =1{يوم واحد} =2{يومين} few{{n} أيام} many{{n} يومًا} other{{n} يوم}}'**
  String khatmaInDays(int count, String n);

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

  /// No description provided for @mushafStyleTitle.
  ///
  /// In ar, this message translates to:
  /// **'طريقة عرض المصحف'**
  String get mushafStyleTitle;

  /// No description provided for @mushafStyleMadinah.
  ///
  /// In ar, this message translates to:
  /// **'مصحف المدينة'**
  String get mushafStyleMadinah;

  /// No description provided for @mushafStyleText.
  ///
  /// In ar, this message translates to:
  /// **'نص متدفق'**
  String get mushafStyleText;

  /// No description provided for @qcfAttribution.
  ///
  /// In ar, this message translates to:
  /// **'خط المصحف: مجمع الملك فهد لطباعة المصحف الشريف'**
  String get qcfAttribution;

  /// No description provided for @widgetPortionDone.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ورد اليوم'**
  String get widgetPortionDone;

  /// No description provided for @widgetAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية للتدبّر'**
  String get widgetAyahTitle;

  /// No description provided for @themePickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مظهر التطبيق'**
  String get themePickerTitle;

  /// No description provided for @themePickerHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغييره متى شئت من الإعدادات'**
  String get themePickerHint;

  /// No description provided for @themePickerStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get themePickerStart;

  /// No description provided for @themeAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeAuto;

  /// No description provided for @addVerseTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة آية إلى الرابط'**
  String get addVerseTitle;

  /// No description provided for @addVerseSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بنص الآية أو اكتب: البقرة ٢٥٥'**
  String get addVerseSearchHint;

  /// No description provided for @addVerseFromSaved.
  ///
  /// In ar, this message translates to:
  /// **'من محفوظاتك'**
  String get addVerseFromSaved;

  /// No description provided for @addVersePickBySurah.
  ///
  /// In ar, this message translates to:
  /// **'اختيار بالسورة ورقم الآية'**
  String get addVersePickBySurah;

  /// No description provided for @addVerseSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get addVerseSurah;

  /// No description provided for @addVerseAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية'**
  String get addVerseAyah;

  /// No description provided for @addVerseNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختيارية)'**
  String get addVerseNote;

  /// No description provided for @addVerseAlready.
  ///
  /// In ar, this message translates to:
  /// **'مضافة إلى هذا الرابط'**
  String get addVerseAlready;

  /// No description provided for @addVerseAction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى الرابط'**
  String get addVerseAction;

  /// No description provided for @addVerseChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get addVerseChange;

  /// No description provided for @addVerseNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get addVerseNoResults;

  /// No description provided for @addVerseSearchSurah.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم السورة أو رقمها'**
  String get addVerseSearchSurah;

  /// No description provided for @mushafStyleMadinahHint.
  ///
  /// In ar, this message translates to:
  /// **'صفحات مطابقة للمصحف المطبوع، وعند التكبير تلتفّ الأسطر.'**
  String get mushafStyleMadinahHint;

  /// No description provided for @mushafStyleTextHint.
  ///
  /// In ar, this message translates to:
  /// **'نص متدفق بالخط الذي تختاره.'**
  String get mushafStyleTextHint;

  /// No description provided for @khatmaStartNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get khatmaStartNow;

  /// No description provided for @askNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما اسمك؟'**
  String get askNameTitle;

  /// No description provided for @askNameHint.
  ///
  /// In ar, this message translates to:
  /// **'نناديك به في التذكيرات والإشعارات، ويبقى على جهازك فقط.'**
  String get askNameHint;

  /// No description provided for @askNameField.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get askNameField;

  /// No description provided for @skipStep.
  ///
  /// In ar, this message translates to:
  /// **'تخطّي'**
  String get skipStep;

  /// No description provided for @yourName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get yourName;

  /// No description provided for @yourNameNotSet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحدَّد'**
  String get yourNameNotSet;

  /// No description provided for @reminderQuranBody.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت تلاوة وتدبّر القرآن الكريم'**
  String get reminderQuranBody;

  /// No description provided for @reminderAdhkarBody.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الأذكار، ذكّر قلبك بالله'**
  String get reminderAdhkarBody;

  /// No description provided for @myReflections.
  ///
  /// In ar, this message translates to:
  /// **'وقفاتي'**
  String get myReflections;

  /// No description provided for @reflectionsAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get reflectionsAll;

  /// No description provided for @reflectionsCommitments.
  ///
  /// In ar, this message translates to:
  /// **'ما التزمت به'**
  String get reflectionsCommitments;

  /// No description provided for @noReflectionsHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على آية في المصحف واختر «وقفة تدبر».'**
  String get noReflectionsHint;

  /// No description provided for @noCommitmentsYet.
  ///
  /// In ar, this message translates to:
  /// **'ما تكتبه جواباً عن «ما العمل الذي تدعوك إليه هذه الآية؟» يظهر هنا.'**
  String get noCommitmentsYet;

  /// No description provided for @commitmentDid.
  ///
  /// In ar, this message translates to:
  /// **'فعلته'**
  String get commitmentDid;

  /// No description provided for @commitmentNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get commitmentNotYet;

  /// No description provided for @commitmentPending.
  ///
  /// In ar, this message translates to:
  /// **'باقٍ'**
  String get commitmentPending;

  /// No description provided for @commitmentSaidAt.
  ///
  /// In ar, this message translates to:
  /// **'قلتَ عند {reference}:'**
  String commitmentSaidAt(String reference);

  /// No description provided for @commitmentQuestion.
  ///
  /// In ar, this message translates to:
  /// **'هل فعلته؟'**
  String get commitmentQuestion;

  /// No description provided for @saveToPhotos.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في الصور'**
  String get saveToPhotos;

  /// No description provided for @cardSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت البطاقة في الصور'**
  String get cardSaved;

  /// No description provided for @cardSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ البطاقة'**
  String get cardSaveFailed;

  /// No description provided for @cardSaveDenied.
  ///
  /// In ar, this message translates to:
  /// **'اسمح لتدبير بإضافة الصور من إعدادات الجهاز'**
  String get cardSaveDenied;

  /// No description provided for @continueReflection.
  ///
  /// In ar, this message translates to:
  /// **'تابع وقفتك'**
  String get continueReflection;

  /// No description provided for @markAyah.
  ///
  /// In ar, this message translates to:
  /// **'علامة'**
  String get markAyah;

  /// No description provided for @unmarkAyah.
  ///
  /// In ar, this message translates to:
  /// **'إزالة العلامة'**
  String get unmarkAyah;

  /// No description provided for @chooseSurah.
  ///
  /// In ar, this message translates to:
  /// **'اختر السورة'**
  String get chooseSurah;

  /// No description provided for @searchSurahHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم السورة أو رقمها'**
  String get searchSurahHint;

  /// No description provided for @enlargeText.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get enlargeText;

  /// No description provided for @textSmaller.
  ///
  /// In ar, this message translates to:
  /// **'تصغير الخط'**
  String get textSmaller;

  /// No description provided for @textLarger.
  ///
  /// In ar, this message translates to:
  /// **'تكبير الخط أكثر'**
  String get textLarger;

  /// No description provided for @defaultTextSize.
  ///
  /// In ar, this message translates to:
  /// **'الحجم الافتراضي'**
  String get defaultTextSize;

  /// No description provided for @reflectionsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{وقفة واحدة} =2{وقفتان} few{{shown} وقفات} other{{shown} وقفة}}'**
  String reflectionsCount(int count, String shown);

  /// No description provided for @streakAtRiskTitle.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{لا تقطع سلسلتك: يوم واحد حتى الآن} =2{لا تقطع سلسلتك: يومان متتاليان} few{لا تقطع سلسلتك: {n} أيام متتالية} other{لا تقطع سلسلتك: {n} يومًا متتاليًا}}'**
  String streakAtRiskTitle(int count, String n);

  /// No description provided for @streakAtRiskBody.
  ///
  /// In ar, this message translates to:
  /// **'صفحة واحدة أو وقفة تدبر تكفي لتبقى السلسلة'**
  String get streakAtRiskBody;

  /// No description provided for @streakReminder.
  ///
  /// In ar, this message translates to:
  /// **'نبّهني قبل أن تنقطع السلسلة'**
  String get streakReminder;

  /// No description provided for @streakReminderOff.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه مسائي إن لم تقرأ شيئًا في يومك'**
  String get streakReminderOff;

  /// No description provided for @streakReminderAt.
  ///
  /// In ar, this message translates to:
  /// **'كل مساء {time} إن لم تقرأ بعد'**
  String streakReminderAt(String time);

  /// No description provided for @streakReminderPrompt.
  ///
  /// In ar, this message translates to:
  /// **'متى نذكّرك إن لم تقرأ في يومك؟'**
  String get streakReminderPrompt;

  /// No description provided for @qibla.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get qibla;

  /// No description provided for @qiblaUpdateLocation.
  ///
  /// In ar, this message translates to:
  /// **'تحديث موقعي'**
  String get qiblaUpdateLocation;

  /// No description provided for @qiblaLocating.
  ///
  /// In ar, this message translates to:
  /// **'نحدد موقعك…'**
  String get qiblaLocating;

  /// No description provided for @qiblaFacing.
  ///
  /// In ar, this message translates to:
  /// **'أنت متجه إلى القبلة'**
  String get qiblaFacing;

  /// No description provided for @qiblaTurnRight.
  ///
  /// In ar, this message translates to:
  /// **'استدر يمينًا {deg}°'**
  String qiblaTurnRight(String deg);

  /// No description provided for @qiblaTurnLeft.
  ///
  /// In ar, this message translates to:
  /// **'استدر يسارًا {deg}°'**
  String qiblaTurnLeft(String deg);

  /// No description provided for @qiblaFromNorth.
  ///
  /// In ar, this message translates to:
  /// **'من الشمال'**
  String get qiblaFromNorth;

  /// No description provided for @qiblaKmToMakkah.
  ///
  /// In ar, this message translates to:
  /// **'كم إلى مكة المكرمة'**
  String get qiblaKmToMakkah;

  /// No description provided for @qiblaFromHere.
  ///
  /// In ar, this message translates to:
  /// **'حسب موقعك الحالي'**
  String get qiblaFromHere;

  /// No description provided for @qiblaFromLastLocation.
  ///
  /// In ar, this message translates to:
  /// **'حسب آخر موقع معروف لك'**
  String get qiblaFromLastLocation;

  /// No description provided for @qiblaNoCompass.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بوصلة في جهازك: وجّه أعلى الجهاز نحو الشمال، والقبلة حيث علامة الكعبة'**
  String get qiblaNoCompass;

  /// No description provided for @qiblaCalibrate.
  ///
  /// In ar, this message translates to:
  /// **'إن بدا الاتجاه غير دقيق فحرّك الجهاز في الهواء على شكل ٨، وابتعد عن المعادن والأجهزة'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaLocationOff.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة في جهازك. شغّلها لنحسب اتجاه القبلة'**
  String get qiblaLocationOff;

  /// No description provided for @qiblaTurnOnLocation.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الموقع'**
  String get qiblaTurnOnLocation;

  /// No description provided for @qiblaNeedsLocation.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج موقعك التقريبي لنحسب اتجاه القبلة، ولا يُرسل إلى أي مكان'**
  String get qiblaNeedsLocation;

  /// No description provided for @qiblaAllowLocation.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالموقع'**
  String get qiblaAllowLocation;

  /// No description provided for @qiblaOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get qiblaOpenSettings;

  /// No description provided for @qiblaLocationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك. تأكد من تشغيل الموقع وحاول مرة أخرى'**
  String get qiblaLocationFailed;

  /// No description provided for @qiblaNorth.
  ///
  /// In ar, this message translates to:
  /// **'ش'**
  String get qiblaNorth;

  /// No description provided for @qiblaEast.
  ///
  /// In ar, this message translates to:
  /// **'ق'**
  String get qiblaEast;

  /// No description provided for @qiblaSouth.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get qiblaSouth;

  /// No description provided for @qiblaWest.
  ///
  /// In ar, this message translates to:
  /// **'غ'**
  String get qiblaWest;

  /// No description provided for @listen.
  ///
  /// In ar, this message translates to:
  /// **'استماع'**
  String get listen;

  /// No description provided for @audioSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التلاوة'**
  String get audioSettings;

  /// No description provided for @reciterLabel.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get reciterLabel;

  /// No description provided for @lowerQuality.
  ///
  /// In ar, this message translates to:
  /// **'جودة أقل'**
  String get lowerQuality;

  /// No description provided for @repeatEachAyah.
  ///
  /// In ar, this message translates to:
  /// **'تكرار كل آية'**
  String get repeatEachAyah;

  /// No description provided for @pauseAfterAyah.
  ///
  /// In ar, this message translates to:
  /// **'وقفة تدبر بعد كل آية'**
  String get pauseAfterAyah;

  /// No description provided for @noPause.
  ///
  /// In ar, this message translates to:
  /// **'بلا وقفة'**
  String get noPause;

  /// No description provided for @secondsShort.
  ///
  /// In ar, this message translates to:
  /// **'{n} ث'**
  String secondsShort(String n);

  /// No description provided for @audioFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل التلاوة. تحقّق من اتصالك بالإنترنت'**
  String get audioFailed;

  /// No description provided for @nextAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get nextAyah;

  /// No description provided for @previousAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get previousAyah;

  /// No description provided for @playAudio.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get playAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pauseAudio;

  /// No description provided for @stopAudio.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة'**
  String get stopAudio;

  /// No description provided for @resting.
  ///
  /// In ar, this message translates to:
  /// **'وقفة تدبر…'**
  String get resting;

  /// No description provided for @audioSource.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات من شبكة Islamic Network ‏(alquran.cloud)، وتحتاج اتصالًا بالإنترنت'**
  String get audioSource;

  /// No description provided for @recitationDownloads.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل التلاوات'**
  String get recitationDownloads;

  /// No description provided for @downloadForOffline.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل للاستماع دون إنترنت'**
  String get downloadForOffline;

  /// No description provided for @downloadedLabel.
  ///
  /// In ar, this message translates to:
  /// **'منزّلة على جهازك'**
  String get downloadedLabel;

  /// No description provided for @downloadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التنزيل، حاول مرة أخرى'**
  String get downloadFailed;

  /// No description provided for @downloadSurah.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل السورة'**
  String get downloadSurah;

  /// No description provided for @cancelDownload.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التنزيل'**
  String get cancelDownload;

  /// No description provided for @deleteDownload.
  ///
  /// In ar, this message translates to:
  /// **'حذف التنزيل'**
  String get deleteDownload;

  /// No description provided for @deleteAllDownloads.
  ///
  /// In ar, this message translates to:
  /// **'حذف كل التنزيلات'**
  String get deleteAllDownloads;

  /// No description provided for @deleteAllDownloadsConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف كل سور {name} المنزّلة من جهازك.'**
  String deleteAllDownloadsConfirm(String name);

  /// No description provided for @downloadsSize.
  ///
  /// In ar, this message translates to:
  /// **'على جهازك: {size} ميجابايت'**
  String downloadsSize(String size);

  /// No description provided for @downloadJuzAmma.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل جزء عمّ'**
  String get downloadJuzAmma;

  /// No description provided for @downloadsHint.
  ///
  /// In ar, this message translates to:
  /// **'السور المنزّلة تُسمع دون إنترنت، وما لم يُنزَّل يُسمع مباشرة عند الاتصال.'**
  String get downloadsHint;

  /// No description provided for @mushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get mushaf;

  /// No description provided for @appColorTheme.
  ///
  /// In ar, this message translates to:
  /// **'لون التطبيق'**
  String get appColorTheme;

  /// No description provided for @sourcesAndCreditsDetails.
  ///
  /// In ar, this message translates to:
  /// **'• نص القرآن الكريم: مشروع تنزيل (Tanzil Project - https://tanzil.net) بالنص العثماني المعتمد برخصة المشاع الإبداعي (CC BY 3.0 — يُمنع التعديل).\n• الخطوط القرآنية المفتوحة المصدر: خط شهرزاد الجديد (Scheherazade New)، خط نوتو نسخ (Noto Naskh Arabic)، خط هرمتان (Harmattan)، خط لطيف (Lateef)، وخط أميري القرآني (AmiriQuran & Amiri) برخصة الخطوط المفتوحة SIL Open Font License 1.1.\n• معاني كلمات القرآن: الموسوعة القرآنية (Quranpedia.net — نسخة البيانات 2026-10-10) وأمهات المعاجم اللغوية التراثية والمعاصرة (لسان العرب، مقاييس اللغة، التبيان، تذكرة الأريب، مفردات الراغب، والمعجم الوسيط).\n• مكتبة الكتب والملازم التدبرية: ملازم هدي القرآن الكريم للسيد حسين بدر الدين الحوثي (86 ملزمة موثقة كاملة)، وأمهات كتب تراث وأدعية أهل البيت عليهم السلام (الصحيفة السجادية، رسالة الحقوق، نهج البلاغة، تحف العقول)، وكتب علوم وتدبر القرآن المفتوحة (الآجري، النووي).\n• الأدعية والأذكار والتسبيح: 88 دعاءً قرآنياً مرتبة حسب المصحف، وحصن المسلم لأذكار الصباح والمساء، وباقة الاستغفار والتسبيح (49 صيغة مأثورة موثقة)، وأدعية أهل البيت والسنة النبوية الشريفة.\n• ترخيص التطبيق: مشروع مفتوح المصدر بالكامل تحت رخصة MIT License.\n• خط مصحف المدينة: خطوط صفحات المصحف (QCF) من مجمع الملك فهد لطباعة المصحف الشريف، وتخطيط الأسطر من بيانات Quran.com.\n• الخصوصية والأمان المحلي: التطبيق يعمل محلياً بالكامل (100% Offline) دون أي اتصال خارجي أو خوادم أو تتبع أو إعلانات، مع تشفير النسخ الاحتياطية بمعيار AES-256.'**
  String get sourcesAndCreditsDetails;

  /// No description provided for @unsavedChanges.
  ///
  /// In ar, this message translates to:
  /// **'تغييرات غير محفوظة'**
  String get unsavedChanges;

  /// No description provided for @discardChangesConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مغادرة المحرر وتجاهل التعديلات غير المحفوظة؟'**
  String get discardChangesConfirm;

  /// No description provided for @discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل والخروج'**
  String get discard;

  /// No description provided for @cannotSaveAnEmptyNote.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حفظ ملاحظة فارغة'**
  String get cannotSaveAnEmptyNote;

  /// No description provided for @editAyahReflection.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تدبر الآية'**
  String get editAyahReflection;

  /// No description provided for @unsaved.
  ///
  /// In ar, this message translates to:
  /// **'غير محفوظ'**
  String get unsaved;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ'**
  String get saved;

  /// No description provided for @reflectionTitleOptional.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التدبر (اختياري)...'**
  String get reflectionTitleOptional;

  /// No description provided for @instantSecureLocalSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ محلي فوري وآمن'**
  String get instantSecureLocalSave;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الفاصلة المرجعية'**
  String get bookmarkRemoved;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @booksBooklets.
  ///
  /// In ar, this message translates to:
  /// **'الملازم والكتب'**
  String get booksBooklets;

  /// No description provided for @searchEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة أو اسم سورة أو ابحث بالجذر اللغوي (مثال: جذر صبر)'**
  String get searchEmptyHint;

  /// No description provided for @sectionHasNoItems.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناصر محفوظة في هذا القسم بعد'**
  String get sectionHasNoItems;

  /// No description provided for @systemTheme.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get systemTheme;

  /// No description provided for @lightThemeExplanation.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري: خلفية ورقية هادئة مع لمسات كحلية وذهبية لقراءة نهارية مريحة وواضحة.'**
  String get lightThemeExplanation;

  /// No description provided for @darkThemeExplanation.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي: ألوان كحلية ليلية مع لمسات ذهبية صُممت خصيصاً لتقليل إجهاد النظر والسطوع أثناء التلاوة والتدبر الطويل.'**
  String get darkThemeExplanation;

  /// No description provided for @privacyOfflineTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمل محلي تام دون إنترنت (100% Offline-First)'**
  String get privacyOfflineTitle;

  /// No description provided for @privacyOfflineBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يطلب التطبيق إذن الإنترنت (android.permission.INTERNET) في ملف التكوين، ويعمل ذاتياً بالكامل على جهازك دون الحاجة لأي خوادم سحابية.'**
  String get privacyOfflineBody;

  /// No description provided for @privacyNoDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'عدم جمع أي بيانات شخصية (Zero Data Collection)'**
  String get privacyNoDataTitle;

  /// No description provided for @privacyNoDataBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يجمع التطبيق ولا يسجل ولا يشارك أي بيانات شخصية، أو معرّفات أجهزة، أو سجلات قراءة، أو إحصاءات استخدام مع أي طرف خارجي على الإطلاق.'**
  String get privacyNoDataBody;

  /// No description provided for @privacyStorageTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخزين محلي وتشفير عالي (AES-256)'**
  String get privacyStorageTitle;

  /// No description provided for @privacyStorageBody.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ كافة ملاحظاتك ووقفاتك التدبرية محلياً في قاعدة بيانات SQLite على جهازك، وتُشفّر النسخ الاحتياطية (.quranbackup) بكلمة مرورك بمعيار AES-256-CBC مع فحص SHA-256.'**
  String get privacyStorageBody;

  /// No description provided for @privacyPermissionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'استخدام حصري ومحدد للأذونات (Device Permissions)'**
  String get privacyPermissionsTitle;

  /// No description provided for @privacyPermissionsBody.
  ///
  /// In ar, this message translates to:
  /// **'تُستخدم أذونات الإشعارات المحلية حصراً لتشغيل منبهات وتذكيرات الورد اليومي التي يحددها المستخدم بنفسه، ولا تُرسل أي إشعارات ترويجية.'**
  String get privacyPermissionsBody;

  /// No description provided for @privacyNoAdsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خلو تام من الإعلانات والمتتبعات (Zero Ads & Trackers)'**
  String get privacyNoAdsTitle;

  /// No description provided for @privacyNoAdsBody.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق خالٍ بنسبة 100% من أي منصات إعلانية أو حزم تتبع أو أدوات تحليل أداء خارجية.'**
  String get privacyNoAdsBody;

  /// No description provided for @privacyOpenSourceBody.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق «تَدْبِير» مشروع مفتوح المصدر بالكامل تحت رخصة MIT، ورمزه المصدري متاح للمراجعة والتدقيق العام على GitHub.'**
  String get privacyOpenSourceBody;

  /// No description provided for @createLinkWithVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط جديد وربط هذه الآية به مباشرة'**
  String get createLinkWithVerseHint;

  /// No description provided for @alreadyAdded.
  ///
  /// In ar, this message translates to:
  /// **'مضافة بالفعل'**
  String get alreadyAdded;

  /// No description provided for @editAyahLink.
  ///
  /// In ar, this message translates to:
  /// **'تعديل رابط الآيات'**
  String get editAyahLink;

  /// No description provided for @titleRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال عنوان الرابط'**
  String get titleRequired;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @reflectionNoteCard.
  ///
  /// In ar, this message translates to:
  /// **'كرت ملاحظة تدبرية'**
  String get reflectionNoteCard;

  /// No description provided for @noteCopiedToClipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ نص الملاحظة إلى الحافظة'**
  String get noteCopiedToClipboard;

  /// No description provided for @copyText.
  ///
  /// In ar, this message translates to:
  /// **'نسخ النص'**
  String get copyText;

  /// No description provided for @deleteNote.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة'**
  String get deleteNote;

  /// No description provided for @myNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظتي'**
  String get myNote;

  /// No description provided for @reflectionNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'كرت ملاحظة تدبرية'**
  String get reflectionNoteLabel;

  /// No description provided for @remove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get remove;

  /// No description provided for @editNoteCard.
  ///
  /// In ar, this message translates to:
  /// **'تعديل كرت الملاحظة'**
  String get editNoteCard;

  /// No description provided for @titleOptional.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الملاحظة (اختياري)'**
  String get titleOptional;

  /// No description provided for @noteContentHint.
  ///
  /// In ar, this message translates to:
  /// **'نص الملاحظة...'**
  String get noteContentHint;

  /// No description provided for @deleteNoteCard.
  ///
  /// In ar, this message translates to:
  /// **'حذف كرت الملاحظة'**
  String get deleteNoteCard;

  /// No description provided for @deleteNoteCardConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف كرت هذه الملاحظة؟'**
  String get deleteNoteCardConfirm;

  /// No description provided for @addNoteCard.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كرت ملاحظة'**
  String get addNoteCard;

  /// No description provided for @addNoteCardHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّل ملاحظتك أو تدبرك ككرت مستقل في هذا الرابط:'**
  String get addNoteCardHint;

  /// No description provided for @noteTitleOptional.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الملاحظة (اختياري)'**
  String get noteTitleOptional;

  /// No description provided for @noteCardAddedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة كرت الملاحظة بنجاح'**
  String get noteCardAddedSuccessfully;

  /// No description provided for @linkNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الرابط غير موجود أو تم حذفه'**
  String get linkNotFound;

  /// No description provided for @addNoteShort.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNoteShort;

  /// No description provided for @searchQuranicSupplications.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في أدعية القرآن الكريم...'**
  String get searchQuranicSupplications;

  /// No description provided for @clearedEmptyAnswersSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح الإجابات الفارغة بنجاح'**
  String get clearedEmptyAnswersSuccessfully;

  /// No description provided for @tadbeerPauseSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ وقفة التدبر بنجاح'**
  String get tadbeerPauseSavedSuccessfully;

  /// No description provided for @reflectionAnswerHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما خطر ببالك...'**
  String get reflectionAnswerHint;

  /// No description provided for @doneAndSave.
  ///
  /// In ar, this message translates to:
  /// **'تم وحفظ'**
  String get doneAndSave;

  /// No description provided for @saveAndFinish.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ما كتبت الآن وإنهاء'**
  String get saveAndFinish;

  /// No description provided for @noMatchingBooks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة لبحثك'**
  String get noMatchingBooks;

  /// No description provided for @booksSectionIsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم فارغ حالياً'**
  String get booksSectionIsEmpty;

  /// No description provided for @noSearchResultsHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب البحث بكلمة أخرى أو اختر تصنيفاً أو سلسلة أخرى.'**
  String get noSearchResultsHint;

  /// No description provided for @emptySectionHint.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي ملازم أو كتب في هذا القسم بعد.'**
  String get emptySectionHint;

  /// No description provided for @sectionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get sectionsTitle;

  /// No description provided for @myVersesSection.
  ///
  /// In ar, this message translates to:
  /// **'آياتي'**
  String get myVersesSection;

  /// No description provided for @toolsSection.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات'**
  String get toolsSection;

  /// No description provided for @appSection.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get appSection;

  /// No description provided for @systemThemeLabel.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي ({mode})'**
  String systemThemeLabel(String mode);

  /// No description provided for @systemThemeExplanation.
  ///
  /// In ar, this message translates to:
  /// **'الوضع التلقائي: يتزامن مظهر التطبيق آلياً مع إعدادات هاتفك (المظهر المفعّل حالياً في جهازك: {mode}).'**
  String systemThemeExplanation(String mode);

  /// No description provided for @exportNoteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تصدير الملاحظة: {error}'**
  String exportNoteFailed(String error);

  /// No description provided for @noteWordCharCount.
  ///
  /// In ar, this message translates to:
  /// **'{words} كلمة · {chars} حرف'**
  String noteWordCharCount(String words, String chars);

  /// No description provided for @searchInSection.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في {section}...'**
  String searchInSection(String section);

  /// No description provided for @verseAddedToLink.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الآية إلى رابط «{title}»'**
  String verseAddedToLink(String title);

  /// No description provided for @reflectionNotesCount.
  ///
  /// In ar, this message translates to:
  /// **'كروت الملاحظات والتدبرات ({count})'**
  String reflectionNotesCount(String count);

  /// No description provided for @connectedVersesCount.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المرتبطة ({count})'**
  String connectedVersesCount(String count);

  /// No description provided for @deleteLinkConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في حذف رابط «{title}»؟'**
  String deleteLinkConfirm(String title);

  /// No description provided for @linkDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف رابط «{title}»'**
  String linkDeleted(String title);

  /// No description provided for @itemCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ {title} إلى الحافظة بنجاح'**
  String itemCopied(String title);

  /// No description provided for @duaAlert.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: {text}'**
  String duaAlert(String text);

  /// No description provided for @questionOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'السؤال {number} من {total}'**
  String questionOfTotal(String number, String total);

  /// No description provided for @permissionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذونات التطبيق'**
  String get permissionsTitle;

  /// No description provided for @permissionsBody.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج تدبير إذن الإشعارات والمنبهات ليذكّرك بوردك وأذكارك في وقتها، ولو كان التطبيق مغلقاً. لا يُرسَل شيء خارج جهازك.'**
  String get permissionsBody;

  /// No description provided for @permissionsAllow.
  ///
  /// In ar, this message translates to:
  /// **'سماح'**
  String get permissionsAllow;

  /// No description provided for @permissionsLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get permissionsLater;

  /// No description provided for @continuousRecitation.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التلاوة (اضغط لآية واحدة)'**
  String get continuousRecitation;

  /// No description provided for @singleAyahRecitation.
  ///
  /// In ar, this message translates to:
  /// **'آية واحدة (اضغط للمتابعة)'**
  String get singleAyahRecitation;

  /// No description provided for @ayahFinished.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الآية'**
  String get ayahFinished;

  /// No description provided for @myReflectionsCardHint.
  ///
  /// In ar, this message translates to:
  /// **'وقفات التدبر التي كتبتها'**
  String get myReflectionsCardHint;

  /// No description provided for @notesCardHint.
  ///
  /// In ar, this message translates to:
  /// **'خواطرك على الآيات'**
  String get notesCardHint;

  /// No description provided for @memorizationCardHint.
  ///
  /// In ar, this message translates to:
  /// **'احفظ وراجع في وقته'**
  String get memorizationCardHint;

  /// No description provided for @searchCardHint.
  ///
  /// In ar, this message translates to:
  /// **'في القرآن وكل ما حفظت'**
  String get searchCardHint;

  /// No description provided for @wordMeaningsCardHint.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات بترتيب المصحف'**
  String get wordMeaningsCardHint;

  /// No description provided for @ayahLinksCardHint.
  ///
  /// In ar, this message translates to:
  /// **'اربط الآيات بموضوع واحد'**
  String get ayahLinksCardHint;

  /// No description provided for @guidedPathwaysCardHint.
  ///
  /// In ar, this message translates to:
  /// **'رحلات تدبر يومًا بيوم'**
  String get guidedPathwaysCardHint;

  /// No description provided for @booksAndBookletsCardHint.
  ///
  /// In ar, this message translates to:
  /// **'الملازم والكتب للقراءة'**
  String get booksAndBookletsCardHint;

  /// No description provided for @tourSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطٍّ'**
  String get tourSkip;

  /// No description provided for @tourNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get tourNext;

  /// No description provided for @tourStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get tourStart;

  /// No description provided for @tourGotIt.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get tourGotIt;

  /// No description provided for @guideButton.
  ///
  /// In ar, this message translates to:
  /// **'شرح هذا القسم'**
  String get guideButton;

  /// No description provided for @tour1Title.
  ///
  /// In ar, this message translates to:
  /// **'كتاب أنزلناه إليك مبارك ليدبروا آياته'**
  String get tour1Title;

  /// No description provided for @tour1Body.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطوّلاً على أي آية لتتدبّرها، أو تحفظها، أو تستمع إليها، أو تربطها بغيرها.'**
  String get tour1Body;

  /// No description provided for @tour2Title.
  ///
  /// In ar, this message translates to:
  /// **'من القراءة إلى التدبّر'**
  String get tour2Title;

  /// No description provided for @tour2Body.
  ///
  /// In ar, this message translates to:
  /// **'أربعة أسئلة لكل آية تفتح لك معانيها، وروابط تجمع الآيات في موضوع واحد.'**
  String get tour2Body;

  /// No description provided for @tour3Title.
  ///
  /// In ar, this message translates to:
  /// **'استمع بأصوات كبار القرّاء'**
  String get tour3Title;

  /// No description provided for @tour3Body.
  ///
  /// In ar, this message translates to:
  /// **'تابع السورة أو قف عند آية واحدة، ونزّل التلاوة لتسمعها دون إنترنت.'**
  String get tour3Body;

  /// No description provided for @tour4Title.
  ///
  /// In ar, this message translates to:
  /// **'وردك اليومي يمشي معك'**
  String get tour4Title;

  /// No description provided for @tour4Body.
  ///
  /// In ar, this message translates to:
  /// **'ختمة بخطة، وسلسلة أيام، وتسبيح، وودجت يضع آية على شاشة هاتفك.'**
  String get tour4Body;

  /// No description provided for @tour5Title.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في رحلتك مع القرآن'**
  String get tour5Title;

  /// No description provided for @tour5Body.
  ///
  /// In ar, this message translates to:
  /// **'كل ما تحتاجه للقراءة والتدبّر والذكر في مكان واحد، ويعمل دون إنترنت.'**
  String get tour5Body;

  /// No description provided for @tourSampleAnswer.
  ///
  /// In ar, this message translates to:
  /// **'أن الله معي في كل حال'**
  String get tourSampleAnswer;

  /// No description provided for @tourSampleAnswer2.
  ///
  /// In ar, this message translates to:
  /// **'مع العسر يسر، فلا أيأس'**
  String get tourSampleAnswer2;

  /// No description provided for @tourSampleAnswer3.
  ///
  /// In ar, this message translates to:
  /// **'ذكر الله يُسكن قلبي'**
  String get tourSampleAnswer3;

  /// No description provided for @tourCreateLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط جديد'**
  String get tourCreateLink;

  /// No description provided for @tourSampleLink.
  ///
  /// In ar, this message translates to:
  /// **'أبواب الرزق'**
  String get tourSampleLink;

  /// No description provided for @tourLinkNote1.
  ///
  /// In ar, this message translates to:
  /// **'الباب الأول: التقوى'**
  String get tourLinkNote1;

  /// No description provided for @tourLinkNote2.
  ///
  /// In ar, this message translates to:
  /// **'الباب الثاني: الاستغفار'**
  String get tourLinkNote2;

  /// No description provided for @tourLinkNote3.
  ///
  /// In ar, this message translates to:
  /// **'الباب الثالث: الشكر'**
  String get tourLinkNote3;

  /// No description provided for @tourSamplePathway.
  ///
  /// In ar, this message translates to:
  /// **'مسار الصبر'**
  String get tourSamplePathway;

  /// No description provided for @tourSamplePathwayHint.
  ///
  /// In ar, this message translates to:
  /// **'سبعة أيام، في كل يوم آية وسؤال'**
  String get tourSamplePathwayHint;

  /// No description provided for @tourDayOne.
  ///
  /// In ar, this message translates to:
  /// **'اليوم الأول'**
  String get tourDayOne;

  /// No description provided for @tourSampleQuestion.
  ///
  /// In ar, this message translates to:
  /// **'متى استعنت بالصبر آخر مرة؟'**
  String get tourSampleQuestion;

  /// No description provided for @tourSampleReciter.
  ///
  /// In ar, this message translates to:
  /// **'محمود خليل الحصري'**
  String get tourSampleReciter;

  /// No description provided for @tourKhatma.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get tourKhatma;

  /// No description provided for @tourStreak.
  ///
  /// In ar, this message translates to:
  /// **'يوم متتالٍ'**
  String get tourStreak;

  /// No description provided for @guideQiblaTitle.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get guideQiblaTitle;

  /// No description provided for @guideQiblaBody.
  ///
  /// In ar, this message translates to:
  /// **'حدّد موقعك مرة، ثم أمسك الهاتف مستوياً وأدره حتى يشير السهم إلى الكعبة.'**
  String get guideQiblaBody;

  /// No description provided for @walkAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية للتدبّر'**
  String get walkAyahTitle;

  /// No description provided for @walkAyahBody.
  ///
  /// In ar, this message translates to:
  /// **'آيات تتجدّد كل يوم، اسحب بينها واضغط «تدبّرها» لتكتب وقفتك.'**
  String get walkAyahBody;

  /// No description provided for @walkQuranTitle.
  ///
  /// In ar, this message translates to:
  /// **'مصحفك ورحلتك'**
  String get walkQuranTitle;

  /// No description provided for @walkQuranBody.
  ///
  /// In ar, this message translates to:
  /// **'تابع القراءة من حيث توقفت، ومن هنا تبدأ ختمتك وترى تقدّمك.'**
  String get walkQuranBody;

  /// No description provided for @walkSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في كل شيء'**
  String get walkSearchTitle;

  /// No description provided for @walkSearchBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة فتجد الآيات وملاحظاتك ووقفاتك في مكان واحد.'**
  String get walkSearchBody;

  /// No description provided for @walkTabsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنقّل بين الأقسام'**
  String get walkTabsTitle;

  /// No description provided for @walkTabsBody.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية والمصحف والاستغفار والأدعية، بلمسة واحدة من أي مكان.'**
  String get walkTabsBody;

  /// No description provided for @walkMoreTitle.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get walkMoreTitle;

  /// No description provided for @walkMoreBody.
  ///
  /// In ar, this message translates to:
  /// **'هنا روابط الآيات ومسارات التدبّر والحفظ والكتب وكل الأقسام.'**
  String get walkMoreBody;

  /// No description provided for @walkTipTitle.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة أخيرة'**
  String get walkTipTitle;

  /// No description provided for @walkTipBody.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تعرف ما يفعله زر، فاضغط عليه مطوّلاً ليظهر لك وصفه.'**
  String get walkTipBody;

  /// No description provided for @walkReplay.
  ///
  /// In ar, this message translates to:
  /// **'دليل الشاشة الرئيسية'**
  String get walkReplay;

  /// No description provided for @walkReplayHint.
  ///
  /// In ar, this message translates to:
  /// **'أعد التعرّف على أهم ما في الرئيسية'**
  String get walkReplayHint;

  /// No description provided for @fileSavedToDevice.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ في الجهاز'**
  String get fileSavedToDevice;

  /// No description provided for @sleepAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get sleepAdhkar;

  /// No description provided for @wakingAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الاستيقاظ'**
  String get wakingAdhkar;

  /// No description provided for @afterPrayerAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار بعد الصلاة'**
  String get afterPrayerAdhkar;

  /// No description provided for @mosqueAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المسجد'**
  String get mosqueAdhkar;

  /// No description provided for @tourReplay.
  ///
  /// In ar, this message translates to:
  /// **'جولة في التطبيق'**
  String get tourReplay;

  /// No description provided for @tourReplayHint.
  ///
  /// In ar, this message translates to:
  /// **'شاهد الجولة التعريفية من جديد'**
  String get tourReplayHint;

  /// No description provided for @guidesReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة عرض الشروحات'**
  String get guidesReset;

  /// No description provided for @guidesResetHint.
  ///
  /// In ar, this message translates to:
  /// **'يشرح كل قسم نفسه عند دخوله التالي'**
  String get guidesResetHint;

  /// No description provided for @guidesResetDone.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر الشروحات من جديد'**
  String get guidesResetDone;

  /// No description provided for @guideReflections1Title.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ وقفتك من الآية'**
  String get guideReflections1Title;

  /// No description provided for @guideReflections1Body.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطوّلاً على أي آية في المصحف، ثم اختر «وقفة تدبر» من وسط القائمة.'**
  String get guideReflections1Body;

  /// No description provided for @guideReflections2Title.
  ///
  /// In ar, this message translates to:
  /// **'أربعة أسئلة تفتح المعنى'**
  String get guideReflections2Title;

  /// No description provided for @guideReflections2Body.
  ///
  /// In ar, this message translates to:
  /// **'أجب عمّا يحضرك ولو بكلمة: ما الذي توقّفت عنده، وماذا تقول لك الآية، وماذا حرّكت فيك، وما العمل الذي تدعوك إليه.'**
  String get guideReflections2Body;

  /// No description provided for @guideReflections3Title.
  ///
  /// In ar, this message translates to:
  /// **'وقفاتك محفوظة هنا'**
  String get guideReflections3Title;

  /// No description provided for @guideReflections3Body.
  ///
  /// In ar, this message translates to:
  /// **'تجد كل وقفة في «وقفاتي»، وتظهر زهرة التدبّر فوق رقم الآية في المصحف لتعود إليها.'**
  String get guideReflections3Body;

  /// No description provided for @guideLinks1Title.
  ///
  /// In ar, this message translates to:
  /// **'موضوع يجمع الآيات'**
  String get guideLinks1Title;

  /// No description provided for @guideLinks1Body.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رابطاً باسم موضوع تريد تدبّره، مثل أبواب الرزق أو الصبر أو الرحمة.'**
  String get guideLinks1Body;

  /// No description provided for @guideLinks2Title.
  ///
  /// In ar, this message translates to:
  /// **'آيات يجمعها معنى واحد'**
  String get guideLinks2Title;

  /// No description provided for @guideLinks2Body.
  ///
  /// In ar, this message translates to:
  /// **'أضف آيات الموضوع، واكتب عند كل آية ما فهمته منها.'**
  String get guideLinks2Body;

  /// No description provided for @guideLinks3Title.
  ///
  /// In ar, this message translates to:
  /// **'انظر الصورة كاملة'**
  String get guideLinks3Title;

  /// No description provided for @guideLinks3Body.
  ///
  /// In ar, this message translates to:
  /// **'اعرض الرابط شبكةً ترى فيها كيف تتكامل الآيات، أو قائمة تقرؤها بالترتيب.'**
  String get guideLinks3Body;

  /// No description provided for @guidePathways1Title.
  ///
  /// In ar, this message translates to:
  /// **'رحلة تدبّر يوماً بيوم'**
  String get guidePathways1Title;

  /// No description provided for @guidePathways1Body.
  ///
  /// In ar, this message translates to:
  /// **'اختر مساراً في موضوع، وفي كل يوم خطوة صغيرة واحدة لا تثقل عليك.'**
  String get guidePathways1Body;

  /// No description provided for @guidePathways2Title.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم وسؤالها'**
  String get guidePathways2Title;

  /// No description provided for @guidePathways2Body.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الآية بتمهّل، ثم أجب عن سؤال اليوم بما يحضرك.'**
  String get guidePathways2Body;

  /// No description provided for @guidePathways3Title.
  ///
  /// In ar, this message translates to:
  /// **'خطوة بعد خطوة'**
  String get guidePathways3Title;

  /// No description provided for @guidePathways3Body.
  ///
  /// In ar, this message translates to:
  /// **'كلما أتممت يوماً أُضيء الذي بعده، ويحفظ التطبيق موضعك لتكمل متى عدت.'**
  String get guidePathways3Body;

  /// No description provided for @guideMushafTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get guideMushafTitle;

  /// No description provided for @guideMushafBody.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لتقليب الصفحات، واضغط مطوّلاً على الآية لقائمتها. وتظهر علاماتك من حفظ وملاحظة وتدبّر فوق رقم الآية.'**
  String get guideMushafBody;

  /// No description provided for @guideMemorizationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ والمراجعة'**
  String get guideMemorizationTitle;

  /// No description provided for @guideMemorizationBody.
  ///
  /// In ar, this message translates to:
  /// **'أضف الآيات التي تحفظها، وراجع كل يوم ما حان وقته. ما تتقنه تتباعد مراجعته، وما تنساه يعود إليك قريباً.'**
  String get guideMemorizationBody;

  /// No description provided for @guideWordMeaningsTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات'**
  String get guideWordMeaningsTitle;

  /// No description provided for @guideWordMeaningsBody.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات الغريبة بترتيب المصحف. ابحث بكلمة أو معنى، أو اختر سورة لتراها وحدها.'**
  String get guideWordMeaningsBody;

  /// No description provided for @guideNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get guideNotesTitle;

  /// No description provided for @guideNotesBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب خاطرتك على آية أو خاطرة عامة، وصدّرها PDF أو اجمعها في دفتر تدبّر.'**
  String get guideNotesBody;

  /// No description provided for @guideSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get guideSearchTitle;

  /// No description provided for @guideSearchBody.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في القرآن وكل ما حفظته في 11 قسماً معاً.'**
  String get guideSearchBody;

  /// No description provided for @guideBooksTitle.
  ///
  /// In ar, this message translates to:
  /// **'الكتب والملازم'**
  String get guideBooksTitle;

  /// No description provided for @guideBooksBody.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الملازم والكتب داخل التطبيق، وتابع من حيث توقفت.'**
  String get guideBooksBody;

  /// No description provided for @guideDuasTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get guideDuasTitle;

  /// No description provided for @guideDuasBody.
  ///
  /// In ar, this message translates to:
  /// **'أدعية القرآن والسنة وأهل البيت، وأذكار يومية بعدّاد. انسخ الدعاء أو افتحه في المصحف.'**
  String get guideDuasBody;

  /// No description provided for @guideTasbeehTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسبيح والاستغفار'**
  String get guideTasbeehTitle;

  /// No description provided for @guideTasbeehBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الدائرة للعدّ، واختر الهدف ٣٣ أو ١٠٠، ويمكن أن يعدّ عنك تلقائياً وينتقل إلى الذكر التالي.'**
  String get guideTasbeehBody;

  /// No description provided for @guideJourneyTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلتي والختمة'**
  String get guideJourneyTitle;

  /// No description provided for @guideJourneyBody.
  ///
  /// In ar, this message translates to:
  /// **'ضع خطة ختمة يتابعها موضع قراءتك تلقائياً، وراقب سلسلة أيامك وخريطة ما قرأت من المصحف.'**
  String get guideJourneyBody;

  /// No description provided for @guideRemindersTitle.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get guideRemindersTitle;

  /// No description provided for @guideRemindersBody.
  ///
  /// In ar, this message translates to:
  /// **'اضبط تذكيراً لوردك أو أذكارك في الوقت الذي يناسبك، ويصلك ولو كان التطبيق مغلقاً.'**
  String get guideRemindersBody;

  /// No description provided for @guideBackupTitle.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get guideBackupTitle;

  /// No description provided for @guideBackupBody.
  ///
  /// In ar, this message translates to:
  /// **'صدّر نسخة مشفّرة بكلمة سرّ من بياناتك واحفظها خارج الهاتف، لتستعيدها إن غيّرت جهازك.'**
  String get guideBackupBody;

  /// No description provided for @guideStep.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step} من {total}'**
  String guideStep(String step, String total);

  /// No description provided for @widgetPortionLeft.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: بقي {left} من {portion} صفحة'**
  String widgetPortionLeft(String left, String portion);

  /// No description provided for @linksReordered.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة الترتيب تلقائيًا'**
  String get linksReordered;

  /// No description provided for @pdfFileMissing.
  ///
  /// In ar, this message translates to:
  /// **'ملف الـ PDF غير موجود على الجهاز.'**
  String get pdfFileMissing;

  /// No description provided for @attachedFileMissing.
  ///
  /// In ar, this message translates to:
  /// **'الملف المرفق غير موجود على الجهاز.'**
  String get attachedFileMissing;

  /// No description provided for @pdfReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة ملف الـ PDF: {error}'**
  String pdfReadFailed(String error);

  /// No description provided for @fileReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة محتوى الملف: {error}'**
  String fileReadFailed(String error);

  /// No description provided for @pdfShowFailed.
  ///
  /// In ar, this message translates to:
  /// **'خطأ أثناء عرض الملف: {error}'**
  String pdfShowFailed(String error);

  /// No description provided for @pdfPageFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الصفحة {page}: {error}'**
  String pdfPageFailed(String page, String error);

  /// No description provided for @booksCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} كتاب/ملزمة'**
  String booksCountLabel(String count);

  /// No description provided for @mushafMenu.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get mushafMenu;

  /// No description provided for @pageMeaningsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'معاني كلمات الصفحة'**
  String get pageMeaningsTooltip;

  /// No description provided for @previousPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة السابقة'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التالية'**
  String get nextPage;

  /// No description provided for @meaningsBadge.
  ///
  /// In ar, this message translates to:
  /// **'المعاني ({count})'**
  String meaningsBadge(String count);

  /// No description provided for @enterPageRange.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الصفحة بين ١ و ٦٠٤'**
  String get enterPageRange;

  /// No description provided for @doneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get doneLabel;

  /// No description provided for @wordMeaningsCount.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات ({count})'**
  String wordMeaningsCount(String count);

  /// No description provided for @hideBar.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الشريط'**
  String get hideBar;

  /// No description provided for @pageWordMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني كلمات صفحة {page}'**
  String pageWordMeanings(String page);

  /// No description provided for @wordsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} كلمات'**
  String wordsCount(String count);

  /// No description provided for @closePanel.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق اللوحة'**
  String get closePanel;

  /// No description provided for @noPageMeanings.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كلمات تحتاج إلى شرح في هذه الصفحة'**
  String get noPageMeanings;

  /// No description provided for @stopAlarm.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المنبه'**
  String get stopAlarm;

  /// No description provided for @testAlarmTitle.
  ///
  /// In ar, this message translates to:
  /// **'منبه تجريبي — تَدْبِير'**
  String get testAlarmTitle;

  /// No description provided for @testNoticeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعار تجريبي — تَدْبِير'**
  String get testNoticeTitle;

  /// No description provided for @testAlarmBody.
  ///
  /// In ar, this message translates to:
  /// **'هذا تنبيه كالمنبه برنين مستمر — اضغط «إيقاف المنبه» أو «فتح المصحف»'**
  String get testAlarmBody;

  /// No description provided for @testNoticeBody.
  ///
  /// In ar, this message translates to:
  /// **'نظام الإشعارات يعمل بنجاح في تطبيق تَدْبِير'**
  String get testNoticeBody;

  /// No description provided for @reminderDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد القرآن الكريم'**
  String get reminderDefaultTitle;

  /// No description provided for @scrollDown.
  ///
  /// In ar, this message translates to:
  /// **'مرّر للأسفل'**
  String get scrollDown;

  /// No description provided for @pageAbbrOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'ص {page} من {total}'**
  String pageAbbrOfTotal(String page, String total);

  /// No description provided for @tourTodayPortion.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get tourTodayPortion;

  /// No description provided for @tourPagesToday.
  ///
  /// In ar, this message translates to:
  /// **'٤ من ٥ صفحات'**
  String get tourPagesToday;

  /// No description provided for @tourSampleNote.
  ///
  /// In ar, this message translates to:
  /// **'التقوى تفتح أبواباً لا أراها'**
  String get tourSampleNote;

  /// No description provided for @tourRemembered.
  ///
  /// In ar, this message translates to:
  /// **'تذكّرت'**
  String get tourRemembered;

  /// No description provided for @tourForgot.
  ///
  /// In ar, this message translates to:
  /// **'نسيت'**
  String get tourForgot;

  /// No description provided for @tourNextReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة بعد ٣ أيام'**
  String get tourNextReview;

  /// No description provided for @tourMeaningLabel.
  ///
  /// In ar, this message translates to:
  /// **'المعنى'**
  String get tourMeaningLabel;

  /// No description provided for @tourBookSample.
  ///
  /// In ar, this message translates to:
  /// **'هدي القرآن'**
  String get tourBookSample;

  /// No description provided for @dhikrSubhanAllah.
  ///
  /// In ar, this message translates to:
  /// **'سبحان الله'**
  String get dhikrSubhanAllah;

  /// No description provided for @tourDuaQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tourDuaQuran;

  /// No description provided for @tourDuaSunnah.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get tourDuaSunnah;

  /// No description provided for @tourDuaAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get tourDuaAdhkar;
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
