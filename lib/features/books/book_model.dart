import 'package:flutter/material.dart';

/// فصل أو مبحث ضمن الملزمة أو الكتاب التدبري.
class BookChapter {
  final String title;
  final String summary;
  final String content;

  /// ينشئ فصلاً أو مبحثاً تدبرياً.
  const BookChapter({
    required this.title,
    this.summary = '',
    required this.content,
  });

  /// تحويل الفصل إلى خريطة JSON للتخزين.
  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'content': content,
      };

  /// إنشاء فصل من خريطة JSON.
  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

/// قسم تصنيفي للملازم والكتب (مثال: ملازم التدبر، علوم القرآن، كتب التفسير).
class BookSection {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final DateTime? createdAt;

  /// ينشئ قسماً جديداً للكتب والملازم.
  const BookSection({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = Icons.folder_special_rounded,
    this.createdAt,
  });

  /// تحويل القسم إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  /// إنشاء قسم من خريطة JSON.
  factory BookSection.fromJson(Map<String, dynamic> json) => BookSection(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: Icons.folder_special_rounded,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// نموذج بيانات الكتاب أو الملزمة مع دعم الملفات المرفقة (PDF، نصوص) والفصول.
class BookModel {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String category;
  final IconData icon;
  final int estimatedMinutes;
  final String? filePath;
  final String? fileName;
  final String? fileType;
  final int fileSizeBytes;
  final List<BookChapter> chapters;
  final DateTime? createdAt;

  /// ينشئ ملزمة أو كتاباً.
  const BookModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.author = '',
    required this.category,
    this.icon = Icons.menu_book_rounded,
    this.estimatedMinutes = 10,
    this.filePath,
    this.fileName,
    this.fileType,
    this.fileSizeBytes = 0,
    this.chapters = const [],
    this.createdAt,
  });

  /// ما إذا كان الكتاب يحتوي على ملف مرفق من الهاتف أو الأصول.
  bool get hasAttachedFile => filePath != null && filePath!.isNotEmpty;

  /// ما إذا كان الملف المرفق بصيغة PDF.
  bool get isPdf =>
      fileType == 'pdf' ||
      (fileName?.toLowerCase().endsWith('.pdf') ?? false) ||
      (filePath?.toLowerCase().endsWith('.pdf') ?? false);

  /// ما إذا كان الملف المرفق بصيغة نصية أو Markdown.
  bool get isText =>
      fileType == 'text' ||
      fileType == 'markdown' ||
      (fileName?.toLowerCase().endsWith('.txt') ?? false) ||
      (fileName?.toLowerCase().endsWith('.md') ?? false);

  /// حجم الملف بصيغة نصية مقروءة للمستخدم.
  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// تحويل الكتاب إلى خريطة JSON للتخزين المحلي.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'author': author,
        'category': category,
        'estimatedMinutes': estimatedMinutes,
        'filePath': filePath,
        'fileName': fileName,
        'fileType': fileType,
        'fileSizeBytes': fileSizeBytes,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  /// إنشاء كتاب من خريطة JSON.
  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        author: json['author'] as String? ?? '',
        category: json['category'] as String? ?? '',
        icon: Icons.menu_book_rounded,
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
        filePath: json['filePath'] as String?,
        fileName: json['fileName'] as String?,
        fileType: json['fileType'] as String?,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        chapters: (json['chapters'] as List<dynamic>?)
                ?.map((c) => BookChapter.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  /// مكتبة الكتب الافتراضية المدمجة (فارغة تلبية لرغبة المستخدم في بدء مكتبة مخصصة).
  static const List<BookModel> defaultBooks = [];
}
