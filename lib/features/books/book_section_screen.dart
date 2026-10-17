import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'book_model.dart';
import 'book_reader_screen.dart';
import 'book_repository.dart';

/// شاشة استعراض محتويات قسم محدد من أقسام المكتبة.
/// تعرض قائمة الملازم أو الكتب التابعة لهذا القسم فقط مع تصفية وبحث موضعي.
class BookSectionScreen extends StatefulWidget {
  final BookSection section;

  const BookSectionScreen({
    super.key,
    required this.section,
  });

  @override
  State<BookSectionScreen> createState() => _BookSectionScreenState();
}

class _BookSectionScreenState extends State<BookSectionScreen> {
  final BookRepository _repo = BookRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedMalazemSeries = 'الكل';
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _repo.init();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _seriesList => widget.section.seriesFilterList;
  bool get _hasSeriesFilter => _seriesList.isNotEmpty;

  List<BookModel> get _allSectionBooks =>
      _repo.getBooksBySection(widget.section.name);

  List<BookModel> get _filteredBooks {
    var list = _allSectionBooks;

    // تصفية السلاسل التابعة للقسم في حال وجودها
    if (_hasSeriesFilter && _selectedMalazemSeries != 'الكل') {
      list = list.where((b) {
        if (_selectedMalazemSeries ==
            'سلسلة هدي القرآن: مدارسة سورة آل عمران') {
          return b.subtitle.contains('آل عمران') && !b.subtitle.contains('رمضان');
        }
        if (_selectedMalazemSeries ==
            'سلسلة هدي القرآن: مدارسة سورة المائدة') {
          return b.subtitle.contains('المائدة') && !b.subtitle.contains('رمضان');
        }
        if (_selectedMalazemSeries ==
            'سلسلة هدي القرآن: مدارسة سورة الصف') {
          return b.subtitle.contains('الصف') || b.title.contains('الصف');
        }
        if (_selectedMalazemSeries == 'فهرس وتوثيق الملازم') {
          return b.subtitle.contains('فهرس') || b.title.contains('فهرس');
        }
        if (_selectedMalazemSeries == 'المحاضرات الكبرى والمناسبات') {
          return (b.subtitle.contains('المحاضرات') ||
                  b.subtitle.contains('دروس من هدي القرآن الكريم')) &&
              !b.subtitle.contains('فهرس') &&
              !b.title.contains('فهرس');
        }
        return b.subtitle.contains(_selectedMalazemSeries);
      }).toList();
    }

    if (_searchQuery.trim().isEmpty) return list;

    final normQuery = ArabicSearchNormalizer.normalize(_searchQuery);
    return list.where((b) {
      final normTitle = ArabicSearchNormalizer.normalize(b.title);
      final normSubtitle = ArabicSearchNormalizer.normalize(b.subtitle);
      final normAuthor = ArabicSearchNormalizer.normalize(b.author);
      final normFileName =
          b.fileName != null ? ArabicSearchNormalizer.normalize(b.fileName!) : '';

      if (normTitle.contains(normQuery) ||
          normSubtitle.contains(normQuery) ||
          normAuthor.contains(normQuery) ||
          normFileName.contains(normQuery)) {
        return true;
      }

      return b.chapters.any((c) {
        final normChapTitle = ArabicSearchNormalizer.normalize(c.title);
        final normChapSummary = ArabicSearchNormalizer.normalize(c.summary);
        final normChapContent = ArabicSearchNormalizer.normalize(c.content);
        return normChapTitle.contains(normQuery) ||
            normChapSummary.contains(normQuery) ||
            normChapContent.contains(normQuery);
      });
    }).toList();
  }

  String _formatSeriesLabel(String series, List<BookModel> allBooks) {
    if (series == 'الكل') {
      return '${context.l10n.allCategories} (${allBooks.length})';
    }
    final count = allBooks.where((b) {
      if (series == 'سلسلة هدي القرآن: مدارسة سورة آل عمران') {
        return b.subtitle.contains('آل عمران');
      }
      if (series == 'سلسلة هدي القرآن: مدارسة سورة المائدة') {
        return b.subtitle.contains('المائدة');
      }
      if (series == 'المحاضرات الكبرى والمناسبات') {
        return b.subtitle.contains('المحاضرات') ||
            b.subtitle.contains('دروس من هدي القرآن الكريم') ||
            b.subtitle.contains('فهرس');
      }
      return b.subtitle.contains(series);
    }).length;

    var cleanName = series
        .replaceAll('سلسلة هدي القرآن: مدارسة ', '')
        .replaceAll('سلسلة ', '');
    return '$cleanName ($count)';
  }

