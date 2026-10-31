/// وقفة تدبر للقارئ عند آية: إجاباته عن الأسئلة الأربعة، وما التزم به.
///
/// الأسئلة: ما الذي استوقفك، وماذا تقول لك الآية، وماذا حرّكت فيك، وما الذي
/// تدعوك إليه؛ وبعض الآيات تبدّل سؤالاً منها (انظر `TadbeerQuestions`).
/// الإجابات الفارغة لا تُحفظ.
class TadbeerItem {
  final String id;

  final int surahNumber;

  final int ayahNumber;

  /// رقم الآية في المصحف كله، إن عُرف.
  final int? ayahId;

  /// الإجابات بمفاتيح [questionKeys].
  final Map<int, String> answers;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// متى كُتب الالتزام (جواب «ما العمل الذي تدعوك إليه هذه الآية؟») أو تغيّر آخر مرة.
  final DateTime? commitmentAt;

  /// هل قال القارئ إنه فعل ما التزم به.
  final bool commitmentDone;

  /// هل سُئل عن التزامه في الرئيسية فقال «ليس بعد»، فلا يُسأل ثانية.
  final bool commitmentAsked;

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

  /// مفتاح جواب «ما العمل الذي تدعوك إليه هذه الآية؟».
  static const int commitmentKey = 3;

  /// ما التزم به القارئ عند هذه الآية، أو null.
  String? get commitment {
    final text = answers[commitmentKey]?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// مفتاح الآية "سورة:آية".
  String get ayahKey => '$surahNumber:$ayahNumber';

  /// مفاتيح الإجابات بترتيب عرض الأسئلة.
  ///
  /// المفتاح يدل على السؤال، فتبقى الإجابات القديمة في مكانها: 1 ما استوقفك، 2
  /// ماذا تقول لك، 5 ماذا حرّكت، 3 ما ستفعله. المفتاح 4 كان لسؤال أُلغي، ويُدمج
  /// في 2 عند القراءة.
  static const List<int> questionKeys = [1, 2, 5, 3];

  /// الأسئلة الأربعة العامة، بترتيب [questionKeys].
  static const List<String> questions = [
    'أيّ كلمة أو عبارة توقّفت عندها؟',
    'ماذا تقول لك هذه الآية؟',
    'ماذا حرّكت فيك؟',
    'ما العمل الذي تدعوك إليه هذه الآية؟',
  ];

  /// هل كل الإجابات فارغة.
  bool get isEmpty => answers.values.every((v) => v.trim().isEmpty);

  /// الإجابات غير الفارغة في نص واحد منسّق.
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

  factory TadbeerItem.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = <int, String>{};
    for (final entry in rawAnswers.entries) {
      final key = int.tryParse(entry.key);
      if (key != null && entry.value is String) {
        parsedAnswers[key] = entry.value as String;
      }
    }
    // السؤال الملغى (مفتاح 4) يُدمج في "ماذا تقول لك الآية".
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
