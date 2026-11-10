import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/motion/app_motion.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'note_pdf_exporter.dart';
import '../../data/models/note_model.dart';
import '../../data/models/user_settings_model.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../../core/design_system/app_icons.dart';

/// محرر الخواطر بملء الشاشة، للخواطر الطويلة.
class NoteEditorScreen extends StatefulWidget {
  /// الخاطرة المعدّلة، أو null لخاطرة جديدة.
  final NoteItem? existingNote;

  const NoteEditorScreen({super.key, this.existingNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final String _initialTitle;
  late final String _initialContent;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final ValueNotifier<({int words, int chars})> _countsNotifier;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.existingNote?.title ?? '';
    _initialContent = widget.existingNote?.content ?? '';
    _titleController = TextEditingController(text: _initialTitle);
    _contentController = TextEditingController(text: _initialContent);
    _countsNotifier = ValueNotifier<({int words, int chars})>(
      _computeCounts(_initialContent),
    );
    _contentController.addListener(_onContentChanged);
  }

  /// هل في العنوان أو المحتوى تعديل لم يُحفظ.
  bool get _hasUnsavedChanges {
    return _titleController.text.trim() != _initialTitle.trim() ||
        _contentController.text.trim() != _initialContent.trim();
  }

  /// يطلب التأكيد قبل الخروج دون حفظ.
  Future<bool?> _showDiscardConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    return AppMotion.showSmoothDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.unsavedChanges,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.discardChangesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
  }

  void _onContentChanged() {
    _countsNotifier.value = _computeCounts(_contentController.text);
  }

  static ({int words, int chars}) _computeCounts(String text) {
    final trimmed = text.trim();
    final words = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    return (words: words, chars: text.length);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    _countsNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.cannotSaveAnEmptyNote,
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final existing = widget.existingNote;
      if (existing != null && existing.isAyahNote) {
        await UserDataStore.instance.saveNote(
          id: existing.id,
          type: NoteType.ayah,
          content: content,
          title: _titleController.text.trim(),
          ayahId: existing.ayahId,
          surahNumber: existing.surahNumber,
          ayahNumber: existing.ayahNumber,
          page: existing.page,
          ayahText: existing.ayahText,
        );
      } else {
        await UserDataStore.instance.saveNote(
          id: existing?.id,
          type: NoteType.free,
          title: _titleController.text.trim(),
          content: content,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// يصدّر الخاطرة PDF ويفتح المشاركة.
  Future<void> _exportPdf() async {
    final note =
        widget.existingNote ??
        NoteItem(
          id: 'preview',
          type: NoteType.free,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    try {
      await NotePdfExporter.exportAndShareNote(context, note);
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.exportNoteFailed(e))));
      }
    }
  }

  /// يكرّر الخاطرة الحالية وينشئ نسخة جديدة منها.
  Future<void> _duplicateAsNewNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final existing = widget.existingNote;
      final rawTitle = _titleController.text.trim();
      final copyTitle = rawTitle.isNotEmpty ? '$rawTitle (نسخة)' : null;

