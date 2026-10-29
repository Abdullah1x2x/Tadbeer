import 'package:uuid/uuid.dart';

import '../storage/user_data_store.dart';

/// نوع الخاطرة.
enum NoteType {
  /// مرتبطة بآية.
  ayah,

  /// حرة، غير مرتبطة بآية.
  free,
}

/// خاطرة القارئ، على آية أو حرة؛ تُعرض كلها من الأحدث إلى الأقدم.
class NoteItem {
  final String id;

  final NoteType type;

  /// عنوان اختياري.
  final String? title;

  final String content;

  /// حقول الآية، تُملأ في خواطر [NoteType.ayah] فقط.
  final int? ayahId;

  final int? surahNumber;

  final int? ayahNumber;

  final int? page;

  /// نص الآية وقت كتابة الخاطرة.
  final String? ayahText;

  final DateTime createdAt;

  final DateTime updatedAt;

  const NoteItem({
    required this.id,
    required this.type,
    this.title,
    required this.content,
    this.ayahId,
    this.surahNumber,
    this.ayahNumber,
    this.page,
    this.ayahText,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAyahNote => type == NoteType.ayah;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    if (title != null) 'title': title,
    'content': content,
    if (ayahId != null) 'ayahId': ayahId,
    if (surahNumber != null) 'surahNumber': surahNumber,
    if (ayahNumber != null) 'ayahNumber': ayahNumber,
    if (page != null) 'page': page,
    if (ayahText != null) 'ayahText': ayahText,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String,
      type: (json['type'] as String?) == 'free' ? NoteType.free : NoteType.ayah,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      ayahId: json['ayahId'] as int?,
      surahNumber: json['surahNumber'] as int?,
      ayahNumber: json['ayahNumber'] as int?,
      page: json['page'] as int?,
      ayahText: json['ayahText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  NoteItem copyWith({String? title, String? content, DateTime? updatedAt}) {
    return NoteItem(
      id: id,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      ayahText: ayahText,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// حفظ الخواطر وتعديلها وحذفها وجلبها لكل آية، فوق [UserDataStore].
class NoteRepository {
  final UserDataStore _store;

  /// [store] للاختبارات؛ الافتراضي هو المخزن العام.
  NoteRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  List<NoteItem> get allNotes => _store.notes;

  /// خواطر آية محددة.
  List<NoteItem> getNotesForAyah(int surahNumber, int ayahNumber) {
    return _store.getNotesForAyah(surahNumber, ayahNumber);
  }

  /// يحفظ خاطرة جديدة، أو يعدّل الموجودة إن مُرّر [id].
  Future<NoteItem> saveNote({
    String? id,
    required NoteType type,
    String? title,
    required String content,
    int? ayahId,
    int? surahNumber,
    int? ayahNumber,
    int? page,
    String? ayahText,
  }) async {
    final now = DateTime.now();

    if (id != null) {
      final existing = _store.notes.where((n) => n.id == id).firstOrNull;
      if (existing != null) {
        final updated = existing.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        );
        await _store.putNote(updated);
        return updated;
      }
    }

    final newNote = NoteItem(
      id: id ?? const Uuid().v4(),
      type: type,
      title: title,
      content: content,
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      ayahText: ayahText,
      createdAt: now,
      updatedAt: now,
    );
    await _store.putNote(newNote);
    return newNote;
  }

  Future<void> deleteNote(String id) async {
    await _store.deleteNote(id);
  }
}
