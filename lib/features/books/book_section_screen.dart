import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool get _isMalazemSection =>
      widget.section.name == 'ملازم السيد حسين الحوثي';

  List<BookModel> get _allSectionBooks =>
      _repo.getBooksBySection(widget.section.name);

  List<BookModel> get _filteredBooks {
    var list = _allSectionBooks;

    // تصفية السلاسل لملازم السيد حسين الحوثي
    if (_isMalazemSection && _selectedMalazemSeries != 'الكل') {
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

  String _formatSeriesLabel(String series, List<BookModel> allBooks) {
    if (series == 'الكل') {
      return 'الكل (${allBooks.length})';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filtered = _filteredBooks;
    final allBooks = _allSectionBooks;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            widget.section.name,
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
                      hintText: _isMalazemSection
                          ? 'ابحث في عناوين ملازم السيد حسين...'
                          : 'ابحث في كتب ومباحث هذا القسم...',
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

              // شرائح السلاسل (تظهر حصرياً لملازم السيد حسين الحوثي)
              if (_isMalazemSection && allBooks.isNotEmpty)
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
                    ? 'لا توجد نتائج مطابقة لبحثك'
                    : 'هذا القسم فارغ حالياً',
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
                    ? 'جرّب البحث بكلمة أخرى أو اختر تصنيفاً أو سلسلة أخرى.'
                    : 'لم تتم إضافة أي ملازم أو كتب في هذا القسم بعد.',
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

            // مؤشر السهم
            Icon(
              Icons.arrow_back_ios_new_rounded,
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
