import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../core/utils/note_pdf_exporter.dart';
import '../../core/utils/tadbeer_journal_exporter.dart';
import '../../features/notes/note_model.dart';
import '../../features/quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import 'note_editor_screen.dart';

/// شاشة عرض وإدارة الخواطر المرتبطة بالآيات والملاحظات الحرة في قائمة موحدة.
///
/// Notes screen displaying both Ayah Notes and Free Notes in a unified stream.
///
/// EDUCATIONAL NOTE:
/// Unified Stream Architecture:
/// - Displays both Ayah Reflections (tied to stable Ayah IDs) and Free Notes.
/// - Sorts newest first.
/// - Supports quick full-text search matching normalized Arabic content.
/// - Individual notes can be exported to formatted A4 PDF documents with Amiri fonts.
/// - Complete periodic reflection journals can be exported to PDF/Markdown.
class NotesScreen extends StatefulWidget {
  /// ينشئ شاشة الملاحظات والخواطر.
  const NotesScreen({super.key});

  /// ينشئ حالة شاشة الملاحظات.
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

/// الحالة الداخلية لشاشة الملاحظات وإدارة البحث والتصدير والحذف.
class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// يحرر موارد متحكم حقل البحث عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يفتح شاشة محرر الملاحظات لإنشاء ملاحظة جديدة أو تعديل ملاحظة قائمة.
  void _openFreeNoteEditor([NoteItem? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(existingNote: existing),
      ),
    );
  }

  /// يبني واجهة شاشة الملاحظات مع شريط البحث وقائمة البطاقات.
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
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_stories_rounded),
              tooltip: l10n.exportTadbeerJournal,
              onPressed: () => TadbeerJournalExporter.showExportDialog(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openFreeNoteEditor(),
          backgroundColor: AppColors.olive,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(
            l10n.newFreeNote,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val.trim()),
                decoration: InputDecoration(
                  hintText: l10n.searchNotesHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.olive),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Notes List
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
                            Icons.edit_note,
                            size: 64,
                            color: AppColors.border(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty
                                ? l10n.noNotesYet
                                : l10n.noSearchResults,
                            style: TextStyle(
                              fontFamily: 'Amiri',
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

  /// يصدر الملاحظة المحددة إلى ملف PDF ويفتح نافذة المشاركة.
  void _exportNotePdf(NoteItem note) async {
    try {
      await NotePdfExporter.exportAndShareNote(note);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تصدير الملاحظة إلى PDF: $e',
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
        );
      }
    }
  }

  /// يعرض نافذة حوار لتأكيد حذف الملاحظة المختارة.
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
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.deleteConfirmMessage,
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'Amiri'),
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
                fontFamily: 'Amiri',
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

/// بطاقة عرض لملاحظة واحدة (سواء كانت مرتبطة بآية أو ملاحظة حرة).
class _NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExportPdf;

  /// ينشئ بطاقة عرض الملاحظة.
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onExportPdf,
  });

  /// يبني واجهة بطاقة الملاحظة مع قائمة الخيارات السريعة.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilk,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Type badge + date + actions menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.isAyahNote ? l10n.ayahNoteLabel : l10n.freeNoteLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.olive,
                    ),
                  ),
                ),
                Text(
                  '${note.createdAt.year}/${note.createdAt.month}/${note.createdAt.day}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'pdf') onExportPdf();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (!note.isAyahNote)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 18,
                            color: AppColors.olive,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.exportPdf),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ayah Note Quote Preview
            if (note.isAyahNote && note.ayahText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.comsilkLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (note.surahNumber != null &&
                        note.ayahNumber != null) ...[
                      Builder(
                        builder: (ctx) {
                          final surah = QuranRepository.instance.getSurah(
                            note.surahNumber!,
                          );
                          return Text(
                            l10n.surahAyahPageReference(
                              surah.name,
                              context.currentLanguage == AppLanguage.arabic
                                  ? ArabicSearchNormalizer.toArabicDigits(note.ayahNumber!)
                                  : note.ayahNumber!,
                              context.currentLanguage == AppLanguage.arabic
                                  ? ArabicSearchNormalizer.toArabicDigits(note.page ?? 1)
                                  : (note.page ?? 1),
                            ),
                            style: TextStyle(
                              fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
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

            // Free Note Title
            if (!note.isAyahNote &&
                note.title != null &&
                note.title!.isNotEmpty) ...[
              Text(
                note.title!,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.nightQuranText
                      : AppColors.dayQuranText,
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Content preview
            Text(
              note.content,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.nightQuranText
                    : AppColors.dayQuranText,
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
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.olive,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
