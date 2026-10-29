/// حوارات تعديل الرابط وحذف عناصره، تشترك فيها الشبكة والقائمة.
library;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/ayah_link_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../data/ayah_link_repository.dart';

/// يعدّل خاطرة الآية داخل الرابط.
Future<void> editAyahLinkVerseNote(
  BuildContext context,
  String linkId,
  AyahLinkVerse verse,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController(text: verse.note ?? '');
  final updatedNote = await showDialog<String>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.comsilkLight,
      title: Text(context.l10n.ayahReflectionNoteTitle),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 8,
        autofocus: true,
        decoration: InputDecoration(
          hintText: context.l10n.ayahReflectionNoteHint,
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.save),
        ),
      ],
    ),
  );

  if (updatedNote != null) {
    await AyahLinkRepository().updateVerseNote(
      linkId,
      verse.surahNumber,
      verse.ayahNumber,
      updatedNote.isEmpty ? null : updatedNote,
    );
  }
}

/// يطلب التأكيد قبل إزالة الآية من الرابط.
Future<void> confirmRemoveAyahLinkVerse(
  BuildContext context,
  String linkId,
  AyahLinkVerse verse,
) async {
  final surah = QuranRepository.instance.getSurah(verse.surahNumber);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(context.l10n.removeAyahFromLinkTitle),
      content: Text(
        context.l10n.removeAyahFromLinkConfirm(verse.ayahNumber, surah.name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(context.l10n.remove),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await AyahLinkRepository().removeVerseFromLink(
      linkId,
      verse.surahNumber,
      verse.ayahNumber,
    );
  }
}

/// يعدّل بطاقة الخاطرة.
Future<void> editAyahLinkNoteCard(
  BuildContext context,
  String linkId,
  AyahLinkNote note,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleController = TextEditingController(text: note.title ?? '');
  final contentController = TextEditingController(text: note.content);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.comsilkLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            AppIcons.notePencil,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.editNoteCard,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: context.l10n.titleOptional,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: context.l10n.noteContentHint,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (contentController.text.trim().isNotEmpty) {
              Navigator.pop(dialogCtx, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.save),
        ),
      ],
    ),
  );

  if (result == true) {
    final newContent = contentController.text.trim();
    final newTitle = titleController.text.trim();
    await AyahLinkRepository().updateNoteInLink(
      linkId,
      note.id,
      content: newContent,
      title: newTitle.isEmpty ? null : newTitle,
    );
  }
}

/// يطلب التأكيد قبل حذف بطاقة الخاطرة.
Future<void> confirmDeleteAyahLinkNoteCard(
  BuildContext context,
  String linkId,
  AyahLinkNote note,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(context.l10n.deleteNoteCard),
      content: Text(context.l10n.deleteNoteCardConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(context.l10n.delete),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await AyahLinkRepository().deleteNoteFromLink(linkId, note.id);
  }
}
