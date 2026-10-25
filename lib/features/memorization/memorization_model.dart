import '../../core/storage/user_data_store.dart';
import '../journey/reading_journey.dart' show dayKey;

/// حالة حفظ آية واحدة في نظام صناديق لايتنر.
class HifzCard {
  /// الصندوق الحالي (٠ = جديدة).
  final int box;

  /// تاريخ المراجعة المستحقة.
  final DateTime due;

  /// ينشئ حالة حفظ لآية.
  const HifzCard({required this.box, required this.due});

  /// Days until the next review for each box after a successful recall.
  static const intervals = [1, 3, 7, 14, 30];

  /// أعلى صندوق.
  static int get maxBox => intervals.length;

  /// تُعدّ الآية محفوظة عند بلوغ الصندوق الثالث.
  bool get isMemorized => box >= 3;

  /// Moves up a box on success (longer gap) or back to box 1 on failure
  /// (review again tomorrow).
  HifzCard grade({required bool remembered, required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final newBox = remembered ? (box + 1).clamp(1, maxBox) : 1;
    return HifzCard(
      box: newBox,
      due: today.add(Duration(days: intervals[newBox - 1])),
    );
  }

  Map<String, dynamic> toJson() => {'box': box, 'due': dayKey(due)};

  factory HifzCard.fromJson(Map<String, dynamic> json) => HifzCard(
    box: (json['box'] as num).toInt(),
    due: DateTime.parse(json['due'] as String),
  );
}

/// مخزن تقدم الحفظ ضمن حالة الميزات العامة.
class HifzStore {
  HifzStore._();

  static const _key = 'memorization';

  static String _id(int surah, int ayah) => '$surah:$ayah';

  /// جميع الآيات المسجلة في الحفظ.
  static Map<String, HifzCard> all() => {
    for (final e in UserDataStore.instance.featureState(_key).entries)
      e.key: HifzCard.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };

  /// حالة آية محددة إن وُجدت.
  static HifzCard? card(int surah, int ayah) => all()[_id(surah, ayah)];

  /// يسجّل تقييم المستخدم لتذكّر الآية.
  static Future<void> grade(
    int surah,
    int ayah, {
    required bool remembered,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final state = UserDataStore.instance.featureState(_key);
    final current =
        card(surah, ayah) ??
        HifzCard(box: 0, due: DateTime(at.year, at.month, at.day));
    state[_id(surah, ayah)] = current
        .grade(remembered: remembered, now: at)
        .toJson();
    return UserDataStore.instance.saveFeatureState(_key, state);
  }

  /// الآيات المستحقة للمراجعة اليوم، مرتبة حسب المصحف.
  static List<(int, int)> dueToday({DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final due = [
      for (final e in all().entries)
        if (!e.value.due.isAfter(today))
          (int.parse(e.key.split(':')[0]), int.parse(e.key.split(':')[1])),
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return due;
  }

  /// عدد الآيات المحفوظة (الصندوق الثالث فما فوق).
  static int memorizedCount() =>
      all().values.where((c) => c.isMemorized).length;

  /// عدد الآيات المحفوظة في سورة.
  static int memorizedInSurah(int surah) => all().entries
      .where((e) => e.key.startsWith('$surah:') && e.value.isMemorized)
      .length;
}
