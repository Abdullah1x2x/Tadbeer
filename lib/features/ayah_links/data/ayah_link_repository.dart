import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/models/ayah_link_model.dart';

/// روابط الآيات: يربط القارئ آيات من سور مختلفة بموضوع واحد.
///
/// تُحفظ مواضع العقد على الخريطة، دون تكرار نص القرآن في التخزين.
class AyahLinkRepository {
  final UserDataStore _store;

  /// [store] للاختبارات؛ الافتراضي هو المخزن العام.
  AyahLinkRepository([UserDataStore? store])
    : _store = store ?? UserDataStore.instance;

  List<AyahLinkItem> get allLinks => _store.ayahLinks;

  AyahLinkItem? getLink(String id) => _store.getAyahLink(id);

  /// ينشئ رابطاً بعنوان ووصف اختياري.
  Future<AyahLinkItem> createLink({
    required String title,
    String? description,
  }) async {
    final now = DateTime.now();
    final link = AyahLinkItem(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description?.trim().isEmpty ?? true
          ? null
          : description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _store.saveAyahLink(link);
    return link;
  }

  Future<void> updateLink(AyahLinkItem link) async {
    await _store.saveAyahLink(link.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteLink(String id) async {
    await _store.deleteAyahLink(id);
  }

  /// يضيف آية إلى الرابط.
  Future<void> addVerseToLink(
    String linkId, {
    required int ayahId,
    required int surahNumber,
    required int ayahNumber,
    required int page,
    String? note,
  }) async {
    final verse = AyahLinkVerse(
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      note: note,
      addedAt: DateTime.now(),
    );
    await _store.addVerseToLink(linkId, verse);
  }

  /// يزيل آية من الرابط.
  Future<void> removeVerseFromLink(
    String linkId,
    int surahNumber,
    int ayahNumber,
  ) async {
    await _store.removeVerseFromLink(linkId, surahNumber, ayahNumber);
  }

  /// يعدّل خاطرة آية داخل الرابط.
  Future<void> updateVerseNote(
    String linkId,
    int surahNumber,
    int ayahNumber,
    String? note,
  ) async {
    await _store.updateVerseNote(linkId, surahNumber, ayahNumber, note);
  }

  /// يضيف بطاقة خاطرة إلى الرابط.
  Future<AyahLinkNote> addNoteToLink(
    String linkId, {
    required String content,
    String? title,
  }) async {
    final now = DateTime.now();
    final note = AyahLinkNote(
      id: const Uuid().v4(),
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final link = getLink(linkId);
    if (link != null) {
      final updatedNotes = [...link.notes, note];
      final updatedPositions = Map<String, LinkNodePosition>.from(
        link.positions,
      );
      if (!updatedPositions.containsKey(note.noteKey)) {
        final count = link.verses.length + updatedNotes.length;
        final angle = (2 * math.pi * (count % 8)) / 8;
        final radius = 330.0 + ((count % 3) * 60.0);
        final dx = 1500.0 + (radius * math.cos(angle));
        final dy = 1500.0 + (radius * math.sin(angle));
        updatedPositions[note.noteKey] = LinkNodePosition(dx: dx, dy: dy);
      }
      final updatedLink = link.copyWith(
        notes: updatedNotes,
        positions: updatedPositions,
        updatedAt: now,
      );
      await updateLink(updatedLink);
    }
    return note;
  }

  /// يعدّل عنوان بطاقة خاطرة أو نصها.
  Future<void> updateNoteInLink(
    String linkId,
    String noteId, {
    required String content,
    String? title,
  }) async {
    final link = getLink(linkId);
    if (link != null) {
      final updatedNotes = link.notes.map((n) {
        if (n.id == noteId) {
          return n.copyWith(
            content: content.trim(),
            title: title?.trim().isEmpty == true ? null : title?.trim(),
            updatedAt: DateTime.now(),
          );
        }
        return n;
      }).toList();
      await updateLink(
        link.copyWith(notes: updatedNotes, updatedAt: DateTime.now()),
      );
    }
  }

  Future<void> deleteNoteFromLink(String linkId, String noteId) async {
    final link = getLink(linkId);
    if (link != null) {
      final updatedNotes = link.notes.where((n) => n.id != noteId).toList();
      final updatedPositions = Map<String, LinkNodePosition>.from(
        link.positions,
      )..remove('note_$noteId');
      await updateLink(
        link.copyWith(
          notes: updatedNotes,
          positions: updatedPositions,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// يحفظ مواضع العقد على الشبكة، وهل رتّبها القارئ بيده.
  Future<void> updatePositions(
    String linkId,
    Map<String, LinkNodePosition> positions,
    bool isManual,
  ) async {
    await _store.updateLinkPositions(linkId, positions, isManual);
  }

  /// يحفظ حالة العرض: الطريقة والإزاحة والتكبير.
  Future<void> updateViewState(
    String linkId, {
    String? viewMode,
    double? panX,
    double? panY,
    double? zoomScale,
  }) async {
    await _store.updateLinkViewState(
      linkId,
      viewMode: viewMode,
      panX: panX,
      panY: panY,
      zoomScale: zoomScale,
    );
  }

  /// الروابط التي تضم الآية.
  List<AyahLinkItem> getLinksForAyah(int surahNumber, int ayahNumber) {
    return _store.getLinksForAyah(surahNumber, ayahNumber);
  }

  /// يبحث في الروابط: العنوان والوصف وأسماء السور والخواطر.
  List<AyahLinkItem> searchLinks(String rawQuery) {
    final normalized = ArabicSearchNormalizer.normalize(rawQuery).trim();
    if (normalized.isEmpty) return allLinks;

    return allLinks.where((link) {
      final normTitle = ArabicSearchNormalizer.normalize(link.title);
      if (normTitle.contains(normalized)) return true;

      if (link.description != null) {
        final normDesc = ArabicSearchNormalizer.normalize(link.description!);
        if (normDesc.contains(normalized)) return true;
      }

      // أسماء سور الآيات.
      for (final v in link.verses) {
        final surah = QuranRepository.instance.getSurah(v.surahNumber);
        final normSurah = ArabicSearchNormalizer.normalize(surah.name);
        if (normSurah.contains(normalized)) return true;

        if (v.note != null) {
          final normNote = ArabicSearchNormalizer.normalize(v.note!);
          if (normNote.contains(normalized)) return true;
        }
      }

      // بطاقات الخواطر.
      for (final n in link.notes) {
        final normContent = ArabicSearchNormalizer.normalize(n.content);
        if (normContent.contains(normalized)) return true;
        if (n.title != null) {
          final normNoteTitle = ArabicSearchNormalizer.normalize(n.title!);
          if (normNoteTitle.contains(normalized)) return true;
        }
      }

      return false;
    }).toList();
  }
}
