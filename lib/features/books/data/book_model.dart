import 'package:flutter/material.dart';

import '../../../core/design_system/app_icons.dart';

/// فصل أو مبحث في كتاب أو ملزمة.
class BookChapter {
  final String title;
  final String summary;
  final String content;

  const BookChapter({
    required this.title,
    this.summary = '',
    required this.content,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    content: json['content'] as String? ?? '',
  );
}

/// قسم في المكتبة (ملازم التدبر، علوم القرآن…).
class BookSection {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color? color;
  final String? countLabel;
  final List<String> seriesFilterList;
  final DateTime? createdAt;

  const BookSection({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = AppIcons.folderStar,
    this.color,
    this.countLabel,
    this.seriesFilterList = const [],
    this.createdAt,
  });
}

/// كتاب أو ملزمة: فصول مكتوبة، أو ملف مرفق (PDF أو نص).
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
  final String? badgeText;
  final Color? badgeColor;
  final DateTime? createdAt;

  const BookModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.author = '',
    required this.category,
    this.icon = AppIcons.bookOpenFill,
    this.estimatedMinutes = 10,
    this.filePath,
    this.fileName,
    this.fileType,
    this.fileSizeBytes = 0,
    this.chapters = const [],
    this.badgeText,
    this.badgeColor,
    this.createdAt,
  });

  /// هل للكتاب ملف مرفق، من الهاتف أو من الأصول.
  bool get hasAttachedFile => filePath != null && filePath!.isNotEmpty;

  bool get isPdf =>
      fileType == 'pdf' ||
      (fileName?.toLowerCase().endsWith('.pdf') ?? false) ||
      (filePath?.toLowerCase().endsWith('.pdf') ?? false);

  /// هل الملف المرفق نص أو Markdown.
  bool get isText =>
      fileType == 'text' ||
      fileType == 'markdown' ||
      (fileName?.toLowerCase().endsWith('.txt') ?? false) ||
      (fileName?.toLowerCase().endsWith('.md') ?? false) ||
      (filePath?.toLowerCase().endsWith('.txt') ?? false) ||
      (filePath?.toLowerCase().endsWith('.md') ?? false);

  /// حجم الملف بصيغة مقروءة.
  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// الكتب المدمجة الافتراضية؛ فارغة، فيبدأ القارئ مكتبته بنفسه.
  static const List<BookModel> defaultBooks = [];
}
