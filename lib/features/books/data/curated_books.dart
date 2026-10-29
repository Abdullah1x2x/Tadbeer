import 'package:flutter/material.dart';

import 'book_model.dart';
import 'heritage_data.dart';
import 'malazem_data.dart';
import '../../../core/design_system/app_icons.dart';

export 'book_model.dart';
export 'malazem_data.dart';

/// قسم يعرّفه المطور في الكود.
class BookSectionConfig {
  /// اسم القسم ('ملازم التدبر'، 'كتب التفسير'…).
  final String name;

  final String description;

  /// الافتراضي [AppIcons.folderStar].
  final IconData icon;

  /// لون تمييز القسم في البطاقات.
  final Color? color;

  /// نص إحصائي للبطاقة ('أمهات كتب كاملة' مثلاً).
  final String? countLabel;

  /// السلاسل التي تُصفّى بها كتب القسم بأزرار أعلى الشاشة.
  final List<String> seriesFilterList;

  final List<BookConfig> books;

  const BookSectionConfig({
    required this.name,
    this.description = '',
    this.icon = AppIcons.folderStar,
    this.color,
    this.countLabel,
    this.seriesFilterList = const [],
    this.books = const [],
  });

  /// القسم كـ[BookSection].
  BookSection toSectionModel() {
    return BookSection(
      id: 'section_${name.hashCode.abs()}',
      name: name,
      description: description,
      icon: icon,
      color: color,
      countLabel: countLabel,
      seriesFilterList: seriesFilterList,
    );
  }
}

/// كتاب يعرّفه المطور: بملف مرفق أو بفصول مكتوبة.
class BookConfig {
  /// يُولَّد إن تُرك فارغاً.
  final String? id;

  final String title;

  /// عنوان فرعي أو نبذة.
  final String subtitle;

  /// المؤلف أو المُعدّ أو المحاضر.
  final String author;

  /// مسار ملف PDF أو نص (TXT/MD) في الأصول، مثل 'assets/books/fatiha.pdf'.
  final String? assetPath;

  /// 'pdf' أو 'text'؛ يُستنتج من الامتداد إن تُرك فارغاً.
  final String? fileType;

  /// فصول مكتوبة في الكود مباشرة.
  final List<BookChapter> chapters;

  /// وقت القراءة التقريبي بالدقائق.
  final int estimatedMinutes;

  final IconData icon;

  /// نص الشارة على البطاقة ('٥٤ دعاءً كاملاً' مثلاً).
  final String? badgeText;

  final Color? badgeColor;

  const BookConfig({
    this.id,
    required this.title,
    this.subtitle = '',
    this.author = '',
    this.assetPath,
    this.fileType,
    this.chapters = const [],
    this.estimatedMinutes = 10,
    this.icon = AppIcons.bookOpenFill,
    this.badgeText,
    this.badgeColor,
  });

  /// الكتاب كـ[BookModel] في القسم [sectionName].
  BookModel toBookModel(String sectionName) {
    String? resolvedFileType = fileType;
    if (resolvedFileType == null && assetPath != null) {
      final lower = assetPath!.toLowerCase();
      if (lower.endsWith('.pdf')) {
        resolvedFileType = 'pdf';
      } else if (lower.endsWith('.txt') || lower.endsWith('.md')) {
        resolvedFileType = 'text';
      }
    }

    return BookModel(
      id: id ?? 'book_${sectionName}_${title.hashCode.abs()}',
      title: title,
      subtitle: subtitle,
      author: author,
      category: sectionName,
      icon: icon,
      estimatedMinutes: estimatedMinutes,
      filePath: assetPath,
      fileName: assetPath?.split('/').last,
      fileType: resolvedFileType,
      chapters: chapters,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}

// أقسام المكتبة وكتبها التي يعرّفها المطور.
//
// لإرفاق ملف: ضعه في assets/books/، ثم أضف القسم والكتاب في
// [curatedBookSections]:
//
//   BookSectionConfig(
//     name: 'ملازم التدبر',
//     books: [
//       BookConfig(
//         title: 'ملزمة مدارسة سورة الفاتحة',
//         assetPath: 'assets/books/tafseer_fatiha.pdf',
//       ),
//     ],
//   ),
//
// ودون ملف: اكتب الفصول مباشرة في `chapters: [BookChapter(title: ..., content:
// ...)]`.

/// أقسام المكتبة المعرّفة في الكود.
final List<BookSectionConfig> curatedBookSections = [
  // ١. تراث وأدعية أهل البيت (عليهم السلام)
  ahlulbaytHeritageSection,

  // ٢. علوم وتدبر القرآن
  quranSciencesSection,

  // ٣. ملازم هدي القرآن (91 ملزمة)
  BookSectionConfig(
    name: 'ملازم هدي القرآن الكريم',
    description: 'سلسلة ملازم ودروس ومحاضرات السيد حسين بدر الدين الحوثي من هدي القرآن الكريم (٩١ ملزمة موثقة كاملة)',
    icon: AppIcons.bookOpenTextFill,
    color: const Color(0xFFC59B27),
    countLabel: '٩١ ملزمة موثقة • PDF وفصول تفاعلية',
    seriesFilterList: const [
      'الكل',
      'سلسلة معرفة الله',
      'سلسلة هدي القرآن: مدارسة سورة آل عمران',
      'سلسلة هدي القرآن: مدارسة سورة المائدة',
      'سلسلة هدي القرآن: مدارسة سورة الصف',
      'سلسلة مديح القرآن',
      'سلسلة دروس رمضان المبارك',
      'في ظلال الأدعية المباركة',
      'في ظلال العبادة والتقوى',
      'المحاضرات الكبرى والمناسبات',
      'فهرس وتوثيق الملازم',
    ],
    books: malazemSayyedHusseinBooks,
  ),
];
