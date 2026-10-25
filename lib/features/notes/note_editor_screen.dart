import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/motion/app_motion.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../core/utils/note_pdf_exporter.dart';
import '../../features/notes/note_model.dart';
import '../../features/quran/data/quran_repository.dart';
import '../../core/design_system/app_icons.dart';

/// شاشة محرر الملاحظات والخواطر التدبرية بملء الشاشة.
///
/// Full-screen, comfortable Arabic note editor for long-form tadbeer reflections.
class NoteEditorScreen extends StatefulWidget {
  /// الملاحظة الحالية المراد تعديلها، أو فارغة عند إنشاء ملاحظة جديدة.
  final NoteItem? existingNote;

  /// ينشئ شاشة محرر الملاحظات.
  const NoteEditorScreen({super.key, this.existingNote});

  /// ينشئ حالة شاشة محرر الملاحظات.
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

/// الحالة الداخلية لشاشة محرر الملاحظات وإدارة الحفظ والتصدير.
class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final String _initialTitle;
  late final String _initialContent;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  int _charCount = 0;
  int _wordCount = 0;
  bool _isSaving = false;

  /// يهيئ متحكمات النصوص ويحسب عدد الكلمات والأحرف المبدئي.
  @override
  void initState() {
    super.initState();
    _initialTitle = widget.existingNote?.title ?? '';
    _initialContent = widget.existingNote?.content ?? '';
    _titleController = TextEditingController(text: _initialTitle);
    _contentController = TextEditingController(text: _initialContent);

    _updateCounts(_contentController.text);
    _contentController.addListener(() {
      _updateCounts(_contentController.text);
    });
  }

  /// يتحقق مما إذا كانت هناك تعديلات غير محفوظة في العنوان أو المحتوى.
  bool get _hasUnsavedChanges {
    return _titleController.text.trim() != _initialTitle.trim() ||
        _contentController.text.trim() != _initialContent.trim();
  }

  /// يعرض حوار تأكيد أنيق عند محاولة الخروج دون حفظ التغييرات.
  Future<bool?> _showDiscardConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    return AppMotion.showSmoothDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.isArabic ? 'تغييرات غير محفوظة' : 'Unsaved Changes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.isArabic
              ? 'هل تريد مغادرة المحرر وتجاهل التعديلات غير المحفوظة؟'
              : 'Do you want to discard your unsaved changes and leave?',
        ),
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
            child: Text(l10n.isArabic ? 'تجاهل والخروج' : 'Discard'),
          ),
        ],
      ),
    );
  }

  /// يحدث عدّاد الكلمات والأحرف عند تغير النص المدخل.
  void _updateCounts(String text) {
    final trimmed = text.trim();
    final words = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    setState(() {
      _charCount = text.length;
      _wordCount = words;
    });
  }

  /// يحرر موارد متحكمات النصوص عند إغلاق الشاشة.
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// يحفظ الملاحظة الجديدة أو المعدلة في التخزين المحلي.
  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.isArabic
                ? 'لا يمكن حفظ ملاحظة فارغة'
                : 'Cannot save an empty note',
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

  /// يصدر الملاحظة الحالية إلى ملف PDF ويفتح نافذة المشاركة.
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
      await NotePdfExporter.exportAndShareNote(note);
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isArabic
                  ? 'تعذر تصدير الملاحظة: $e'
                  : 'Failed to export note: $e',
            ),
          ),
        );
      }
    }
  }

  /// يبني واجهة محرر الملاحظات مع حقول العنوان والمحتوى وشريط الإحصائيات.
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
                              ? (l10n.isArabic
                                    ? 'تعديل تدبر الآية'
                                    : 'Edit Ayah Reflection')
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
                  label: _hasUnsavedChanges
                      ? (l10n.isArabic ? 'غير محفوظ' : 'Unsaved')
                      : (l10n.isArabic ? 'محفوظ' : 'Saved'),
                  color: _hasUnsavedChanges
                      ? AppColors.statusWarning
                      : AppColors.cyberEmerald,
                  showDot: true,
                  isCompact: true,
                ),
              ],
            ),
            actions: [
              if (_contentController.text.isNotEmpty)
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
                        // Linked Ayah Banner (for Ayah reflection notes)
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
                                Text(
                                  '﴿ ${existing.ayahText} ﴾',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: 17,
                                    height: 1.8,
                                    color: isDark
                                        ? AppColors.nightQuranText
                                        : AppColors.dayQuranText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Note Title Field
                        TextField(
                          controller: _titleController,
                          textDirection: context.currentLanguage.direction,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: isAyahNote
                                ? (l10n.isArabic
                                      ? 'عنوان التدبر (اختياري)...'
                                      : 'Reflection title (optional)...')
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

                        // Large comfortable editing area
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

                // Bottom status bar with word & character counts
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
                      Text(
                        l10n.isArabic
                            ? '${ArabicSearchNormalizer.toArabicDigits(_wordCount)} كلمة · ${ArabicSearchNormalizer.toArabicDigits(_charCount)} حرف'
                            : '$_wordCount words · $_charCount chars',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightSubtitle
                              : AppColors.daySubtitle,
                        ),
                      ),
                      Text(
                        l10n.isArabic
                            ? 'حفظ محلي فوري وآمن'
                            : 'Instant & secure local save',
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
