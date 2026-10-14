import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'book_model.dart';
import 'book_reader_screen.dart';
import 'book_repository.dart';

/// شاشة تصفح واستعراض مكتبة الكتب والملازم التدبرية.
/// مقسمة إلى أقسام رئيسية: ملازم السيد حسين، تراث أهل البيت (ع)، وعلوم القرآن.
class BooksScreen extends StatefulWidget {
  final String? initialSection;

  const BooksScreen({
    super.key,
    this.initialSection,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final BookRepository _repo = BookRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  late String _selectedCategory;
  String _selectedMalazemSeries = 'الكل';
  String _searchQuery = '';

  static const List<String> _malazemSeriesList = [
    'الكل',
    'سلسلة معرفة الله',
    'سلسلة مديح القرآن',
    'سلسلة دروس رمضان المبارك',
    'سلسلة هدي القرآن: مدارسة سورة آل عمران',
    'سلسلة هدي القرآن: مدارسة سورة المائدة',
    'في ظلال الأدعية المباركة',
    'في ظلال العبادة والتقوى',
    'المحاضرات الكبرى والمناسبات',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialSection ?? 'الكل';
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

  List<BookModel> get _filteredBooks {
    var list = _repo.getBooksBySection(_selectedCategory);

    // إذا كان القسم المختار هو ملازم السيد حسين وتم اختيار سلسلة محددة
    if (_selectedCategory == 'ملازم السيد حسين الحوثي' &&
        _selectedMalazemSeries != 'الكل') {
      list = list.where((b) {
        if (_selectedMalazemSeries ==
            'سلسلة هدي القرآن: مدارسة سورة آل عمران') {
          return b.subtitle.contains('آل عمران');
        }
        if (_selectedMalazemSeries ==
            'سلسلة هدي القرآن: مدارسة سورة المائدة') {
          return b.subtitle.contains('المائدة');
        }
        if (_selectedMalazemSeries == 'المحاضرات الكبرى والمناسبات') {
          return b.subtitle.contains('المحاضرات') ||
              b.subtitle.contains('دروس من هدي القرآن الكريم') ||
              b.subtitle.contains('فهرس');
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

  String _formatSeriesLabel(String series, List<BookModel> allSectionBooks) {
    if (series == 'الكل') {
      return 'الكل (${allSectionBooks.length})';
    }
    final count = allSectionBooks.where((b) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final filtered = _filteredBooks;
    final categories = _repo.categoryNames;
    final allMalazemBooks =
        _repo.getBooksBySection('ملازم السيد حسين الحوثي');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            l10n.booksAndBooklets,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // شريط البحث الموضعي
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ابحث في عناوين الملازم والكتب...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // شرائح أقسام المكتبة الرئيسية
              if (categories.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final count = _repo.getBooksBySection(cat).length;
                      final label =
                          cat == 'الكل' ? 'الكل ($count)' : '$cat ($count)';

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(label),
                          labelStyle: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                          ),
                          selectedColor: isDark
                              ? AppColors.darkAccentGold
                              : AppColors.oliveDark,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // شرائح سلاسل ملازم السيد حسين الحوثي (تظهر عند اختيار قسم الملازم)
              if (_selectedCategory == 'ملازم السيد حسين الحوثي' &&
                  allMalazemBooks.isNotEmpty)
                Container(
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.olive)
                      .withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _malazemSeriesList.map((series) {
                        final isSelected = _selectedMalazemSeries == series;
                        final label =
                            _formatSeriesLabel(series, allMalazemBooks);

                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(label),
                            labelStyle: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                            selectedColor: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.oliveDark,
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

              // قائمة الكتب والملازم
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
                          return _BookCard(
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.library_books_rounded,
                  size: 40,
                  color: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.oliveDark,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                hasSearch
                    ? 'لا توجد نتائج مطابقة لبحثك'
                    : 'قسم الكتب والملازم فارغ حالياً',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'جرّب البحث بكلمات أخرى أو اختر تصنيفاً آخر.'
                    : 'لم تتم إضافة أي ملازم أو كتب في ملفات التطبيق حتى الآن.\nيمكن للمطور إضافة الأقسام والملازم بسهولة عبر ملف curated_books.dart.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
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

class _BookCard extends StatelessWidget {
  final BookModel book;
  final bool isDark;
  final Color primaryColor;
  final int index;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.isDark,
    required this.primaryColor,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = book.isPdf;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            // أيقونة الكتاب / الملزمة
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.redAccent.withValues(alpha: 0.12)
                    : (isDark
                            ? AppColors.darkAccentGold
                            : AppColors.olive)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPdf
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : (isDark
                              ? AppColors.darkAccentGold
                              : AppColors.oliveDark)
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.menu_book_rounded,
                  color: isPdf
                      ? Colors.redAccent
                      : (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.oliveDark),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // عنوان الملزمة وتفاصيلها
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkAccentGold
                                  : AppColors.olive)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.subtitle.isNotEmpty
                              ? book.subtitle
                              : book.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.oliveDark,
                          ),
                        ),
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
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
                        ),
                      ],
                      if (book.chapters.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${book.chapters.length} مباحث',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.oliveDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // مؤشر القراءة الفورية
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