      if (existing != null && existing.isAyahNote) {
        await UserDataStore.instance.saveNote(
          type: NoteType.ayah,
          title: copyTitle,
          content: content,
          ayahId: existing.ayahId,
          surahNumber: existing.surahNumber,
          ayahNumber: existing.ayahNumber,
          page: existing.page,
          ayahText: existing.ayahText,
        );
      } else {
        await UserDataStore.instance.saveNote(
          type: NoteType.free,
          title: copyTitle,
          content: content,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.newDuplicatedNoteCreatedSuccessfully,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final existing = widget.existingNote;
    final isAyahNote = existing?.isAyahNote == true;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldDiscard = await _showDiscardConfirmationDialog(context);
          if (shouldDiscard == true && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    existing == null
                        ? l10n.newFreeNote
                        : (isAyahNote
                              ? (l10n.editAyahReflection)
                              : l10n.editNote),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FuturisticBadge(
                  label: _hasUnsavedChanges ? (l10n.unsaved) : (l10n.saved),
                  color: _hasUnsavedChanges
                      ? AppColors.statusWarning
                      : AppColors.cyberEmerald,
                  showDot: true,
                  isCompact: true,
                ),
              ],
            ),
            actions: [
              if (_contentController.text.isNotEmpty) ...[
                if (existing != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: FuturisticIconButton(
                      icon: AppIcons.copy,
                      tooltip: l10n.duplicateAsNewNote,
                      size: 38,
                      iconSize: 20,
                      onTap: _duplicateAsNewNote,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: FuturisticIconButton(
                    icon: AppIcons.filePdf,
                    tooltip: l10n.exportPdf,
                    size: 38,
                    iconSize: 20,
                    onTap: _exportPdf,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: FuturisticButton(
                  onPressed: _isSaving ? null : _saveNote,
                  isLoading: _isSaving,
                  icon: AppIcons.check,
                  label: l10n.save,
                  color: AppColors.primary(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // الآية المرتبطة، في خواطر الآيات.
                        if (isAyahNote && existing?.ayahText != null) ...[
                          FuturisticCard(
                            accentColor: AppColors.accentGold(context),
                            showTopAccentGlow: true,
                            borderRadius: AppTokens.radiusLg,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (existing!.surahNumber != null &&
                                    existing.ayahNumber != null) ...[
                                  Builder(
                                    builder: (ctx) {
                                      final surah = QuranRepository.instance
                                          .getSurah(existing.surahNumber!);
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.ayahReference(
                                              surah.name,
                                              l10n.isArabic
                                                  ? ArabicSearchNormalizer.toArabicDigits(
                                                      existing.ayahNumber!,
                                                    )
                                                  : existing.ayahNumber!,
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'IBMPlexSansArabic',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.comsilk
                                                  : AppColors.oliveDark,
                                            ),
                                          ),
                                          FuturisticBadge(
                                            label: l10n.pageAbbr(
                                              l10n.isArabic
                                                  ? ArabicSearchNormalizer.toArabicDigits(
                                                      existing.page ?? 1,
                                                    )
                                                  : (existing.page ?? 1),
                                            ),
                                            color: AppColors.accentGold(
                                              context,
                                            ),
                                            isCompact: true,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Builder(
                                  builder: (ctx) {
                                    final ayah = existing.surahNumber != null && existing.ayahNumber != null
                                        ? QuranRepository.instance.getAyah(existing.surahNumber!, existing.ayahNumber!)
                                        : null;
                                    final isMadinah = UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah;
                                    final fallback = Text(
                                      '﴿ ${existing.ayahText} ﴾',
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontFamily: UserDataStore.instance.quranFontFamily,
                                        fontSize: 17,
                                        height: 1.8,
                                        color: isDark
                                            ? AppColors.nightQuranText
                                            : AppColors.dayQuranText,
                                      ),
                                    );
                                    if (isMadinah && ayah != null) {
                                      return QcfAyahText(
                                        ayah: ayah,
                                        fontSize: 18,
                                        height: 1.8,
                                        textAlign: TextAlign.center,
                                        color: isDark
                                            ? AppColors.nightQuranText
                                            : AppColors.dayQuranText,
                                        fallback: fallback,
                                      );
                                    }
                                    return fallback;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: _titleController,
                          textDirection: context.currentLanguage.direction,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: isAyahNote
                                ? (l10n.reflectionTitleOptional)
                                : l10n.noteTitle,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.comsilk,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _contentController,
                          minLines: 12,
                          maxLines: null,
                          textDirection: context.currentLanguage.direction,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.65,
                            color: isDark
                                ? AppColors.nightQuranText
                                : AppColors.dayQuranText,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.noteContent,
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.comsilk,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightBorder,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // شريط الحالة: عدد الكلمات والأحرف.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.comsilk,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<({int words, int chars})>(
                        valueListenable: _countsNotifier,
                        builder: (context, counts, _) => Text(
                          l10n.noteWordCharCount(counts.words, counts.chars),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                      ),
                      Text(
                        l10n.instantSecureLocalSave,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightSubtitle
                              : AppColors.daySubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
