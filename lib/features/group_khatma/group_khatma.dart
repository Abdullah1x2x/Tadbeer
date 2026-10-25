import 'dart:convert';

import '../../core/storage/user_data_store.dart';
import '../quran/data/quran_repository.dart';

/// عدد أجزاء القرآن الكريم.
const int juzCount = 30;

/// ختمة جماعية: توزيع الأجزاء الثلاثين على المشاركين.
///
/// Works fully offline: the organizer shares a short code (as text or a QR
/// code to show); each participant pastes it, picks their name and tracks
/// their own juz.
class GroupKhatma {
  /// عنوان الختمة.
  final String title;

  /// أسماء المشاركين.
  final List<String> names;

  /// لكل جزء (الفهرس ٠ = الجزء ١) رقم المشارك المكلّف به.
  final List<int> assignment;

  /// المشارك الحالي على هذا الجهاز، إن اختار اسمه.
  final int? me;

  /// الأجزاء التي أتمها المستخدم.
  final Set<int> done;

  /// ينشئ ختمة جماعية.
  const GroupKhatma({
    required this.title,
    required this.names,
    required this.assignment,
    this.me,
    this.done = const {},
  });

  /// يوزّع الأجزاء على المشاركين بالتساوي قدر الإمكان، بالتسلسل.
  factory GroupKhatma.create(String title, List<String> names) {
    final n = names.length;
    final perPerson = juzCount ~/ n;
    final extra = juzCount % n;
    final assignment = <int>[];
    for (var p = 0; p < n; p++) {
      // The first [extra] people take one more juz.
      final count = perPerson + (p < extra ? 1 : 0);
      assignment.addAll(List.filled(count, p));
    }
    return GroupKhatma(title: title, names: names, assignment: assignment);
  }

  /// أجزاء مشارك محدد (أرقام من ١ إلى ٣٠).
  List<int> juzOf(int person) => [
    for (var j = 0; j < juzCount; j++)
      if (assignment[j] == person) j + 1,
  ];

  /// رمز المشاركة القابل للنسخ.
  String get shareCode => base64Url.encode(
    utf8.encode(jsonEncode({'t': title, 'n': names, 'a': assignment})),
  );

  /// يقرأ رمز مشاركة؛ يعيد null إن كان غير صالح.
  static GroupKhatma? fromCode(String code) {
    try {
      final cleaned = code.trim().replaceAll(RegExp(r'\s'), '');
      final map = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(cleaned))),
      ) as Map<String, dynamic>;
      final names = (map['n'] as List).cast<String>();
      final assignment = (map['a'] as List)
          .map((e) => (e as num).toInt())
          .toList();
      if (names.isEmpty ||
          assignment.length != juzCount ||
          assignment.any((p) => p < 0 || p >= names.length)) {
        return null;
      }
      return GroupKhatma(
        title: map['t'] as String? ?? '',
        names: names,
        assignment: assignment,
      );
    } catch (_) {
      return null;
    }
  }

  GroupKhatma copyWith({int? me, Set<int>? done}) => GroupKhatma(
    title: title,
    names: names,
    assignment: assignment,
    me: me ?? this.me,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'names': names,
    'assignment': assignment,
    if (me != null) 'me': me,
    'done': (done.toList()..sort()),
  };

  factory GroupKhatma.fromJson(Map<String, dynamic> json) => GroupKhatma(
    title: json['title'] as String? ?? '',
    names: (json['names'] as List).cast<String>(),
    assignment: (json['assignment'] as List)
        .map((e) => (e as num).toInt())
        .toList(),
    me: (json['me'] as num?)?.toInt(),
    done: {
      for (final d in (json['done'] as List? ?? const [])) (d as num).toInt(),
    },
  );
}

/// تخزين الختمة الجماعية الحالية ضمن حالة الميزات.
class GroupKhatmaStore {
  GroupKhatmaStore._();

  static const _key = 'group_khatma';

  /// الختمة الجماعية الحالية إن وُجدت.
  static GroupKhatma? current() {
    final state = UserDataStore.instance.featureState(_key);
    return state.isEmpty ? null : GroupKhatma.fromJson(state);
  }

  /// يحفظ الختمة الجماعية.
  static Future<void> save(GroupKhatma khatma) =>
      UserDataStore.instance.saveFeatureState(_key, khatma.toJson());

  /// يحذف الختمة الجماعية.
  static Future<void> clear() =>
      UserDataStore.instance.saveFeatureState(_key, const {});
}

/// أول صفحة في الجزء [juz].
int firstPageOfJuz(int juz) {
  final repo = QuranRepository.instance;
  for (var p = 1; p <= 604; p++) {
    if (repo.getPage(p).juzNumber == juz) return p;
  }
  return 1;
}
