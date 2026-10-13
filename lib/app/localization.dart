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

  /// استرجاع نطاق الترجمة الحالي من سياق البناء.
  static AppLocalizationScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationScope>();
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
  /// النصوص المترجمة المرتبطة باللغة الحالية.
  AppStrings get l10n => AppLocalizationScope.of(this).strings;

  /// اللغة المفعّلة حالياً في الواجهة.
  AppLanguage get currentLanguage =>
      AppLocalizationScope.of(this).currentLanguage;
}
