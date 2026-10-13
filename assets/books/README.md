# 📚 مجلد الكتب والملازم (Assets Books)

ضع ملفات الـ PDF أو الملفات النصية (`.pdf`, `.txt`, `.md`) هنا في هذا المجلد.

## كيفية استخدام الملفات:
1. انسخ ملفك وضعْه هنا مباشرة (مثال: `assets/books/my_booklet.pdf`).
2. افتح ملف `lib/features/books/curated_books.dart`.
3. أضف القسم والكتاب واكتب المسار:
```dart
BookConfig(
  title: 'عنوان الملزمة',
  author: 'اسم المؤلف',
  assetPath: 'assets/books/my_booklet.pdf',
)
```
أو يمكنك إضافتها عبر ملف `assets/books/books_catalog.json`.
