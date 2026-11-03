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
///
/// كل نص يأتي من [AppLocalizations] مباشرة؛ وهنا فقط ما يضيف عليه شيئاً، كتحويل
/// الأرقام.
extension type AppStrings._(AppLocalizations _l) implements AppLocalizations {
  factory AppStrings(AppLanguage language) =>
      AppStrings._(language == AppLanguage.arabic ? _ar : _en);

  // تُولَّد الترجمات من lib/l10n/app_ar.arb و app_en.arb.
  static final AppLocalizations _ar = lookupAppLocalizations(
    const Locale('ar'),
  );
  static final AppLocalizations _en = lookupAppLocalizations(
    const Locale('en'),
  );
  AppLanguage get language => AppLanguage.fromCode(_l.localeName);

  bool get isArabic => language == AppLanguage.arabic;

  /// يكتب الأرقام بالأرقام العربية الهندية في الواجهة العربية.
  String digits(Object? value) =>
      isArabic ? ArabicSearchNormalizer.convertDigits('$value') : '$value';

  String _n(Object? value) => ArabicSearchNormalizer.convertDigits('$value');

  // مقدمة التدبر
  String get tadbeerVerse =>
      'أَفَلَا يَتَدَبَّرُونَ الْقُرْآنَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَا';

  // قارئ المصحف والقائمة الجانبية
  String pageNumber(int page) => _l.pageNumber(digits(page));

  String juzNumber(int juz) => _l.juzNumber(digits(juz));

  String hizbNumber(int hizb) => _l.hizbNumber(digits(hizb));

  // خريطة المصحف وسجل التدبر
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
  String shortDate(DateTime d) => isArabic
      ? _n('${d.day}/${d.month}/${d.year}')
      : '${d.day}/${d.month}/${d.year}';

  // مسارات التدبر
  String daysOfTotal(int a, int b) => _l.daysOfTotal(digits(a), digits(b));
  String dayN(int n) => _l.dayN(digits(n));

  // الحفظ
  String versesMemorized(int n) => _l.versesMemorized(digits(n));
  String reviewToday(int n) => _l.reviewToday(digits(n));
  String versesOfTotal(int a, int b) => _l.versesOfTotal(digits(a), digits(b));
  String sessionSummary(int a, int b) =>
      _l.sessionSummary(digits(a), digits(b));

  // الختمة المتتابعة
  String fromMyPosition(int page) => _l.fromMyPosition(digits(page));
  String reachedPage(int page) => _l.reachedPage(digits(page));

  String portionReminderTitle(int pages) =>
      _l.portionReminderTitle(digits(pages));
  String portionLeftTitle(int pages) => _l.portionLeftTitle(digits(pages));

  /// يملأ الودجت الأرقام بنفسه، فتبقى هنا متغيرات.
  String get widgetPortionLeftTemplate =>
      _l.widgetPortionLeft('{left}', '{portion}');
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

  String chapterN(int n) => _l.chapterN(digits(n));

  /// اسم [AppColorTheme] بحسب ترتيبه.
  String colorThemeName(int i) => isArabic
      ? const ['كحلي', 'زمردي', 'عنابي', 'بني خشبي', 'تركوازي'][i]
      : const ['Navy', 'Emerald', 'Burgundy', 'Brown', 'Teal'][i];

  // رحلة القراءة والختمة
  String daysCount(int d) => _l.daysCount(d, digits(d));
  String pagesPerDayHint(int n) => _l.pagesPerDayHint(digits(n));
  String completedKhatmas(int n) => _l.completedKhatmas(digits(n));
  String behindBy(int n) => _l.behindBy(digits(n));
  String khatmaInDays(int n) => _l.khatmaInDays(n, digits(n));
  String dayOfPlan(int d, int total) => _l.dayOfPlan(digits(d), digits(total));
  String pagesOfTarget(int a, int b) => _l.pagesOfTarget(digits(a), digits(b));
  String continueFromPage(int p) => _l.continueFromPage(digits(p));

