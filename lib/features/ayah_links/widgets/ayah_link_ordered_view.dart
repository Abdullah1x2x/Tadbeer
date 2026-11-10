import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/ayah_link_model.dart';
import '../data/ayah_link_repository.dart';
import 'ayah_link_edit_dialogs.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../quran/qcf/qcf_ayah_text.dart';
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
        content: Text(context.l10n.noteCopiedToClipboard),
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
                    context.l10n.reflectionNotesCount(notes.length),
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
            for (var i = 0; i < notes.length; i++)
              _AyahLinkNoteCard(
                note: notes[i],
                isDark: isDark,
                onEdit: () => editAyahLinkNoteCard(context, link.id, notes[i]),
                onDelete: () =>
                    confirmDeleteAyahLinkNoteCard(context, link.id, notes[i]),
                onCopy: () => _copyNoteCard(context, notes[i]),
                onDuplicate: () async {
                  await HapticFeedback.lightImpact();
                  await AyahLinkRepository.instance.duplicateNoteInLink(
                    link.id,
                    notes[i].id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.noteCardDuplicatedInLink,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                onMoveUp: i > 0
                    ? () async {
                        await HapticFeedback.lightImpact();
                        await UserDataStore.instance.reorderNoteInLink(
                          link.id,
                          i,
                          i - 1,
                        );
                      }
                    : null,
                onMoveDown: i < notes.length - 1
                    ? () async {
                        await HapticFeedback.lightImpact();
                        await UserDataStore.instance.reorderNoteInLink(
                          link.id,
                          i,
                          i + 1,
                        );
                      }
                    : null,
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
                    context.l10n.connectedVersesCount(verses.length),
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
                              verse.isRange
                                  ? context.l10n.ayahRangeReference(surah.name, context.l10n.digits(verse.ayahNumber), context.l10n.digits(verse.toAyahNumber))
                                  : context.l10n.ayahReference(
                                      surah.name,
                                      verse.ayahNumber,
                                    ),
                              style: TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              if (verses.length > 1) ...[
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(AppIcons.caretUp, size: 20),
                                  tooltip: context.l10n.moveUp,
                                  color: index > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .disabledColor
                                          .withValues(alpha: 0.3),
                                  onPressed: index > 0
                                      ? () async {
                                          await HapticFeedback.lightImpact();
                                          await UserDataStore.instance
                                              .reorderVerseInLink(
                                            link.id,
                                            index,
                                            index - 1,
                                          );
                                        }
                                      : null,
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(AppIcons.caretDown, size: 20),
                                  tooltip: context.l10n.moveDown,
                                  color: index < verses.length - 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .disabledColor
                                          .withValues(alpha: 0.3),
                                  onPressed: index < verses.length - 1
                                      ? () async {
                                          await HapticFeedback.lightImpact();
                                          await UserDataStore.instance
                                              .reorderVerseInLink(
                                            link.id,
                                            index,
                                            index + 1,
                                          );
                                        }
                                      : null,
                                ),
                              ],
                              PopupMenuButton<String>(
                                icon: appMenuIcon,
                          onSelected: (val) async {
                            if (val == 'move_up') {
                              await HapticFeedback.lightImpact();
                              await UserDataStore.instance.reorderVerseInLink(
                                link.id,
                                index,
                                index - 1,
                              );
                            } else if (val == 'move_down') {
                              await HapticFeedback.lightImpact();
                              await UserDataStore.instance.reorderVerseInLink(
                                link.id,
                                index,
                                index + 1,
                              );
                            } else if (val == 'quran') {
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
                              await editAyahLinkVerseNote(context, link.id, verse);
                            } else if (val == 'duplicate') {
                              await HapticFeedback.lightImpact();
                              await AyahLinkRepository.instance.duplicateVerseInLink(
                                link.id,
                                verse,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.verseCardDuplicatedInLink,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else if (val == 'delete') {
                              await confirmRemoveAyahLinkVerse(
                                context,
                                link.id,
                                verse,
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (index > 0)
                              appMenuItem(
                                value: 'move_up',
                                icon: AppIcons.caretUp,
                                label: context.l10n.moveUp,
                              ),
                            if (index < verses.length - 1)
                              appMenuItem(
                                value: 'move_down',
                                icon: AppIcons.caretDown,
                                label: context.l10n.moveDown,
                              ),
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
                              value: 'duplicate',
                              icon: AppIcons.copy,
                              label: context.l10n.duplicateVerseCardShort,
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
                  ],
                ),
                const SizedBox(height: 10),

                    if (verse.isRange) ...[
                      Builder(
                        builder: (ctx) {
                          final rangeAyahs = [
                            for (var a = verse.ayahNumber;
                                a <= verse.effectiveEndAyah;
                                a++)
                              QuranRepository.instance.getAyah(
                                verse.surahNumber,
                                a,
                              ),
                          ].whereType<Ayah>().toList();

                          final isMadinah =
                              UserDataStore.instance.settings.mushafStyle ==
                                  MushafStyle.madinah;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final a in rangeAyahs)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuranScreen(
                                            initialPage: a.page,
                                            targetSurahNumber: a.surahNumber,
                                            targetAyahNumber: a.ayahNumber,
                                          ),
                                        ),
                                      );
                                    },
                                    child: isMadinah
                                        ? QcfAyahText(
                                            ayah: a,
                                            fontSize: fontSize,
                                            color: isDark
                                                ? AppColors.nightQuranText
                                                : AppColors.dayQuranText,
                                            height: 1.8,
                                            fallback: Text(
                                              '﴿ ${a.text} ﴾ [${ArabicSearchNormalizer.toArabicDigits(a.ayahNumber)}]',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: UserDataStore
                                                    .instance
                                                    .quranFontFamily,
                                                fontSize: fontSize,
                                                height: 1.8,
                                                color: isDark
                                                    ? AppColors.nightQuranText
                                                    : AppColors.dayQuranText,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            '﴿ ${a.text} ﴾ [${ArabicSearchNormalizer.toArabicDigits(a.ayahNumber)}]',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: UserDataStore
                                                  .instance.quranFontFamily,
                                              fontSize: fontSize,
                                              height: 1.8,
                                              color: isDark
                                                  ? AppColors.nightQuranText
                                                  : AppColors.dayQuranText,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ] else if (ayah != null)
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
                        child:
                            UserDataStore.instance.settings.mushafStyle ==
                                MushafStyle.madinah
                            ? QcfAyahText(
                                ayah: ayah,
                                fontSize: fontSize,
                                color: isDark
                                    ? AppColors.nightQuranText
                                    : AppColors.dayQuranText,
                                height: 1.8,
                                fallback: Text(
                                  '﴿ ${ayah.text} ﴾',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily:
                                        UserDataStore.instance.quranFontFamily,
                                    fontSize: fontSize,
                                    height: 1.8,
                                    color: isDark
                                        ? AppColors.nightQuranText
                                        : AppColors.dayQuranText,
                                  ),
                                ),
                              )
                            : Text(
                                '﴿ ${ayah.text} ﴾',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily:
                                      UserDataStore.instance.quranFontFamily,
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
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _AyahLinkNoteCard({
    required this.note,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    this.onDuplicate,
    this.onMoveUp,
    this.onMoveDown,
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
                  hasTitle ? title.trim() : (context.l10n.reflectionNoteCard),
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onMoveUp != null || onMoveDown != null) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.moveUp,
                      icon: const Icon(AppIcons.caretUp, size: 20),
                      color: onMoveUp != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.3),
                      onPressed: onMoveUp,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.moveDown,
                      icon: const Icon(AppIcons.caretDown, size: 20),
                      color: onMoveDown != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .disabledColor
                              .withValues(alpha: 0.3),
                      onPressed: onMoveDown,
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: appMenuIcon,
                    onSelected: (val) {
                      if (val == 'move_up') {
                        onMoveUp?.call();
                      } else if (val == 'move_down') {
                        onMoveDown?.call();
                      } else if (val == 'edit') {
                        onEdit();
                      } else if (val == 'copy') {
                        onCopy();
                      } else if (val == 'duplicate') {
                        onDuplicate?.call();
                      } else if (val == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (onMoveUp != null)
                        appMenuItem(
                          value: 'move_up',
                          icon: AppIcons.caretUp,
                          label: context.l10n.moveUp,
                        ),
                      if (onMoveDown != null)
                        appMenuItem(
                          value: 'move_down',
                          icon: AppIcons.caretDown,
                          label: context.l10n.moveDown,
                        ),
                      appMenuItem(
                        value: 'edit',
                        icon: AppIcons.pencilSimple,
                        label: context.l10n.editVerseNote,
                      ),
                      appMenuItem(
                        value: 'copy',
                        icon: AppIcons.copy,
                        label: context.l10n.copyText,
                      ),
                      if (onDuplicate != null)
                        appMenuItem(
                          value: 'duplicate',
                          icon: AppIcons.copy,
                          label: context.l10n.duplicateCard,
                        ),
                      appMenuItem(
                        value: 'delete',
                        icon: AppIcons.trash,
                        label: context.l10n.deleteNote,
                        destructive: true,
                      ),
                    ],
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
