import 'package:flutter/material.dart';

import '../core/utils/arabic_search_normalizer.dart';
import '../l10n/app_localizations.dart';

/// لغات الواجهة مع اتجاه النص لكل منها.
enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);

  final String code;
  final String label;
  final TextDirection direction;

  const AppLanguage(this.code, this.label, this.direction);

  /// اللغة المقابلة لرمز محفوظ، والعربية لأي رمز غير معروف.
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

/// نصوص الواجهة باللغتين، مأخوذة من ملفات ARB عبر gen-l10n.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  // تُولَّد الترجمات من lib/l10n/app_ar.arb و app_en.arb.
  static final AppLocalizations _ar = lookupAppLocalizations(
    const Locale('ar'),
  );
  static final AppLocalizations _en = lookupAppLocalizations(
    const Locale('en'),
  );
  AppLocalizations get _l => language == AppLanguage.arabic ? _ar : _en;

  bool get isArabic => language == AppLanguage.arabic;

  /// يكتب الأرقام بالأرقام العربية الهندية في الواجهة العربية.
  String digits(Object? value) =>
      isArabic ? ArabicSearchNormalizer.convertDigits('$value') : '$value';

  String _n(Object? value) => ArabicSearchNormalizer.convertDigits('$value');

  // هوية التطبيق
  String get appName => _l.appName;
  String get appTagline => _l.appTagline;

  // التنقل والأقسام الرئيسية
  String get home => _l.home;
  String get quran => _l.quran;
  String get notes => _l.notes;
  String get bookmarks => _l.bookmarks;
  String get highlights => _l.highlights;
  String get search => _l.search;
  String get settings => _l.settings;
  String get reminders => _l.reminders;
  String get ayahLinks => _l.ayahLinks;
  String get backup => _l.backup;
  String get duas => _l.duas;
  String get quranDuas => _l.quranDuas;
  String get tasbeehAndIstighfar => _l.tasbeehAndIstighfar;
  String get tasbeehSubtitle => _l.tasbeehSubtitle;
  String get booksAndBooklets => _l.booksAndBooklets;
  String get booksSubtitle => _l.booksSubtitle;
  String get about => _l.about;
  String get more => _l.more;

  // مقدمة التدبر
  String get tadbeerVerse =>
      'أَفَلَا يَتَدَبَّرُونَ الْقُرْآنَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَا';
  String get tadbeerVerseRef => _l.tadbeerVerseRef;

  String get tadbeerMessage => _l.tadbeerMessage;

  String get tadabburVerse => tadbeerVerse;

  // قارئ المصحف والقائمة الجانبية
  String pageNumber(int page) => _l.pageNumber(digits(page));

  String juzNumber(int juz) => _l.juzNumber(digits(juz));

  String hizbNumber(int hizb) => _l.hizbNumber(digits(hizb));

  String get surahs => _l.surahs;
  String get juzs => _l.juzs;
  String get jumpToPage => _l.jumpToPage;
  String get go => _l.go;
  String get cancel => _l.cancel;
  String get options => _l.options;

  // خريطة المصحف وسجل التدبر
  String get mushafMap => _l.mushafMap;
  String get mapTab => _l.mapTab;
  String get reflectionLog => _l.reflectionLog;
  String pagesTouched(int n) => _l.pagesTouched(digits(n));

  /// اسم حالة [PageActivity] في مفتاح الخريطة، بحسب ترتيبها.
  String activityLabel(int i) => isArabic
      ? const [
          'لم تُقرأ',
          'مقروءة',
          'محفوظة أو مميزة',
          'في الحفظ',
          'فيها تدبر',
        ][i]
      : const [
          'Not read',
          'Read',
          'Saved or highlighted',
          'Memorizing',
          'Reflected',
        ][i];
  String get noReflectionsYet => _l.noReflectionsYet;
  String get reflectionsEmptyHint => _l.reflectionsEmptyHint;
  String shortDate(DateTime d) => isArabic
      ? _n('${d.day}/${d.month}/${d.year}')
      : '${d.day}/${d.month}/${d.year}';

  // مسارات التدبر
  String get guidedPathways => _l.guidedPathways;
  String get guidedPathwaysHint => _l.guidedPathwaysHint;
  String daysOfTotal(int a, int b) => _l.daysOfTotal(digits(a), digits(b));
  String dayN(int n) => _l.dayN(digits(n));
  String get completeDay => _l.completeDay;
  String get pathwayUnlockHint => _l.pathwayUnlockHint;
  String get pathwayComplete => _l.pathwayComplete;

  // الحفظ
  String get memorization => _l.memorization;
  String versesMemorized(int n) => _l.versesMemorized(digits(n));
  String get memorizationHint => _l.memorizationHint;
  String reviewToday(int n) => _l.reviewToday(digits(n));
  String get nothingDueToday => _l.nothingDueToday;
  String get chooseSurahToMemorize => _l.chooseSurahToMemorize;
  String versesOfTotal(int a, int b) => _l.versesOfTotal(digits(a), digits(b));
  String get tapToReveal => _l.tapToReveal;
  String get needsReview => _l.needsReview;
  String get mastered => _l.mastered;
  String get sessionDone => _l.sessionDone;
  String sessionSummary(int a, int b) =>
      _l.sessionSummary(digits(a), digits(b));

  // آية اليوم
  String get ayahOfTheDay => _l.ayahOfTheDay;
  String get reflectOnIt => _l.reflectOnIt;

  // الختمة المتتابعة
  String get fromMushafStart => _l.fromMushafStart;
  String fromMyPosition(int page) => _l.fromMyPosition(digits(page));
  String reachedPage(int page) => _l.reachedPage(digits(page));
  String get setKhatmaPosition => _l.setKhatmaPosition;
  String get pageNumberLabel => _l.pageNumberLabel;
  String get markPortionDone => _l.markPortionDone;

  String get reflectionsThisMonth => _l.reflectionsThisMonth;

  String get portionReminderPrompt => _l.portionReminderPrompt;
  String portionReminderTitle(int pages) =>
      _l.portionReminderTitle(digits(pages));
  String get portionReminderSet => _l.portionReminderSet;
  String portionLeftTitle(int pages) => _l.portionLeftTitle(digits(pages));
  String get portionLeftBody => _l.portionLeftBody;
  String get adhkarSetCompleted => _l.adhkarSetCompleted;

  /// يملأ الودجت الأرقام بنفسه، فتبقى هنا متغيرات.
  String get widgetPortionLeftTemplate =>
      _l.widgetPortionLeft('{left}', '{portion}');
  String get widgetPortionDone => _l.widgetPortionDone;
  String get widgetAyahTitle => _l.widgetAyahTitle;
  String get themePickerTitle => _l.themePickerTitle;
  String get themePickerHint => _l.themePickerHint;
  String get themePickerStart => _l.themePickerStart;
  String get themeAuto => _l.themeAuto;
  String get mushafStyleMadinahHint => _l.mushafStyleMadinahHint;
  String get mushafStyleTextHint => _l.mushafStyleTextHint;
  String get pageSize => _l.pageSize;
  String get khatmaStartNow => _l.khatmaStartNow;
  String get askNameTitle => _l.askNameTitle;
  String get askNameHint => _l.askNameHint;
  String get askNameField => _l.askNameField;
  String get skipStep => _l.skipStep;
  String get yourName => _l.yourName;
  String get yourNameNotSet => _l.yourNameNotSet;
  String get reminderQuranBody => _l.reminderQuranBody;
  String get reminderAdhkarBody => _l.reminderAdhkarBody;
  String get myReflections => _l.myReflections;
  String get myReflectionsSubtitle => _l.myReflectionsSubtitle;
  String get reflectionsAll => _l.reflectionsAll;
  String get reflectionsCommitments => _l.reflectionsCommitments;
  String get noReflectionsHint => _l.noReflectionsHint;
  String get noCommitmentsYet => _l.noCommitmentsYet;
  String get commitmentDid => _l.commitmentDid;
  String get commitmentNotYet => _l.commitmentNotYet;
  String get commitmentPending => _l.commitmentPending;
  String get commitmentQuestion => _l.commitmentQuestion;
  String commitmentSaidAt(String reference) => _l.commitmentSaidAt(reference);

  /// يوجّه [text] إلى القارئ باسمه ("أحمد، …")؛ الاسم أولاً لتناسب الصيغة
  /// الجميع.
  String toReader(String name, String text) {
    final n = name.trim();
    if (n.isEmpty || text.isEmpty) return text;
    if (isArabic) return '$n، $text';
    return '$n, ${text[0].toLowerCase()}${text.substring(1)}';
  }

  /// نسبة مئوية بأرقام اللغة الحالية (١٢٠٪ / 120%).
  String percent(int value) => isArabic ? '${digits(value)}٪' : '$value%';
  String get addVerseTitle => _l.addVerseTitle;
  String get addVerseSearchHint => _l.addVerseSearchHint;
  String get addVerseFromSaved => _l.addVerseFromSaved;
  String get addVersePickBySurah => _l.addVersePickBySurah;
  String get addVerseSurah => _l.addVerseSurah;
  String get addVerseAyah => _l.addVerseAyah;
  String get addVerseNote => _l.addVerseNote;
  String get addVerseAlready => _l.addVerseAlready;
  String get addVerseAction => _l.addVerseAction;
  String get addVerseChange => _l.addVerseChange;
  String get addVerseNoResults => _l.addVerseNoResults;
  String get addVerseSearchSurah => _l.addVerseSearchSurah;
  String get mushafStyleTitle => _l.mushafStyleTitle;
  String get mushafStyleMadinah => _l.mushafStyleMadinah;
  String get mushafStyleText => _l.mushafStyleText;
  String get qcfAttribution => _l.qcfAttribution;

  String get reflectedToday => _l.reflectedToday;

  String get addToMemorization => _l.addToMemorization;
  String get removeFromMemorization => _l.removeFromMemorization;

  String get journeyBackupSection => _l.journeyBackupSection;

  String get dailyJourney => _l.dailyJourney;

  String get adhkarReminders => _l.adhkarReminders;
  String get morningAdhkarReminder => _l.morningAdhkarReminder;
  String get eveningAdhkarReminder => _l.eveningAdhkarReminder;

  String get monthlyReport => _l.monthlyReport;
  String get activeDaysLabel => _l.activeDaysLabel;
  String get reflectionsLabel => _l.reflectionsLabel;
  String get memorizedLabel => _l.memorizedLabel;
  String monthTitle(int month, int year) {
    const ar = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return isArabic ? '${ar[month - 1]} ${_n(year)}' : '${en[month - 1]} $year';
  }

  String get continueWhereYouLeft => _l.continueWhereYouLeft;
  String get adhkarKind => _l.adhkarKind;
  String chapterN(int n) => _l.chapterN(digits(n));

  String get weeklyGoals => _l.weeklyGoals;
  String get editGoals => _l.editGoals;
  String get pagesGoal => _l.pagesGoal;
  String get reflectionsGoal => _l.reflectionsGoal;

  String get appColorTheme => isArabic ? 'لون التطبيق' : 'App color';

  /// اسم [AppColorTheme] بحسب ترتيبه.
  String colorThemeName(int i) => isArabic
      ? const ['كحلي', 'زمردي', 'عنابي', 'بني خشبي', 'تركوازي'][i]
      : const ['Navy', 'Emerald', 'Burgundy', 'Brown', 'Teal'][i];

  // وضع التأمل
  String get focusMode => _l.focusMode;
  String get breathe => _l.breathe;
  String get breatheIn => _l.breatheIn;
  String get breatheOut => _l.breatheOut;
  String get swipeForNextAyah => _l.swipeForNextAyah;

  // رحلة القراءة والختمة
  String get myJourney => _l.myJourney;
  String get startKhatmaTitle => _l.startKhatmaTitle;
  String get startKhatmaHint => _l.startKhatmaHint;
  String daysCount(int d) => _l.daysCount(d, digits(d));
  String pagesPerDayHint(int n) => _l.pagesPerDayHint(digits(n));
  String get startKhatma => _l.startKhatma;
  String completedKhatmas(int n) => _l.completedKhatmas(digits(n));
  String get cancelKhatma => _l.cancelKhatma;
  String get cancelKhatmaConfirm => _l.cancelKhatmaConfirm;
  String get onTrack => _l.onTrack;
  String behindBy(int n) => _l.behindBy(digits(n));
  String khatmaInDays(int n) => _l.khatmaInDays(n, digits(n));
  String pagesOfMushaf(int n) => _l.pagesOfMushaf(digits(n));
  String dayOfPlan(int d, int total) => _l.dayOfPlan(digits(d), digits(total));
  String get todayPortion => _l.todayPortion;
  String pagesOfTarget(int a, int b) => _l.pagesOfTarget(digits(a), digits(b));
  String get keepReading => _l.keepReading;
  String continueFromPage(int p) => _l.continueFromPage(digits(p));
  String get streakDays => _l.streakDays;
  String get totalPagesRead => _l.totalPagesRead;
  String get khatmasLabel => _l.khatmasLabel;
  String get lastSevenDays => _l.lastSevenDays;

  /// اسم مختصر ليوم الأسبوع ([DateTime.weekday]: ١ = الإثنين).
  String weekdayShort(int weekday) => isArabic
      ? const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'][weekday - 1]
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
  String get close => _l.close;
  String get clearText => _l.clearText;
  String get decrease => _l.decrease;
  String get increase => _l.increase;
  String get sajdah => _l.sajdah;

  String ayahCount(int count) => _l.ayahCount(digits(count));

  // نافذة إجراءات الآية
  String get addNote => _l.addNote;
  String get saveBookmark => _l.saveBookmark;
  String get removeBookmark => _l.removeBookmark;
  String get continueReflection => _l.continueReflection;
  String get markAyah => _l.markAyah;
  String get unmarkAyah => _l.unmarkAyah;
  String get chooseSurah => _l.chooseSurah;
  String get searchSurahHint => _l.searchSurahHint;
  String get enlargeText => _l.enlargeText;
  String get textSmaller => _l.textSmaller;
  String get textLarger => _l.textLarger;
  String get defaultTextSize => _l.defaultTextSize;
  String get recitationDownloads => _l.recitationDownloads;
  String get downloadForOffline => _l.downloadForOffline;
  String get downloadedLabel => _l.downloadedLabel;
  String get downloadFailed => _l.downloadFailed;
  String get downloadSurah => _l.downloadSurah;
  String get cancelDownload => _l.cancelDownload;
  String get deleteDownload => _l.deleteDownload;
  String get deleteAllDownloads => _l.deleteAllDownloads;
  String deleteAllDownloadsConfirm(String name) =>
      _l.deleteAllDownloadsConfirm(name);
  String downloadsSize(String size) => _l.downloadsSize(size);
  String get downloadJuzAmma => _l.downloadJuzAmma;
  String get downloadsHint => _l.downloadsHint;
  String get listen => _l.listen;
  String get listenFromHere => _l.listenFromHere;
  String get audioSettings => _l.audioSettings;
  String get reciterLabel => _l.reciterLabel;
  String get lowerQuality => _l.lowerQuality;
  String get repeatEachAyah => _l.repeatEachAyah;
  String get pauseAfterAyah => _l.pauseAfterAyah;
  String get noPause => _l.noPause;
  String secondsShort(int n) => _l.secondsShort(digits(n));
  String get audioFailed => _l.audioFailed;
  String get nextAyah => _l.nextAyah;
  String get previousAyah => _l.previousAyah;
  String get playAudio => _l.playAudio;
  String get pauseAudio => _l.pauseAudio;
  String get stopAudio => _l.stopAudio;
  String get resting => _l.resting;
  String get audioSource => _l.audioSource;
  String get qibla => _l.qibla;
  String get qiblaUpdateLocation => _l.qiblaUpdateLocation;
  String get qiblaLocating => _l.qiblaLocating;
  String get qiblaFacing => _l.qiblaFacing;
  String qiblaTurnRight(int deg) => _l.qiblaTurnRight(digits(deg));
  String qiblaTurnLeft(int deg) => _l.qiblaTurnLeft(digits(deg));
  String get qiblaFromNorth => _l.qiblaFromNorth;
  String get qiblaKmToMakkah => _l.qiblaKmToMakkah;
  String get qiblaFromHere => _l.qiblaFromHere;
  String get qiblaFromLastLocation => _l.qiblaFromLastLocation;
  String get qiblaNoCompass => _l.qiblaNoCompass;
  String get qiblaCalibrate => _l.qiblaCalibrate;
  String get qiblaLocationOff => _l.qiblaLocationOff;
  String get qiblaTurnOnLocation => _l.qiblaTurnOnLocation;
  String get qiblaNeedsLocation => _l.qiblaNeedsLocation;
  String get qiblaAllowLocation => _l.qiblaAllowLocation;
  String get qiblaOpenSettings => _l.qiblaOpenSettings;
  String get qiblaLocationFailed => _l.qiblaLocationFailed;
  String get qiblaNorth => _l.qiblaNorth;
  String get qiblaEast => _l.qiblaEast;
  String get qiblaSouth => _l.qiblaSouth;
  String get qiblaWest => _l.qiblaWest;
  String streakAtRiskTitle(int n) => _l.streakAtRiskTitle(n, digits(n));
  String get streakAtRiskBody => _l.streakAtRiskBody;
  String get streakReminder => _l.streakReminder;
  String get streakReminderOff => _l.streakReminderOff;
  String streakReminderAt(String time) => _l.streakReminderAt(time);
  String get streakReminderPrompt => _l.streakReminderPrompt;
  String reflectionsCount(int count, String shown) =>
      _l.reflectionsCount(count, shown);
  String get highlight => _l.highlight;
  String get removeHighlight => _l.removeHighlight;
  String get copy => _l.copy;
  String get share => _l.share;
  String get shareAsImage => _l.shareAsImage;
  String get shareImage => _l.shareImage;
  String get cardSquare => _l.cardSquare;
  String get cardStory => _l.cardStory;
  String get cardDark => _l.cardDark;
  String get cardLight => _l.cardLight;
  String get saveToPhotos => _l.saveToPhotos;
  String get cardSaved => _l.cardSaved;
  String get cardSaveFailed => _l.cardSaveFailed;
  String get cardSaveDenied => _l.cardSaveDenied;
  String get copiedToClipboard => _l.copiedToClipboard;

  // الملاحظات
  String get newNote => _l.newNote;
  String get newFreeNote => _l.newFreeNote;
  String get noteTitle => _l.noteTitle;
  String get noteContent => _l.noteContent;
  String get save => _l.save;
  String get delete => _l.delete;
  String get deleteConfirmTitle => _l.deleteConfirmTitle;
  String get deleteConfirmMessage => _l.deleteConfirmMessage;
  String get exportPdf => _l.exportPdf;
  String get noNotesYet => _l.noNotesYet;
  String get freeNoteLabel => _l.freeNoteLabel;
  String get ayahNoteLabel => _l.ayahNoteLabel;
  String get goToAyah => _l.goToAyah;

  // الفواصل والتظليل
  String get noBookmarksYet => _l.noBookmarksYet;
  String get noHighlightsYet => _l.noHighlightsYet;
  String get bookmarksEmptyHint => _l.bookmarksEmptyHint;
  String get highlightsEmptyHint => _l.highlightsEmptyHint;
  String get openMushaf => _l.openMushaf;

  // البحث
  String get searchGlobalPlaceholder => _l.searchGlobalPlaceholder;
  String get searchAll => _l.searchAll;
  String get searchBookmarksHint => _l.searchBookmarksHint;
  String get searchHighlightsHint => _l.searchHighlightsHint;
  String get searchRemindersHint => _l.searchRemindersHint;
  String get searchNotesHint => _l.searchNotesHint;
  String get tadbeerSectionTitle => _l.tadbeerSectionTitle;
  String get wordMeanings => _l.wordMeanings;
  String get wordMeaningsScreenTitle => _l.wordMeaningsScreenTitle;
  String get approvedSourcesTitle => _l.approvedSourcesTitle;
  String get searchInAllSections => _l.searchInAllSections;
  String get filterSearchTitle => _l.filterSearchTitle;
  String get selectSearchSection => _l.selectSearchSection;
  String get noSearchResults => _l.noSearchResults;

  // التذكيرات
  String get addReminder => _l.addReminder;
  String get editReminder => _l.editReminder;
  String get reminderTitle => _l.reminderTitle;
  String get defaultReminderTitle => _l.defaultReminderTitle;
  String get reminderTime => _l.reminderTime;
  String get repeatDaily => _l.repeatDaily;
  String get repeatOnce => _l.repeatOnce;
  String get selectDays => _l.selectDays;
  String get noRemindersYet => _l.noRemindersYet;
  String get remindersEmptyHint => _l.remindersEmptyHint;

  // روابط الآيات
  String get newAyahLink => _l.newAyahLink;
  String get addToAyahLink => _l.addToAyahLink;
  String get networkView => _l.networkView;
  String get orderedView => _l.orderedView;
  String get autoLayout => _l.autoLayout;
  String get linkTitle => _l.linkTitle;
  String get linkTitleHint => _l.linkTitleHint;
  String get linkDescription => _l.linkDescription;
  String get linkDescriptionHint => _l.linkDescriptionHint;
  String get addVerse => _l.addVerse;
  String get resetToCenter => _l.resetToCenter;
  String get noAyahLinksYet => _l.noAyahLinksYet;
  String get ayahLinksSubtitle => _l.ayahLinksSubtitle;

  String versesCount(int count) => _l.versesCount(digits(count));

  // النسخ الاحتياطي والاستعادة
  String get exportBackup => _l.exportBackup;
  String get restoreBackup => _l.restoreBackup;
  String get restoreWarningTitle => _l.restoreWarningTitle;
  String get restoreWarningMessage => _l.restoreWarningMessage;
  String get confirmRestore => _l.confirmRestore;
  String get saveToDeviceFiles => _l.saveToDeviceFiles;
  String get shareViaApps => _l.shareViaApps;
  String get backupSavedSuccess => _l.backupSavedSuccess;
  String get restoreSuccess => _l.restoreSuccess;
  String get corruptBackupError => _l.corruptBackupError;
  String get dataSaveFailed => _l.dataSaveFailed;
  String get dataLoadFailed => _l.dataLoadFailed;
  String get corruptItemsSkipped => _l.corruptItemsSkipped;

  String get enterBackupPassword => _l.enterBackupPassword;

  // الإعدادات
  String get appearance => _l.appearance;
  String get themeMode => _l.themeMode;
  String get light => _l.light;
  String get dark => _l.dark;
  String get system => _l.system;
  String get languageTitle => _l.languageTitle;
  String get fontSize => _l.fontSize;
  String get mushafPaperTone => _l.mushafPaperTone;
  String get paperClassic => _l.paperClassic;
  String get paperSepia => _l.paperSepia;
  String get aboutContent => _l.aboutContent;

  // بطاقات الشاشة الرئيسية
  String get resumeReading => _l.resumeReading;
  String get additionalTools => _l.additionalTools;
  String get quranAndSunnahDuas => _l.quranAndSunnahDuas;
  String get quranDuasTitle => _l.quranDuasTitle;
  String get quranDuasSubtitle => _l.quranDuasSubtitle;
  String duasCountBadge(dynamic count) => _l.duasCountBadge(digits(count));
  String adhkarCountBadge(dynamic count) => _l.adhkarCountBadge(digits(count));
  String get morningEveningAdhkarTitle => _l.morningEveningAdhkarTitle;
  String get morningEveningAdhkarSubtitle => _l.morningEveningAdhkarSubtitle;
  String get ahlulbaytDuasTitle => _l.ahlulbaytDuasTitle;
  String get ahlulbaytDuasSubtitle => _l.ahlulbaytDuasSubtitle;
  String get sunnahDuasTitle => _l.sunnahDuasTitle;
  String get sunnahDuasSubtitle => _l.sunnahDuasSubtitle;
  String get jawamiDuasTitle => _l.jawamiDuasTitle;
  String get jawamiDuasSubtitle => _l.jawamiDuasSubtitle;
  String get wordsOfQuran => _l.wordsOfQuran;
  String get yourThoughtsAndReflections => _l.yourThoughtsAndReflections;
  String get connectionsAndThemes => _l.connectionsAndThemes;
  String get dailyPortion => _l.dailyPortion;
  String get tadbeerLibrary => _l.tadbeerLibrary;
  String get offlineQuranAndReflection => _l.offlineQuranAndReflection;

  // صيغ المراجع القرآنية
  String readingPosition(String surahName, dynamic page) =>
      _l.readingPosition(surahName, digits(page));
  String ayahReference(String surahName, dynamic ayahNumber) =>
      _l.ayahReference(surahName, digits(ayahNumber));
  String surahTitle(String surahName) => _l.surahTitle(surahName);
  String ayahTitle(dynamic ayahNumber) => _l.ayahTitle(digits(ayahNumber));
  String pageAbbr(dynamic page) => _l.pageAbbr(digits(page));
  String juzAbbr(dynamic juz) => _l.juzAbbr(digits(juz));
  String get meccan => _l.meccan;
  String get medinan => _l.medinan;
  String ayahsCount(dynamic count) => _l.ayahsCount(digits(count));
  String get searchSurahsHint => _l.searchSurahsHint;
  String get searchWordMeaningsHint => _l.searchWordMeaningsHint;
  String get allSurahsWithCount => _l.allSurahsWithCount;
  String wordSearchResultsCount(dynamic count) =>
      _l.wordSearchResultsCount(digits(count));
  String get noWordsFound => _l.noWordsFound;
  String get noWordsFoundSubtitle => _l.noWordsFoundSubtitle;
  String get lexicalMeaningTitle => _l.lexicalMeaningTitle;
  String get verifiedDocumentation => _l.verifiedDocumentation;
  String surahAyahPageReference(
    String surahName,
    dynamic ayahNumber,
    dynamic page,
  ) => _l.surahAyahPageReference(surahName, digits(ayahNumber), digits(page));

  // الإجراءات والحوارات العامة
  String get edit => _l.edit;
  String get editNote => _l.editNote;
  String get tadbeerPause => _l.tadbeerPause;
  String get ayahLink => _l.ayahLink;
  String get exportTadbeerJournal => _l.exportTadbeerJournal;
  String get continueLabel => _l.continueLabel;
  String get doNotShowAgain => _l.doNotShowAgain;
  String get curatedPathways => _l.curatedPathways;
  String get importFromQrCode => _l.importFromQrCode;
  String get searchAyahLinksHint => _l.searchAyahLinksHint;
  String get noAyahLinkSearchResults => _l.noAyahLinkSearchResults;
  String get tryAnotherAyahLinkSearch => _l.tryAnotherAyahLinkSearch;
  String linkedAyahsCount(dynamic count) => _l.linkedAyahsCount(digits(count));
  String get importPathway => _l.importPathway;
  String get editTitleAndDescription => _l.editTitleAndDescription;
  String get deleteAyahLink => _l.deleteAyahLink;

  // الإعدادات وإدارة البيانات
  String get typographyAndReading => _l.typographyAndReading;
  String get quranFontFamily => _l.quranFontFamily;
  String fontSizePoints(dynamic points) => _l.fontSizePoints(digits(points));
  String get resetToDefault => _l.resetToDefault;
  String resetToDefaultWithVal(dynamic val) =>
      _l.resetToDefaultWithVal(digits(val));
  String get applicationSection => _l.applicationSection;
  String get dataSection => _l.dataSection;
  String get dailyRemindersSubtitle => _l.dailyRemindersSubtitle;
  String get backupSubtitle => _l.backupSubtitle;
  String get resetData => _l.resetData;
  String get resetDataSubtitle => _l.resetDataSubtitle;
  String get confirmReset => _l.confirmReset;
  String get resetSuccess => _l.resetSuccess;
  String get resetWarningMessage => _l.resetWarningMessage;
  String get versionInfo => _l.versionInfo;
  String get sourcesAndCredits => _l.sourcesAndCredits;

  String get sourcesAndCreditsDetails => isArabic
      ? '• نص القرآن الكريم: مشروع تنزيل (Tanzil Project - https://tanzil.net) بالنص العثماني المعتمد برخصة المشاع الإبداعي (CC BY 3.0 — يُمنع التعديل).\n'
            '• الخطوط القرآنية المفتوحة المصدر: خط شهرزاد الجديد (Scheherazade New)، خط نوتو نسخ (Noto Naskh Arabic)، خط هرمتان (Harmattan)، خط لطيف (Lateef)، وخط أميري القرآني (AmiriQuran & Amiri) برخصة الخطوط المفتوحة SIL Open Font License 1.1.\n'
            '• معاني كلمات القرآن: الموسوعة القرآنية (Quranpedia.net — نسخة البيانات 2026-10-10) وأمهات المعاجم اللغوية التراثية والمعاصرة (لسان العرب، مقاييس اللغة، التبيان، تذكرة الأريب، مفردات الراغب، والمعجم الوسيط).\n'
            '• مكتبة الكتب والملازم التدبرية: ملازم هدي القرآن الكريم للسيد حسين بدر الدين الحوثي (86 ملزمة موثقة كاملة)، وأمهات كتب تراث وأدعية أهل البيت عليهم السلام (الصحيفة السجادية، رسالة الحقوق، نهج البلاغة، تحف العقول)، وكتب علوم وتدبر القرآن المفتوحة (الآجري، النووي).\n'
            '• الأدعية والأذكار والتسبيح: 88 دعاءً قرآنياً مرتبة حسب المصحف، وحصن المسلم لأذكار الصباح والمساء، وباقة الاستغفار والتسبيح (49 صيغة مأثورة موثقة)، وأدعية أهل البيت والسنة النبوية الشريفة.\n'
            '• ترخيص التطبيق: مشروع مفتوح المصدر بالكامل تحت رخصة MIT License.\n'
            '• خط مصحف المدينة: خطوط صفحات المصحف (QCF) من مجمع الملك فهد لطباعة المصحف الشريف، وتخطيط الأسطر من بيانات Quran.com.\n'
            '• الخصوصية والأمان المحلي: التطبيق يعمل محلياً بالكامل (100% Offline) دون أي اتصال خارجي أو خوادم أو تتبع أو إعلانات، مع تشفير النسخ الاحتياطية بمعيار AES-256.'
      : '• Holy Quran Text: Tanzil Project (https://tanzil.net) authentic text in Uthmani script under Creative Commons Attribution 3.0 (CC BY 3.0 — modification strictly prohibited).\n'
            '• Open-Source Quranic Typography: Scheherazade New, Noto Naskh Arabic, Harmattan, Lateef, and Amiri Quran (AmiriQuran & Amiri) under SIL Open Font License 1.1.\n'
            '• Quran Vocabulary Lexicon: Quranic Encyclopedia (Quranpedia.net — release 2026-10-10) and classical & modern Arabic dictionaries (Lisan al-Arab, Maqayis al-Lughah, Al-Tibyan, Tadhkirat al-Arib, Mufradat al-Raghib, and Al-Mu\'jam al-Wasit).\n'
            '• Contemplation Books & Pamphlets Library: Lessons from the Guidance of the Holy Quran by Sayyed Hussein Badreddin al-Houthi (86 documented pamphlets), classical Ahlulbayt heritage & supplications (Al-Sahifah al-Sajjadiyah, Risalat al-Huquq, Nahj al-Balagha, Tuhaf al-Uqul), and Quranic sciences treatises (Al-Ajurri, Al-Nawawi).\n'
            '• Supplications, Adhkar & Tasbeeh: 88 Quranic duas arranged in Mushaf order, Hisn al-Muslim morning and evening adhkar, Tasbeeh & Istighfar sanctuary (49 authenticated formulas), and supplications from Ahlulbayt and the Noble Sunnah.\n'
            '• Application License: 100% free and open-source project licensed under the MIT License.\n'
            '• Madinah Mushaf script: page fonts (QCF) by the King Fahd Glorious Quran Printing Complex, with line layout from Quran.com data.\n'
            '• Local Privacy & Security: Operates 100% offline with zero external connections, servers, tracking, or ads, featuring local AES-256 backup encryption.';
  String get openSourceLicenses => _l.openSourceLicenses;

  String get privacyPolicy => _l.privacyPolicy;

  String get privacyPolicyTitle => _l.privacyPolicyTitle;

  String get privacyPolicySubtitle => _l.privacyPolicySubtitle;

  // إعداد التذكيرات
  String get alertType => _l.alertType;
  String get notificationAlert => _l.notificationAlert;
  String get notificationSubtitle => _l.notificationSubtitle;
  String get alarmAlert => _l.alarmAlert;
  String get alarmSubtitle => _l.alarmSubtitle;
  String get repeatMode => _l.repeatMode;
  String get daySat => _l.daySat;
  String get daySun => _l.daySun;
  String get dayMon => _l.dayMon;
  String get dayTue => _l.dayTue;
  String get dayWed => _l.dayWed;
  String get dayThu => _l.dayThu;
  String get dayFri => _l.dayFri;
  String get testAlertTooltip => _l.testAlertTooltip;
  String get testNotificationNow => _l.testNotificationNow;
  String get testAlarmNow => _l.testAlarmNow;
  String get testAlarmSentSuccess => _l.testAlarmSentSuccess;
  String get testNotificationSentSuccess => _l.testNotificationSentSuccess;
  String get testAlertPermissionError => _l.testAlertPermissionError;
  String reminderScheduledSuccess(String mode) =>
      _l.reminderScheduledSuccess(mode);
  String get specificDays => _l.specificDays;

  // إعداد النسخ الاحتياطي
  String get exportBackupSubtitle => _l.exportBackupSubtitle;
  String get restoreBackupSubtitle => _l.restoreBackupSubtitle;
  String get restoreFailed => _l.restoreFailed;
  String get selectBackupLocation => _l.selectBackupLocation;
  String get backupCreateFailed => _l.backupCreateFailed;
  String errorSavingFile(dynamic err) => _l.errorSavingFile('$err');

  // الأدعية والأذكار
  String get viewAyah => _l.viewAyah;
  String get duaCopiedSuccess => _l.duaCopiedSuccess;
  String get searchDuasHint => _l.searchDuasHint;
  String get noDuasFound => _l.noDuasFound;
  String get allDuasFilter => _l.allDuasFilter;
  String get morningAdhkar => _l.morningAdhkar;
  String get eveningAdhkar => _l.eveningAdhkar;
  String get resetCounters => _l.resetCounters;
  String get adhkarCountersResetSuccess => _l.adhkarCountersResetSuccess;
  String get dhikrCopiedSuccess => _l.dhikrCopiedSuccess;
  String dhikrIndex(dynamic index) => _l.dhikrIndex(digits(index));
  String get copyDhikr => _l.copyDhikr;
  String get completed => _l.completed;
  String remainingCount(dynamic count) => _l.remainingCount(digits(count));
  String get once => _l.once;

  // أدعية أهل البيت
  String get searchAhlulbaytHint => _l.searchAhlulbaytHint;
  String ahlulbaytDuasCountBadge(dynamic count) =>
      _l.ahlulbaytDuasCountBadge(digits(count));
  String get ahlulbaytDuasScreenTitle => _l.ahlulbaytDuasScreenTitle;
  String get copyFullDua => _l.copyFullDua;
  String get fullDuaCopiedSuccess => _l.fullDuaCopiedSuccess;
  String get decreaseFontSize => _l.decreaseFontSize;
  String get increaseFontSize => _l.increaseFontSize;
  String get fullAuthenticText => _l.fullAuthenticText;
  String searchGeneralDuasHint(String title) => _l.searchGeneralDuasHint(title);
  String generalDuasCountBadge(dynamic count) =>
      _l.generalDuasCountBadge(digits(count));
  String duaIndex(dynamic index) => _l.duaIndex(digits(index));
  String get copyDuaTooltip => _l.copyDuaTooltip;

  // قارئ الكتب والملازم
  String get tableOfContents => _l.tableOfContents;
  String bookIndexPrefix(String title) => _l.bookIndexPrefix(title);
  String pageOfTotal(dynamic page, dynamic total) =>
      _l.pageOfTotal(digits(page), digits(total));
  String sectionOfTotal(dynamic section, dynamic total) =>
      _l.sectionOfTotal(digits(section), digits(total));
  String get previousSection => _l.previousSection;
  String get nextSection => _l.nextSection;
  String get previousDua => _l.previousDua;
  String get nextDua => _l.nextDua;
  String get shareFile => _l.shareFile;
  String get copyContent => _l.copyContent;
  String get preparingDocument => _l.preparingDocument;
  String get retry => _l.retry;
  String get openAndReadPdf => _l.openAndReadPdf;
  String get noTextContentAvailable => _l.noTextContentAvailable;
  String searchSectionHint(String name) => _l.searchSectionHint(name);
  String get verifiedPamphletPdf => _l.verifiedPamphletPdf;
  String fullSectionsCount(dynamic count) =>
      _l.fullSectionsCount(digits(count));
  String get directTextReading => _l.directTextReading;
  String get textCopied => _l.textCopied;
  String get fileNotFound => _l.fileNotFound;
  String fileShareError(dynamic error) => _l.fileShareError('$error');
  String pdfReadError(dynamic error) => _l.pdfReadError('$error');
  String fileContentReadError(dynamic error) =>
      _l.fileContentReadError('$error');
  String get noTextContent => _l.noTextContent;
  String get textFile => _l.textFile;

  // عروض روابط الآيات
  String get openInQuran => _l.openInQuran;
  String get editVerseNote => _l.editVerseNote;
  String get removeVerseFromLink => _l.removeVerseFromLink;
  String get removeAyahFromLinkTitle => _l.removeAyahFromLinkTitle;
  String removeAyahFromLinkConfirm(dynamic ayah, dynamic surah) =>
      _l.removeAyahFromLinkConfirm(digits(ayah), digits(surah));
  String get reflectionNote => _l.reflectionNote;
  String get reflectionNoteColon => _l.reflectionNoteColon;
  String get ayahReflectionNoteTitle => _l.ayahReflectionNoteTitle;
  String get ayahReflectionNoteHint => _l.ayahReflectionNoteHint;
  String get noAyahsAddedToLink => _l.noAyahsAddedToLink;
  String get addAyahsToBuildMap => _l.addAyahsToBuildMap;
  String get addAyah => _l.addAyah;
  String get previous => _l.previous;
  String get next => _l.next;
  String get allCategories => _l.allCategories;

  // الاستغفار والتسبيح
  String get istighfar => _l.istighfar;
  String get tasbeeh => _l.tasbeeh;
  String get browseAllFormulas => _l.browseAllFormulas;
  String get resetCycleCounter => _l.resetCycleCounter;
  String get resetCycleCounterTitle => _l.resetCycleCounterTitle;
  String get resetCycleCounterConfirm => _l.resetCycleCounterConfirm;
  String get resetCycleAction => _l.resetCycleAction;
  String get tapAnywhereToCount => _l.tapAnywhereToCount;
  String targetCount(dynamic target) => _l.targetCount(digits(target));
  String get freeCount => _l.freeCount;
  String get countSettings => _l.countSettings;
  String get freeCountOpen => _l.freeCountOpen;
  String countTimes(dynamic count) => _l.countTimes(digits(count));
  String get autoAdvanceUponCompletion => _l.autoAdvanceUponCompletion;
  String get todayCount => isArabic ? 'استغفار وتسبيح اليوم' : "Today's Count";
  String get lifetimeTotalCount => _l.lifetimeTotalCount;
  String formulaXOfY(dynamic current, dynamic total) =>
      _l.formulaXOfY(digits(current), digits(total));
  String allFormulasCount(dynamic total) => _l.allFormulasCount(digits(total));
  String get copyDhikrTooltip => _l.copyDhikrTooltip;
  String get dhikrCopied => _l.dhikrCopied;
  String targetReachedAuto(dynamic target) =>
      _l.targetReachedAuto(digits(target));
  String targetReached(dynamic target) => _l.targetReached(digits(target));
  String get tasbeehAndIstighfarFormulas => _l.tasbeehAndIstighfarFormulas;
  String get searchDhikrHint => _l.searchDhikrHint;
  String get noMatchingFormulas => _l.noMatchingFormulas;
  String get swipeOrTapToChange => _l.swipeOrTapToChange;
  String get nextDhikr => _l.nextDhikr;
  String get previousDhikr => _l.previousDhikr;

  String get autoCount => _l.autoCount;

  String get stopAutoCount => _l.stopAutoCount;

  /// مدة الإيقاع لكل عَدّة، بالثواني.
  String smartPaceSeconds(dynamic seconds) =>
      _l.smartPaceSeconds(digits(seconds));

  String get decreasePace => _l.decreasePace;

  String get increasePace => _l.increasePace;

  // الكتب
  String get booksSectionEmpty => _l.booksSectionEmpty;
  String get booksSectionEmptyDescription => _l.booksSectionEmptyDescription;
}

