import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/ayah_link_model.dart';
import 'ayah_link_edit_dialogs.dart';
import '../../../data/quran/quran_repository.dart';
import '../../quran/screens/quran_screen.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_menu.dart';

/// قائمة الرابط المرتبة، لقراءة الآيات المترابطة بتتابع هادئ.
class AyahLinkOrderedView extends StatelessWidget {
  final AyahLinkItem link;

  /// عند الضغط على زر إضافة آية.
  final VoidCallback onAddVerse;

  const AyahLinkOrderedView({
    super.key,
    required this.link,
    required this.onAddVerse,
  });

  void _copyNoteCard(BuildContext context, AyahLinkNote note) {
    Clipboard.setData(ClipboardData(text: note.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.isArabic
              ? 'تم نسخ نص الملاحظة إلى الحافظة'
              : 'Note copied to clipboard',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verses = link.verses;
    final notes = link.notes;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // بطاقة العنوان والوصف.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.graphFill,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link.title,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (link.description != null &&
                    link.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    link.description!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // بطاقات الخواطر.
          if (notes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    AppIcons.noteFill,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.isArabic
                        ? 'كروت الملاحظات والتدبرات (${ArabicSearchNormalizer.toArabicDigits(notes.length)})'
                        : 'Reflection Notes (${notes.length})',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (final note in notes)
              _AyahLinkNoteCard(
                note: note,
                isDark: isDark,
                onEdit: () => editAyahLinkNoteCard(context, link.id, note),
                onDelete: () =>
                    confirmDeleteAyahLinkNoteCard(context, link.id, note),
                onCopy: () => _copyNoteCard(context, note),
              ),
            const SizedBox(height: 12),
          ],

          // عنوان قسم الآيات، حين توجد خواطر أيضاً.
          if (verses.isNotEmpty && notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    AppIcons.listNumbers,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.isArabic
                        ? 'الآيات المرتبطة (${ArabicSearchNormalizer.toArabicDigits(verses.length)})'
                        : 'Connected Verses (${verses.length})',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          if (verses.isEmpty && notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      AppIcons.bookOpenFill,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noAyahsAddedToLink,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: onAddVerse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(AppIcons.plus, size: 18),
                      label: Text(context.l10n.addAyah),
                    ),
                  ],
                ),
              ),
            )
          else if (verses.isEmpty && notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onAddVerse,
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: Text(context.l10n.addAyah),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          else
            ...List.generate(verses.length, (index) {
              final verse = verses[index];
              final surah = QuranRepository.instance.getSurah(
                verse.surahNumber,
              );
              final ayah = QuranRepository.instance.getAyah(
                verse.surahNumber,
                verse.ayahNumber,
              );
              final effectiveNote = verse.getEffectiveNote();
              final hasNote = effectiveNote != null && effectiveNote.isNotEmpty;
              final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // رأس العنصر: الترتيب والسورة والإجراءات.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  context.l10n.isArabic
                                      ? ArabicSearchNormalizer.toArabicDigits(
                                          index + 1,
                                        )
                                      : '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.isArabic
                                  ? 'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(verse.ayahNumber)}'
                                  : 'Surah ${surah.name} · Verse ${verse.ayahNumber}',
                              style: TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: appMenuIcon,
                          onSelected: (val) {
                            if (val == 'quran') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuranScreen(
                                    initialPage: verse.page,
                                    targetSurahNumber: verse.surahNumber,
                                    targetAyahNumber: verse.ayahNumber,
                                  ),
                                ),
                              );
                            } else if (val == 'note') {
                              editAyahLinkVerseNote(context, link.id, verse);
                            } else if (val == 'delete') {
                              confirmRemoveAyahLinkVerse(
                                context,
                                link.id,
                                verse,
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            appMenuItem(
                              value: 'quran',
                              icon: AppIcons.bookOpenFill,
                              label: context.l10n.openInQuran,
                            ),
                            appMenuItem(
                              value: 'note',
                              icon: AppIcons.notePencil,
                              label: context.l10n.editVerseNote,
                            ),
                            appMenuItem(
                              value: 'delete',
                              icon: AppIcons.trash,
                              label: context.l10n.removeVerseFromLink,
                              destructive: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (ayah != null)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuranScreen(
                                initialPage: verse.page,
                                targetSurahNumber: verse.surahNumber,
                                targetAyahNumber: verse.ayahNumber,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '﴿ ${ayah.text} ﴾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: fontSize,
                            height: 1.8,
                            color: isDark
                                ? AppColors.nightQuranText
                                : AppColors.dayQuranText,
                          ),
                        ),
                      ),

                    if (hasNote) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcons.note,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                effectiveNote,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// بطاقة خاطرة مستقلة في الرابط.
class _AyahLinkNoteCard extends StatelessWidget {
  final AyahLinkNote note;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _AyahLinkNoteCard({
    required this.note,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final title = note.title;
    final hasTitle = title != null && title.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.notePencil,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasTitle
                      ? title.trim()
                      : (context.l10n.isArabic
                            ? 'كرت ملاحظة تدبرية'
                            : 'Reflection Note Card'),
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: appMenuIcon,
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'copy') {
                    onCopy();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  appMenuItem(
                    value: 'edit',
                    icon: AppIcons.pencilSimple,
                    label: context.l10n.isArabic
                        ? 'تعديل الملاحظة'
                        : 'Edit Note',
                  ),
                  appMenuItem(
                    value: 'copy',
                    icon: AppIcons.copy,
                    label: context.l10n.isArabic ? 'نسخ النص' : 'Copy Text',
                  ),
                  appMenuItem(
                    value: 'delete',
                    icon: AppIcons.trash,
                    label: context.l10n.isArabic
                        ? 'حذف الملاحظة'
                        : 'Delete Note',
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 10),
          // النص كاملاً دون قص.
          SelectableText(
            note.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
