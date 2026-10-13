import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'book_model.dart';
import 'book_reader_screen.dart';
import 'book_repository.dart';

/// شاشة تصفح واستعراض مكتبة الكتب والملازم التدبرية.
/// تعرض الأقسام والملازم المعرفة برمجياً من قبل المطور في ملفات التطبيق.
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final BookRepository _repo = BookRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';
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

  List<BookModel> get _filteredBooks {
    final list = _repo.getBooksBySection(_selectedCategory);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final filtered = _filteredBooks;
    final categories = _repo.categoryNames;

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
                    prefixIcon: Icon(Icons.search_rounded,
                        color: primaryColor, size: 20),
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
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // شرائح تصنيفات الأقسام
            if (categories.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final count = _repo.getBooksBySection(cat).length;
                    final label = cat == 'الكل' ? 'الكل ($count)' : '$cat ($count)';

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

            // قائمة الكتب أو شاشة الحالة الفارغة
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(isDark, primaryColor)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = filtered[index];
                        return _BookCard(
                          book: book,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookReaderScreen(book: book),
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
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = book.isPdf;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة نوع الملزمة
            Container(
              width: 48,
              height: 48,
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
                              : AppColors.olive)
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_rounded
                    : (book.hasAttachedFile
                        ? Icons.description_rounded
                        : Icons.menu_book_rounded),
                color: isPdf
                    ? Colors.redAccent
                    : (isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // تفاصيل الكتاب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkAccentGold
                                  : AppColors.olive)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.oliveDark,
                          ),
                        ),
                      ),
                      if (book.hasAttachedFile) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPdf ? 'PDF' : 'مستند نصي',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      book.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (book.author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // سهم الانتقال للقراءة
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
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
