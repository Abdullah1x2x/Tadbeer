/// يمثل جلسة "وقفة تدبر" تأملية للمستخدم حول آية قرآنية محددة.
///
/// Represents a user's reflective Tadbeer Pause session for an individual Ayah.
///
/// EDUCATIONAL NOTE:
/// Tadbeer encourages contemplation (تدبر) through 4 guiding questions:
/// what stopped you, what the ayah says to you, what it stirred in you,
/// and what you will do with it today. Some ayahs swap one of them, see
/// `TadbeerQuestions`.
///
/// Offline-first principles:
/// - Stored locally via stable Ayah ID (`surahNumber:ayahNumber`).
/// - Re-opens with previous answers populated for that Ayah.
/// - Empty answers are never stored.
/// - Unifies seamlessly with the Ayah Links network and notes display.
class TadbeerItem {
  /// المعرّف الفريد لوقفة التدبر.
  final String id;

  /// رقم السورة التي تنتمي إليها الآية.
  final int surahNumber;

  /// رقم الآية داخل السورة.
  final int ayahNumber;

  /// المعرّف الموحد للآية (إن وجد).
  final int? ayahId;

  /// خريطة إجابات المستخدم مربوطة بمفتاح السؤال من [questionKeys].
  final Map<int, String> answers;

  /// تاريخ ووقت إنشاء وقفة التدبر.
  final DateTime createdAt;

  /// تاريخ ووقت آخر تحديث لوقفة التدبر.
  final DateTime updatedAt;

  /// متى كُتب ما التزم به القارئ (جواب «ما الذي ستفعله بها اليوم؟»)
  /// أو تغيّر آخر مرة.
  final DateTime? commitmentAt;

  /// ما إذا قال القارئ إنه فعل ما التزم به.
  final bool commitmentDone;

  /// ما إذا سُئل عن التزامه في الرئيسية فقال «ليس بعد»، فلا يُسأل ثانية.
  final bool commitmentAsked;

  /// ينشئ كائن وقفة تدبر جديد.
  const TadbeerItem({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    this.ayahId,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
    this.commitmentAt,
    this.commitmentDone = false,
    this.commitmentAsked = false,
  });

  /// مفتاح جواب «ما الذي ستفعله بها اليوم؟».
  static const int commitmentKey = 3;

  /// ما التزم به القارئ عند هذه الآية، أو null إن لم يكتب شيئاً.
  String? get commitment {
    final text = answers[commitmentKey]?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// المفتاح المركب للآية بصيغة (رقم السورة:رقم الآية).
  String get ayahKey => '$surahNumber:$ayahNumber';

  /// مفاتيح الإجابات بترتيب عرض الأسئلة.
  ///
  /// Answers are keyed by what a question asks, so earlier saves keep their
  /// place: 1 what stopped you, 2 what the ayah says to you, 5 what it
  /// stirred, 3 what you will do. Key 4 held a retired question about the
  /// ayah before; [TadbeerItem.fromJson] folds it into 2.
  static const List<int> questionKeys = [1, 2, 5, 3];

  /// الأسئلة التوجيهية الأربعة العامة لوقفة التدبر، بترتيب [questionKeys].
  static const List<String> questions = [
    'أيّ كلمة أو عبارة توقّفت عندها؟',
    'ماذا تقول لك هذه الآية؟',
    'ماذا حرّكت فيك؟',
    'ما الذي ستفعله بها اليوم؟',
  ];

  /// ما إذا كانت جميع إجابات وقفة التدبر فارغة.
  bool get isEmpty => answers.values.every((v) => v.trim().isEmpty);

  /// يجمع جميع الإجابات غير الفارغة في ملخص نصي منسق.
  ///
  /// Formats all non-empty answers into a clean, peaceful reflection summary.
  String get combinedSummary {
    final buffer = StringBuffer();
    for (final key in questionKeys) {
      final ans = answers[key]?.trim();
      if (ans != null && ans.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(ans);
      }
    }
    return buffer.toString();
  }

  /// يحول كائن وقفة التدبر إلى خريطة بيانات JSON للحفظ المحلي.
  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    if (ayahId != null) 'ayahId': ayahId,
    'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (commitmentAt != null) 'commitmentAt': commitmentAt!.toIso8601String(),
    if (commitmentDone) 'commitmentDone': true,
    if (commitmentAsked) 'commitmentAsked': true,
  };

  /// ينشئ كائن وقفة تدبر من خريطة بيانات JSON المحفوظة.
  factory TadbeerItem.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = <int, String>{};
    for (final entry in rawAnswers.entries) {
      final key = int.tryParse(entry.key);
      if (key != null && entry.value is String) {
        parsedAnswers[key] = entry.value as String;
      }
    }
    // The retired question about the ayah before joins what the ayah says.
    final retired = parsedAnswers.remove(4)?.trim() ?? '';
    if (retired.isNotEmpty) {
      final said = parsedAnswers[2]?.trim() ?? '';
      parsedAnswers[2] = said.isEmpty ? retired : '$said\n$retired';
    }
    return TadbeerItem(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      ayahId: json['ayahId'] as int?,
      answers: parsedAnswers,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      commitmentAt: DateTime.tryParse(json['commitmentAt'] as String? ?? ''),
      commitmentDone: json['commitmentDone'] as bool? ?? false,
      commitmentAsked: json['commitmentAsked'] as bool? ?? false,
    );
  }

  /// ينشئ نسخة محدثة من وقفة التدبر مع تعديل الإجابات أو تاريخ التحديث.
  TadbeerItem copyWith({
    Map<int, String>? answers,
    DateTime? updatedAt,
    bool? commitmentDone,
    bool? commitmentAsked,
  }) {
    return TadbeerItem(
      id: id,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      ayahId: ayahId,
      answers: answers ?? this.answers,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commitmentAt: commitmentAt,
      commitmentDone: commitmentDone ?? this.commitmentDone,
      commitmentAsked: commitmentAsked ?? this.commitmentAsked,
    );
  }
}

/// اسم بديل متوافق مع الإصدارات السابقة لنموذج وقفة التدبر.
///
/// Backward compatibility typedef
typedef TadabburItem = TadbeerItem;
