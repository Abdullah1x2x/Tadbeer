import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../notes/note_model.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import '../qcf/qcf_ayah_text.dart';
import '../../ayah_links/widgets/ayah_link_picker_dialog.dart';
import '../../settings/user_settings_model.dart';
import '../../memorization/memorization_model.dart';
import '../../share/ayah_share_sheet.dart';
import '../../tadbeer/tadbeer_pause_sheet.dart';
import '../../../core/design_system/app_icons.dart';

/// Modal action sheet for interacting with an individual Ayah.
///
/// EDUCATIONAL NOTE:
/// Offers quick actions:
/// 1. Tadbeer reflection note (linked to this ayah via stable ID)
/// 2. Bookmark toggle (pinning verse for recitation)
/// 3. Color highlight (4 calm, non-distracting colors)
/// 4. Copying authentic Quranic verse with reference
/// نافذة إجراءات منبثقة للتفاعل مع الآية القرآنية (وقفة تدبر، ربط آيات، ملاحظة، علامة مرجعية، تظليل، نسخ).
class AyahActionSheet extends StatefulWidget {
  final Ayah ayah;

  /// What the sheet opens on: all actions, or straight to one of its editors.
  final AyahSheetMode mode;

  /// ينشئ نافذة إجراءات الآية القرآنية المحددة.
  const AyahActionSheet({
    super.key,
    required this.ayah,
    this.mode = AyahSheetMode.actions,
  });

  /// Displays the Ayah action sheet as a smooth, responsive modal dialog.
  /// يعرض نافذة إجراءات الآية كحوار منبثق سلس ومتجاوب.
  static Future<void> show(
    BuildContext context,
    Ayah ayah, {
    AyahSheetMode mode = AyahSheetMode.actions,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) =>
          AyahActionSheet(ayah: ayah, mode: mode),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// ينشئ الحالة التفاعلية لنافذة إجراءات الآية.
  @override
  State<AyahActionSheet> createState() => _AyahActionSheetState();
}

/// ما تفتح عليه نافذة الآية.
enum AyahSheetMode {
  /// كل الإجراءات.
  actions,

  /// محرر ملاحظة الآية.
  note,

  /// اختيار لون التمييز.
  highlight,
}

/// Backward compatibility alias for AyahActionSheet
/// اسم بديل متوافق مع الإصدارات السابقة لنافذة إجراءات الآية.
typedef AyahActionDialog = AyahActionSheet;

/// الحالة التفاعلية لنافذة إجراءات الآية القرآنية.
class _AyahActionSheetState extends State<AyahActionSheet> {
  late bool _isNoteEditorOpen = widget.mode == AyahSheetMode.note;
  late bool _isHighlightPickerOpen = widget.mode == AyahSheetMode.highlight;
  late TextEditingController _noteController;
  String? _existingNoteId;

  /// يهيئ حقل الملاحظة بالبيانات المحفوظة مسبقاً للآية إن وجدت.
  @override
  void initState() {
    super.initState();
    final existingNotes = UserDataStore.instance.getNotesForAyah(
      widget.ayah.surahNumber,
      widget.ayah.ayahNumber,
    );
    if (existingNotes.isNotEmpty) {
      _existingNoteId = existingNotes.first.id;
      _noteController = TextEditingController(
        text: existingNotes.first.content,
      );
    } else {
      _noteController = TextEditingController();
    }
  }

