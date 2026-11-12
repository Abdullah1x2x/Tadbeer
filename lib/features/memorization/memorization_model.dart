import '../../data/models/reading_journey.dart' show dayKey;
import '../../data/storage/user_data_store.dart';

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
    final newBox = remembered ? (box + 1).clamp(1, maxBox) : 1;
    return HifzCard(
      box: newBox,
      due: DateTime(now.year, now.month, now.day + intervals[newBox - 1]),
    );
  }

  Map<String, dynamic> toJson() => {'box': box, 'due': dayKey(due)};

  factory HifzCard.fromJson(Map<String, dynamic> json) => HifzCard(
    box: (json['box'] as num).toInt(),
    due: DateTime.parse(json['due'] as String),
  );
}

/// ملخّص محفوظات الحفظ المحسوب في تمريرة واحدة دون تكرار فك البطاقات.
class HifzSummary {
  final List<(int, int)> due;
  final int memorizedCount;
  final int inProgressCount;
  final Map<int, int> memorizedBySurah;
  final Map<int, int> inProgressBySurah;
  final Map<int, int> dueBySurah;
  final Map<int, List<(int, int)>> trackedVersesBySurah;

  const HifzSummary({
    required this.due,
    required this.memorizedCount,
    required this.inProgressCount,
    required this.memorizedBySurah,
    required this.inProgressBySurah,
    required this.dueBySurah,
    required this.trackedVersesBySurah,
  });

  int memorizedInSurah(int surah) => memorizedBySurah[surah] ?? 0;

  int inProgressInSurah(int surah) => inProgressBySurah[surah] ?? 0;

  int dueInSurah(int surah) => dueBySurah[surah] ?? 0;

  List<(int, int)> trackedInSurah(int surah) =>
      trackedVersesBySurah[surah] ?? const [];
}

/// تقسيم نص الآية إلى كلمات حقيقية مع استبعاد علامات الوقف والسجدة المنفصلة.
final _arabicLetterRe = RegExp(r'[\u0621-\u064A\u066E-\u06D3\u06FA-\u06FF]');
final _firstGraphemeRe = RegExp(r'^.\p{M}*', unicode: true);

List<String> hifzWordsOf(String ayahText) => [
  for (final token in ayahText.trim().split(RegExp(r'\s+')))
    if (token.isNotEmpty && _arabicLetterRe.hasMatch(token)) token,
];

/// أول حرف (مع تشكيله) تلميحاً للآيات المكوّنة من كلمة واحدة فقط.
String hifzSingleWordHint(String word) {
  final m = _firstGraphemeRe.firstMatch(word);
  return m?.group(0) ?? (word.isEmpty ? '' : word.substring(0, 1));
}

/// تقدّم الحفظ، محفوظ ضمن حالة الميزات.
class HifzStore {
  HifzStore._();

  static const _key = 'memorization';

  static String _id(int surah, int ayah) => '$surah:$ayah';

  static (int, int)? _parseId(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    if (s == null || a == null) return null;
    return (s, a);
  }

  /// كل الآيات المضافة للحفظ.
  static Map<String, HifzCard> all() => {
    for (final e in UserDataStore.instance.featureState(_key).entries)
      e.key: HifzCard.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };

  /// يحسب إحصاءات الحفظ والمستحق اليوم والتقدّم لكل سورة في تمريرة واحدة.
  static HifzSummary summary({DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final raw = UserDataStore.instance.featureState(_key);

    final due = <(int, int)>[];
    var memorizedCount = 0;
    var inProgressCount = 0;
    final memorizedBySurah = <int, int>{};
    final inProgressBySurah = <int, int>{};
    final dueBySurah = <int, int>{};
    final trackedBySurah = <int, List<(int, int)>>{};

    for (final entry in raw.entries) {
      final pair = _parseId(entry.key);
      final value = entry.value;
      if (pair == null || value is! Map) continue;
      final (s, a) = pair;
      final card = HifzCard.fromJson(Map<String, dynamic>.from(value));

      trackedBySurah.putIfAbsent(s, () => []).add((s, a));

      if (card.isMemorized) {
        memorizedCount++;
        memorizedBySurah[s] = (memorizedBySurah[s] ?? 0) + 1;
      } else {
        inProgressCount++;
        inProgressBySurah[s] = (inProgressBySurah[s] ?? 0) + 1;
      }

      if (!card.due.isAfter(today)) {
        due.add((s, a));
        dueBySurah[s] = (dueBySurah[s] ?? 0) + 1;
      }
    }

    due.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    for (final list in trackedBySurah.values) {
      list.sort((a, b) => a.$2.compareTo(b.$2));
    }

    return HifzSummary(
      due: due,
      memorizedCount: memorizedCount,
      inProgressCount: inProgressCount,
      memorizedBySurah: memorizedBySurah,
      inProgressBySurah: inProgressBySurah,
      dueBySurah: dueBySurah,
      trackedVersesBySurah: trackedBySurah,
    );
  }

  /// مفاتيح الآيات المضافة للحفظ، دون كلفة قراءة بطاقاتها.
  static Set<String> ids() =>
      UserDataStore.instance.featureState(_key).keys.toSet();

  /// حالة حفظ الآية، أو null؛ تقرأ بطاقتها وحدها لا كل المحفوظ.
  static HifzCard? card(int surah, int ayah) {
    final raw = UserDataStore.instance.featureState(_key)[_id(surah, ayah)];
    return raw == null
        ? null
        : HifzCard.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  /// يسجّل تقييم القارئ لتذكّر الآية.
  ///
  /// إن كانت الآية مقيّمة سابقاً وموعدها القادم بعد اليوم فلا يقفز صندوقها
  /// بالتكرار في نفس اليوم عند النقر على «أتقنتها»، مع بقاء سلسلة الأيام نشطة.
  static Future<void> grade(
    int surah,
    int ayah, {
    required bool remembered,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final existing = card(surah, ayah);
    if (existing != null &&
        remembered &&
        existing.box > 0 &&
        existing.due.isAfter(today)) {
      await UserDataStore.instance.markActiveDay(now: at);
      return;
    }

    final state = UserDataStore.instance.featureState(_key);
    final current = existing ?? HifzCard(box: 0, due: today);
    state[_id(surah, ayah)] = current
        .grade(remembered: remembered, now: at)
        .toJson();
    await UserDataStore.instance.saveFeatureState(_key, state);
    // جلسة الحفظ تحفظ سلسلة الأيام أيضاً.
    await UserDataStore.instance.markActiveDay(now: at);
  }

  static bool contains(int surah, int ayah) =>
      UserDataStore.instance.featureState(_key).containsKey(_id(surah, ayah));

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

  /// يزيل الآية من جدول الحفظ والمراجعة.
  static Future<void> remove(int surah, int ayah) {
    final state = UserDataStore.instance.featureState(_key);
    final id = _id(surah, ayah);
    if (!state.containsKey(id)) return Future.value();
    state.remove(id);
    return UserDataStore.instance.saveFeatureState(_key, state);
  }

  /// الآيات المستحقة اليوم، بترتيب المصحف.
  static List<(int, int)> dueToday({DateTime? now}) => summary(now: now).due;

  /// عدد الآيات المحفوظة (الصندوق الثالث فما فوق).
  static int memorizedCount() => summary().memorizedCount;

  /// عدد الآيات المحفوظة في السورة [surah].
  static int memorizedInSurah(int surah) =>
      summary().memorizedInSurah(surah);
}

