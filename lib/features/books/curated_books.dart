import 'package:flutter/material.dart';

import 'book_model.dart';
import 'data/heritage_data.dart';
import 'data/malazem_data.dart';

export 'book_model.dart';
export 'data/malazem_data.dart';

/// تكوين قسم للملازم والكتب يُحدده المطور في ملفات التطبيق.
class BookSectionConfig {
  /// اسم القسم (مثال: 'ملازم التدبر'، 'كتب التفسير'، 'ملخصات الدورات').
  final String name;

  /// وصف مختصر للقسم (اختياري).
  final String description;

  /// أيقونة القسم (اختياري، الافتراضي: Icons.folder_special_rounded).
  final IconData icon;

  /// لون تمييز القسم في الواجهة والبطاقات (اختياري).
  final Color? color;

  /// وصف إحصائي أو تفصيلي مخصص للبطاقة (اختياري، مثل: 'أمهات كتب كاملة').
  final String? countLabel;

  /// قائمة فئات السلاسل لتصفية هذا القسم بأزرار تفاعلية أعلى الشاشة (اختياري).
  final List<String> seriesFilterList;

  /// قائمة الكتب والملازم التابعة لهذا القسم.
  final List<BookConfig> books;

  const BookSectionConfig({
    required this.name,
    this.description = '',
    this.icon = Icons.folder_special_rounded,
    this.color,
    this.countLabel,
    this.seriesFilterList = const [],
    this.books = const [],
  });

  /// تحويل التكوين إلى نموذج BookSection.
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

/// تكوين كتاب أو ملزمة يضيفها المطور في ملفات التطبيق مع إرفاق ملف أو كتابة فصول.
class BookConfig {
  /// معرّف اختياري للملزمة (إذا تُرك فارغاً يُولّد تلقائياً).
  final String? id;

  /// عنوان الكتاب أو الملزمة الرئيسي.
  final String title;

  /// عنوان فرعي أو نبذة تعريفية مختصرة (اختياري).
  final String subtitle;

  /// اسم المؤلف أو المُعدّ أو المحاضر (اختياري).
  final String author;

  /// مسار الملف المرفق داخل الأصول assets (اختياري).
  /// يدعم ملفات PDF (مثل: 'assets/books/fatiha.pdf')
  /// والملفات النصية (مثل: 'assets/books/lesson.txt' أو 'assets/books/notes.md').
  final String? assetPath;

  /// نوع الملف: 'pdf' أو 'text' (يُستنتج تلقائياً من امتداد الملف إذا تُرك فارغاً).
  final String? fileType;

  /// فصول ومباحث نصية مكتوبة برمجياً مباشرة داخل الكود (اختياري).
  final List<BookChapter> chapters;

  /// وقت القراءة التقريبي بالدقائق.
  final int estimatedMinutes;

  /// أيقونة مخصصة للكتاب أو الملزمة.
  final IconData icon;

  /// نص الشارة التوضيحية على بطاقة الكتاب (اختياري، مثل: '٥٤ دعاءً كاملاً').
  final String? badgeText;

  /// لون الشارة التوضيحية للبطاقة (اختياري).
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
    this.icon = Icons.menu_book_rounded,
    this.badgeText,
    this.badgeColor,
  });

  /// تحويل التكوين إلى نموذج BookModel للواجهة وقارئ الكتب.
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

// =============================================================================
// 📚 سجل الأقسام والملازم والكتب التدبرية — المخصص للمطور
// =============================================================================
//
// 💡 كيف تضيف قسماً جديداً وترفق ملفات وملازم؟
//
// 1. لإرفاق ملف PDF أو ملف نصي (TXT / MD):
//    - ضع الملف في مجلد: assets/books/
//      (مثال: assets/books/tafseer_fatiha.pdf)
//
// 2. أضف القسم والملزمة في القائمة أدناه [curatedBookSections]:
//
//    مثال (1): قسم يحتوي على ملزمة مرفقة بملف PDF:
//    -----------------------------------------------
//    BookSectionConfig(
//      name: 'ملازم التدبر',
//      description: 'ملازم دورات التدبر وتفسير الآيات',
//      books: [
//        BookConfig(
//          title: 'ملزمة مدارسة سورة الفاتحة',
//          subtitle: 'دليل عملي في تدبر السبع المثاني',
//          author: 'مركز تدبر',
//          assetPath: 'assets/books/tafseer_fatiha.pdf',
//        ),
//      ],
//    ),
//
//    مثال (2): قسم يحتوي على ملزمة مرفقة بملف نصي (.txt أو .md):
//    -----------------------------------------------------------
//    BookSectionConfig(
//      name: 'ملخصات الدورات',
//      description: 'تلخيصات الدروس والمحاضرات القرآنية',
//      books: [
//        BookConfig(
//          title: 'فوائد سورة الكهف',
//          assetPath: 'assets/books/kahf_notes.txt',
//        ),
//      ],
//    ),
//
//    مثال (3): قسم يحتوي على فصول نصية مكتوبة مباشرة دون ملف خارجي:
//    --------------------------------------------------------------
//    BookSectionConfig(
//      name: 'قواعد التفسير',
//      books: [
//        BookConfig(
//          title: 'قواعد حسان في فهم القرآن',
//          chapters: [
//            BookChapter(
//              title: 'المبحث الأول: الإخلاص والنية',
//              content: 'نص محتوى المبحث يكتب هنا بكل سهولة...',
//            ),
//            BookChapter(
//              title: 'المبحث الثاني: التدبر والعمل',
//              content: 'نص محتوى المبحث الثاني...',
//            ),
//          ],
//        ),
//      ],
//    ),
// =============================================================================

/// قائمة الأقسام والملازم التي يحددها المطور في التطبيق.
/// قم بإضافة أقسامك وملازمك وملفاتك المرفقة هنا مباشرة:
final List<BookSectionConfig> curatedBookSections = [
  // 1. قسم تراث وأدعية أهل البيت (عليهم السلام)
  ahlulbaytHeritageSection,

  // 2. قسم علوم وتدبر القرآن الكريم
  quranSciencesSection,

  // 3. قسم ملازم هدي القرآن الكريم (91 ملزمة موثقة كاملة)
  BookSectionConfig(
    name: 'ملازم هدي القرآن الكريم',
    description:
        'سلسلة ملازم ودروس ومحاضرات السيد حسين بدر الدين الحوثي من هدي القرآن الكريم (91 ملزمة موثقة كاملة)',
    icon: Icons.auto_stories_rounded,
    color: const Color(0xFFC59B27),
    countLabel: '91 ملزمة موثقة • PDF وفصول تفاعلية',
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