  /// يحرر متحكم النص عند إغلاق النافذة.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// يحفظ ملاحظة المستخدم المرتبطة بالآية أو يحذفها إذا كان النص فارغاً.
  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty && _existingNoteId != null) {
      await UserDataStore.instance.deleteNote(_existingNoteId!);
    } else if (text.isNotEmpty) {
      await UserDataStore.instance.saveNote(
        id: _existingNoteId,
        type: NoteType.ayah,
        content: text,
        ayahId: widget.ayah.id,
        surahNumber: widget.ayah.surahNumber,
        ayahNumber: widget.ayah.ayahNumber,
        page: widget.ayah.page,
        ayahText: widget.ayah.text,
      );
    }
    if (mounted) {
      setState(() => _isNoteEditorOpen = false);
    }
  }

  /// يبني واجهة نافذة إجراءات الآية وأوضاع تحرير الملاحظة أو اختيار لون التظليل.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surah = QuranRepository.instance.getSurah(widget.ayah.surahNumber);
    final storage = UserDataStore.instance;
    final isBookmarked = storage.isBookmarked(
      widget.ayah.surahNumber,
      widget.ayah.ayahNumber,
    );
    final currentHighlight = storage.getHighlight(
      widget.ayah.surahNumber,
      widget.ayah.ayahNumber,
    );
    final quranText = isDark
        ? AppColors.nightQuranText
        : AppColors.dayQuranText;
    final plainAyah = Text(
      '﴿ ${widget.ayah.text} ﴾',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: storage.quranFontFamily,
        fontSize: 19,
        height: 1.8,
        color: quranText,
      ),
    );
    final inHifz = HifzStore.contains(
      widget.ayah.surahNumber,
      widget.ayah.ayahNumber,
    );
    final hasReflection =
        storage.getTadbeer(widget.ayah.surahNumber, widget.ayah.ayahNumber) !=
        null;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width.clamp(300.0, 520.0),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.comsilkLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Surah and Ayah reference
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.ayahReference(
                          surah.name,
                          context.currentLanguage == AppLanguage.arabic
                              ? ArabicSearchNormalizer.toArabicDigits(
                                  widget.ayah.ayahNumber,
                                )
                              : widget.ayah.ayahNumber,
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily:
                              context.currentLanguage == AppLanguage.arabic
                              ? 'IBMPlexSansArabic'
                              : null,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${context.l10n.pageAbbr(context.currentLanguage == AppLanguage.arabic ? ArabicSearchNormalizer.toArabicDigits(widget.ayah.page) : widget.ayah.page)} · ${context.l10n.juzAbbr(context.currentLanguage == AppLanguage.arabic ? ArabicSearchNormalizer.toArabicDigits(widget.ayah.juz) : widget.ayah.juz)}',
                      style: TextStyle(
                        fontFamily:
                            context.currentLanguage == AppLanguage.arabic
                            ? 'IBMPlexSansArabic'
                            : null,
                        fontSize: 13,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                    ),
                  ],
                ),
              ),

              // The ayah as the reader sees it in the Mushaf: in the
              // Madinah script, or in their font in the flowing text view.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: storage.settings.mushafStyle == MushafStyle.madinah
                      ? QcfAyahText(
                          ayah: widget.ayah,
                          fontSize: 23,
                          color: quranText,
                          fallback: plainAyah,
                        )
                      : plainAyah,
                ),
              ),

              const Divider(height: 1),

              // Note Editor Mode
              if (_isNoteEditorOpen) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.ayahNoteLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 5,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark
                              ? AppColors.nightQuranText
                              : AppColors.dayQuranText,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.noteContent,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.border(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _isNoteEditorOpen = false),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.nightSubtitle
                                    : AppColors.daySubtitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _saveNote();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(AppIcons.check, size: 16),
                            label: Text(
                              l10n.save,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (_isHighlightPickerOpen) ...[
                // Highlight Color Picker Mode
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          AppColors.highlightColors.length,
                          (index) {
                            final color = AppColors.highlightColors[index];
                            final isSelected =
                                currentHighlight?.colorIndex == index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await storage.setHighlight(
                                    widget.ayah,
                                    index,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                          : Colors.transparent,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          AppIcons.check,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (currentHighlight != null) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () async {
                            await storage.removeHighlight(
                              widget.ayah.surahNumber,
                              widget.ayah.ayahNumber,
                            );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            AppIcons.trash,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          label: Text(
                            l10n.removeHighlight,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Reflection leads, as the app's purpose; the other actions
                // sit in a grid of four that takes another one in its row.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: _ReflectButton(
                    label: hasReflection
                        ? l10n.continueReflection
                        : l10n.tadbeerPause,
                    onTap: () {
                      Navigator.of(context).pop();
                      TadbeerPauseSheet.show(context, widget.ayah);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                  child: _ActionGrid(
                    children: [
                      _ActionButton(
                        icon: AppIcons.graphFill,
                        label: l10n.ayahLink,
                        onTap: () {
                          Navigator.of(context).pop();
                          AyahLinkPickerDialog.show(context, widget.ayah);
                        },
                      ),
                      _ActionButton(
                        icon: AppIcons.notePencil,
                        label: l10n.addNote,
                        onTap: () => setState(() => _isNoteEditorOpen = true),
                        hasActiveIndicator: _existingNoteId != null,
                      ),
                      _ActionButton(
                        icon: isBookmarked
                            ? AppIcons.bookmarkSimpleFill
                            : AppIcons.bookmarkSimple,
                        label: isBookmarked ? l10n.unmarkAyah : l10n.markAyah,
                        iconColor: isBookmarked
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        onTap: () async {
                          await storage.toggleBookmark(widget.ayah);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                      _ActionButton(
                        icon: AppIcons.highlighterCircle,
                        label: l10n.highlight,
                        iconColor: currentHighlight != null
                            ? AppColors.highlightColors[currentHighlight
                                  .colorIndex]
                            : null,
                        onTap: () =>
                            setState(() => _isHighlightPickerOpen = true),
                      ),
                      _ActionButton(
                        icon: inHifz ? AppIcons.brainFill : AppIcons.brain,
                        label: inHifz
                            ? l10n.removeFromMemorization
                            : l10n.addToMemorization,
                        iconColor: inHifz
                            ? AppColors.accentGold(context)
                            : null,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await HifzStore.toggle(
                            widget.ayah.surahNumber,
                            widget.ayah.ayahNumber,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      _ActionButton(
                        icon: AppIcons.export,
                        label: l10n.share,
                        onTap: () {
                          final ayah = widget.ayah;
                          Navigator.of(context).pop();
                          AyahShareSheet.show(context, ayah);
                        },
                      ),
                      _ActionButton(
                        icon: AppIcons.copy,
                        label: l10n.copy,
                        onTap: () {
                          final shareText =
                              '﴿${widget.ayah.text}﴾ [سورة ${surah.name}: ${widget.ayah.ayahNumber}]';
                          Clipboard.setData(ClipboardData(text: shareText));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.copiedToClipboard,
                                textAlign: TextAlign.center,
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The ayah's actions, four to a row; a row that is not full is centred,
/// so adding an action needs nothing but a new child.
class _ActionGrid extends StatelessWidget {
  final List<Widget> children;

  const _ActionGrid({required this.children});

  static const _perRow = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth / _perRow;
        return Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 4,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// زر وقفة التدبر البارز في رأس الإجراءات.
class _ReflectButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ReflectButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentGold(context),
        // Dark text on gold reads clearly in both modes.
        foregroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightPrimaryDark,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      icon: const Icon(AppIcons.flowerLotusFill, size: 22),
      label: Text(label),
    );
  }
}

/// زر إجراء في شبكة نافذة الآية: أيقونة في دائرة وتسمية تحتها، ونقطة ذهبية
/// إن كان للآية ما يخص هذا الإجراء.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool hasActiveIndicator;

  /// ينشئ زر إجراء لنافذة إجراءات الآية.
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.hasActiveIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.accentGold(context);
    final color =
        iconColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightPrimaryDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: isDark ? 0.18 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                if (hasActiveIndicator)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Two lines at most, so a longer name wraps instead of shrinking.
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.nightQuranText
                    : AppColors.dayQuranText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
