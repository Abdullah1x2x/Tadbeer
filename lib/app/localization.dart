import 'package:flutter/material.dart';

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

  /// ما إذا كانت اللغة الحالية للتطبيق هي اللغة العربية.
  bool get isArabic => language == AppLanguage.arabic;

  // App Identity
  String get appName => isArabic ? 'تَدْبِير' : 'Tadbeer';
  String get appTagline =>
      isArabic ? 'قراءة وتدبّر القرآن الكريم' : 'Quran Reading & Reflection';

  // Navigation / Main Sections
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get quran => isArabic ? 'المصحف' : 'Quran';
  String get notes => isArabic ? 'الملاحظات' : 'Notes';
  String get bookmarks => isArabic ? 'المحفوظات' : 'Bookmarks';
  String get highlights => isArabic ? 'المميزة' : 'Highlights';
  String get search => isArabic ? 'البحث' : 'Search';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get reminders => isArabic ? 'التنبيهات' : 'Reminders';
  String get ayahLinks => isArabic ? 'روابط الآيات' : 'Ayah Links';
  String get backup => isArabic ? 'النسخ الاحتياطي' : 'Backup & Restore';
  String get duas => isArabic ? 'الأدعية' : 'Duas';
  String get quranDuas => isArabic ? 'أدعية من القرآن' : 'Duas from the Quran';
  String get tasbeehAndIstighfar =>
      isArabic ? 'استغفار وتسبيح' : 'Istighfar & Tasbeeh';
  String get tasbeehSubtitle => isArabic
      ? 'سبحة إلكترونية وأوراد الاستغفار والتسبيح'
      : 'Digital Tasbeeh & Istighfar Counter';
  String get booksAndBooklets => isArabic ? 'كتب وملازم' : 'Books & Booklets';
  String get booksSubtitle => isArabic
      ? 'مكتبة الملازم التدبرية ومختصرات علوم القرآن'
      : 'Tadbeer Library & Study Booklets';
  String get about => isArabic ? 'عن تَدْبِير' : 'About Tadbeer';
  String get more => isArabic ? 'المزيد' : 'More';

  // Tadbeer Intro
  String get tadbeerVerse =>
      'أَفَلَا يَتَدَبَّرُونَ الْقُرْآنَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَا';
  String get tadbeerVerseRef =>
      isArabic ? 'سورة محمد · آية ٢٤' : 'Surah Muhammad · Verse 24';

  String get tadbeerMessage => isArabic
      ? 'عِش مع القرآن، وتأمّل آياته، وتدبّر معانيها، واربط بين الآيات، ودوّن خواطرك، واستلهم هدايته.'
      : 'Engage with the Quran, reflect on its verses, contemplate their meanings, connect related verses, record your thoughts, and draw inspiration from its guidance.';

  String get tadabburVerse => tadbeerVerse;

  // Quran Reader & Side Menu
  /// تنسيق نص رقم الصفحة الحالية في المصحف.
  String pageNumber(int page) => isArabic ? 'صفحة $page' : 'Page $page';

  /// تنسيق نص رقم الجزء الحالي في المصحف.
  String juzNumber(int juz) => isArabic ? 'الجزء $juz' : 'Juz $juz';

  /// تنسيق نص رقم الحزب الحالي في المصحف.
  String hizbNumber(int hizb) => isArabic ? 'الحزب $hizb' : 'Hizb $hizb';

  String get surahs => isArabic ? 'السور' : 'Surahs';
  String get juzs => isArabic ? 'الأجزاء' : 'Juzs';
  String get jumpToPage => isArabic ? 'الانتقال إلى صفحة' : 'Jump to Page';
  String get go => isArabic ? 'انتقال' : 'Go';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get sajdah => isArabic ? 'سجدة تلاوة' : 'Sajdah';

  /// تنسيق نص عدد آيات السورة.
  String ayahCount(int count) => isArabic ? '$count آية' : '$count Verses';

  // Ayah Action Modal
  String get addNote => isArabic ? 'ملاحظة' : 'Note';
  String get saveBookmark => isArabic ? 'حفظ' : 'Bookmark';
  String get removeBookmark => isArabic ? 'إزالة الحفظ' : 'Remove Bookmark';
  String get highlight => isArabic ? 'تمييز' : 'Highlight';
  String get removeHighlight => isArabic ? 'إزالة التمييز' : 'Remove Highlight';
  String get copy => isArabic ? 'نسخ' : 'Copy';
  String get copiedToClipboard =>
      isArabic ? 'تم نسخ الآية إلى الحافظة' : 'Ayah copied to clipboard';

  // Notes
  String get newNote => isArabic ? 'ملاحظة جديدة' : 'New Note';
  String get newFreeNote => isArabic ? 'ملاحظة حرة' : 'Free Note';
  String get noteTitle => isArabic ? 'عنوان الملاحظة' : 'Note Title';
  String get noteContent => isArabic
      ? 'اكتب تدبرك أو ملاحظتك هنا...'
      : 'Write your reflection or note here...';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get deleteConfirmTitle => isArabic ? 'تأكيد الحذف' : 'Confirm Delete';
  String get deleteConfirmMessage => isArabic
      ? 'هل أنت متأكد من رغبتك في الحذف؟ لا يمكن التراجع عن هذا الإجراء.'
      : 'Are you sure you want to delete this item? This action cannot be undone.';
  String get exportPdf => isArabic ? 'تصدير PDF' : 'Export PDF';
  String get noNotesYet => isArabic ? 'لا توجد ملاحظات بعد' : 'No notes yet';
  String get freeNoteLabel => isArabic ? 'ملاحظة حرة' : 'Free Note';
  String get ayahNoteLabel => isArabic ? 'تدبر آية' : 'Ayah Reflection';
  String get goToAyah => isArabic ? 'الذهاب إلى الآية' : 'Go to Ayah';

  // Bookmarks & Highlights
  String get noBookmarksYet =>
      isArabic ? 'لا توجد آيات محفوظة بعد' : 'No bookmarks yet';
  String get noHighlightsYet =>
      isArabic ? 'لا توجد آيات مميزة بعد' : 'No highlights yet';

  // Search
  String get searchGlobalPlaceholder =>
      isArabic
          ? 'ابحث في القرآن، الملاحظات، التدبر، والمزيد...'
          : 'Search Quran, notes, reflections, and more...';
  String get searchAll => isArabic ? 'الكل' : 'All';
  String get searchBookmarksHint =>
      isArabic ? 'ابحث في الآيات المحفوظة...' : 'Search bookmarks...';
  String get searchHighlightsHint =>
      isArabic ? 'ابحث في الآيات المميزة...' : 'Search highlights...';
  String get searchRemindersHint =>
      isArabic ? 'ابحث في التنبيهات...' : 'Search reminders...';
  String get searchNotesHint =>
      isArabic ? 'ابحث في الملاحظات...' : 'Search notes...';
  String get tadbeerSectionTitle => isArabic ? 'التدبر' : 'Tadbeer';
  String get wordMeanings => isArabic ? 'معاني الكلمات' : 'Word Meanings';
  String get wordMeaningsScreenTitle =>
      isArabic ? 'معاني كلمات القرآن' : 'Quran Word Meanings';
  String get approvedSourcesTitle =>
      isArabic ? 'المصادر المعتمدة' : 'Approved Sources';
  String get searchInAllSections =>
      isArabic ? 'البحث في جميع الأقسام' : 'Search in All Sections';
  String get filterSearchTitle =>
      isArabic ? 'تصفية نطاق البحث' : 'Filter Search Scope';
  String get selectSearchSection => isArabic
      ? 'اختر القسم المطلوب للبحث فيه مباشرة'
      : 'Select a section to search directly';
  String get noSearchResults =>
      isArabic ? 'لا توجد نتائج مطابقة' : 'No matching results found';

  // Reminders
  String get addReminder => isArabic ? 'إضافة تنبيه' : 'Add Reminder';
  String get editReminder => isArabic ? 'تعديل التنبيه' : 'Edit Reminder';
  String get reminderTitle =>
      isArabic ? 'عنوان التنبيه (اختياري)' : 'Reminder Title (optional)';
  String get defaultReminderTitle =>
      isArabic ? 'ورد القرآن الكريم' : 'Daily Quran Reading';
  String get reminderTime => isArabic ? 'وقت التنبيه' : 'Time';
  String get repeatDaily => isArabic ? 'تكرار يومي' : 'Repeat Daily';
  String get repeatOnce => isArabic ? 'مرة واحدة' : 'Once';
  String get selectDays => isArabic ? 'أيام التكرار' : 'Repeat Days';
  String get noRemindersYet =>
      isArabic ? 'لا توجد تنبيهات قراءة مضافة' : 'No reading reminders added';

  // Ayah Links (روابط الآيات)
  String get newAyahLink => isArabic ? 'إنشاء رابط آيات' : 'New Ayah Link';
  String get addToAyahLink =>
      isArabic ? 'إضافة إلى رابط آيات' : 'Add to Ayah Links';
  String get networkView => isArabic ? 'شبكة' : 'Network';
  String get orderedView => isArabic ? 'مرتب' : 'Ordered';
  String get autoLayout => isArabic ? 'إعادة الترتيب تلقائيًا' : 'Auto Layout';
  String get linkTitle =>
      isArabic ? 'عنوان الرابط / الفكرة' : 'Link Title / Theme';
  String get linkTitleHint =>
      isArabic ? 'مثال: الصبر عند الشدة' : 'e.g., Patience in Adversity';
  String get linkDescription => isArabic
      ? 'الملاحظة العامة / الفكرة (اختيارية)'
      : 'General Note / Idea (optional)';
  String get linkDescriptionHint => isArabic
      ? 'سجل تأملك أو الفكرة التي تجمع هذه الآيات...'
      : 'Record your reflection connecting these verses...';
  String get addVerse => isArabic ? 'إضافة آية' : 'Add Verse';
  String get resetToCenter => isArabic ? 'العودة إلى الوسط' : 'Center View';
  String get noAyahLinksYet =>
      isArabic ? 'لا توجد روابط آيات بعد' : 'No ayah links yet';
  String get ayahLinksSubtitle => isArabic
      ? 'خريطة شخصية لربط الآيات واستكشاف العلاقات التدبرية'
      : 'Personal maps connecting verses explored during Tadbeer';

  /// تنسيق نص عدد الآيات المربوطة في الرابط.
  String versesCount(int count) => isArabic ? '$count آيات' : '$count Verses';

  // Backup & Restore
  String get exportBackup =>
      isArabic ? 'تصدير نسخة احتياطية' : 'Export Backup File';
  String get restoreBackup =>
      isArabic ? 'استعادة نسخة احتياطية' : 'Restore from Backup';
  String get restoreWarningTitle =>
      isArabic ? 'تنبيه هام قبل الاستعادة' : 'Important Restore Notice';
  String get restoreWarningMessage => isArabic
      ? 'استعادة النسخة الاحتياطية ستستبدل بياناتك الحالية بالكامل ولن تدمجها. هل ترغب بالاستمرار؟'
      : 'Restoring a backup will completely replace your current user data. It will not merge. Do you want to proceed?';
  String get confirmRestore =>
      isArabic ? 'استبدال واستعادة' : 'Replace & Restore';
  String get saveToDeviceFiles =>
      isArabic ? 'حفظ في ملفات الجهاز' : 'Save to Device Files';
  String get shareViaApps =>
      isArabic ? 'مشاركة عبر التطبيقات' : 'Share via Apps';
  String get backupSavedSuccess => isArabic
      ? 'تم حفظ النسخة الاحتياطية في الملفات بنجاح'
      : 'Backup saved to files successfully';
  String get restoreSuccess =>
      isArabic ? 'تمت استعادة البيانات بنجاح' : 'Data restored successfully';
  String get corruptBackupError => isArabic
      ? 'الملف غير صالح أو كلمة المرور غير صحيحة. تم إلغاء الاستعادة لحماية بياناتك.'
      : 'Invalid or corrupt backup file. Restore cancelled to protect your data.';
  String get enterBackupPassword => isArabic
      ? 'كلمة مرور التشفير (اختيارية)'
      : 'Encryption Password (optional)';

  // Settings
  String get appearance => isArabic ? 'المظهر' : 'Appearance';
  String get themeMode => isArabic ? 'السمة' : 'Theme';
  String get light => isArabic ? 'فاتح' : 'Light';
  String get dark => isArabic ? 'داكن' : 'Dark';
  String get system => isArabic ? 'تلقائي (حسب النظام)' : 'System Default';
  String get languageTitle => isArabic ? 'اللغة' : 'Language';
  String get fontSize => isArabic ? 'حجم خط المصحف' : 'Quran Font Size';
  String get aboutContent => isArabic
      ? 'تدبير مشروع قرآني يهدف إلى تعزيز التدبّر في آيات الله، ومساعدة المسلم على التأمل في معاني القرآن الكريم، والتفكّر في هداياته، واستحضار أثر آياته في الحياة والعمل بها، لتكون علاقتنا بالقرآن قائمة على التدبّر والفهم والاهتداء، لا على التلاوة وحدها.'
      : 'Tadbeer is a Quranic project aimed at fostering contemplation of Allah\'s verses, helping reflect on the meanings of the Holy Quran, pondering its guidance, and living by its teachings—so our relationship with the Quran is grounded in contemplation, understanding, and guidance, not recitation alone.';

  // Home Screen Cards & Subtitles
  String get resumeReading =>
      isArabic ? 'استئناف القراءة' : 'Resume Reading';
  String get additionalTools =>
      isArabic ? 'أدوات إضافية' : 'Additional Tools';
  String get quranAndSunnahDuas =>
      isArabic ? 'أدعية الكتاب والسنة' : 'Quran & Sunnah Duas';
  String get quranDuasTitle =>
      isArabic ? 'أدعية من القرآن' : 'Quranic Duas';
  String get quranDuasSubtitle =>
      isArabic ? 'أدعية الأنبياء والصالحين وخواتيم السور المأثورة في كتاب الله' : 'Duas of Prophets and the righteous in the Book of Allah';
  String duasCountBadge(dynamic count) =>
      isArabic ? '$count دعاء' : '$count Duas';
  String adhkarCountBadge(dynamic count) =>
      isArabic ? '$count ذكر' : '$count Adhkar';
  String get morningEveningAdhkarTitle =>
      isArabic ? 'أذكار الصباح والمساء' : 'Morning & Evening Adhkar';
  String get morningEveningAdhkarSubtitle =>
      isArabic ? 'أذكار اليوم والليلة وحصن المسلم مع عدادات تفاعلية' : 'Daily Adhkar & fortress of the Muslim with counters';
  String get ahlulbaytDuasTitle =>
      isArabic ? 'أدعية مأثورة عن أهل البيت' : 'Ahlulbayt Duas';
  String get ahlulbaytDuasSubtitle =>
      isArabic ? 'الصحيفة السجادية ومناجاة وأدعية الأئمة الأطهار' : 'Al-Sahifa al-Sajjadiyya and supplications of Ahlulbayt';
  String get sunnahDuasTitle =>
      isArabic ? 'أدعية من السنة النبوية' : 'Sunnah Duas';
  String get sunnahDuasSubtitle =>
      isArabic ? 'أدعية مأثورة وصحيحة عن النبي ﷺ لكشف الكرب' : 'Authentic prophetic supplications for ease and relief';
  String get jawamiDuasTitle =>
      isArabic ? 'جوامع الدعاء والرجاء' : 'Comprehensive Duas';
  String get jawamiDuasSubtitle =>
      isArabic ? 'أدعية جامعة لخيري الدنيا والآخرة والهدى والعافية' : 'Comprehensive prayers for goodness in this life and the hereafter';
  String get wordsOfQuran =>
      isArabic ? 'غريب ألفاظ القرآن' : 'Quran Vocabulary';
  String get yourThoughtsAndReflections =>
      isArabic ? 'خواطرك وتدبراتك' : 'Thoughts & Reflections';
  String get connectionsAndThemes =>
      isArabic ? 'الربط والعلاقات' : 'Connections & Themes';
  String get dailyPortion => isArabic ? 'الورد اليومي' : 'Daily Portion';
  String get tadbeerLibrary =>
      isArabic ? 'مكتبة المتدبر' : 'Contemplative Library';
  String get offlineQuranAndReflection =>
      isArabic ? 'مصحف وتدبّر بدون إنترنت' : 'Offline Quran & Contemplation';

  // Common Quran Formats & References
  String readingPosition(String surahName, dynamic page) =>
      isArabic ? 'سورة $surahName · صفحة $page' : 'Surah $surahName · Page $page';
  String ayahReference(String surahName, dynamic ayahNumber) =>
      isArabic ? 'سورة $surahName · الآية $ayahNumber' : 'Surah $surahName · Verse $ayahNumber';
  String surahTitle(String surahName) =>
      isArabic ? 'سورة $surahName' : 'Surah $surahName';
  String ayahTitle(dynamic ayahNumber) =>
      isArabic ? 'الآية $ayahNumber' : 'Verse $ayahNumber';
  String pageAbbr(dynamic page) => isArabic ? 'ص $page' : 'p. $page';
  String juzAbbr(dynamic juz) => isArabic ? 'ج $juz' : 'Juz $juz';
  String get meccan => isArabic ? 'مكية' : 'Meccan';
  String get medinan => isArabic ? 'مدنية' : 'Medinan';
  String ayahsCount(dynamic count) =>
      isArabic ? '$count آية' : '$count verses';
  String get searchSurahsHint =>
      isArabic ? 'بحث في السور...' : 'Search surahs...';
  String get searchWordMeaningsHint =>
      isArabic ? 'ابحث عن كلمة قرآنية أو معناها...' : 'Search Quranic word or meaning...';
  String get allSurahsWithCount =>
      isArabic ? 'جميع السور (١١٤ سورة)' : 'All Surahs (114 Surahs)';
  String wordSearchResultsCount(dynamic count) =>
      isArabic ? 'النتائج: $count كلمة' : 'Results: $count words';
  String get noWordsFound =>
      isArabic ? 'لا توجد كلمات مطابقة لبحثك' : 'No words match your search';
  String get noWordsFoundSubtitle =>
      isArabic ? 'جرب البحث بكلمة أخرى أو قم بإلغاء التصفية لتصفح جميع الكلمات.' : 'Try searching for another word or clear filters to browse all words.';
  String get lexicalMeaningTitle =>
      isArabic ? 'المعنى اللغوي المعجمي:' : 'Lexical Meaning:';
  String get verifiedDocumentation =>
      isArabic ? 'توثيق معتمد' : 'Verified Source';
  String surahAyahPageReference(String surahName, dynamic ayahNumber, dynamic page) =>
      isArabic
          ? 'سورة $surahName · آية $ayahNumber · ص $page'
          : 'Surah $surahName · Verse $ayahNumber · p. $page';

  // Actions & Common Dialogs
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get editNote => isArabic ? 'تعديل الملاحظة' : 'Edit Note';
  String get tadbeerPause => isArabic ? 'وقفة تدبر' : 'Tadbeer Pause';
  String get ayahLink => isArabic ? 'رابط آيات' : 'Ayah Link';
  String get exportTadbeerJournal =>
      isArabic ? 'تصدير دفتر التدبر والخواطر' : 'Export Tadbeer Journal';
  String get continueLabel => isArabic ? 'متابعة' : 'Continue';
  String get doNotShowAgain =>
      isArabic ? 'لا تظهر لي هذه النافذة مرة أخرى' : 'Do not show this intro again';
  String get curatedPathways =>
      isArabic ? 'المسارات التدبرية المقترحة' : 'Curated Pathways';
  String get importFromQrCode =>
      isArabic ? 'استيراد رابط آيات عبر الرمز' : 'Import Ayah Link via QR Code';
  String get searchAyahLinksHint =>
      isArabic ? 'ابحث في روابط الآيات أو السور...' : 'Search ayah links or surahs...';
  String get noAyahLinkSearchResults =>
      isArabic ? 'لا توجد نتائج مطابقة لبحثك' : 'No matching results found';
  String get tryAnotherAyahLinkSearch =>
      isArabic ? 'جرّب البحث بكلمة أخرى أو اسم سورة' : 'Try searching with another word or surah name';
  String linkedAyahsCount(dynamic count) =>
      isArabic ? '$count آيات مرتبطة' : '$count linked verses';
  String get importPathway =>
      isArabic ? 'استيراد المسار' : 'Import Pathway';
  String get editTitleAndDescription =>
      isArabic ? 'تعديل العنوان والوصف' : 'Edit Title & Description';
  String get deleteAyahLink =>
      isArabic ? 'حذف الرابط' : 'Delete Link';

  // Settings & Data Management
  String get typographyAndReading =>
      isArabic ? 'الخط والقراءة' : 'Typography & Reading';
  String get quranFontFamily =>
      isArabic ? 'نوع خط المصحف' : 'Quran Font Family';
  String fontSizePoints(dynamic points) =>
      isArabic ? '$points نقطة' : '$points pt';
  String get resetToDefault =>
      isArabic ? 'إعادة للوضع الافتراضي' : 'Reset to Default';
  String resetToDefaultWithVal(dynamic val) =>
      isArabic ? 'إعادة للوضع الافتراضي ($val)' : 'Reset to default ($val)';
  String get applicationSection =>
      isArabic ? 'التطبيق' : 'Application';
  String get dataSection => isArabic ? 'البيانات' : 'Data';
  String get dailyRemindersSubtitle =>
      isArabic ? 'تنبيهات الورد اليومي ومواعيد القراءة' : 'Daily reading reminders & schedules';
  String get backupSubtitle =>
      isArabic ? 'تصدير واستعادة ملفات مشفرة بدون اتصال' : 'Offline encrypted backup & restore';
  String get resetData =>
      isArabic ? 'إعادة تعيين البيانات' : 'Reset User Data';
  String get resetDataSubtitle =>
      isArabic ? 'حذف الملاحظات والمحفوظات والتمييزات واستعادة الإعدادات الأصلية' : 'Delete notes, bookmarks, highlights and reset app settings';
  String get confirmReset =>
      isArabic ? 'تأكيد إعادة التعيين' : 'Confirm Reset';
  String get resetSuccess =>
      isArabic ? 'تمت إعادة تعيين البيانات بنجاح' : 'Data reset successfully';
  String get resetWarningMessage => isArabic
      ? 'هل أنت متأكد من رغبتك في حذف جميع الملاحظات والمحفوظات والتمييزات واستعادة الإعدادات الأصلية للتطبيق؟\n\nلا يمكن التراجع عن هذا الإجراء إلا إذا كانت لديك نسخة احتياطية سابقة.'
      : 'Are you sure you want to delete all notes, bookmarks, and highlights, and restore default app settings? This cannot be undone unless you have a backup.';
  String get versionInfo =>
      isArabic ? 'الإصدار ١.٠.٠ · مجاني وبدون إعلانات أو إنترنت' : 'Version 1.0.0 · Free, ad-free & offline';
  String get sourcesAndCredits =>
      isArabic ? 'المصادر والتوثيق المعتمد:' : 'Sources & Documentation:';
  String get openSourceLicenses =>
      isArabic ? 'تراخيص البرمجيات والمصادر المفتوحة' : 'Software & Open Source Licenses';

  // Reminders Configuration
  String get alertType => isArabic ? 'طريقة التنبيه:' : 'Alert Type:';
  String get notificationAlert => isArabic ? 'إشعار' : 'Notification';
  String get notificationSubtitle =>
      isArabic ? 'إشعار عادي في الشريط' : 'Standard status bar notification';
  String get alarmAlert => isArabic ? 'منبه' : 'Alarm';
  String get alarmSubtitle =>
      isArabic ? 'رنين مستمر كالمنبه' : 'Continuous ring like an alarm';
  String get repeatMode => isArabic ? 'نوع التكرار:' : 'Repeat Mode:';
  String get daySat => isArabic ? 'سبت' : 'Sat';
  String get daySun => isArabic ? 'أحد' : 'Sun';
  String get dayMon => isArabic ? 'إثنين' : 'Mon';
  String get dayTue => isArabic ? 'ثلاثاء' : 'Tue';
  String get dayWed => isArabic ? 'أربعاء' : 'Wed';
  String get dayThu => isArabic ? 'خميس' : 'Thu';
  String get dayFri => isArabic ? 'جمعة' : 'Fri';
  String get testAlertTooltip =>
      isArabic ? 'تجربة الإشعار أو المنبه الآن' : 'Test notification or alarm now';
  String get testNotificationNow =>
      isArabic ? 'تجربة إشعار الآن' : 'Test notification now';
  String get testAlarmNow =>
      isArabic ? 'تجربة منبه الآن' : 'Test alarm now';
  String get testAlarmSentSuccess =>
      isArabic ? 'تم إطلاق منبه تجريبي الآن — تفقد الإشعارات لإيقافه' : 'Test alarm triggered — check notifications to stop';
  String get testNotificationSentSuccess =>
      isArabic ? 'تم إرسال إشعار تجريبي الآن — تفقد شريط الإشعارات' : 'Test notification sent — check status bar';
  String get testAlertPermissionError =>
      isArabic ? 'تعذر إرسال التنبيه، يرجى التأكد من تفعيل أذونات الإشعارات في إعدادات الجهاز' : 'Could not trigger alert. Please check notification permissions in device settings';
  String reminderScheduledSuccess(String mode) =>
      isArabic ? 'تم حفظ وجدولة التنبيه ($mode) بنجاح' : 'Reminder scheduled successfully ($mode)';
  String get specificDays => isArabic ? 'أيام محددة' : 'Specific days';

  // Backup Configuration
  String get exportBackupSubtitle => isArabic
      ? 'اختر البيانات التي ترغب بتضمينها في النسخة المشفرة (.quranbackup):'
      : 'Select data to include in the encrypted backup (.quranbackup):';
  String get restoreBackupSubtitle => isArabic
      ? 'استعادة البيانات من ملف .quranbackup محفوظ سابقًا. تُستبدل البيانات الحالية بالكامل بعد التحقق من سلامة التشفير وصحة الملف.'
      : 'Restore data from a previously saved .quranbackup file. Current data will be completely replaced after verifying file integrity.';
  String get restoreFailed =>
      isArabic ? 'فشلت الاستعادة' : 'Restore Failed';
  String get selectBackupLocation =>
      isArabic ? 'اختر موقع حفظ النسخة الاحتياطية' : 'Select backup destination';
  String get backupCreateFailed =>
      isArabic ? 'فشل إنشاء النسخة الاحتياطية' : 'Failed to create backup';
  String errorSavingFile(dynamic err) =>
      isArabic ? 'خطأ أثناء حفظ الملف: $err' : 'Error saving file: $err';

  // Supplications & Adhkar
  String get viewAyah => isArabic ? 'عرض الآية' : 'View Ayah';
  String get duaCopiedSuccess =>
      isArabic ? 'تم نسخ نص الدعاء بنجاح' : 'Supplication text copied successfully';
  String get searchDuasHint => isArabic
      ? 'ابحث في أدعية القرآن الكريم بالكلمة أو السورة...'
      : 'Search Quranic supplications by word or Surah...';
  String get noDuasFound =>
      isArabic ? 'لا توجد أدعية مطابقة لبحثك' : 'No supplications match your search';
  String get allDuasFilter => isArabic ? 'الكل' : 'All';
  String get morningAdhkar => isArabic ? 'أذكار الصباح' : 'Morning Adhkar';
  String get eveningAdhkar => isArabic ? 'أذكار المساء' : 'Evening Adhkar';
  String get resetCounters =>
      isArabic ? 'إعادة ضبط العدادات' : 'Reset Counters';
  String get adhkarCountersResetSuccess =>
      isArabic ? 'تمت إعادة ضبط عدادات الأذكار' : 'Adhkar counters have been reset';
  String get dhikrCopiedSuccess =>
      isArabic ? 'تم نسخ نص الذكر الشريف بنجاح' : 'Dhikr copied successfully';
  String dhikrIndex(dynamic index) =>
      isArabic ? 'ذكر $index' : 'Dhikr $index';
  String get copyDhikr => isArabic ? 'نسخ نص الذكر' : 'Copy Dhikr';
  String get completed => isArabic ? 'اكتمل' : 'Completed';
  String remainingCount(dynamic count) =>
      isArabic ? 'باقٍ $count' : '$count remaining';
  String get once => isArabic ? 'مرة واحدة' : 'Once';

  // Ahlulbayt & Hadith Duas
  String get searchAhlulbaytHint => isArabic
      ? 'ابحث في أدعية أهل البيت والصحيفة السجادية...'
      : 'Search Ahlulbayt supplications & Al-Sahifa...';
  String ahlulbaytDuasCountBadge(dynamic count) =>
      isArabic ? '$count دعاء مأثور' : '$count supplications';
  String get ahlulbaytDuasScreenTitle =>
      isArabic ? 'أدعية أهل البيت عليهم السلام' : 'Supplications of Ahlulbayt';
  String get copyFullDua =>
      isArabic ? 'نسخ الدعاء كاملاً' : 'Copy full supplication';
  String get fullDuaCopiedSuccess => isArabic
      ? 'تم نسخ نص الدعاء كاملاً إلى الحافظة'
      : 'Full supplication text copied to clipboard';
  String get decreaseFontSize =>
      isArabic ? 'تصغير الخط' : 'Decrease font size';
  String get increaseFontSize =>
      isArabic ? 'تكبير الخط' : 'Increase font size';
  String get fullAuthenticText =>
      isArabic ? 'نص كامل ومأثور' : 'Full Authentic Text';
  String searchGeneralDuasHint(String title) =>
      isArabic ? 'ابحث في $title...' : 'Search in $title...';
  String generalDuasCountBadge(dynamic count) =>
      isArabic ? '$count دعاء مبارك' : '$count supplications';
  String duaIndex(dynamic index) =>
      isArabic ? 'دعاء $index' : 'Dua $index';
  String get copyDuaTooltip =>
      isArabic ? 'نسخ نص الدعاء' : 'Copy supplication text';

  // Books & Pamphlets Reader
  String get tableOfContents =>
      isArabic ? 'فهرس المباحث' : 'Table of Contents';
  String bookIndexPrefix(String title) =>
      isArabic ? 'فهرس: $title' : 'Index: $title';
  String pageOfTotal(dynamic page, dynamic total) =>
      isArabic ? 'صفحة $page من $total' : 'Page $page of $total';
  String sectionOfTotal(dynamic section, dynamic total) =>
      isArabic ? 'المبحث $section من $total' : 'Section $section of $total';
  String get previousSection =>
      isArabic ? 'المبحث السابق' : 'Previous Section';
  String get nextSection =>
      isArabic ? 'المبحث التالي' : 'Next Section';
  String get previousDua =>
      isArabic ? 'الدعاء السابق' : 'Previous Dua';
  String get nextDua =>
      isArabic ? 'الدعاء التالي' : 'Next Dua';
  String get shareFile =>
      isArabic ? 'مشاركة الملف' : 'Share File';
  String get copyContent =>
      isArabic ? 'نسخ المحتوى' : 'Copy Content';
  String get preparingDocument => isArabic
      ? 'جاري تجهيز وعرض الملزمة...'
      : 'Preparing and loading document...';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get openAndReadPdf =>
      isArabic ? 'فتح ومطالعة ملف PDF' : 'Open & Read PDF';
  String get noTextContentAvailable => isArabic
      ? 'لا يتوفر محتوى نصي لهذه الملزمة حالياً.'
      : 'No text content available for this publication currently.';
  String searchSectionHint(String name) => isArabic
      ? 'ابحث في محتويات وعناوين $name...'
      : 'Search contents and titles of $name...';
  String get verifiedPamphletPdf =>
      isArabic ? 'ملزمة موثقة • PDF' : 'Verified Booklet • PDF';
  String fullSectionsCount(dynamic count) =>
      isArabic ? '$count مباحث كاملة' : '$count Full Sections';
  String get directTextReading =>
      isArabic ? 'قراءة نصية مباشرة' : 'Direct Text Reading';
  String get textCopied =>
      isArabic ? 'تم نسخ النص إلى الحافظة بنجاح.' : 'Text copied to clipboard successfully.';
  String get fileNotFound =>
      isArabic ? 'الملف غير موجود على الجهاز.' : 'File not found on device.';
  String fileShareError(dynamic error) => isArabic
      ? 'تعذر مشاركة أو فتح الملف: $error'
      : 'Could not share or open file: $error';
  String pdfReadError(dynamic error) => isArabic
      ? 'تعذر قراءة ملف الـ PDF: $error'
      : 'Could not read PDF file: $error';
  String fileContentReadError(dynamic error) => isArabic
      ? 'تعذر قراءة محتوى الملف: $error'
      : 'Could not read file content: $error';
  String get noTextContent =>
      isArabic ? 'لا يوجد محتوى نصي.' : 'No text content available.';
  String get textFile => isArabic ? 'ملف نصي' : 'Text File';

  // Ayah Links Views
  String get openInQuran =>
      isArabic ? 'فتح في المصحف' : 'Open in Quran';
  String get editVerseNote =>
      isArabic ? 'تعديل الملاحظة' : 'Edit Note';
  String get removeVerseFromLink =>
      isArabic ? 'إزالة من الرابط' : 'Remove from Link';
  String get removeAyahFromLinkTitle =>
      isArabic ? 'إزالة الآية من الرابط' : 'Remove Ayah from Link';
  String removeAyahFromLinkConfirm(dynamic ayah, dynamic surah) => isArabic
      ? 'هل تريد إزالة الآية $ayah من سورة $surah من هذا الرابط؟'
      : 'Do you want to remove Ayah $ayah of Surah $surah from this link?';
  String get reflectionNote =>
      isArabic ? 'ملاحظة التدبر' : 'Reflection Note';
  String get reflectionNoteColon =>
      isArabic ? 'ملاحظة التدبر:' : 'Reflection note:';
  String get ayahReflectionNoteTitle =>
      isArabic ? 'ملاحظة التدبر على الآية' : 'Ayah Reflection Note';
  String get ayahReflectionNoteHint => isArabic
      ? 'اكتب تدبرك أو الرابط الذي لاحظته...'
      : 'Write your reflection or the connection you noted...';
  String get noAyahsAddedToLink => isArabic
      ? 'لم تتم إضافة أي آيات لهذا الرابط بعد'
      : 'No verses have been added to this link yet';
  String get addAyahsToBuildMap => isArabic
      ? 'أضف الآيات التي لاحظت ارتباطها لبناء خريطتك التدبرية'
      : 'Add connected verses to build your reflection map';
  String get addAyah => isArabic ? 'إضافة آية' : 'Add Verse';
  String get previous => isArabic ? 'السابق' : 'Previous';
  String get next => isArabic ? 'التالي' : 'Next';
  String get allCategories => isArabic ? 'الكل' : 'All';

  // Tasbeeh & Istighfar
  String get istighfar => isArabic ? 'الاستغفار' : 'Istighfar';
  String get tasbeeh => isArabic ? 'التسبيح' : 'Tasbeeh';
  String get browseAllFormulas =>
      isArabic ? 'استعراض كل الصيغ' : 'Browse All Formulas';
  String get resetCycleCounter =>
      isArabic ? 'تصفير عداد الدورة' : 'Reset Cycle Counter';
  String get resetCycleCounterTitle =>
      isArabic ? 'تصفير عداد الدورة؟' : 'Reset cycle counter?';
  String get resetCycleCounterConfirm => isArabic
      ? 'سيتم إعادة عداد الدورة الحالية إلى الصفر مع الحفاظ التام على مجموعك الإجمالي المحفوظ.'
      : 'The current cycle count will be reset to zero while preserving your total saved count.';
  String get resetCycleAction =>
      isArabic ? 'تصفير الدورة' : 'Reset Cycle';
  String get tapAnywhereToCount =>
      isArabic ? 'انقر في أي مكان للعدّ' : 'Tap anywhere to count';
  String targetCount(dynamic target) =>
      isArabic ? 'الهدف: $target' : 'Target: $target';
  String get freeCount => isArabic ? 'عدّ حر' : 'Free count';
  String get freeCountOpen =>
      isArabic ? 'عدّ حر (مفتوح)' : 'Free count (open)';
  String countTimes(dynamic count) =>
      isArabic ? '$count مرة' : '$count times';
  String get autoAdvanceUponCompletion => isArabic
      ? 'التبديل التلقائي عند اكتمال الورد'
      : 'Auto-advance upon completion';
  String get todayCount =>
      isArabic ? 'استغفار وتسبيح اليوم' : "Today's Count";
  String get lifetimeTotalCount =>
      isArabic ? 'المجموع الكلي المحفوظ' : 'Total Lifetime Count';
  String formulaXOfY(dynamic current, dynamic total) =>
      isArabic ? 'صيغة $current من $total' : 'Formula $current of $total';
  String allFormulasCount(dynamic total) =>
      isArabic ? 'كل الصيغ ($total)' : 'All formulas ($total)';
  String get copyDhikrTooltip =>
      isArabic ? 'نسخ نص الذكر' : 'Copy dhikr';
  String get dhikrCopied => isArabic
      ? 'تم نسخ نص الذكر إلى الحافظة بنجاح.'
      : 'Dhikr copied to clipboard successfully.';
  String targetReachedAuto(dynamic target) => isArabic
      ? 'ما شاء الله! أتممت الورد ($target). تم الانتقال تلقائياً إلى الذكر التالي.'
      : 'MashaAllah! Target completed ($target). Auto-advanced to next dhikr.';
  String targetReached(dynamic target) => isArabic
      ? 'ما شاء الله! أتممت الورد المستهدف ($target) بنجاح.'
      : 'MashaAllah! Target ($target) completed successfully.';
  String get tasbeehAndIstighfarFormulas =>
      isArabic ? 'صيغ الاستغفار والتسبيح' : 'Tasbeeh & Istighfar Formulas';
  String get searchDhikrHint =>
      isArabic ? 'ابحث في نصوص الأذكار...' : 'Search in dhikr texts...';
  String get noMatchingFormulas =>
      isArabic ? 'لا توجد صيغ مطابقة للبحث' : 'No matching formulas found';
  String get swipeOrTapToChange =>
      isArabic ? 'اسحب أفقياً أو انقر للتبديل' : 'Swipe horizontally or tap to cycle';
  String get nextDhikr => isArabic ? 'الذكر التالي' : 'Next Dhikr';
  String get previousDhikr => isArabic ? 'الذكر السابق' : 'Previous Dhikr';
  /// زر تفعيل وضع العد التلقائي للسبحة.
  String get autoCount => isArabic ? 'عدّ تلقائي' : 'Auto Count';
  /// زر إيقاف العد التلقائي المؤقت للسبحة.
  String get stopAutoCount => isArabic ? 'إيقاف' : 'Pause';
  /// عرض مدة الإيقاع الزمني المحسوب لكل عَدّة بالثواني.
  String smartPaceSeconds(dynamic seconds) =>
      isArabic ? 'إيقاع $seconds ث' : 'Pace ${seconds}s';
  /// تلميح تسريع وتيرة العد التلقائي.
  String get decreasePace => isArabic ? 'تسريع الوتيرة' : 'Faster pace';
  /// تلميح إبطاء وتيرة العد التلقائي وتدبر الذكر.
  String get increasePace => isArabic ? 'إبطاء الوتيرة' : 'Slower pace';

  // Books
  String get booksSectionEmpty => isArabic
      ? 'قسم الكتب والملازم فارغ حالياً'
      : 'Books & booklets section is currently empty';
  String get booksSectionEmptyDescription => isArabic
      ? 'لم تتم إضافة أي أقسام أو كتب في ملفات التطبيق حتى الآن.'
      : 'No sections or books have been added yet.';
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
