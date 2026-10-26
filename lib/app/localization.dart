import 'package:flutter/material.dart';

import '../core/utils/arabic_search_normalizer.dart';
import '../l10n/app_localizations.dart';

/// اللغات المدعومة في واجهة تطبيق تَدْبِير مع اتجاه النص المقابل لكل لغة.
enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);

  final String code;
  final String label;
  final TextDirection direction;

  const AppLanguage(this.code, this.label, this.direction);

  /// استرجاع لغة التطبيق المقابلة لرمز اللغة المحفوظ، مع اعتماد العربية افتراضياً.
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

/// مستودع النصوص المترجمة لواجهة المستخدم باللغتين العربية والإنجليزية.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  // Translations are generated from lib/l10n/app_ar.arb and app_en.arb.
  static final AppLocalizations _ar = lookupAppLocalizations(
    const Locale('ar'),
  );
  static final AppLocalizations _en = lookupAppLocalizations(
    const Locale('en'),
  );
  AppLocalizations get _l => language == AppLanguage.arabic ? _ar : _en;

  /// ما إذا كانت اللغة الحالية للتطبيق هي اللغة العربية.
  bool get isArabic => language == AppLanguage.arabic;

  /// Renders numbers with Arabic-Indic digits in the Arabic UI.
  String digits(Object? value) =>
      isArabic ? ArabicSearchNormalizer.convertDigits('$value') : '$value';

  String _n(Object? value) => ArabicSearchNormalizer.convertDigits('$value');

  // App Identity
  String get appName => _l.appName;
  String get appTagline => _l.appTagline;

  // Navigation / Main Sections
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

  // Tadbeer Intro
  String get tadbeerVerse =>
      'أَفَلَا يَتَدَبَّرُونَ الْقُرْآنَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَا';
  String get tadbeerVerseRef => _l.tadbeerVerseRef;

  String get tadbeerMessage => _l.tadbeerMessage;

  String get tadabburVerse => tadbeerVerse;

  // Quran Reader & Side Menu
  /// تنسيق نص رقم الصفحة الحالية في المصحف.
  String pageNumber(int page) =>
      _l.pageNumber(digits(page));

  /// تنسيق نص رقم الجزء الحالي في المصحف.
  String juzNumber(int juz) =>
      _l.juzNumber(digits(juz));

  /// تنسيق نص رقم الحزب الحالي في المصحف.
  String hizbNumber(int hizb) =>
      _l.hizbNumber(digits(hizb));

  String get surahs => _l.surahs;
  String get juzs => _l.juzs;
  String get jumpToPage => _l.jumpToPage;
  String get go => _l.go;
  String get cancel => _l.cancel;
  String get options => _l.options;

  // Mushaf map & reflection log
  String get mushafMap => _l.mushafMap;
  String get mapTab => _l.mapTab;
  String get reflectionLog => _l.reflectionLog;
  String pagesTouched(int n) =>
      _l.pagesTouched(digits(n));

  /// Legend label for [PageActivity] by index.
  String activityLabel(int i) => isArabic
      ? const ['لم تُقرأ', 'مقروءة', 'محفوظة أو مميزة', 'في الحفظ', 'فيها تدبر'][i]
      : const ['Not read', 'Read', 'Saved or highlighted', 'Memorizing', 'Reflected'][i];
  String get noReflectionsYet => _l.noReflectionsYet;
  String get reflectionsEmptyHint => _l.reflectionsEmptyHint;
  String shortDate(DateTime d) =>
      isArabic ? _n('${d.day}/${d.month}/${d.year}') : '${d.day}/${d.month}/${d.year}';

  // Guided pathways
  String get guidedPathways => _l.guidedPathways;
  String get guidedPathwaysHint => _l.guidedPathwaysHint;
  String daysOfTotal(int a, int b) =>
      _l.daysOfTotal(digits(a), digits(b));
  String dayN(int n) =>
      _l.dayN(digits(n));
  String get completeDay => _l.completeDay;
  String get pathwayUnlockHint => _l.pathwayUnlockHint;
  String get pathwayComplete => _l.pathwayComplete;

  // Memorization (الحفظ)
  String get memorization => _l.memorization;
  String versesMemorized(int n) =>
      _l.versesMemorized(digits(n));
  String get memorizationHint => _l.memorizationHint;
  String reviewToday(int n) =>
      _l.reviewToday(digits(n));
  String get nothingDueToday => _l.nothingDueToday;
  String get chooseSurahToMemorize => _l.chooseSurahToMemorize;
  String versesOfTotal(int a, int b) =>
      _l.versesOfTotal(digits(a), digits(b));
  String get tapToReveal => _l.tapToReveal;
  String get needsReview => _l.needsReview;
  String get mastered => _l.mastered;
  String get sessionDone => _l.sessionDone;
  String sessionSummary(int a, int b) =>
      _l.sessionSummary(digits(a), digits(b));

  // Ayah of the day
  String get ayahOfTheDay => _l.ayahOfTheDay;
  String get reflectOnIt => _l.reflectOnIt;

  // Reading vs viewing

  // Sequential khatma
  String get fromMushafStart => _l.fromMushafStart;
  String fromMyPosition(int page) =>
      _l.fromMyPosition(digits(page));
  String reachedPage(int page) =>
      _l.reachedPage(digits(page));
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
  /// The widget fills in the numbers itself, so they stay placeholders.
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
  String commitmentSaidAt(String reference) =>
      _l.commitmentSaidAt(reference);

  /// Addresses [text] to the reader by [name] ("أحمد، …" / "Ahmed, …");
  /// the name goes first so the wording suits anyone.
  String toReader(String name, String text) {
    final n = name.trim();
    if (n.isEmpty || text.isEmpty) return text;
    if (isArabic) return '$n، $text';
    return '$n, ${text[0].toLowerCase()}${text.substring(1)}';
  }

  /// A percentage in this language's digits (١٢٠٪ / 120%).
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
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return isArabic
        ? '${ar[month - 1]} ${_n(year)}'
        : '${en[month - 1]} $year';
  }

  // Group khatma
  String get groupKhatma => _l.groupKhatma;
  String get groupKhatmaHint => _l.groupKhatmaHint;
  String get createGroupKhatma => _l.createGroupKhatma;
  String get groupKhatmaTitle => _l.groupKhatmaTitle;
  String get participantNames => _l.participantNames;
  String get oneNamePerLine => _l.oneNamePerLine;
  String get distributeJuz => _l.distributeJuz;
  String get joinWithCode => _l.joinWithCode;
  String get pasteGroupCode => _l.pasteGroupCode;
  String get invalidGroupCode => _l.invalidGroupCode;
  String get join => _l.join;
  String get whoAreYou => _l.whoAreYou;
  String juzList(List<int> juz) =>
      isArabic ? 'الأجزاء: ${juz.map(_n).join('، ')}' : 'Juz: ${juz.join(', ')}';
  String juzLabel(int juz) =>
      _l.juzLabel(digits(juz));
  String myJuzTitle(String name) =>
      _l.myJuzTitle(name);
  String get readJuz => _l.readJuz;
  String get everyonesJuz => _l.everyonesJuz;
  String get showQr => _l.showQr;
  String get leaveGroupKhatma => _l.leaveGroupKhatma;
  String get groupCodeIntro => _l.groupCodeIntro;

  String get continueWhereYouLeft => _l.continueWhereYouLeft;
  String get adhkarKind => _l.adhkarKind;
  String chapterN(int n) =>
      _l.chapterN(digits(n));

  String get weeklyGoals => _l.weeklyGoals;
  String get editGoals => _l.editGoals;
  String get pagesGoal => _l.pagesGoal;
  String get reflectionsGoal => _l.reflectionsGoal;

  String get appColorTheme => isArabic ? 'لون التطبيق' : 'App color';

  /// Name of [AppColorTheme] by index.
  String colorThemeName(int i) => isArabic
      ? const ['كحلي', 'زمردي', 'عنابي', 'بني خشبي', 'تركوازي'][i]
      : const ['Navy', 'Emerald', 'Burgundy', 'Brown', 'Teal'][i];

  // Focus mode (وضع التأمل)
  String get focusMode => _l.focusMode;
  String get breathe => _l.breathe;
  String get breatheIn => _l.breatheIn;
  String get breatheOut => _l.breatheOut;
  String get swipeForNextAyah => _l.swipeForNextAyah;

  // Reading journey (الختمة والإحصاءات)
  String get myJourney => _l.myJourney;
  String get startKhatmaTitle => _l.startKhatmaTitle;
  String get startKhatmaHint => _l.startKhatmaHint;
  String daysCount(int d) =>
      _l.daysCount(digits(d));
  String pagesPerDayHint(int n) =>
      _l.pagesPerDayHint(digits(n));
  String get startKhatma => _l.startKhatma;
  String completedKhatmas(int n) =>
      _l.completedKhatmas(digits(n));
  String get cancelKhatma => _l.cancelKhatma;
  String get cancelKhatmaConfirm => _l.cancelKhatmaConfirm;
  String get onTrack => _l.onTrack;
  String behindBy(int n) =>
      _l.behindBy(digits(n));
  String khatmaInDays(int n) =>
      _l.khatmaInDays(digits(n));
  String pagesOfMushaf(int n) =>
      _l.pagesOfMushaf(digits(n));
  String dayOfPlan(int d, int total) =>
      _l.dayOfPlan(digits(d), digits(total));
  String get todayPortion => _l.todayPortion;
  String pagesOfTarget(int a, int b) =>
      _l.pagesOfTarget(digits(a), digits(b));
  String get keepReading => _l.keepReading;
  String continueFromPage(int p) =>
      _l.continueFromPage(digits(p));
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

  /// تنسيق نص عدد آيات السورة.
  String ayahCount(int count) =>
      _l.ayahCount(digits(count));

  // Ayah Action Modal
  String get addNote => _l.addNote;
  String get saveBookmark => _l.saveBookmark;
  String get removeBookmark => _l.removeBookmark;
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

  // Notes
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

  // Bookmarks & Highlights
  String get noBookmarksYet => _l.noBookmarksYet;
  String get noHighlightsYet => _l.noHighlightsYet;
  String get bookmarksEmptyHint => _l.bookmarksEmptyHint;
  String get highlightsEmptyHint => _l.highlightsEmptyHint;
  String get openMushaf => _l.openMushaf;

  // Search
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

  // Reminders
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

  // Ayah Links (روابط الآيات)
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

  /// تنسيق نص عدد الآيات المربوطة في الرابط.
  String versesCount(int count) =>
      _l.versesCount(digits(count));

  // Backup & Restore
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

  // Settings
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

  // Home Screen Cards & Subtitles
  String get resumeReading => _l.resumeReading;
  String get additionalTools => _l.additionalTools;
  String get quranAndSunnahDuas => _l.quranAndSunnahDuas;
  String get quranDuasTitle => _l.quranDuasTitle;
  String get quranDuasSubtitle => _l.quranDuasSubtitle;
  String duasCountBadge(dynamic count) =>
      _l.duasCountBadge(digits(count));
  String adhkarCountBadge(dynamic count) =>
      _l.adhkarCountBadge(digits(count));
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

  // Common Quran Formats & References
  String readingPosition(String surahName, dynamic page) =>
      _l.readingPosition(surahName, digits(page));
  String ayahReference(String surahName, dynamic ayahNumber) =>
      _l.ayahReference(surahName, digits(ayahNumber));
  String surahTitle(String surahName) =>
      _l.surahTitle(surahName);
  String ayahTitle(dynamic ayahNumber) =>
      _l.ayahTitle(digits(ayahNumber));
  String pageAbbr(dynamic page) =>
      _l.pageAbbr(digits(page));
  String juzAbbr(dynamic juz) =>
      _l.juzAbbr(digits(juz));
  String get meccan => _l.meccan;
  String get medinan => _l.medinan;
  String ayahsCount(dynamic count) =>
      _l.ayahsCount(digits(count));
  String get searchSurahsHint => _l.searchSurahsHint;
  String get searchWordMeaningsHint => _l.searchWordMeaningsHint;
  String get allSurahsWithCount => _l.allSurahsWithCount;
  String wordSearchResultsCount(dynamic count) =>
      _l.wordSearchResultsCount(digits(count));
  String get noWordsFound => _l.noWordsFound;
  String get noWordsFoundSubtitle => _l.noWordsFoundSubtitle;
  String get lexicalMeaningTitle => _l.lexicalMeaningTitle;
  String get verifiedDocumentation => _l.verifiedDocumentation;
  String surahAyahPageReference(String surahName, dynamic ayahNumber, dynamic page) =>
      _l.surahAyahPageReference(surahName, digits(ayahNumber), digits(page));

  // Actions & Common Dialogs
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
  String linkedAyahsCount(dynamic count) =>
      _l.linkedAyahsCount(digits(count));
  String get importPathway => _l.importPathway;
  String get editTitleAndDescription => _l.editTitleAndDescription;
  String get deleteAyahLink => _l.deleteAyahLink;

  // Settings & Data Management
  String get typographyAndReading => _l.typographyAndReading;
  String get quranFontFamily => _l.quranFontFamily;
  String fontSizePoints(dynamic points) =>
      _l.fontSizePoints(digits(points));
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
  /// تفاصيل المصادر وتراخيص المحتوى المعتمد في التطبيق.
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
  /// زر استعراض ميثاق وسياسة الخصوصية والأمان.
  String get privacyPolicy => _l.privacyPolicy;
  /// عنوان نافذة ميثاق الخصوصية والأمان.
  String get privacyPolicyTitle => _l.privacyPolicyTitle;
  /// وصف موجز للخصوصية والأمان.
  String get privacyPolicySubtitle => _l.privacyPolicySubtitle;

  // Reminders Configuration
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

  // Backup Configuration
  String get exportBackupSubtitle => _l.exportBackupSubtitle;
  String get restoreBackupSubtitle => _l.restoreBackupSubtitle;
  String get restoreFailed => _l.restoreFailed;
  String get selectBackupLocation => _l.selectBackupLocation;
  String get backupCreateFailed => _l.backupCreateFailed;
  String errorSavingFile(dynamic err) =>
      _l.errorSavingFile('$err');

  // Supplications & Adhkar
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
  String dhikrIndex(dynamic index) =>
      _l.dhikrIndex(digits(index));
  String get copyDhikr => _l.copyDhikr;
  String get completed => _l.completed;
  String remainingCount(dynamic count) =>
      _l.remainingCount(digits(count));
  String get once => _l.once;

  // Ahlulbayt & Hadith Duas
  String get searchAhlulbaytHint => _l.searchAhlulbaytHint;
  String ahlulbaytDuasCountBadge(dynamic count) =>
      _l.ahlulbaytDuasCountBadge(digits(count));
  String get ahlulbaytDuasScreenTitle => _l.ahlulbaytDuasScreenTitle;
  String get copyFullDua => _l.copyFullDua;
  String get fullDuaCopiedSuccess => _l.fullDuaCopiedSuccess;
  String get decreaseFontSize => _l.decreaseFontSize;
  String get increaseFontSize => _l.increaseFontSize;
  String get fullAuthenticText => _l.fullAuthenticText;
  String searchGeneralDuasHint(String title) =>
      _l.searchGeneralDuasHint(title);
  String generalDuasCountBadge(dynamic count) =>
      _l.generalDuasCountBadge(digits(count));
  String duaIndex(dynamic index) =>
      _l.duaIndex(digits(index));
  String get copyDuaTooltip => _l.copyDuaTooltip;

  // Books & Pamphlets Reader
  String get tableOfContents => _l.tableOfContents;
  String bookIndexPrefix(String title) =>
      _l.bookIndexPrefix(title);
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
  String searchSectionHint(String name) =>
      _l.searchSectionHint(name);
  String get verifiedPamphletPdf => _l.verifiedPamphletPdf;
  String fullSectionsCount(dynamic count) =>
      _l.fullSectionsCount(digits(count));
  String get directTextReading => _l.directTextReading;
  String get textCopied => _l.textCopied;
  String get fileNotFound => _l.fileNotFound;
  String fileShareError(dynamic error) =>
      _l.fileShareError('$error');
  String pdfReadError(dynamic error) =>
      _l.pdfReadError('$error');
  String fileContentReadError(dynamic error) =>
      _l.fileContentReadError('$error');
  String get noTextContent => _l.noTextContent;
  String get textFile => _l.textFile;

  // Ayah Links Views
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

  // Tasbeeh & Istighfar
  String get istighfar => _l.istighfar;
  String get tasbeeh => _l.tasbeeh;
  String get browseAllFormulas => _l.browseAllFormulas;
  String get resetCycleCounter => _l.resetCycleCounter;
  String get resetCycleCounterTitle => _l.resetCycleCounterTitle;
  String get resetCycleCounterConfirm => _l.resetCycleCounterConfirm;
  String get resetCycleAction => _l.resetCycleAction;
  String get tapAnywhereToCount => _l.tapAnywhereToCount;
  String targetCount(dynamic target) =>
      _l.targetCount(digits(target));
  String get freeCount => _l.freeCount;
  String get countSettings => _l.countSettings;
  String get freeCountOpen => _l.freeCountOpen;
  String countTimes(dynamic count) =>
      _l.countTimes(digits(count));
  String get autoAdvanceUponCompletion => _l.autoAdvanceUponCompletion;
  String get todayCount =>
      isArabic ? 'استغفار وتسبيح اليوم' : "Today's Count";
  String get lifetimeTotalCount => _l.lifetimeTotalCount;
  String formulaXOfY(dynamic current, dynamic total) =>
      _l.formulaXOfY(digits(current), digits(total));
  String allFormulasCount(dynamic total) =>
      _l.allFormulasCount(digits(total));
  String get copyDhikrTooltip => _l.copyDhikrTooltip;
  String get dhikrCopied => _l.dhikrCopied;
  String targetReachedAuto(dynamic target) =>
      _l.targetReachedAuto(digits(target));
  String targetReached(dynamic target) =>
      _l.targetReached(digits(target));
  String get tasbeehAndIstighfarFormulas => _l.tasbeehAndIstighfarFormulas;
  String get searchDhikrHint => _l.searchDhikrHint;
  String get noMatchingFormulas => _l.noMatchingFormulas;
  String get swipeOrTapToChange => _l.swipeOrTapToChange;
  String get nextDhikr => _l.nextDhikr;
  String get previousDhikr => _l.previousDhikr;
  /// زر تفعيل وضع العد التلقائي للسبحة.
  String get autoCount => _l.autoCount;
  /// زر إيقاف العد التلقائي المؤقت للسبحة.
  String get stopAutoCount => _l.stopAutoCount;
  /// عرض مدة الإيقاع الزمني المحسوب لكل عَدّة بالثواني.
  String smartPaceSeconds(dynamic seconds) =>
      _l.smartPaceSeconds(digits(seconds));
  /// تلميح تسريع وتيرة العد التلقائي.
  String get decreasePace => _l.decreasePace;
  /// تلميح إبطاء وتيرة العد التلقائي وتدبر الذكر.
  String get increasePace => _l.increasePace;

  // Books
  String get booksSectionEmpty => _l.booksSectionEmpty;
  String get booksSectionEmptyDescription => _l.booksSectionEmptyDescription;
}

