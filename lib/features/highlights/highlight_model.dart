import 'package:uuid/uuid.dart';

import '../../core/storage/user_data_store.dart';
import '../quran/data/quran_models.dart';

/// يمثل تظليل آية في المصحف بأحد الألوان الأربعة الهادئة.
///
/// ملاحظة:
/// التظليل يربط معرّف الآية الموحد بمؤشر لون (0..3) دون المساس بالنص القرآني،
/// ويحافظ على وضوح القراءة في الوضعين الفاتح والداكن.
class HighlightItem {
  /// المعرّف الفريد لعنصر التظليل.
  final String id;

  /// معرّف الآية الموحد (1..6236) للربط الثابت.
  final int ayahId;

  /// رقم السورة التي تنتمي إليها الآية.
  final int surahNumber;

  /// رقم الآية داخل السورة.
  final int ayahNumber;

  /// رقم صفحة المصحف التي تقع فيها الآية.
  final int page;

  /// مؤشر اللون المختار للتظليل (من 0 إلى 3).
  final int colorIndex;

  /// تاريخ ووقت إنشاء التظليل.
  final DateTime createdAt;

  /// ينشئ عنصر تظليل جديد للآية المحددة.
  const HighlightItem({
    required this.id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.colorIndex,
    required this.createdAt,
  });

  /// المفتاح المركب للآية بصيغة (رقم السورة:رقم الآية).
  String get ayahKey => '$surahNumber:$ayahNumber';

  /// يحول بيانات التظليل إلى خريطة JSON للحفظ المحلي.
  Map<String, dynamic> toJson() => {
    'id': id,
    'ayahId': ayahId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'page': page,
    'colorIndex': colorIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  /// ينشئ كائن تظليل من خريطة بيانات JSON المحفوظة.
  factory HighlightItem.fromJson(Map<String, dynamic> json) {
    return HighlightItem(
      id: json['id'] as String,
      ayahId: json['ayahId'] as int,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      page: json['page'] as int,
      colorIndex: json['colorIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// مستودع إدارة تظليلات الآيات في التطبيق.
///
/// يوفر واجهة لإضافة وتحديث وحذف تظليل الآية مع دعم التفاعل اللحظي عبر [UserDataStore].
/// تم دمج هذا المستودع داخل ملف النموذج لتوحيد الشيفرة وتقليل عدد الملفات.
class HighlightRepository {
  final UserDataStore _store;

  /// ينشئ مستودع التظليلات مع إمكانية تمرير مخزن بيانات مخصص.
  HighlightRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  /// قائمة بجميع التظليلات المحفوظة للمستخدم.
  List<HighlightItem> get allHighlights => _store.highlights;

  /// يسترجع تظليل الآية المحددة برقم السورة ورقم الآية إن وجد.
  HighlightItem? getHighlight(int surahNumber, int ayahNumber) {
    return _store.findHighlight(surahNumber, ayahNumber);
  }

  /// تعيين أو تحديث لون التظليل للآية المحددة.
  Future<void> setHighlight(Ayah ayah, int colorIndex) async {
    final existing = getHighlight(ayah.surahNumber, ayah.ayahNumber);
    final item = HighlightItem(
      id: existing?.id ?? const Uuid().v4(),
      ayahId: ayah.id,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      page: ayah.page,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await _store.putHighlight(item);
  }

  /// إزالة التظليل عن الآية.
  Future<void> removeHighlight(int surahNumber, int ayahNumber) async {
    await _store.removeHighlight(surahNumber, ayahNumber);
  }
}
