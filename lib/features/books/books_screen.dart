import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'book_model.dart';
import 'book_reader_screen.dart';
import 'book_repository.dart';

/// شاشة مكتبة الملازم والكتب التدبرية وتنظيم الأقسام وإرفاق الملفات.
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
        final normChapContent = ArabicSearchNormalizer.normalize(c.content);
        return normChapTitle.contains(normQuery) ||
            normChapContent.contains(normQuery);
      });
    }).toList();
  }

  void _showAddSectionDialog() {
    HapticFeedback.lightImpact();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.create_new_folder_rounded,
                  color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'إضافة قسم جديد',
                style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'اسم القسم (مطلوب)',
                    hintText: 'مثال: ملازم التدبر، علوم القرآن، الفقه...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال اسم القسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'وصف مختصر للقسم (اختياري)',
                    hintText: 'نبذة عن محتويات هذا القسم...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.oliveDark,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  Navigator.pop(ctx);
                  await _repo.addSection(name: name, description: desc);
                  if (mounted) {
                    setState(() {
                      _selectedCategory = name;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة قسم «$name» بنجاح'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('إضافة القسم'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSection(BookSection section) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'حذف قسم «${section.name}»؟',
            style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'سيتم حذف هذا القسم وكافة الكتب والملازم المرفقة التابعة له من الذاكرة المحلية.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                await _repo.deleteSection(section.id);
                if (mounted) {
                  setState(() {
                    _selectedCategory = 'الكل';
                  });
                }
              },
              child: const Text('حذف القسم'),
            ),
          ],
        );
      },
    );
  }

  void _showAddBookBottomSheet() {
    HapticFeedback.lightImpact();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final authorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String currentSection = _selectedCategory == 'الكل'
        ? (_repo.sections.isNotEmpty ? _repo.sections.first.name : 'عام')
        : _selectedCategory;

    File? pickedFile;
    String? pickedFileName;
    int pickedFileSize = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryColor = Theme.of(ctx).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'إضافة كتاب أو ملزمة مع إرفاق ملف',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // اختيار أو تحديد القسم
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _repo.sections
                                        .any((s) => s.name == currentSection)
                                    ? currentSection
                                    : (_repo.sections.isNotEmpty
                                        ? _repo.sections.first.name
                                        : null),
                                decoration: const InputDecoration(
                                  labelText: 'القسم التابع له',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: _repo.sections.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s.name,
                                    child: Text(s.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => currentSection = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'إنشاء قسم جديد',
                              icon: const Icon(Icons.add_box_rounded),
                              color: primaryColor,
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showAddSectionDialog();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // عنوان الكتاب
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الكتاب أو الملزمة (مطلوب)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال عنوان الكتاب أو الملزمة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // المؤلف
                        TextField(
                          controller: authorController,
                          decoration: const InputDecoration(
                            labelText: 'المؤلف / المنسق / الجهة (اختياري)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // نبذة مختصرة
                        TextField(
                          controller: subtitleController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'نبذة أو وصف مختصر (اختياري)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // بطاقة إرفاق الملف
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.comsilk,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.attach_file_rounded,
                                      color: primaryColor, size: 20),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'الملف المرفق (PDF أو نص أو Markdown)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (pickedFile == null)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.file_upload_outlined),
                                  label: const Text(
                                      'اختيار ملف من الهاتف (PDF / TXT / MD)'),
                                  onPressed: () async {
                                    final files =
                                        await FilePicker.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'txt', 'md'],
                                    );
                                    if (files.isNotEmpty &&
                                        files.first.path != null) {
                                      final f = File(files.first.path!);
                                      final size = await f.length();
                                      setSheetState(() {
                                        pickedFile = f;
                                        pickedFileName = files.first.name;
                                        pickedFileSize = size;
                                      });
                                    }
                                  },
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppColors.darkAccentGold
                                            : AppColors.olive)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        pickedFileName!
                                                .toLowerCase()
                                                .endsWith('.pdf')
                                            ? Icons.picture_as_pdf_rounded
                                            : Icons.description_rounded,
                                        color: isDark
                                            ? AppColors.darkAccentGold
                                            : AppColors.oliveDark,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pickedFileName!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${(pickedFileSize / 1024).toStringAsFixed(1)} KB • جاهز للإرفاق',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'إزالة الملف',
                                        icon: const Icon(Icons.close_rounded,
                                            size: 18),
                                        onPressed: () {
                                          setSheetState(() {
                                            pickedFile = null;
                                            pickedFileName = null;
                                            pickedFileSize = 0;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // زر الحفظ
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.oliveDark,
                            foregroundColor:
                                isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final title = titleController.text.trim();
                              final author = authorController.text.trim();
                              final subtitle = subtitleController.text.trim();
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);

                              if (_repo.sections.isEmpty) {
                                await _repo.addSection(name: currentSection);
                              }

                              await _repo.addBook(
                                title: title,
                                sectionName: currentSection,
                                author: author,
                                subtitle: subtitle,
                                attachedFile: pickedFile,
                              );

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'تمت إضافة «$title» إلى قسم «$currentSection» بنجاح'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'حفظ وإضافة إلى المكتبة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBook(BookModel book) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'حذف «${book.title}»؟',
            style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'سيتم حذف هذا الكتاب والملف المرفق التابع له من الذاكرة المحلية.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                await _repo.deleteBook(book.id);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final filtered = _filteredBooks;
    final categories = _repo.categoryNames;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          l10n.booksAndBooklets,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إضافة قسم جديد',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _showAddSectionDialog,
          ),
          IconButton(
            tooltip: 'إضافة كتاب / ملزمة',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _showAddBookBottomSheet,
          ),
        ],
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
                    hintText: 'ابحث في عناوين الملازم والكتب والملفات...',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ...categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final sectionObj = _repo.sections
                        .where((s) => s.name == cat)
                        .firstOrNull;
                    final count = _repo.getBooksBySection(cat).length;
                    final label = cat == 'الكل' ? 'الكل ($count)' : '$cat ($count)';

                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onLongPress: sectionObj != null
                            ? () => _confirmDeleteSection(sectionObj)
                            : null,
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
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('قسم جديد'),
                    onPressed: _showAddSectionDialog,
                  ),
                ],
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
                          onDelete: () => _confirmDeleteBook(book),
                        );
                      },
                    ),
            ),
          ],
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
                    : 'يمكنك الآن إنشاء أقسامك التدبرية وإضافة كتبك وملازمك وإرفاق ملفات الـ PDF أو النصوص بسهولة تامة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text(
                    'إضافة كتاب أو ملزمة مع إرفاق ملف',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _showAddBookBottomSheet,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('إضافة قسم جديد'),
                  onPressed: _showAddSectionDialog,
                ),
              ],
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
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
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
                            isPdf
                                ? 'PDF ${book.formattedFileSize}'
                                : 'مستند نصي',
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

            // قائمة الخيارات
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              onSelected: (val) {
                if (val == 'delete') {
                  onDelete();
                } else if (val == 'open') {
                  onTap();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('فتح / قراءة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
