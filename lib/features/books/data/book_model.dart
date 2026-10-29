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

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'content': content,
  };

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    if (color != null) 'color': color!.toARGB32(),
    if (countLabel != null) 'countLabel': countLabel,
    if (seriesFilterList.isNotEmpty) 'seriesFilterList': seriesFilterList,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory BookSection.fromJson(Map<String, dynamic> json) => BookSection(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: AppIcons.folderStar,
    color: json['color'] != null ? Color(json['color'] as int) : null,
    countLabel: json['countLabel'] as String?,
    seriesFilterList:
        (json['seriesFilterList'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
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
    if (badgeText != null) 'badgeText': badgeText,
    if (badgeColor != null) 'badgeColor': badgeColor!.toARGB32(),
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    author: json['author'] as String? ?? '',
    category: json['category'] as String? ?? '',
    icon: AppIcons.bookOpenFill,
    estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
    filePath: json['filePath'] as String?,
    fileName: json['fileName'] as String?,
    fileType: json['fileType'] as String?,
    fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    chapters:
        (json['chapters'] as List<dynamic>?)
            ?.map((c) => BookChapter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [],
    badgeText: json['badgeText'] as String?,
    badgeColor: json['badgeColor'] != null
        ? Color(json['badgeColor'] as int)
        : null,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  /// الكتب المدمجة الافتراضية؛ فارغة، فيبدأ القارئ مكتبته بنفسه.
  static const List<BookModel> defaultBooks = [];
}
