import '../../core/storage/user_data_store.dart';

/// يحدد إحداثيات موضع العقدة داخل لوحة شبكة روابط الآيات.
///
/// Position of a node within the Ayah Link canvas.
class LinkNodePosition {
  /// الإحداثي الأفقي للعقدة.
  final double dx;

  /// الإحداثي الرأسي للعقدة.
  final double dy;

  /// ينشئ كائن إحداثيات موضع العقدة.
  const LinkNodePosition({required this.dx, required this.dy});

  /// يحول إحداثيات العقدة إلى خريطة بيانات قابلة للتخزين بصيغة JSON.
  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};

  /// ينشئ كائن إحداثيات العقدة من خريطة بيانات JSON.
  factory LinkNodePosition.fromJson(Map<String, dynamic> json) {
    return LinkNodePosition(
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
    );
  }

  /// ينشئ نسخة معدلة من إحداثيات العقدة.
  LinkNodePosition copyWith({double? dx, double? dy}) {
    return LinkNodePosition(dx: dx ?? this.dx, dy: dy ?? this.dy);
  }

  /// يتحقق من تطابق إحداثيات عقدتين.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkNodePosition &&
          runtimeType == other.runtimeType &&
          dx == other.dx &&
          dy == other.dy;

  /// يحسب رمز التجزئة لإحداثيات العقدة.
  @override
  int get hashCode => Object.hash(dx, dy);
}

/// يمثل آية قرآنية واحدة مشاركة ضمن رابط آيات تدبري.
///
/// Represents a single verse participating in an Ayah Link.
///
/// Uses stable ayah linkage (surahNumber, ayahNumber, page, ayahId)
/// so that Quran text is never duplicated into the user's storage.
class AyahLinkVerse {
  /// المعرّف الفريد للآية في المصحف.
  final int ayahId;

  /// رقم السورة التي تنتمي إليها الآية.
  final int surahNumber;

  /// رقم الآية داخل السورة.
  final int ayahNumber;

  /// رقم الصفحة في مصحف المدينة.
  final int page;

  /// ملاحظة التدبر الخاصة بهذه الآية ضمن هذا الرابط.
  final String? note;

  /// تاريخ ووقت إضافة الآية إلى الرابط.
  final DateTime addedAt;

  /// ينشئ عنصر آية مرتبطة داخل رابط الآيات.
  const AyahLinkVerse({
    required this.ayahId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    this.note,
    required this.addedAt,
  });

  /// المفتاح المرجعي للآية بصيغة رقم السورة ورقم الآية.
  String get ayahKey => '$surahNumber:$ayahNumber';

  /// يعيد ملاحظة التدبر الفعالة للآية من الرابط أو من سجل التدبر العام.
  ///
  /// Returns the effective reflection note for this verse:
  /// 1. Specific note assigned within this link (if non-empty)
  /// 2. User's general note or Tadbeer pause reflection for this Ayah
  String? getEffectiveNote() {
    if (note != null && note!.trim().isNotEmpty) {
      return note!.trim();
    }
    return UserDataStore.instance.getReflectionForAyah(surahNumber, ayahNumber);
  }

  /// يحول بيانات الآية المرتبطة إلى خريطة JSON للتخزين.
  Map<String, dynamic> toJson() => {
    'ayahId': ayahId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'page': page,
    if (note != null && note!.isNotEmpty) 'note': note,
    'addedAt': addedAt.toIso8601String(),
  };

