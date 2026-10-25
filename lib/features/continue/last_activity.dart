import '../../core/storage/user_data_store.dart';

/// نوع النشاط الأخير الذي يمكن استكماله.
enum ActivityKind { adhkar, book, hifz, pathway }

/// آخر موضع في قسم من الأقسام لاستكماله من الرئيسية.
class LastActivity {
  final ActivityKind kind;

  /// معرّف العنصر: فئة الأذكار، أو معرّف الكتاب، أو رقم السورة، أو معرّف المسار.
  final String ref;

  /// عنوان للعرض (اسم الكتاب أو المسار...).
  final String title;

  /// موضع داخل العنصر (فصل الكتاب مثلاً).
  final int position;

  final DateTime at;

  const LastActivity({
    required this.kind,
    required this.ref,
    required this.title,
    this.position = 0,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'ref': ref,
    'title': title,
    'position': position,
    'at': at.toIso8601String(),
  };

  factory LastActivity.fromJson(ActivityKind kind, Map<String, dynamic> json) =>
      LastActivity(
        kind: kind,
        ref: json['ref'] as String,
        title: json['title'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        at: DateTime.parse(json['at'] as String),
      );
}

/// سجل آخر نشاط في كل قسم (عنصر واحد لكل نوع).
class LastActivityStore {
  LastActivityStore._();

  static const _key = 'last_activity';

  /// يسجّل آخر نشاط من نوع [kind]، ويتجاهل التكرار بلا تغيير.
  static Future<void> record(
    ActivityKind kind, {
    required String ref,
    required String title,
    int position = 0,
  }) {
    final state = UserDataStore.instance.featureState(_key);
    final previous = state[kind.name];
    if (previous is Map &&
        previous['ref'] == ref &&
        previous['position'] == position) {
      return Future.value();
    }
    state[kind.name] = LastActivity(
      kind: kind,
      ref: ref,
      title: title,
      position: position,
      at: DateTime.now(),
    ).toJson();
    return UserDataStore.instance.saveFeatureState(_key, state);
  }

  /// أحدث الأنشطة أولاً.
  static List<LastActivity> recent() {
    final state = UserDataStore.instance.featureState(_key);
    return [
      for (final kind in ActivityKind.values)
        if (state[kind.name] is Map)
          LastActivity.fromJson(
            kind,
            Map<String, dynamic>.from(state[kind.name] as Map),
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));
  }
}
