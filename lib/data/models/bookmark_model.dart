import 'package:uuid/uuid.dart';

import '../storage/user_data_store.dart';
import '../quran/quran_models.dart';

/// فاصل على آية، يعود منه القارئ إلى موضعها بنقرة من شاشة الفواصل.
class BookmarkItem {
  final String id;

  /// رقم الآية في المصحف كله (1..6236).
  final int ayahId;

  final int surahNumber;

  final int ayahNumber;

  final int page;

  final DateTime createdAt;

  const BookmarkItem({
    required this.id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.createdAt,
  });

  /// مفتاح الآية "سورة:آية".
  String get ayahKey => '$surahNumber:$ayahNumber';

  Map<String, dynamic> toJson() => {
    'id': id,
    'ayahId': ayahId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'page': page,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'] as String,
      ayahId: json['ayahId'] as int,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      page: json['page'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// إضافة الفواصل وحذفها والتحقق منها، فوق [UserDataStore].
class BookmarkRepository {
  final UserDataStore _store;

  /// [store] للاختبارات؛ الافتراضي هو المخزن العام.
  BookmarkRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  List<BookmarkItem> get allBookmarks => _store.bookmarks;

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _store.isBookmarked(surahNumber, ayahNumber);
  }

  /// يضيف الفاصل أو يحذفه، ويعيد true إن صارت الآية محفوظة.
  Future<bool> toggleBookmark(Ayah ayah) async {
    final currentlyBookmarked = isBookmarked(ayah.surahNumber, ayah.ayahNumber);
    if (currentlyBookmarked) {
      final existing = _store.bookmarks.firstWhere(
        (b) =>
            b.surahNumber == ayah.surahNumber &&
            b.ayahNumber == ayah.ayahNumber,
      );
      await _store.removeBookmark(existing.id);
      return false;
    } else {
      final item = BookmarkItem(
        id: const Uuid().v4(),
        ayahId: ayah.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
        createdAt: DateTime.now(),
      );
      await _store.putBookmark(item);
      return true;
    }
  }

  Future<void> removeBookmark(String id) async {
    await _store.removeBookmark(id);
  }
}
