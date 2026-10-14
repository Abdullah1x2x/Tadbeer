import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import 'book_model.dart';
import 'book_repository.dart';
import 'book_section_screen.dart';

export 'book_section_screen.dart';

/// شاشة دليل أقسام مكتبة الكتب والملازم التدبرية.
/// تعرض الأقسام الرئيسية فقط في بطاقات مميزة، وينتقل المستخدم إلى داخل كل قسم
/// لتصفح وقراءة الكتب والملازم التابعة له.
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

  @override
  void initState() {
    super.initState();
    _repo.init();
    _repo.addListener(_onRepoChanged);

    // إذا تم تمرير قسم مبدئي، يتم الانتقال إليه بعد اكتمال بناء الشاشة
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final matchingSection = _repo.sections.cast<BookSection?>().firstWhere(
              (s) => s?.name == widget.initialSection,
              orElse: () => null,
            );
        if (matchingSection != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookSectionScreen(section: matchingSection),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final sections = _repo.sections;

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
              fontSize: 19,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: sections.isEmpty
              ? _buildEmptyState(isDark, primaryColor)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final bookCount =
                        _repo.getBooksBySection(section.name).length;
                    return _SectionDirectoryCard(
                      section: section,
                      bookCount: bookCount,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookSectionScreen(section: section),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
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
                  Icons.auto_stories_rounded,
                  size: 40,
                  color: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.oliveDark,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'قسم الكتب والملازم فارغ حالياً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم تتم إضافة أي أقسام أو كتب في ملفات التطبيق حتى الآن.\nيمكن للمطور إضافة الأقسام والملازم بسهولة عبر ملف curated_books.dart.',
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

/// بطاقة عرض القسم في شاشة دليل الأقسام الرئيسية.
class _SectionDirectoryCard extends StatelessWidget {
  final BookSection section;
  final int bookCount;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SectionDirectoryCard({
    required this.section,
    required this.bookCount,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  Color _getBadgeColor() {
    if (section.name.contains('السيد حسين')) {
      return isDark ? AppColors.darkAccentGold : const Color(0xFFC59B27);
    }
    if (section.name.contains('أهل البيت')) {
      return isDark ? const Color(0xFF4E9F76) : const Color(0xFF2E6F4D);
    }
    if (section.name.contains('علوم وتدبر')) {
      return isDark ? const Color(0xFF5BA4A4) : const Color(0xFF2C7A7B);
    }
    return primaryColor;
  }

  IconData _getSectionIcon() {
    if (section.name.contains('السيد حسين')) {
      return Icons.auto_stories_rounded;
    }
    if (section.name.contains('أهل البيت')) {
      return Icons.mosque_rounded;
    }
    if (section.name.contains('علوم وتدبر')) {
      return Icons.menu_book_rounded;
    }
    return section.icon;
  }

  String _formatCountLabel() {
    if (section.name.contains('السيد حسين')) {
      return '$bookCount ملزمة موثقة • PDF مباشر';
    }
    if (section.name.contains('أهل البيت')) {
      return '$bookCount أمهات كتب كاملة • 54 دعاء و50 حقاً';
    }
    if (section.name.contains('علوم وتدبر')) {
      return '$bookCount كتب تدبرية وتفسيرية';
    }
    return '$bookCount كتاب/ملزمة';
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final iconData = _getSectionIcon();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // إطار الأيقونة البارز
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: badgeColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // اسم القسم ووصفه وعدد الملازم/الكتب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      section.name,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (section.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        section.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatCountLabel(),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // مؤشر السهم للتنقل داخل القسم
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 13,
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
