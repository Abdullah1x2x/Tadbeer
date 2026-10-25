import 'package:uuid/uuid.dart';

import '../../core/storage/user_data_store.dart';
import '../quran/data/quran_models.dart';

/// يمثل إشارة مرجعية (فاصل قراءة) لآية محددة في المصحف.
///
/// ملاحظة:
/// الإشارات المرجعية مرتبطة بآية محددة ورقم الصفحة لتمكين القارئ من العودة
/// السريعة بلمسة واحدة من شاشة "الفواصل" إلى موضع التلاوة.
class BookmarkItem {
  /// المعرّف الفريد للإشارة المرجعية.
  final String id;

  /// معرّف الآية الموحد (1..6236) لضمان الربط الدقيق.
  final int ayahId;

  /// رقم السورة التي تقع فيها الآية.
  final int surahNumber;

  /// رقم الآية داخل السورة.
  final int ayahNumber;

  /// رقم صفحة المصحف التي تحتوي على الآية.
  final int page;

  /// تاريخ ووقت إنشاء الإشارة المرجعية.
  final DateTime createdAt;

  /// ينشئ كائن إشارة مرجعية لآية قرآنية.
  const BookmarkItem({
    required this.id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.createdAt,
  });

  /// المفتاح النصي للآية بصيغة رقم السورة ورقم الآية.
  String get ayahKey => '$surahNumber:$ayahNumber';

  /// يحول بيانات الإشارة المرجعية إلى خريطة JSON للتخزين.
  Map<String, dynamic> toJson() => {
    'id': id,
    'ayahId': ayahId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'page': page,
    'createdAt': createdAt.toIso8601String(),
  };

  /// ينشئ كائن إشارة مرجعية من خريطة بيانات JSON.
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

/// مستودع إدارة الإشارات المرجعية (الفواصل) في التطبيق.
///
/// يوفر واجهة لإضافة وحذف وفحص حالة الفاصل للآية بالاعتماد على [UserDataStore].
/// تم دمج هذا المستودع داخل ملف النموذج لتقليل تشتت الملفات وتقديم واجهة موحدة للفواصل.
class BookmarkRepository {
  final UserDataStore _store;

  /// ينشئ مستودع الفواصل المرجعية بالاعتماد على مخزن بيانات المستخدم.
  BookmarkRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  /// يعيد قائمة جميع الإشارات المرجعية المحفوظة.
  List<BookmarkItem> get allBookmarks => _store.bookmarks;

  /// يتحقق مما إذا كانت الآية المحددة محفوظة في الفواصل المرجعية.
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _store.hasBookmark(surahNumber, ayahNumber);
  }

  /// تبديل حالة الفاصل للآية (إضافة إذا لم تكن موجودة، وحذف إذا كانت مضافة).
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

  /// يحذف إشارة مرجعية محددة بواسطة معرّفها.
  Future<void> removeBookmark(String id) async {
    await _store.removeBookmark(id);
  }
}