  /// ينشئ كائن آية مرتبطة من خريطة بيانات JSON.
  factory AyahLinkVerse.fromJson(Map<String, dynamic> json) {
    return AyahLinkVerse(
      ayahId: json['ayahId'] as int,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      page: json['page'] as int,
      note: json['note'] as String?,
      addedAt: json.containsKey('addedAt')
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  /// ينشئ نسخة محدثة من الآية المرتبطة مع إمكانية تعديل الملاحظة.
  AyahLinkVerse copyWith({String? note}) {
    return AyahLinkVerse(
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      note: note ?? this.note,
      addedAt: addedAt,
    );
  }
}

/// يمثل علاقة ربط مباشرة بين آيتين داخل شبكة رابط الآيات.
///
/// Optional future-proof representation of an explicit relationship edge
/// between two ayahs in the link network.
class AyahLinkRelationship {
  /// مفتاح الآية المصدر في العلاقة.
  final String fromAyahKey;

  /// مفتاح الآية الهدف في العلاقة.
  final String toAyahKey;

  /// عنوان مختصر اختياري لوصف العلاقة.
  final String? label;

  /// ملاحظة تفصيلية اختيارية حول وجه الارتباط.
  final String? note;

  /// ينشئ علاقة ربط بين آيتين في الشبكة.
  const AyahLinkRelationship({
    required this.fromAyahKey,
    required this.toAyahKey,
    this.label,
    this.note,
  });

  /// يحول علاقة الربط إلى خريطة بيانات JSON.
  Map<String, dynamic> toJson() => {
    'from': fromAyahKey,
    'to': toAyahKey,
    if (label != null) 'label': label,
    if (note != null) 'note': note,
  };

  /// ينشئ كائن علاقة ربط من خريطة بيانات JSON.
  factory AyahLinkRelationship.fromJson(Map<String, dynamic> json) {
    return AyahLinkRelationship(
      fromAyahKey: json['from'] as String,
      toAyahKey: json['to'] as String,
      label: json['label'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// يمثل بطاقة ملاحظة أو تدبر حر مستقل مضاف داخل رابط الآيات.
///
/// An independent reflection note card within an Ayah Link.
class AyahLinkNote {
  /// المعرف الفريد لبطاقة الملاحظة.
  final String id;

  /// عنوان اختياري للملاحظة أو الفكرة التدبرية.
  final String? title;

  /// نص الملاحظة أو التدبر بالكامل.
  final String content;

  /// تاريخ إنشاء الملاحظة.
  final DateTime createdAt;

  /// تاريخ آخر تعديل للملاحظة.
  final DateTime updatedAt;

  /// ينشئ كائن بطاقة ملاحظة تدبرية جديدة.
  const AyahLinkNote({
    required this.id,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// المفتاح المرجعي للعقدة على لوحة الشبكة.
  String get noteKey => 'note_$id';

  /// تحويل بطاقة الملاحظة إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (title != null && title!.isNotEmpty) 'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// إنشاء بطاقة ملاحظة من خريطة JSON.
  factory AyahLinkNote.fromJson(Map<String, dynamic> json) {
    return AyahLinkNote(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// إنشاء نسخة محدثة من بطاقة الملاحظة.
  AyahLinkNote copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return AyahLinkNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// يمثل كيان رابط الآيات التدبري بما يشمل العنوان والوصف والآيات ومواضع العقد.
///
/// Represents an Ayah Link (روابط الآيات) collection entity.
///
/// Holds the theme/title, optional personal description, member ayahs,
/// canvas node positions, view preferences, and layout state.
class AyahLinkItem {
  /// المعرّف الفريد لرابط الآيات.
  final String id;

  /// عنوان الرابط أو المحور التدبري.
  final String title;

  /// وصف إضافي اختياري لفكرة الرابط التدبرية.
  final String? description;

  /// قائمة الآيات القرآنية المنضمة لهذا الرابط.
  final List<AyahLinkVerse> verses;

  /// قائمة كروت الملاحظات والتدبرات الحرة التابعة لهذا الرابط.
  final List<AyahLinkNote> notes;

  /// خريطة مواضع العقد على لوحة الشبكة التفاعلية.
  final Map<String, LinkNodePosition> positions;

  /// قائمة العلاقات المباشرة بين الآيات داخل الرابط.
  final List<AyahLinkRelationship> relationships;

  /// يحدد ما إذا كان ترتيب العقد يدوياً أم تلقائياً.
  final bool isManualLayout;

  /// آخر وضع عرض نشط للرابط مثل الشبكة أو القائمة المرتبة.
  final String lastViewMode; // 'network', 'ordered', 'cards'

  /// الإزاحة الأفقية المحفوظة لمنظور الشبكة.
  final double? panX;

  /// الإزاحة الرأسية المحفوظة لمنظور الشبكة.
  final double? panY;

  /// مستوى التكبير المحفوظ لمنظور الشبكة.
  final double? zoomScale;

  /// تاريخ ووقت إنشاء الرابط.
  final DateTime createdAt;

  /// تاريخ ووقت آخر تحديث للرابط.
  final DateTime updatedAt;

  /// ينشئ كائن رابط آيات متكامل.
  const AyahLinkItem({
    required this.id,
    required this.title,
    this.description,
    this.verses = const [],
    this.notes = const [],
    this.positions = const {},
    this.relationships = const [],
    this.isManualLayout = false,
    this.lastViewMode = 'network',
    this.panX,
    this.panY,
    this.zoomScale,
    required this.createdAt,
    required this.updatedAt,
  });

  /// يتحقق مما إذا كان الرابط يحتوي على آية محددة برقم السورة ورقم الآية.
  bool containsAyah(int surahNumber, int ayahNumber) {
    final key = '$surahNumber:$ayahNumber';
    return verses.any((v) => v.ayahKey == key);
  }

  /// يحول بيانات رابط الآيات إلى خريطة JSON للتخزين.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'verses': verses.map((v) => v.toJson()).toList(),
    if (notes.isNotEmpty)
      'notes': notes.map((n) => n.toJson()).toList(),
    'positions': positions.map((k, v) => MapEntry(k, v.toJson())),
    if (relationships.isNotEmpty)
      'relationships': relationships.map((r) => r.toJson()).toList(),
    'isManualLayout': isManualLayout,
    'lastViewMode': lastViewMode,
    if (panX != null) 'panX': panX,
    if (panY != null) 'panY': panY,
    if (zoomScale != null) 'zoomScale': zoomScale,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// ينشئ كائن رابط آيات من خريطة بيانات JSON.
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
      isManualLayout: json['isManualLayout'] as bool? ?? false,
      lastViewMode: json['lastViewMode'] as String? ?? 'network',
      panX: (json['panX'] as num?)?.toDouble(),
      panY: (json['panY'] as num?)?.toDouble(),
      zoomScale: (json['zoomScale'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// ينشئ نسخة محدثة من رابط الآيات مع تعديل الحقول المطلوبة.
  AyahLinkItem copyWith({
    String? title,
    String? description,
    List<AyahLinkVerse>? verses,
    List<AyahLinkNote>? notes,
    Map<String, LinkNodePosition>? positions,
    List<AyahLinkRelationship>? relationships,
    bool? isManualLayout,
    String? lastViewMode,
    double? panX,
    double? panY,
    double? zoomScale,
    DateTime? updatedAt,
  }) {
    return AyahLinkItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      verses: verses ?? this.verses,
      notes: notes ?? this.notes,
      positions: positions ?? this.positions,
      relationships: relationships ?? this.relationships,
      isManualLayout: isManualLayout ?? this.isManualLayout,
      lastViewMode: lastViewMode ?? this.lastViewMode,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      zoomScale: zoomScale ?? this.zoomScale,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
