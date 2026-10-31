import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'note_pdf_exporter.dart';
import 'tadbeer_journal_exporter.dart';
import '../../data/models/note_model.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import 'note_editor_screen.dart';
import '../../core/design_system/app_icons.dart';
import '../onboarding/tour/section_guide.dart';

/// الخواطر كلها في قائمة واحدة، خواطر الآيات والحرة معاً، الأحدث أولاً.
///
/// فيها بحث في النص، وتصدير الخاطرة PDF، وتصدير دفتر التدبر لفترة PDF أو
/// Markdown.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يفتح المحرر لخاطرة جديدة، أو لتعديل [existing].
  void _openFreeNoteEditor([NoteItem? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(existingNote: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.notes,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            GuideButton(topic: GuideTopic.notes),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FuturisticIconButton(
                icon: AppIcons.bookOpenTextFill,
                tooltip: l10n.exportTadbeerJournal,
                size: 40,
                iconSize: 20,
                onTap: () => TadbeerJournalExporter.showExportDialog(context),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openFreeNoteEditor(),
          backgroundColor: AppColors.olive,
          foregroundColor: Colors.white,
          icon: const Icon(AppIcons.plus),
          label: Text(
            l10n.newFreeNote,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.comsilk,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: AppTokens.borderRegular,
                  ),
                  boxShadow: AppTokens.cardShadow(isDark: isDark),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.searchNotesHint,
                    hintStyle: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                    prefixIcon: Icon(
                      AppIcons.magnifyingGlass,
                      color: isDark ? AppColors.darkPrimary : AppColors.olive,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: context.l10n.clearText,
                            icon: const Icon(AppIcons.x, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListenableBuilder(
                listenable: UserDataStore.instance,
                builder: (context, _) {
                  final notes = UserDataStore.instance.notes.where((n) {
                    if (_query.isEmpty) return true;
                    final q = ArabicSearchNormalizer.normalize(_query);
                    final title = ArabicSearchNormalizer.normalize(
                      n.title ?? '',
                    );
                    final content = ArabicSearchNormalizer.normalize(n.content);
                    final verse = ArabicSearchNormalizer.normalize(
                      n.ayahText ?? '',
                    );
                    return title.contains(q) ||
                        content.contains(q) ||
                        verse.contains(q);
                  }).toList();

                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.notePencil,
                            size: 64,
                            color: AppColors.border(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty
                                ? l10n.noNotesYet
                                : l10n.noSearchResults,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        onTap: () {
                          if (note.isAyahNote &&
                              note.surahNumber != null &&
                              note.ayahNumber != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuranScreen(
                                  initialPage: note.page,
                                  targetSurahNumber: note.surahNumber,
                                  targetAyahNumber: note.ayahNumber,
                                ),
                              ),
                            );
                          } else {
                            _openFreeNoteEditor(note);
                          }
                        },
                        onEdit: () => _openFreeNoteEditor(note),
                        onDelete: () => _showDeleteConfirmDialog(note),
                        onExportPdf: () => _exportNotePdf(note),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// يصدّر الخاطرة PDF ويفتح المشاركة.
  void _exportNotePdf(NoteItem note) async {
    try {
      await NotePdfExporter.exportAndShareNote(context, note);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.exportNoteFailed(e),
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
          ),
        );
      }
    }
  }

  /// يطلب التأكيد قبل حذف الخاطرة.
  void _showDeleteConfirmDialog(NoteItem note) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.comsilkLight,
        title: Text(
          l10n.deleteConfirmTitle,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.deleteConfirmMessage,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserDataStore.instance.deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              l10n.delete,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة خاطرة، على آية أو حرة.
class _NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExportPdf;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final accent = note.isAyahNote
        ? AppColors.cyberEmerald
        : AppColors.electricGold;

    return FuturisticCard(
      onTap: onTap,
      accentColor: accent,
      showTopAccentGlow: note.isAyahNote,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الرأس: نوع الخاطرة والتاريخ وقائمة الإجراءات.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FuturisticBadge(
                label: note.isAyahNote
                    ? l10n.ayahNoteLabel
                    : l10n.freeNoteLabel,
                color: accent,
                showDot: note.isAyahNote,
                isCompact: true,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${note.createdAt.year}/${note.createdAt.month}/${note.createdAt.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: appMenuIcon,
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'pdf') onExportPdf();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      if (!note.isAyahNote)
                        appMenuItem(
                          value: 'edit',
                          icon: AppIcons.pencilSimpleFill,
                          label: l10n.edit,
                        ),
                      appMenuItem(
                        value: 'pdf',
                        icon: AppIcons.filePdfFill,
                        label: l10n.exportPdf,
                      ),
                      appMenuItem(
                        value: 'delete',
                        icon: AppIcons.trash,
                        label: l10n.delete,
                        destructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // مقتطف الآية في خواطر الآيات.
          if (note.isAyahNote && note.ayahText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.comsilkLight,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(
                  color: accent.withValues(alpha: 0.15),
                  width: AppTokens.borderHairline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note.surahNumber != null && note.ayahNumber != null) ...[
                    Builder(
                      builder: (ctx) {
                        final surah = QuranRepository.instance.getSurah(
                          note.surahNumber!,
                        );
                        return Text(
                          l10n.surahAyahPageReference(
                            surah.name,
                            context.currentLanguage == AppLanguage.arabic
                                ? ArabicSearchNormalizer.toArabicDigits(
                                    note.ayahNumber!,
                                  )
                                : note.ayahNumber!,
                            context.currentLanguage == AppLanguage.arabic
                                ? ArabicSearchNormalizer.toArabicDigits(
                                    note.page ?? 1,
                                  )
                                : (note.page ?? 1),
                          ),
                          style: TextStyle(
                            fontFamily:
                                context.currentLanguage == AppLanguage.arabic
                                ? 'IBMPlexSansArabic'
                                : null,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oliveDark,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '﴿ ${note.ayahText} ﴾',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 15,
                      color: isDark
                          ? AppColors.nightQuranText
                          : AppColors.dayQuranText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (!note.isAyahNote &&
              note.title != null &&
              note.title!.isNotEmpty) ...[
            Text(
              note.title!,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.nightQuranText
                    : AppColors.dayQuranText,
              ),
            ),
            const SizedBox(height: 6),
          ],

          Text(
            note.content,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          if (note.isAyahNote) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.goToAyah,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
