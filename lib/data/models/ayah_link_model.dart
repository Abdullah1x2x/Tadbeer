import '../storage/user_data_store.dart';

/// موضع عقدة على لوحة شبكة الروابط.
class LinkNodePosition {
  final double dx;

  final double dy;

  const LinkNodePosition({required this.dx, required this.dy});

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};

  factory LinkNodePosition.fromJson(Map<String, dynamic> json) {
    return LinkNodePosition(
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
    );
  }

  LinkNodePosition copyWith({double? dx, double? dy}) {
    return LinkNodePosition(dx: dx ?? this.dx, dy: dy ?? this.dy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkNodePosition &&
          runtimeType == other.runtimeType &&
          dx == other.dx &&
          dy == other.dy;

  @override
  int get hashCode => Object.hash(dx, dy);
}

/// آية ضمن رابط. تحفظ موضع الآية فقط لا نصها، فلا يتكرر نص القرآن في بيانات
/// المستخدم.
class AyahLinkVerse {
  /// رقم الآية في المصحف كله (1..6236).
  final int ayahId;

  final int surahNumber;

  final int ayahNumber;

  /// رقم الآية الأخيرة إن كان الكرت لنطاق آيات متتالية، وإلا null.
  final int? toAyahNumber;

  /// رقم الصفحة في مصحف المدينة.
  final int page;

  /// خاطرة القارئ على هذه الآية داخل هذا الرابط.
  final String? note;

  /// معرّف فريد للكرت لتمييزه خاصة عند تكرار الآية في نفس الرابط.
  final String id;

  final DateTime addedAt;

  AyahLinkVerse({
    String? id,
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    this.toAyahNumber,
    required this.page,
    this.note,
    required this.addedAt,
  }) : id = id ??
            (toAyahNumber != null && toAyahNumber > ayahNumber
                ? '$surahNumber:$ayahNumber-$toAyahNumber'
                : '$surahNumber:$ayahNumber');

  /// هل الكرت يحتوي على نطاق آيات متتالية (آيتين أو أكثر).
  bool get isRange => toAyahNumber != null && toAyahNumber! > ayahNumber;

  /// رقم الآية الأخيرة في الكرت.
  int get effectiveEndAyah => isRange ? toAyahNumber! : ayahNumber;

  /// عدد الآيات في الكرت.
  int get verseCount => isRange ? (toAyahNumber! - ayahNumber + 1) : 1;

  /// مفتاح الآية "سورة:آية" أو "سورة:بداية-نهاية".
  String get ayahKey => isRange
      ? '$surahNumber:$ayahNumber-$toAyahNumber'
      : '$surahNumber:$ayahNumber';

  /// مفتاح العقدة على شبكة الروابط.
  String get nodeKey => id;

  /// هل يحتوي هذا الكرت على الآية المحددة.
  bool containsAyah(int surah, int ayah) {
    if (surah != surahNumber) return false;
    if (!isRange) return ayah == ayahNumber;
    return ayah >= ayahNumber && ayah <= toAyahNumber!;
  }

  /// الخاطرة المعروضة للآية: خاطرتها في هذا الرابط، وإلا خاطرة القارئ العامة أو
  /// وقفة التدبر عليها.
  String? getEffectiveNote() {
    if (note != null && note!.trim().isNotEmpty) {
      return note!.trim();
    }
    return UserDataStore.instance.getReflectionForAyah(surahNumber, ayahNumber);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ayahId': ayahId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    if (toAyahNumber != null) 'toAyahNumber': toAyahNumber,
    'page': page,
    if (note != null && note!.isNotEmpty) 'note': note,
    'addedAt': addedAt.toIso8601String(),
  };

  factory AyahLinkVerse.fromJson(Map<String, dynamic> json) {
    final s = json['surahNumber'] as int;
    final a = json['ayahNumber'] as int;
    final to = json['toAyahNumber'] as int?;
    final defaultId = (to != null && to > a) ? '$s:$a-$to' : '$s:$a';
    return AyahLinkVerse(
      id: json['id'] as String? ?? defaultId,
      ayahId: json['ayahId'] as int,
      surahNumber: s,
      ayahNumber: a,
      toAyahNumber: to,
      page: json['page'] as int,
      note: json['note'] as String?,
      addedAt: json.containsKey('addedAt')
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  static const Object _unset = Object();

  AyahLinkVerse copyWith({
    String? id,
    Object? note = _unset,
    Object? toAyahNumber = _unset,
  }) {
    return AyahLinkVerse(
      id: id ?? this.id,
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      toAyahNumber: identical(toAyahNumber, _unset)
          ? this.toAyahNumber
          : toAyahNumber as int?,
      page: page,
      note: identical(note, _unset) ? this.note : note as String?,
      addedAt: addedAt,
    );
  }
}

/// علاقة صريحة بين آيتين في الشبكة، بعنوان وملاحظة اختياريين.
class AyahLinkRelationship {
  final String fromAyahKey;

  final String toAyahKey;

  /// وصف قصير للعلاقة.
  final String? label;

  /// شرح وجه الارتباط.
  final String? note;

  const AyahLinkRelationship({
    required this.fromAyahKey,
    required this.toAyahKey,
    this.label,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'from': fromAyahKey,
    'to': toAyahKey,
    if (label != null) 'label': label,
    if (note != null) 'note': note,
  };

  factory AyahLinkRelationship.fromJson(Map<String, dynamic> json) {
    return AyahLinkRelationship(
      fromAyahKey: json['from'] as String,
      toAyahKey: json['to'] as String,
      label: json['label'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// بطاقة خاطرة حرة داخل رابط، غير مرتبطة بآية.
class AyahLinkNote {
  final String id;

  final String? title;

  final String content;

  final DateTime createdAt;

  final DateTime updatedAt;

  const AyahLinkNote({
    required this.id,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// مفتاح البطاقة كعقدة في الشبكة.
  String get noteKey => 'note_$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    if (title != null && title!.isNotEmpty) 'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AyahLinkNote.fromJson(Map<String, dynamic> json) {
    return AyahLinkNote(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static const Object _unset = Object();

  AyahLinkNote copyWith({
    Object? title = _unset,
    String? content,
    DateTime? updatedAt,
  }) {
    return AyahLinkNote(
      id: id,
      title: identical(title, _unset) ? this.title : title as String?,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// رابط آيات: محور بعنوان، وآياته وبطاقاته، ومواضعها على الشبكة، وحالة العرض
/// المحفوظة.
class AyahLinkItem {
  final String id;

  /// عنوان المحور التدبري.
  final String title;

  final String? description;

  final List<AyahLinkVerse> verses;

  /// بطاقات الخواطر الحرة في الرابط.
  final List<AyahLinkNote> notes;

  /// مواضع العقد على الشبكة، بمفتاح الآية أو البطاقة.
  final Map<String, LinkNodePosition> positions;

  final List<AyahLinkRelationship> relationships;

  /// لون كل بطاقة بمفتاح الآية أو البطاقة: [darkCardColor] للداكن، أو رقم في
  /// [AppColors.highlightColors]. غياب المفتاح يعني اللون الافتراضي.
  final Map<String, int> nodeColors;

  /// إخفاء الخطوط التلقائية من المحور إلى البطاقات.
  final bool hideHubLines;

  /// إخفاء خيوط القارئ بين البطاقات.
  final bool hideThreads;

  /// قيمة [nodeColors] للبطاقة الداكنة.
  static const int darkCardColor = -1;

  /// هل رتّب القارئ العقد بيده، أم تُرتّب تلقائياً.
  final bool isManualLayout;

  /// آخر طريقة عرض استُخدمت.
  final String lastViewMode; // 'network', 'ordered', 'cards'

  /// منظور الشبكة المحفوظ: الإزاحة الأفقية.
  final double? panX;

  /// الإزاحة الرأسية.
  final double? panY;

  /// مستوى التكبير.
  final double? zoomScale;

  final DateTime createdAt;

  final DateTime updatedAt;

  const AyahLinkItem({
    required this.id,
    required this.title,
    this.description,
    this.verses = const [],
    this.notes = const [],
    this.positions = const {},
    this.relationships = const [],
    this.nodeColors = const {},
    this.hideHubLines = false,
    this.hideThreads = false,
    this.isManualLayout = false,
    this.lastViewMode = 'network',
    this.panX,
    this.panY,
    this.zoomScale,
    required this.createdAt,
    required this.updatedAt,
  });

  bool containsAyah(int surahNumber, int ayahNumber) {
    return verses.any((v) => v.containsAyah(surahNumber, ayahNumber));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'verses': verses.map((v) => v.toJson()).toList(),
    if (notes.isNotEmpty) 'notes': notes.map((n) => n.toJson()).toList(),
    'positions': positions.map((k, v) => MapEntry(k, v.toJson())),
    if (relationships.isNotEmpty)
      'relationships': relationships.map((r) => r.toJson()).toList(),
    if (nodeColors.isNotEmpty) 'nodeColors': nodeColors,
    if (hideHubLines) 'hideHubLines': true,
    if (hideThreads) 'hideThreads': true,
    'isManualLayout': isManualLayout,
    'lastViewMode': lastViewMode,
    if (panX != null) 'panX': panX,
    if (panY != null) 'panY': panY,
    if (zoomScale != null) 'zoomScale': zoomScale,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AyahLinkItem.fromJson(Map<String, dynamic> json) {
    final versesList = <AyahLinkVerse>[];
    if (json.containsKey('verses')) {
      final raw = json['verses'] as List;
      for (final v in raw) {
        versesList.add(AyahLinkVerse.fromJson(v as Map<String, dynamic>));
      }
    }

    final notesList = <AyahLinkNote>[];
    if (json.containsKey('notes')) {
      final raw = json['notes'] as List;
      for (final n in raw) {
        notesList.add(AyahLinkNote.fromJson(n as Map<String, dynamic>));
      }
    }

    final positionsMap = <String, LinkNodePosition>{};
    if (json.containsKey('positions')) {
      final rawPos = json['positions'] as Map<String, dynamic>;
      for (final entry in rawPos.entries) {
        positionsMap[entry.key] = LinkNodePosition.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    final relationshipsList = <AyahLinkRelationship>[];
    if (json.containsKey('relationships')) {
      final rawRel = json['relationships'] as List;
      for (final r in rawRel) {
        relationshipsList.add(
          AyahLinkRelationship.fromJson(r as Map<String, dynamic>),
        );
      }
    }

    return AyahLinkItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      verses: versesList,
      notes: notesList,
      positions: positionsMap,
      relationships: relationshipsList,
      nodeColors: (json['nodeColors'] as Map<String, dynamic>? ?? const {}).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      hideHubLines: json['hideHubLines'] as bool? ?? false,
      hideThreads: json['hideThreads'] as bool? ?? false,
      isManualLayout: json['isManualLayout'] as bool? ?? false,
      lastViewMode: json['lastViewMode'] as String? ?? 'network',
      panX: (json['panX'] as num?)?.toDouble(),
      panY: (json['panY'] as num?)?.toDouble(),
      zoomScale: (json['zoomScale'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static const Object _unset = Object();

  AyahLinkItem copyWith({
    String? title,
    Object? description = _unset,
    List<AyahLinkVerse>? verses,
    List<AyahLinkNote>? notes,
    Map<String, LinkNodePosition>? positions,
    List<AyahLinkRelationship>? relationships,
    Map<String, int>? nodeColors,
    bool? hideHubLines,
    bool? hideThreads,
    bool? isManualLayout,
    String? lastViewMode,
    Object? panX = _unset,
    Object? panY = _unset,
    Object? zoomScale = _unset,
    DateTime? updatedAt,
  }) {
    return AyahLinkItem(
      id: id,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      verses: verses ?? this.verses,
      notes: notes ?? this.notes,
      positions: positions ?? this.positions,
      relationships: relationships ?? this.relationships,
      nodeColors: nodeColors ?? this.nodeColors,
      hideHubLines: hideHubLines ?? this.hideHubLines,
      hideThreads: hideThreads ?? this.hideThreads,
      isManualLayout: isManualLayout ?? this.isManualLayout,
      lastViewMode: lastViewMode ?? this.lastViewMode,
      panX: identical(panX, _unset) ? this.panX : panX as double?,
      panY: identical(panY, _unset) ? this.panY : panY as double?,
      zoomScale: identical(zoomScale, _unset)
          ? this.zoomScale
          : zoomScale as double?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