/// يوفّر اللغة الحالية ونصوصها لكل الواجهة، ويعيد البناء عند تغيّر اللغة.
class AppLocalizationScope extends InheritedWidget {
  final AppLanguage currentLanguage;
  final AppStrings strings;
  final void Function(AppLanguage) onLanguageChanged;

  const AppLocalizationScope({
    super.key,
    required this.currentLanguage,
    required this.strings,
    required this.onLanguageChanged,
    required super.child,
  });

  static AppLocalizationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLocalizationScope>();
  }

  static AppLocalizationScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppLocalizationScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLocalizationScope oldWidget) {
    return currentLanguage != oldWidget.currentLanguage;
  }
}

/// اختصارات للوصول إلى النصوص واللغة عبر `context`.
extension AppLocalizationExtension on BuildContext {
  /// النصوص الحالية، أو العربية إن لم يوجد [AppLocalizationScope].
  AppStrings get l10n =>
      AppLocalizationScope.maybeOf(this)?.strings ??
      const AppStrings(AppLanguage.arabic);

  /// اللغة الحالية، أو العربية إن لم يوجد [AppLocalizationScope].
  AppLanguage get currentLanguage =>
      AppLocalizationScope.maybeOf(this)?.currentLanguage ?? AppLanguage.arabic;
}