  String _getSectionTitle(BuildContext context) {
    if (context.currentLanguage == AppLanguage.arabic) {
      return widget.section.name;
    }
    if (widget.section.name.contains('ملازم')) {
      return 'Huda Al-Quran Booklets';
    }
    if (widget.section.name.contains('تراث')) {
      return 'Ahlulbayt Heritage & Duas';
    }
    if (widget.section.name.contains('علوم')) {
      return 'Quranic Sciences & Reflection';
    }
    return widget.section.name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filtered = _filteredBooks;
    final allBooks = _allSectionBooks;
    final sectionTitle = _getSectionTitle(context);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            sectionTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // شريط البحث الموضعي داخل هذا القسم
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchSectionHint(sectionTitle),
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : Icon(
                              Icons.search_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // شرائح السلاسل (تظهر للأقسام التي تحدد سلاسل تصنيفية)
              if (_hasSeriesFilter && allBooks.isNotEmpty)
                Container(
                  color: (widget.section.color ?? primaryColor)
                      .withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _seriesList.map((series) {
                        final isSelected = _selectedMalazemSeries == series;
                        final label = _formatSeriesLabel(series, allBooks);

                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(label),
                            labelStyle: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                            selectedColor: widget.section.color ??
                                (isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.oliveDark),
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedMalazemSeries = series);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // قائمة كتب أو ملازم القسم
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(isDark, primaryColor)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final book = filtered[index];
                          return _SectionBookCard(
                            book: book,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            index: index + 1,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookReaderScreen(book: book),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    final hasSearch = _searchQuery.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.library_books_rounded,
                  size: 36,
                  color: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.oliveDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch
                    ? (context.l10n.isArabic
                        ? 'لا توجد نتائج مطابقة لبحثك'
                        : 'No results match your search')
                    : (context.l10n.isArabic
                        ? 'هذا القسم فارغ حالياً'
                        : 'This section is currently empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? (context.l10n.isArabic
                        ? 'جرّب البحث بكلمة أخرى أو اختر تصنيفاً أو سلسلة أخرى.'
                        : 'Try searching with another word or choose a different category.')
                    : (context.l10n.isArabic
                        ? 'لم تتم إضافة أي ملازم أو كتب في هذا القسم بعد.'
                        : 'No pamphlets or books have been added to this section yet.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBookCard extends StatelessWidget {
  final BookModel book;
  final bool isDark;
  final Color primaryColor;
  final int index;
  final VoidCallback onTap;

  const _SectionBookCard({
    required this.book,
    required this.isDark,
    required this.primaryColor,
    required this.index,
    required this.onTap,
  });

  String _formatChapterCount(BuildContext context) {
    final isArabic = context.currentLanguage == AppLanguage.arabic;
    if (book.badgeText != null && book.badgeText!.isNotEmpty) {
      if (!isArabic) {
        if (book.badgeText!.contains('دعاء')) {
          return '54 Complete Duas';
        }
        if (book.badgeText!.contains('حق')) {
          return '50 Detailed Rights';
        }
        if (book.badgeText!.contains('مواعظ')) {
          return 'Teachings & Sermons';
        }
      }
      return book.badgeText!;
    }
    if (book.isPdf) {
      return context.l10n.verifiedPamphletPdf;
    }
    if (book.chapters.isNotEmpty) {
      return context.l10n.fullSectionsCount(book.chapters.length);
    }
    return context.l10n.directTextReading;
  }

  Color _getBadgeColor() {
    if (book.badgeColor != null) {
      return book.badgeColor!;
    }
    if (book.isPdf) {
      return Colors.redAccent;
    }
    return primaryColor;
  }

  IconData _getBookIcon() {
    if (book.isPdf) {
      return Icons.picture_as_pdf_rounded;
    }
    return book.icon;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final iconData = _getBookIcon();
    final countLabel = _formatChapterCount(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. تفاصيل الكتاب وعنوانه (تبدأ من أقصى اليمين بأريحية كاملة)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (book.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      book.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          countLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      if (book.author.isNotEmpty)
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 2. أيقونة الكتاب وسهم الدخول (على أقصى اليسار)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: badgeColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  context.currentLanguage.direction == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
