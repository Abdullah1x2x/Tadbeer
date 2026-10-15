import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
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
      textDirection: context.currentLanguage.direction,
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
              Text(
                context.l10n.booksSectionEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.booksSectionEmptyDescription,
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
    if (section.color != null) {
      return section.color!;
    }
    return primaryColor;
  }

  IconData _getSectionIcon() {
    return section.icon;
  }

  String _getSectionTitle(BuildContext context) {
    if (context.currentLanguage == AppLanguage.arabic) {
      return section.name;
    }
    if (section.name.contains('ملازم')) {
      return 'Huda Al-Quran Booklets';
    }
    if (section.name.contains('تراث')) {
      return 'Ahlulbayt Heritage & Duas';
    }
    if (section.name.contains('علوم')) {
      return 'Quranic Sciences & Reflection';
    }
    return section.name;
  }

  String _getSectionDescription(BuildContext context) {
    if (context.currentLanguage == AppLanguage.arabic) {
      return section.description;
    }
    if (section.name.contains('ملازم')) {
      return 'Lectures & study booklets of Sayyed Hussein Badr al-Din al-Houthi from Quranic guidance';
    }
    if (section.name.contains('تراث')) {
      return 'Supplications, Nahj al-Balagha, and spiritual heritage of the Ahlulbayt';
    }
    if (section.name.contains('علوم')) {
      return 'Foundational books on Quran recitation etiquette and reflection principles';
    }
    return section.description;
  }

  String _formatCountLabel(BuildContext context) {
    final isArabic = context.currentLanguage == AppLanguage.arabic;
    final count = isArabic
        ? ArabicSearchNormalizer.toArabicDigits(bookCount)
        : bookCount.toString();
    if (!isArabic) {
      if (section.name.contains('ملازم')) {
        return '$count Verified Booklets • Direct PDF';
      }
      if (section.name.contains('تراث')) {
        return '$count Heritage Books • Complete Texts';
      }
      if (section.name.contains('علوم')) {
        return '$count Study & Reflection Books';
      }
      return '$count books/booklets';
    }
    if (section.countLabel != null && section.countLabel!.isNotEmpty) {
      return '$count ${section.countLabel}';
    }
    return '$count كتاب/ملزمة';
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
              // 1. تفاصيل القسم واسمه (على اليمين)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSectionTitle(context),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (section.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _getSectionDescription(context),
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
                        _formatCountLabel(context),
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
              const SizedBox(width: 14),

              // 2. أيقونة القسم وسهم الدخول (على اليسار)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
      ),
    );
  }
}
