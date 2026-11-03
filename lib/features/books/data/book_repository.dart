import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'curated_books.dart';

/// أقسام المكتبة وكتبها، من كتب التطبيق المرفقة.
class BookRepository extends ChangeNotifier {
  static final BookRepository instance = BookRepository._internal();
  BookRepository._internal();

  bool _initialized = false;

  final List<BookSection> _sections = [];
  final List<BookModel> _books = [];

  List<BookSection> get sections => List.unmodifiable(_sections);

  List<BookModel> get books => List.unmodifiable(_books);

  /// هل قُرئت البيانات.
  bool get isInitialized => _initialized;

  /// أسماء الأقسام، يسبقها "الكل".
  List<String> get categoryNames {
    final names = _sections.map((s) => s.name).toList();
    return ['الكل', ...names];
  }

  /// يقرأ الأقسام والكتب.
  Future<void> init({@visibleForTesting bool reload = false}) async {
    if (_initialized && !reload) return;

    _sections.clear();
    _books.clear();

    // ١. الأقسام والكتب المعرّفة في curated_books.dart.
    _loadCuratedBooks();

    // ٢. كتالوج JSON في الأصول، إن وُجد.
    await _loadCatalogJson();

    _initialized = true;
    notifyListeners();
  }

  void _loadCuratedBooks() {
    for (final sec in curatedBookSections) {
      if (!_sections.any((s) => s.name == sec.name)) {
        _sections.add(sec.toSectionModel());
      }
      for (final book in sec.books) {
        final model = book.toBookModel(sec.name);
        if (!_books.any(
          (b) =>
              b.id == model.id ||
              (b.title == model.title && b.category == model.category),
        )) {
          _books.add(model);
        }
      }
    }
  }

  Future<void> _loadCatalogJson() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/books/books_catalog.json',
      );
      if (jsonStr.trim().isEmpty) return;
      final dynamic list = jsonDecode(jsonStr);
      if (list is List) {
        for (final secItem in list) {
          if (secItem is Map<String, dynamic>) {
            final secName = secItem['name'] as String? ?? '';
            if (secName.trim().isEmpty) continue;
            if (!_sections.any((s) => s.name == secName)) {
              _sections.add(
                BookSection(
                  id: 'json_sec_${secName.hashCode.abs()}',
                  name: secName,
                  description: secItem['description'] as String? ?? '',
                ),
              );
            }
            final booksList = secItem['books'];
            if (booksList is List) {
              for (final bookItem in booksList) {
                if (bookItem is Map<String, dynamic>) {
                  final bTitle = bookItem['title'] as String? ?? '';
                  if (bTitle.trim().isEmpty) continue;
                  final assetPath = bookItem['assetPath'] as String?;
                  final bookModel = BookModel(
                    id:
                        bookItem['id'] as String? ??
                        'json_book_${secName}_${bTitle.hashCode.abs()}',
                    title: bTitle,
                    subtitle: bookItem['subtitle'] as String? ?? '',
                    author: bookItem['author'] as String? ?? '',
                    category: secName,
                    estimatedMinutes:
                        bookItem['estimatedMinutes'] as int? ?? 10,
                    filePath: assetPath,
                    fileName: assetPath?.split('/').last,
                    fileType:
                        bookItem['fileType'] as String? ??
                        (assetPath != null &&
                                assetPath.toLowerCase().endsWith('.pdf')
                            ? 'pdf'
                            : (assetPath != null ? 'text' : null)),
                    chapters:
                        (bookItem['chapters'] as List<dynamic>?)
                            ?.map(
                              (c) => BookChapter.fromJson(
                                c as Map<String, dynamic>,
                              ),
                            )
                            .toList() ??
                        const [],
                  );
                  if (!_books.any(
                    (b) =>
                        b.id == bookModel.id ||
                        (b.title == bookModel.title &&
                            b.category == bookModel.category),
                  )) {
                    _books.add(bookModel);
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // يُتجاهل الفشل في الاختبارات.
    }
  }

  /// كتب [sectionName]، أو كل الكتب.
  List<BookModel> getBooksBySection(String sectionName) {
    if (sectionName == 'الكل') return books;
    return _books.where((b) => b.category == sectionName).toList();
  }

  /// للاختبارات: يضع [sections] و[books] مكان المكتبة.
  @visibleForTesting
  void replaceForTest({
    List<BookSection> sections = const [],
    List<BookModel> books = const [],
  }) {
    _sections
      ..clear()
      ..addAll(sections);
    _books
      ..clear()
      ..addAll(books);
    _initialized = true;
    notifyListeners();
  }
}
