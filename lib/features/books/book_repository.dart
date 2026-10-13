import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'book_model.dart';

/// مستودع إدارة حالة وتخزين أقسام وملازم وكتب المكتبة التدبرية محلياً.
class BookRepository extends ChangeNotifier {
  static final BookRepository instance = BookRepository._internal();
  BookRepository._internal();

  static const _uuid = Uuid();
  bool _initialized = false;
  File? _storageFileOverride;
  Directory? _booksDirectoryOverride;

  final List<BookSection> _sections = [];
  final List<BookModel> _books = [];

  bool _disableDiskPersistence = false;

  /// قائمة الأقسام الحالية المتاحة.
  List<BookSection> get sections => List.unmodifiable(_sections);

  /// قائمة جميع الكتب والملازم المضافة.
  List<BookModel> get books => List.unmodifiable(_books);

  /// ما إذا كان المستودع قد أتم قراءة البيانات من القرص.
  bool get isInitialized => _initialized;

  /// أسماء الأقسام الحالية بالإضافة إلى خيار "الكل".
  List<String> get categoryNames {
    final names = _sections.map((s) => s.name).toList();
    return ['الكل', ...names];
  }

  /// تهيئة المستودع وقراءة الأقسام والكتب المحفوظة محلياً.
  /// يمكن تمرير [storageFile] و [booksDirectory] في بيئة الاختبارات أو التخصيص.
  /// [disableDisk] يسمح بتشغيل المستودع كلياً في الذاكرة أثناء الاختبارات لتفادي بطء القرص.
  Future<void> init({
    File? storageFile,
    Directory? booksDirectory,
    bool disableDisk = false,
  }) async {
    _disableDiskPersistence = disableDisk;
    if (storageFile != null) _storageFileOverride = storageFile;
    if (booksDirectory != null) _booksDirectoryOverride = booksDirectory;
    if (_initialized && storageFile == null && booksDirectory == null && !disableDisk) return;

    if (_disableDiskPersistence) {
      _initialized = true;
      notifyListeners();
      return;
    }

    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;

          _sections.clear();
          if (jsonMap['sections'] is List) {
            for (final item in jsonMap['sections'] as List<dynamic>) {
              _sections.add(BookSection.fromJson(item as Map<String, dynamic>));
            }
          }

          _books.clear();
          if (jsonMap['books'] is List) {
            for (final item in jsonMap['books'] as List<dynamic>) {
              _books.add(BookModel.fromJson(item as Map<String, dynamic>));
            }
          }
        }
      }
    } catch (e) {
      // السقوط الآمن في بيئات الاختبار
      debugPrint('BookRepository init error: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  /// الحصول على الكتب التابعة لقسم محدد (أو الكل).
  List<BookModel> getBooksBySection(String sectionName) {
    if (sectionName == 'الكل') return books;
    return _books.where((b) => b.category == sectionName).toList();
  }

  /// إضافة قسم جديد للكتب والملازم.
  Future<BookSection> addSection({
    required String name,
    String description = '',
    IconData? icon,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('اسم القسم لا يمكن أن يكون فارغاً');
    }

    // التحقق من عدم وجود قسم بنفس الاسم مسبقاً
    final existing = _sections.where((s) => s.name == cleanName).firstOrNull;
    if (existing != null) {
      return existing;
    }

    final newSection = BookSection(
      id: _uuid.v4(),
      name: cleanName,
      description: description.trim(),
      icon: icon ?? Icons.folder_special_rounded,
      createdAt: DateTime.now(),
    );

    _sections.add(newSection);
    await _saveToDisk();
    notifyListeners();
    return newSection;
  }

  /// حذف قسم محدد وحذف الكتب التابعة له.
  Future<void> deleteSection(String sectionId) async {
    final index = _sections.indexWhere((s) => s.id == sectionId);
    if (index == -1) return;

    final targetSection = _sections[index];
    _sections.removeAt(index);

    // حذف ملفات وكتب هذا القسم من الذاكرة والقرص
    final booksToDelete =
        _books.where((b) => b.category == targetSection.name).toList();
    for (final book in booksToDelete) {
      await _deleteAttachedFileSilently(book.filePath);
      _books.removeWhere((b) => b.id == book.id);
    }

    await _saveToDisk();
    notifyListeners();
  }

  /// إضافة كتاب أو ملزمة مع إمكانية إرفاق ملف من الهاتف (PDF أو نصي).
  Future<BookModel> addBook({
    required String title,
    required String sectionName,
    String subtitle = '',
    String author = '',
    File? attachedFile,
    List<BookChapter>? chapters,
    int? estimatedMinutes,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('عنوان الكتاب لا يمكن أن يكون فارغاً');
    }

    // التأكد من وجود القسم في قائمة الأقسام
    if (!_sections.any((s) => s.name == sectionName.trim())) {
      await addSection(name: sectionName.trim());
    }

    String? savedFilePath;
    String? originalFileName;
    String? fileType;
    int fileSizeBytes = 0;

    if (attachedFile != null && await attachedFile.exists()) {
      final storageDir = await _getBooksStorageDirectory();
      originalFileName = p.basename(attachedFile.path);
      final ext = p.extension(attachedFile.path).toLowerCase().replaceAll('.', '');
      final uniqueFileName = '${_uuid.v4()}_$originalFileName';
      final destinationFile = File('${storageDir.path}/$uniqueFileName');

      await attachedFile.copy(destinationFile.path);
      savedFilePath = destinationFile.path;
      fileSizeBytes = await destinationFile.length();

      if (ext == 'pdf') {
        fileType = 'pdf';
      } else if (ext == 'txt' || ext == 'md') {
        fileType = 'text';
      } else {
        fileType = ext;
      }
    }

    final newBook = BookModel(
      id: _uuid.v4(),
      title: cleanTitle,
      subtitle: subtitle.trim(),
      author: author.trim(),
      category: sectionName.trim(),
      filePath: savedFilePath,
      fileName: originalFileName,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      chapters: chapters ?? const [],
      estimatedMinutes: estimatedMinutes ?? 10,
      createdAt: DateTime.now(),
    );

    _books.insert(0, newBook);
    await _saveToDisk();
    notifyListeners();
    return newBook;
  }

  /// حذف كتاب أو ملزمة وملفه المرفق من القرص.
  Future<void> deleteBook(String bookId) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index == -1) return;

    final book = _books[index];
    _books.removeAt(index);

    await _deleteAttachedFileSilently(book.filePath);
    await _saveToDisk();
    notifyListeners();
  }

  /// مسح كافة الكتب والأقسام وتصفير المكتبة بالكامل.
  Future<void> clearAll() async {
    for (final book in _books) {
      await _deleteAttachedFileSilently(book.filePath);
    }
    _books.clear();
    _sections.clear();
    await _saveToDisk();
    notifyListeners();
  }

  Future<void> _deleteAttachedFileSilently(String? filePath) async {
    if (_disableDiskPersistence || filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<Directory> _getBooksStorageDirectory() async {
    if (_booksDirectoryOverride != null) {
      if (!await _booksDirectoryOverride!.exists()) {
        await _booksDirectoryOverride!.create(recursive: true);
      }
      return _booksDirectoryOverride!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/tadbeer_books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  Future<File?> _getStorageFile() async {
    if (_storageFileOverride != null) {
      return _storageFileOverride;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/tadbeer_books_library.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToDisk() async {
    if (_disableDiskPersistence) return;
    try {
      final file = await _getStorageFile();
      if (file == null) return;

      final data = {
        'sections': _sections.map((s) => s.toJson()).toList(),
        'books': _books.map((b) => b.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // التجاهل الآمن في بيئات الاختبار
    }
  }
}
