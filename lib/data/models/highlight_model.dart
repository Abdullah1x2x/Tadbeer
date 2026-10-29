import 'package:uuid/uuid.dart';

import '../storage/user_data_store.dart';
import '../quran/quran_models.dart';

/// تظليل آية بأحد الألوان الأربعة، دون المساس بالنص القرآني.
class HighlightItem {
  final String id;

  /// رقم الآية في المصحف كله (1..6236).
  final int ayahId;

  final int surahNumber;

  final int ayahNumber;

  final int page;

  /// رقم اللون في [AppColors.highlightColors] (0..3).
  final int colorIndex;

  final DateTime createdAt;

  const HighlightItem({
    required this.id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.colorIndex,
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
    'colorIndex': colorIndex,
    'createdAt': createdAt.toIso8601String(),
  };

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

/// تظليل الآيات وتغييره وإزالته، فوق [UserDataStore].
class HighlightRepository {
  final UserDataStore _store;

  /// [store] للاختبارات؛ الافتراضي هو المخزن العام.
  HighlightRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  List<HighlightItem> get allHighlights => _store.highlights;

  /// تظليل الآية، أو null إن لم تكن مظلّلة.
  HighlightItem? getHighlight(int surahNumber, int ayahNumber) {
    return _store.findHighlight(surahNumber, ayahNumber);
  }

  /// يظلّل الآية بـ[colorIndex]، أو يغيّر لونها.
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

  Future<void> removeHighlight(int surahNumber, int ayahNumber) async {
    await _store.removeHighlight(surahNumber, ayahNumber);
  }
}