  /// اسم مختصر ليوم الأسبوع ([DateTime.weekday]: ١ = الإثنين).
  String weekdayShort(int weekday) => isArabic
      ? const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'][weekday - 1]
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];

  String ayahCount(int count) => _l.ayahCount(digits(count));

  // نافذة إجراءات الآية
  String deleteAllDownloadsConfirm(String name) =>
      _l.deleteAllDownloadsConfirm(name);
  String downloadsSize(String size) => _l.downloadsSize(size);
  String secondsShort(int n) => _l.secondsShort(digits(n));
  String qiblaTurnRight(int deg) => _l.qiblaTurnRight(digits(deg));
  String qiblaTurnLeft(int deg) => _l.qiblaTurnLeft(digits(deg));
  String streakAtRiskTitle(int n) => _l.streakAtRiskTitle(n, digits(n));
  String streakReminderAt(String time) => _l.streakReminderAt(time);
  String reflectionsCount(int count, String shown) =>
      _l.reflectionsCount(count, shown);

  // روابط الآيات

  String versesCount(int count) => _l.versesCount(digits(count));

  // بطاقات الشاشة الرئيسية
  String duasCountBadge(dynamic count) => _l.duasCountBadge(digits(count));
  String adhkarCountBadge(dynamic count) => _l.adhkarCountBadge(digits(count));

  // صيغ المراجع القرآنية
  String readingPosition(String surahName, dynamic page) =>
      _l.readingPosition(surahName, digits(page));
  String ayahReference(String surahName, dynamic ayahNumber) =>
      _l.ayahReference(surahName, digits(ayahNumber));
  String surahTitle(String surahName) => _l.surahTitle(surahName);
  String ayahTitle(dynamic ayahNumber) => _l.ayahTitle(digits(ayahNumber));
  String pageAbbr(dynamic page) => _l.pageAbbr(digits(page));
  String juzAbbr(dynamic juz) => _l.juzAbbr(digits(juz));
  String ayahsCount(dynamic count) => _l.ayahsCount(digits(count));
  String wordSearchResultsCount(dynamic count) =>
      _l.wordSearchResultsCount(digits(count));
  String surahAyahPageReference(
    String surahName,
    dynamic ayahNumber,
    dynamic page,
  ) => _l.surahAyahPageReference(surahName, digits(ayahNumber), digits(page));

  // الإجراءات والحوارات العامة
  String linkedAyahsCount(dynamic count) => _l.linkedAyahsCount(digits(count));

  // إعداد التذكيرات
  String reminderScheduledSuccess(String mode) =>
      _l.reminderScheduledSuccess(mode);

  // إعداد النسخ الاحتياطي
  String errorSavingFile(dynamic err) => _l.errorSavingFile('$err');

  // الأدعية والأذكار
  String dhikrIndex(dynamic index) => _l.dhikrIndex(digits(index));
  String remainingCount(dynamic count) => _l.remainingCount(digits(count));

  // أدعية أهل البيت
  String ahlulbaytDuasCountBadge(dynamic count) =>
      _l.ahlulbaytDuasCountBadge(digits(count));
  String searchGeneralDuasHint(String title) => _l.searchGeneralDuasHint(title);
  String generalDuasCountBadge(dynamic count) =>
      _l.generalDuasCountBadge(digits(count));
  String duaIndex(dynamic index) => _l.duaIndex(digits(index));

  // قارئ الكتب والملازم
  String bookIndexPrefix(String title) => _l.bookIndexPrefix(title);
  String pageOfTotal(dynamic page, dynamic total) =>
      _l.pageOfTotal(digits(page), digits(total));
  String sectionOfTotal(dynamic section, dynamic total) =>
      _l.sectionOfTotal(digits(section), digits(total));
  String searchSectionHint(String name) => _l.searchSectionHint(name);
  String fullSectionsCount(dynamic count) =>
      _l.fullSectionsCount(digits(count));
  String fileShareError(dynamic error) => _l.fileShareError('$error');

  // عروض روابط الآيات
  String removeAyahFromLinkConfirm(dynamic ayah, dynamic surah) =>
      _l.removeAyahFromLinkConfirm(digits(ayah), digits(surah));

  // الاستغفار والتسبيح
  String targetCount(dynamic target) => _l.targetCount(digits(target));
  String countTimes(dynamic count) => _l.countTimes(digits(count));
  String get todayCount => isArabic ? 'استغفار وتسبيح اليوم' : "Today's Count";
  String formulaXOfY(dynamic current, dynamic total) =>
      _l.formulaXOfY(digits(current), digits(total));
  String allFormulasCount(dynamic total) => _l.allFormulasCount(digits(total));
  String targetReachedAuto(dynamic target) =>
      _l.targetReachedAuto(digits(target));
  String targetReached(dynamic target) => _l.targetReached(digits(target));

  /// مدة الإيقاع لكل عَدّة، بالثواني.
  String smartPaceSeconds(dynamic seconds) =>
      _l.smartPaceSeconds(digits(seconds));

  // نصوص الشاشات
  String pdfReadFailed(String error) => _l.pdfReadFailed(error);
  String fileReadFailed(String error) => _l.fileReadFailed(error);
  String pdfShowFailed(String error) => _l.pdfShowFailed(error);
  String pdfPageFailed(String page, String error) =>
      _l.pdfPageFailed(page, error);
  String booksCountLabel(String count) => _l.booksCountLabel(count);
  String meaningsBadge(String count) => _l.meaningsBadge(count);
  String wordMeaningsCount(String count) => _l.wordMeaningsCount(count);
  String pageWordMeanings(String page) => _l.pageWordMeanings(page);
  String wordsCount(String count) => _l.wordsCount(count);
  String pageAbbrOfTotal(dynamic page, dynamic total) =>
      _l.pageAbbrOfTotal(digits(page), digits(total));
  String guideStep(int step, int total) =>
      _l.guideStep(digits(step), digits(total));
  String exportNoteFailed(Object error) => _l.exportNoteFailed('$error');
  String noteWordCharCount(int words, int chars) =>
      _l.noteWordCharCount(digits(words), digits(chars));
  String searchInSection(String section) => _l.searchInSection(section);
  String verseAddedToLink(String title) => _l.verseAddedToLink(title);
  String reflectionNotesCount(int count) =>
      _l.reflectionNotesCount(digits(count));
  String connectedVersesCount(int count) =>
      _l.connectedVersesCount(digits(count));
  String deleteLinkConfirm(String title) => _l.deleteLinkConfirm(title);
  String linkDeleted(String title) => _l.linkDeleted(title);
  String itemCopied(String title) => _l.itemCopied(title);
  String duaAlert(String text) => _l.duaAlert(text);
  String questionOfTotal(int number, int total) =>
      _l.questionOfTotal(digits(number), digits(total));
  String systemThemeLabel(String mode) => _l.systemThemeLabel(mode);
  String systemThemeExplanation(String mode) => _l.systemThemeExplanation(mode);
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
      AppStrings(AppLanguage.arabic);

  /// اللغة الحالية، أو العربية إن لم يوجد [AppLocalizationScope].
  AppLanguage get currentLanguage =>
      AppLocalizationScope.maybeOf(this)?.currentLanguage ?? AppLanguage.arabic;
}
