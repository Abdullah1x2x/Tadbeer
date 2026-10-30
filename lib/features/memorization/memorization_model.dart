import '../../data/storage/user_data_store.dart';
import '../../data/models/reading_journey.dart' show dayKey;

/// حالة حفظ آية في نظام صناديق لايتنر.
class HifzCard {
  /// الصندوق الحالي (٠ = جديدة).
  final int box;

  /// موعد المراجعة القادمة.
  final DateTime due;

  const HifzCard({required this.box, required this.due});

  /// الأيام حتى المراجعة التالية لكل صندوق بعد تذكّر صحيح.
  static const intervals = [1, 3, 7, 14, 30];

  static int get maxBox => intervals.length;

  /// الآية محفوظة متى بلغت الصندوق الثالث.
  bool get isMemorized => box >= 3;

  /// يرفعها صندوقاً عند التذكّر فتتباعد المراجعة، ويعيدها إلى الصندوق الأول عند
  /// النسيان فتُراجع غداً.
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

/// تقدّم الحفظ، محفوظ ضمن حالة الميزات.
class HifzStore {
  HifzStore._();

  static const _key = 'memorization';

  static String _id(int surah, int ayah) => '$surah:$ayah';

  /// كل الآيات المضافة للحفظ.
  static Map<String, HifzCard> all() => {
    for (final e in UserDataStore.instance.featureState(_key).entries)
      e.key: HifzCard.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };

  /// مفاتيح الآيات المضافة للحفظ، دون كلفة قراءة بطاقاتها.
  static Set<String> ids() =>
      UserDataStore.instance.featureState(_key).keys.toSet();

  /// حالة حفظ الآية، أو null.
  static HifzCard? card(int surah, int ayah) => all()[_id(surah, ayah)];

  /// يسجّل تقييم القارئ لتذكّر الآية.
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
    return UserDataStore.instance
        .saveFeatureState(_key, state)
        // جلسة الحفظ تحفظ سلسلة الأيام أيضاً.
        .then((_) => UserDataStore.instance.markActiveDay(now: at));
  }

  static bool contains(int surah, int ayah) => card(surah, ayah) != null;

  /// يضيف الآية للحفظ (مستحقة اليوم)، أو يزيلها إن كانت مضافة.
  static Future<void> toggle(int surah, int ayah, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final state = UserDataStore.instance.featureState(_key);
    final id = _id(surah, ayah);
    if (state.containsKey(id)) {
      state.remove(id);
    } else {
      state[id] = HifzCard(
        box: 0,
        due: DateTime(at.year, at.month, at.day),
      ).toJson();
    }
    return UserDataStore.instance.saveFeatureState(_key, state);
  }

  /// الآيات المستحقة اليوم، بترتيب المصحف.
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

  /// عدد الآيات المحفوظة في السورة [surah].
  static int memorizedInSurah(int surah) => all().entries
      .where((e) => e.key.startsWith('$surah:') && e.value.isMemorized)
      .length;
}