/// عنصر وراثة لتوفير إعدادات اللغة والنصوص المترجمة لجميع عناصر شجرة الواجهة.
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

  /// استرجاع نطاق الترجمة الحالي من سياق البناء إن وجد.
  static AppLocalizationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLocalizationScope>();
  }

  /// استرجاع نطاق الترجمة الحالي من سياق البناء.
  static AppLocalizationScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppLocalizationScope found in context');
    return scope!;
  }

  /// إشعار العناصر التابعة عند تغيّر اللغة الحالية.
  @override
  bool updateShouldNotify(AppLocalizationScope oldWidget) {
    return currentLanguage != oldWidget.currentLanguage;
  }
}

/// امتداد يسهّل الوصول إلى النصوص المترجمة واللغة الحالية مباشرة عبر `context`.
extension AppLocalizationExtension on BuildContext {
  /// النصوص المترجمة المرتبطة باللغة الحالية مع الرجوع للغة الافتراضية إذا لم يتوفر نطاق.
  AppStrings get l10n =>
      AppLocalizationScope.maybeOf(this)?.strings ??
      const AppStrings(AppLanguage.arabic);

  /// اللغة المفعّلة حالياً في الواجهة مع الرجوع للغة العربية افتراضياً.
  AppLanguage get currentLanguage =>
      AppLocalizationScope.maybeOf(this)?.currentLanguage ?? AppLanguage.arabic;
}
