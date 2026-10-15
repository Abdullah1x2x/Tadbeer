import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';

/// الشاشة الرئيسية المستقلة لقسم «معاني كلمات القرآن».
///
/// تتيح للمستخدم:
/// 1. استعراض الكلمات القرآنية الصعبة المعتمدة.
/// 2. البحث عن كلمة أو جزء منها أو معناها.
/// 3. التصفية حسب السورة.
/// 4. الانتقال إلى موضع الكلمة في المصحف الشريف بدقة.
/// 5. الوصول إلى صفحة المصادر المعتمدة.
class WordMeaningsScreen extends StatefulWidget {
  final int? initialSurahNumber;

  /// ينشئ شاشة معاني كلمات القرآن مع إمكانية التصفية المبدئية بسورة محددة.
  const WordMeaningsScreen({super.key, this.initialSurahNumber});

  /// ينشئ الحالة التفاعلية لشاشة معاني كلمات القرآن.
  @override
  State<WordMeaningsScreen> createState() => _WordMeaningsScreenState();
}

/// الحالة التفاعلية لشاشة استعراض والبحث في معاني كلمات القرآن الكريم.
class _WordMeaningsScreenState extends State<WordMeaningsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedSurah;
  List<QuranWordMeaning> _displayedWords = [];

  /// يهيئ السورة المختارة وقائمة الكلمات المعروضة ويستمع لتغيرات حقل البحث.
  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.initialSurahNumber;
    _filterWords();
    _searchController.addListener(_onSearchChanged);
  }

  /// يزيل مستمع البحث ويحرر متحكم النص عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// يعيد تصفية قائمة الكلمات المعروضة عند تغير نص البحث.
  void _onSearchChanged() {
    _filterWords();
  }

  /// يصفي معاني الكلمات القرآنية بناءً على نص البحث والسورة المحددة.
  void _filterWords() {
    final repo = QuranRepository.instance;
    final query = _searchController.text.trim();

    List<QuranWordMeaning> list;
    if (query.isNotEmpty) {
      list = repo.searchWordMeanings(query, limit: 300);
      if (_selectedSurah != null) {
        list = list.where((w) => w.surah == _selectedSurah).toList();
      }
    } else if (_selectedSurah != null) {
      list = repo.getWordMeaningsForSurah(_selectedSurah!);
    } else {
      list = repo.allWordMeanings;
    }

    setState(() {
      _displayedWords = list;
    });
  }

  /// يبني واجهة شاشة معاني كلمات القرآن مع أدوات البحث والتصفية وقائمة النتائج.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = QuranRepository.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahs = repo.surahs;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: Text(
            l10n.wordMeaningsScreenTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Top Filter and Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchWordMeaningsHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.comsilkLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Surah Filter Dropdown
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.comsilkLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.6,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _selectedSurah,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                              hint: Text(l10n.allSurahsWithCount),
                              dropdownColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.comsilkLight,
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(l10n.allSurahsWithCount),
                                ),
                                ...surahs.map(
                                  (s) => DropdownMenuItem<int?>(
                                    value: s.number,
                                    child: Text(
                                      '${context.currentLanguage == AppLanguage.arabic ? "${ArabicSearchNormalizer.toArabicDigits(s.number)}. " : "${s.number}. "}${l10n.surahTitle(s.name)}',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSurah = val;
                                });
                                _filterWords();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Results count header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.wordSearchResultsCount(
                        context.currentLanguage == AppLanguage.arabic
                            ? ArabicSearchNormalizer.toArabicDigits(_displayedWords.length)
                            : _displayedWords.length,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedSurah != null || _searchController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _selectedSurah = null;
                        });
                        _filterWords();
                      },
                      child: Text(
                        l10n.resetToDefault,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.olive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Words List
            Expanded(
              child: _displayedWords.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _displayedWords.length,
                      itemBuilder: (context, index) {
                        final item = _displayedWords[index];
                        final surah = repo.getSurah(item.surah);
                        return _WordCard(
                          item: item,
                          surahName: surah.name,
                          isDark: isDark,
                          onNavigateToMushaf: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuranScreen(
                                  initialPage: item.page,
                                  targetSurahNumber: item.surah,
                                  targetAyahNumber: item.ayah,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// يبني واجهة الحالة الفارغة عند عدم العثور على كلمات مطابقة للبحث أو التصفية.
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noWordsFound,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.noWordsFoundSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يعرض نافذة سفلية بتفاصيل معنى الكلمة القرآنية وموضعها ومصدرها المعتمد.
void _showWordDetailsModal(
  BuildContext context,
  QuranWordMeaning item,
  String surahName,
  bool isDark,
) {
  final l10n = context.l10n;
  final isArabic = context.currentLanguage == AppLanguage.arabic;
  final ayahDigits = isArabic ? ArabicSearchNormalizer.toArabicDigits(item.ayah) : item.ayah;
  final pageDigits = isArabic ? ArabicSearchNormalizer.toArabicDigits(item.page) : item.page;

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: context.currentLanguage.direction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.word,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.oliveLight : AppColors.olive,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.olive : AppColors.oliveLight)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.surahAyahPageReference(surahName, ayahDigits, pageDigits),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.lexicalMeaningTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meaning,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: isDark ? AppColors.oliveLight : AppColors.olive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.sourceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    if (item.sourceUrl != null)
                      Text(
                        l10n.verifiedDocumentation,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// بطاقة عرض الكلمة القرآنية ومعناها مع زر الانتقال المباشر إلى موضعها في المصحف.
class _WordCard extends StatelessWidget {
  final QuranWordMeaning item;
  final String surahName;
  final bool isDark;
  final VoidCallback onNavigateToMushaf;

  /// ينشئ بطاقة عرض الكلمة القرآنية ومعناها.
  const _WordCard({
    required this.item,
    required this.surahName,
    required this.isDark,
    required this.onNavigateToMushaf,
  });

  /// يبني واجهة بطاقة الكلمة القرآنية ومعناها المعجمي.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = context.currentLanguage == AppLanguage.arabic;
    final ayahDigits = isArabic ? ArabicSearchNormalizer.toArabicDigits(item.ayah) : item.ayah;
    final pageDigits = isArabic ? ArabicSearchNormalizer.toArabicDigits(item.page) : item.page;

    return InkWell(
      onTap: () => _showWordDetailsModal(context, item, surahName, isDark),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Word & Surah/Ayah badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quranic Word
                Expanded(
                  child: Text(
                    item.word,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.oliveLight : AppColors.olive,
                    ),
                  ),
                ),

              // Surah & Ayah Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.comsilkLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 0.6,
                  ),
                ),
                child: Text(
                  l10n.ayahReference(surahName, ayahDigits),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Jump to Mushaf Page Button
              InkWell(
                onTap: onNavigateToMushaf,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.olive : AppColors.oliveLight)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.oliveLight
                            : AppColors.oliveDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pageAbbr(pageDigits),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Arabic Lexical Meaning
          Text(
            item.meaning,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
}

/// صفحة «المصادر المعتمدة» لمعاني كلمات القرآن.
class WordMeaningsSourcesScreen extends StatelessWidget {
  /// ينشئ شاشة المصادر المعتمدة لمعاني كلمات القرآن.
  const WordMeaningsSourcesScreen({super.key});

  /// يبني واجهة شاشة المصادر المعتمدة وتفاصيل التوثيق والملكية الفكرية.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 0,
          title: Text(
            l10n.approvedSourcesTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro Callout Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.olive : AppColors.oliveLight)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? AppColors.oliveLight : AppColors.olive)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: isDark ? AppColors.oliveLight : AppColors.olive,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تعتمد هذه الميزة تعريفات لغوية معجمية موجزة ومستقلة تماماً عن تفسير القرآن وسياق الآيات، مستمدة حصراً من أمهات المعاجم اللغوية المعتمدة دون تخمين.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Source 1: Al-Mu'jam Al-Waseet (Primary)
            _SourceCard(
              title: 'المعجم الوسيط',
              badge: 'المصدر الأساسي المعتمد',
              author: 'مجمع اللغة العربية بالقاهرة',
              details:
                  'إصدار مجمع اللغة العربية بالقاهرة — جمهورية مصر العربية.\n'
                  'المصدر المعجمي الأساسي المعتمد في التطبيق لاستخلاص التعريفات اللغوية المعجمية المجردة والموجزة للكلمات العربية.\n'
                  'الرابط الرسمي: https://www.arabicacademy.gov.eg/ar/',
              isPrimary: true,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Source 2: Doha Historical Dictionary
            _SourceCard(
              title: 'معجم الدوحة التاريخي للغة العربية',
              badge: 'مرجع التحقق للألفاظ القديمة',
              author: 'المركز العربي للأبحاث ودراسة السياسات (قطر)',
              details:
                  'مشروع معجم الدوحة التاريخي للغة العربية — الدوحة.\n'
                  'المرجع العلمي المعتمد للتحقق من الألفاظ العربية القديمة وشواهدها التاريخية وسياقاتها المعجمية الأولى.\n'
                  'الرابط الرسمي: https://www.dohadictionary.org/',
              isPrimary: false,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Source 3: Quranpedia.net & Classical Lexicons
            _SourceCard(
              title: 'الموسوعة القرآنية (Quranpedia.net) والمعاجم التراثية',
              badge: 'المصدر الرقمي والتراثي (نسخة 2026-10-10)',
              author: 'فريق الموسوعة القرآنية وأئمة اللغة والتفسير',
              details:
                  'الهيكلة الرقمية والربط بالآيات مستمدة من حزمة بيانات الموسوعة القرآنية المفتوحة (https://quranpedia.net — الإصدار 2026-10-10)، مع التحقق من أمهات المعاجم التراثية في الملكية العامة: لسان العرب لابن منظور، مقاييس اللغة لابن فارس، التبيان لابن الهائم، وتذكرة الأريب لابن الجوزي.',
              isPrimary: false,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Legal & Terms of Use Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تحقيق الملكية الفكرية وتراخيص الاستخدام',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• الموسوعة القرآنية (https://quranpedia.net — نسخة 2026-10-10): تتيح استخدام البيانات مجاناً داخل التطبيقات، وتشترط عند نشر قاعدة البيانات ذكر الموسوعة القرآنية مع الرابط ورقم الإصدار.\n'
                    '• معجم الدوحة التاريخي (dohadictionary.org): تنص شروط الاستخدام صراحةً على أن جميع مواده المعجمية وقواعد بياناته محمية بقوانين الملكية الفكرية، ويُمنع إنشاء أعمال مشتقة أو استخدام بياناته برمجياً في خدمات رقمية وتطبيقات دون إذن خطي مسبق من إدارة المشروع.\n'
                    '• المعجم الوسيط (arabicacademy.gov.eg): حقوقه محفوظة لمجمع اللغة العربية بالقاهرة، ولا يوفر واجهة API عامة، ويقتصر إدراج مفرداته في التطبيق على الاقتباس التوثيقي الموجز لأغراض غير تجارية مع نسبة كل تعريف إلى مصدره.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// بطاقة تعرض بيانات مصدر معجمي معتمد (العنوان، الشارة، المؤلف، والتفاصيل).
class _SourceCard extends StatelessWidget {
  final String title;
  final String badge;
  final String author;
  final String details;
  final bool isPrimary;
  final bool isDark;

  /// ينشئ بطاقة تعريف بمصدر معجمي معتمد.
  const _SourceCard({
    required this.title,
    required this.badge,
    required this.author,
    required this.details,
    required this.isPrimary,
    required this.isDark,
  });

  /// يبني واجهة بطاقة المصدر المعجمي.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? (isDark ? AppColors.oliveLight : AppColors.olive)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isPrimary ? 1.4 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? (isDark ? AppColors.oliveLight : AppColors.olive)
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? (isDark ? AppColors.olive : AppColors.oliveLight)
                          .withValues(alpha: 0.25)
                      : (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.comsilkLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? (isDark ? AppColors.oliveLight : AppColors.oliveDark)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'المؤلف: $author',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
