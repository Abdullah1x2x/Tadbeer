import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../ayah_link_model.dart';
import '../ayah_link_repository.dart';
import '../../quran/data/quran_repository.dart';
import '../../quran/screens/quran_screen.dart';

/// واجهة عرض الشبكة التفاعلية لرابط الآيات مع عقدة المحور المركزية وعقد الآيات المحيطة.
///
/// Flagship interactive Network Canvas View for an Ayah Link.
///
/// Features:
/// - Virtual canvas with central theme node and surrounding verse nodes.
/// - Deterministic radial auto-layout preventing node collisions.
/// - Drag-and-drop manual positioning with state persistence.
/// - Pan & pinch-to-zoom navigation via [InteractiveViewer].
/// - Centering action and smooth animated camera navigation.
/// - Smooth animated camera focus when tapping an ayah.
/// - Detailed verse inspector bottom sheet.
class AyahLinkNetworkView extends StatefulWidget {
  /// بيانات رابط الآيات المعروض في الشبكة.
  final AyahLinkItem link;

  /// دالة الاستدعاء عند الضغط على زر إضافة آية.
  final VoidCallback onAddVerse;

  /// ينشئ واجهة عرض الشبكة التفاعلية لرابط الآيات.
  const AyahLinkNetworkView({
    super.key,
    required this.link,
    required this.onAddVerse,
  });

  /// ينشئ حالة واجهة الشبكة التفاعلية لرابط الآيات.
  @override
  State<AyahLinkNetworkView> createState() => AyahLinkNetworkViewState();
}

/// حالة واجهة الشبكة التفاعلية التي تدير مواضع العقد وحركة الكاميرا والتفاعل.
class AyahLinkNetworkViewState extends State<AyahLinkNetworkView>
    with SingleTickerProviderStateMixin {
  static const double _canvasSize = 3000.0;
  static const double _centerCoord = _canvasSize / 2; // 1500.0

  late TransformationController _transformController;
  late AnimationController _animController;
  Animation<Matrix4>? _matrixAnimation;

  // Local mutable positions for real-time drag responsiveness
  final Map<String, Offset> _positions = {};

  final AyahLinkRepository _repo = AyahLinkRepository();

  /// يهيئ متحكمات التحويل والحركة ويستعيد مواضع العقد والمنظور.
  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _syncPositionsFromLink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOrRestoreViewport();
    });
  }

  /// يزامن مواضع العقد عند تغير قائمة الآيات أو إعدادات الترتيب في الرابط.
  @override
  void didUpdateWidget(covariant AyahLinkNetworkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link.verses.length != widget.link.verses.length ||
        oldWidget.link.notes.length != widget.link.notes.length ||
        oldWidget.link.isManualLayout != widget.link.isManualLayout ||
        oldWidget.link.positions != widget.link.positions) {
      _syncPositionsFromLink();
    }
  }

  /// يحرر موارد متحكمات التحويل والحركة عند التخلص من الواجهة.
  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// يزامن مواضع العقد المحلية مع المواضع المحفوظة أو يعيد حساب الترتيب التلقائي.
  void _syncPositionsFromLink() {
    final existing = widget.link.positions;
    final verses = widget.link.verses;
    final notes = widget.link.notes;

    if (!widget.link.isManualLayout || existing.isEmpty) {
      // Compute radial auto layout for verses and notes
      _computeAutoLayoutPositions(verses, notes);
    } else {
      _positions.clear();
      for (final v in verses) {
        final pos = existing[v.ayahKey];
        if (pos != null) {
          _positions[v.ayahKey] = Offset(pos.dx, pos.dy);
        }
      }
      for (final n in notes) {
        final pos = existing[n.noteKey];
        if (pos != null) {
          _positions[n.noteKey] = Offset(pos.dx, pos.dy);
        }
      }
      // For any newly added items without saved position, assign auto-slot
      _assignMissingPositions(verses, notes);
    }
  }

  /// يحسب المواضع الدائرية التلقائية للعقد حول المركز، مع دعم حلقات متحدة المركز
  /// وتعديل نصف القطر وفق مقياس الخط لتفادي تداخل الكروت.
  void _computeAutoLayoutPositions(
    List<AyahLinkVerse> verses,
    List<AyahLinkNote> notes,
  ) {
    _positions.clear();
    final allKeys = [
      ...verses.map((v) => v.ayahKey),
      ...notes.map((n) => n.noteKey),
    ];
    final count = allKeys.length;
    if (count == 0) return;

    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final scaleRatio = (fontSize / 18.0).clamp(0.85, 1.45);

    if (count <= 8) {
      final radius = 320.0 * scaleRatio;
      for (int i = 0; i < count; i++) {
        final angle = (2 * math.pi * i / count) - (math.pi / 2);
        final x = _centerCoord + radius * math.cos(angle);
        final y = _centerCoord + radius * math.sin(angle);
        _positions[allKeys[i]] = Offset(x, y);
      }
    } else if (count <= 18) {
      final innerCount = math.min(6, (count / 2).ceil());
      final outerCount = count - innerCount;

      final r1 = 280.0 * scaleRatio;
      for (int i = 0; i < innerCount; i++) {
        final angle = (2 * math.pi * i / innerCount) - (math.pi / 2);
        final x = _centerCoord + r1 * math.cos(angle);
        final y = _centerCoord + r1 * math.sin(angle);
        _positions[allKeys[i]] = Offset(x, y);
      }

      final r2 = 490.0 * scaleRatio;
      for (int i = 0; i < outerCount; i++) {
        final angle = (2 * math.pi * i / outerCount) - (math.pi / 3);
        final x = _centerCoord + r2 * math.cos(angle);
        final y = _centerCoord + r2 * math.sin(angle);
        _positions[allKeys[innerCount + i]] = Offset(x, y);
      }
    } else {
      // Concentric rings with minimum angular distance
      int assigned = 0;
      int ringIndex = 0;

      while (assigned < count) {
        final radius = (280.0 + (ringIndex * 210.0)) * scaleRatio;
        // Estimate how many nodes fit comfortably on this circumference
        final circumference = 2 * math.pi * radius;
        final capacity = math.max(
          6,
          (circumference / (240.0 * scaleRatio)).floor(),
        );
        final inThisRing = math.min(capacity, count - assigned);

        for (int i = 0; i < inThisRing; i++) {
          final angle =
              (2 * math.pi * i / inThisRing) + (ringIndex * (math.pi / 5));
          final x = _centerCoord + radius * math.cos(angle);
          final y = _centerCoord + radius * math.sin(angle);
          _positions[allKeys[assigned + i]] = Offset(x, y);
        }

        assigned += inThisRing;
        ringIndex++;
      }
    }
  }

  /// يعين مواضع افتراضية لأي آيات أو ملاحظات مضافة حديثاً لا تملك موضعاً محفوظاً بعد.
  void _assignMissingPositions(
    List<AyahLinkVerse> verses,
    List<AyahLinkNote> notes,
  ) {
    final allKeys = [
      ...verses.map((v) => v.ayahKey),
      ...notes.map((n) => n.noteKey),
    ];
    for (int i = 0; i < allKeys.length; i++) {
      final key = allKeys[i];
      if (!_positions.containsKey(key)) {
        final angle = (2 * math.pi * i / math.max(1, allKeys.length));
        final radius = 340.0;
        _positions[key] = Offset(
          _centerCoord + radius * math.cos(angle),
          _centerCoord + radius * math.sin(angle),
        );
      }
    }
  }

  /// يهيئ منظور الكاميرا باستعادة الإزاحة والتكبير المحفوظين أو توسيط اللوحة.
  void _initOrRestoreViewport() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;

    if (widget.link.panX != null &&
        widget.link.panY != null &&
        widget.link.zoomScale != null) {
      final matrix = Matrix4.identity()
        ..translate2D(widget.link.panX!, widget.link.panY!)
        ..scale2D(widget.link.zoomScale!);
      _transformController.value = matrix;
    } else {
      // Center on (_centerCoord, _centerCoord)
      _centerViewport(size, animate: false);
    }
  }

  /// يضبط مصفوفة التحويل لتوسيط لوحة الشبكة داخل مساحة العرض المتاحة.
  void _centerViewport(Size viewportSize, {bool animate = true}) {
    const scale = 0.95;
    final targetX = (viewportSize.width / 2) - (_centerCoord * scale);
    final targetY = (viewportSize.height / 2) - (_centerCoord * scale);

    final targetMatrix = Matrix4.identity()
      ..translate2D(targetX, targetY)
      ..scale2D(scale);

    if (animate) {
      _animateToMatrix(targetMatrix);
    } else {
      _transformController.value = targetMatrix;
    }
  }

  /// يحرك منظور الكاميرا بسلاسة نحو مصفوفة التحويل المستهدفة.
  void _animateToMatrix(Matrix4 target) {
    _matrixAnimation?.removeListener(_onMatrixAnim);
    _animController.reset();

    _matrixAnimation =
        Matrix4Tween(begin: _transformController.value, end: target).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _matrixAnimation!.addListener(_onMatrixAnim);
    _animController.forward();
  }

  /// يحدّث قيمة متحكم التحويل أثناء تقدم حركة الكاميرا.
  void _onMatrixAnim() {
    if (_matrixAnimation != null) {
      _transformController.value = _matrixAnimation!.value;
    }
  }

  /// يعيد توسيط منظور الشبكة نحو العقدة المركزية بحركة سلسة ويحفظ الحالة.
  ///
  /// Smoothly animates the canvas viewport back to its initial center.
  void centerView() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    _centerViewport(size, animate: true);
    const scale = 0.95;
    final targetX = (size.width / 2) - (_centerCoord * scale);
    final targetY = (size.height / 2) - (_centerCoord * scale);
    _repo.updateViewState(
      widget.link.id,
      panX: targetX,
      panY: targetY,
      zoomScale: scale,
    );
  }

  /// يعيد ترتيب عقد الآيات تلقائياً حول المركز ويحفظ المواضع الجديدة.
  ///
  /// Public action called to trigger automatic re-layout
  Future<void> autoLayout() async {
    setState(() {
      _computeAutoLayoutPositions(widget.link.verses, widget.link.notes);
    });

    final map = <String, LinkNodePosition>{};
    for (final entry in _positions.entries) {
      map[entry.key] = LinkNodePosition(dx: entry.value.dx, dy: entry.value.dy);
    }
    await _repo.updatePositions(widget.link.id, map, false);
    if (mounted) {
      _centerViewport(MediaQuery.of(context).size);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إعادة الترتيب تلقائيًا'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// يوجه الكاميرا نحو عقدة الآية المختارة ثم يفتح اللوحة التفصيلية للآية.
  ///
  /// Smoothly zooms and centers on a selected Ayah node, then opens inspector
  void _focusAyahNode(AyahLinkVerse verse) {
    final pos = _positions[verse.ayahKey];
    if (pos == null) return;

    final viewportSize = MediaQuery.of(context).size;
    const focusScale = 1.15;

    // We offset the target center slightly above viewport center so the bottom sheet has room
    final targetCenterY = viewportSize.height * 0.42;

    final targetX = (viewportSize.width / 2) - (pos.dx * focusScale);
    final targetY = targetCenterY - (pos.dy * focusScale);

    final targetMatrix = Matrix4.identity()
      ..translate2D(targetX, targetY)
      ..scale2D(focusScale);

    _animateToMatrix(targetMatrix);

    // Open verse inspector sheet
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _showVerseInspectorSheet(verse);
      }
    });
  }

  /// يعرض نافذة سفلية تتضمن النص الكامل للآية وملاحظة التدبر وخيارات الإجراءات.
  void _showVerseInspectorSheet(AyahLinkVerse verse) {
    final surah = QuranRepository.instance.getSurah(verse.surahNumber);
    final ayah = QuranRepository.instance.getAyah(
      verse.surahNumber,
      verse.ayahNumber,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Directionality(
          textDirection: context.currentLanguage.direction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBorder,
              ),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.isArabic
                              ? 'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(verse.ayahNumber)}'
                              : 'Surah ${surah.name} · Verse ${verse.ayahNumber}',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.olive,
                          ),
                        ),
                        Text(
                          context.l10n.isArabic
                              ? 'ص ${ArabicSearchNormalizer.toArabicDigits(verse.page)}'
                              : 'p. ${verse.page}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.olive,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scrollable content for Verse & Reflection Note
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full Verse Text
                            if (ayah != null)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.comsilk,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '﴿ ${ayah.text} ﴾',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: 18,
                                    height: 1.8,
                                    color: isDark
                                        ? AppColors.nightQuranText
                                        : AppColors.dayQuranText,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Reflection note (if any, from link, note or tadbeer)
                            () {
                              final effectiveNote = verse.getEffectiveNote();
                              if (effectiveNote != null && effectiveNote.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.olive.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.olive.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.sticky_note_2_outlined,
                                              size: 16,
                                              color: AppColors.olive,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              context.l10n.reflectionNoteColon,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.olive,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          effectiveNote,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: isDark
                                                ? AppColors.nightSubtitle
                                                : AppColors.daySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Open in Mushaf
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetCtx);
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.olive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: Text(
                            context.l10n.openInQuran,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Edit note button
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        tooltip: context.l10n.reflectionNote,
                        onPressed: () {
                          Navigator.pop(bottomSheetCtx);
                          _showEditNoteDialog(verse);
                        },
                      ),
                      const SizedBox(width: 6),

                      // Remove verse from link button
                      IconButton.filledTonal(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        tooltip: context.l10n.removeVerseFromLink,
                        onPressed: () {
                          Navigator.pop(bottomSheetCtx);
                          _confirmRemoveVerse(verse);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  /// يفتح نافذة حوار لتعديل ملاحظة التدبر الخاصة بآية داخل الرابط.
  Future<void> _showEditNoteDialog(AyahLinkVerse verse) async {
    final controller = TextEditingController(text: verse.note ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (updatedNote != null) {
      await _repo.updateVerseNote(
        widget.link.id,
        verse.surahNumber,
        verse.ayahNumber,
        updatedNote.isEmpty ? null : updatedNote,
      );
    }
  }

  /// يعرض نافذة تأكيد لإزالة آية محددة من رابط الآيات.
  Future<void> _confirmRemoveVerse(AyahLinkVerse verse) async {
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
            child: Text(context.l10n.isArabic ? 'إزالة' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.removeVerseFromLink(
        widget.link.id,
        verse.surahNumber,
        verse.ayahNumber,
      );
    }
  }

  /// يركز الكاميرا بنعومة على عقدة كرت الملاحظة المحددة ويعرض تفاصيلها في نافذة سفلية.
  void _focusNoteNode(AyahLinkNote note) {
    final pos = _positions[note.noteKey];
    if (pos == null) return;

    final viewportSize = MediaQuery.of(context).size;
    const focusScale = 1.15;
    final targetCenterY = viewportSize.height * 0.42;

    final targetX = (viewportSize.width / 2) - (pos.dx * focusScale);
    final targetY = targetCenterY - (pos.dy * focusScale);

    final targetMatrix = Matrix4.identity()
      ..translate2D(targetX, targetY)
      ..scale2D(focusScale);

    _animateToMatrix(targetMatrix);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _showNoteInspectorSheet(note);
      }
    });
  }

  /// يعرض نافذة سفلية تتضمن النص الكامل لكرت الملاحظة وخيارات التعديل والنسخ والحذف.
  void _showNoteInspectorSheet(AyahLinkNote note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Directionality(
          textDirection: context.currentLanguage.direction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightBorder,
              ),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sticky_note_2_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasTitle
                                ? note.title!.trim()
                                : (context.l10n.isArabic
                                    ? 'كرت ملاحظة تدبرية'
                                    : 'Reflection Note Card'),
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scrollable content for Note
                    Flexible(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.comsilk,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            note.content,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightPrimaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Actions Row
                    Row(
                      children: [
                        // Copy Note
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(bottomSheetCtx);
                              Clipboard.setData(
                                ClipboardData(text: note.content),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.isArabic
                                        ? 'تم نسخ نص الملاحظة إلى الحافظة'
                                        : 'Note copied to clipboard',
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.olive,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(
                              context.l10n.isArabic
                                  ? 'نسخ النص'
                                  : 'Copy Text',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Edit Note Button
                        IconButton.filledTonal(
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          tooltip: context.l10n.isArabic
                              ? 'تعديل الملاحظة'
                              : 'Edit Note',
                          onPressed: () {
                            Navigator.pop(bottomSheetCtx);
                            _showEditNoteCardDialog(note);
                          },
                        ),
                        const SizedBox(width: 6),

                        // Delete Note Button
                        IconButton.filledTonal(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          tooltip: context.l10n.isArabic
                              ? 'حذف الملاحظة'
                              : 'Delete Note',
                          onPressed: () {
                            Navigator.pop(bottomSheetCtx);
                            _confirmDeleteNoteCard(note);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// يفتح نافذة حوار لتعديل كرت الملاحظة في الرابط.
  Future<void> _showEditNoteCardDialog(AyahLinkNote note) async {
    final titleController = TextEditingController(text: note.title ?? '');
    final contentController = TextEditingController(text: note.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.comsilkLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          context.l10n.isArabic ? 'تعديل كرت الملاحظة' : 'Edit Note Card',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: context.l10n.isArabic
                      ? 'عنوان الملاحظة (اختياري)'
                      : 'Title (optional)',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.comsilk,
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
                  hintText: context.l10n.isArabic
                      ? 'نص الملاحظة...'
                      : 'Note content...',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.comsilk,
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
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == true) {
      await _repo.updateNoteInLink(
        widget.link.id,
        note.id,
        content: contentController.text.trim(),
        title: titleController.text.trim().isEmpty
            ? null
            : titleController.text.trim(),
      );
    }
  }

  /// يعرض نافذة تأكيد لحذف كرت الملاحظة من الرابط.
  Future<void> _confirmDeleteNoteCard(AyahLinkNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          context.l10n.isArabic ? 'حذف كرت الملاحظة' : 'Delete Note Card',
        ),
        content: Text(
          context.l10n.isArabic
              ? 'هل أنت متأكد من حذف كرت هذه الملاحظة؟'
              : 'Are you sure you want to delete this note card?',
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
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deleteNoteFromLink(widget.link.id, note.id);
    }
  }

  /// يحفظ مواضع العقد المعدلة يدوياً بعد انتهاء عملية السحب.
  void _persistManualPositions() {
    final map = <String, LinkNodePosition>{};
    for (final entry in _positions.entries) {
      map[entry.key] = LinkNodePosition(
        dx: entry.value.dx,
        dy: entry.value.dy,
      );
    }
    _repo.updatePositions(widget.link.id, map, true);
  }

  /// يبني لوحة الشبكة التفاعلية وعقد الآيات وواجهة الحالة الفارغة.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verses = widget.link.verses;
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);

    return Stack(
      children: [
        // Interactive Canvas
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          minScale: 0.25,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(500),
          onInteractionEnd: (details) {
            // Save pan / zoom view state
            final translation = _transformController.value.getTranslation();
            final scale = _transformController.value.getMaxScaleOnAxis();
            _repo.updateViewState(
              widget.link.id,
              panX: translation.x,
              panY: translation.y,
              zoomScale: scale,
            );
          },
          child: SizedBox(
            width: _canvasSize,
            height: _canvasSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Custom Connections Painter
                CustomPaint(
                  size: const Size(_canvasSize, _canvasSize),
                  painter: _NetworkConnectionsPainter(
                    center: const Offset(_centerCoord, _centerCoord),
                    positions: _positions,
                    isDark: isDark,
                  ),
                ),

                // Center Theme Node
                Positioned(
                  left: _centerCoord - 100,
                  top: _centerCoord - 50,
                  child: _CenterThemeNode(
                    title: widget.link.title,
                    description: widget.link.description,
                    versesCount: verses.length,
                    isDark: isDark,
                  ),
                ),

                // Verse Nodes
                for (final verse in verses)
                  if (_positions.containsKey(verse.ayahKey))
                    Positioned(
                      left: _positions[verse.ayahKey]!.dx - (nodeWidth / 2),
                      top: _positions[verse.ayahKey]!.dy - 60,
                      child: _VerseCanvasNode(
                        verse: verse,
                        isDark: isDark,
                        onTap: () => _focusAyahNode(verse),
                        onPanUpdate: (delta) {
                          setState(() {
                            final current = _positions[verse.ayahKey]!;
                            _positions[verse.ayahKey] = current + delta;
                          });
                        },
                        onPanEnd: () => _persistManualPositions(),
                      ),
                    ),

                // Note Nodes
                for (final note in widget.link.notes)
                  if (_positions.containsKey(note.noteKey))
                    Positioned(
                      left: _positions[note.noteKey]!.dx - (nodeWidth / 2),
                      top: _positions[note.noteKey]!.dy - 50,
                      child: _NoteCanvasNode(
                        note: note,
                        isDark: isDark,
                        onTap: () => _focusNoteNode(note),
                        onPanUpdate: (delta) {
                          setState(() {
                            final current = _positions[note.noteKey]!;
                            _positions[note.noteKey] = current + delta;
                          });
                        },
                        onPanEnd: () => _persistManualPositions(),
                      ),
                    ),
              ],
            ),
          ),
        ),

        // Empty state overlay if no verses and no notes yet
        if (verses.isEmpty && widget.link.notes.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hub_outlined,
                    size: 48,
                    color: AppColors.olive,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noAyahsAddedToLink,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.addAyahsToBuildMap,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onAddVerse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.addAyah),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// رسام خطوط الشبكة لربط العقدة المركزية بالعقد الفرعية بمنحنيات بيزييه ناعمة.
class _NetworkConnectionsPainter extends CustomPainter {
  final Offset center;
  final Map<String, Offset> positions;
  final bool isDark;

  /// ينشئ رسام خطوط الشبكة.
  const _NetworkConnectionsPainter({
    required this.center,
    required this.positions,
    required this.isDark,
  });

  /// يرسم المسارات المنحنية ونقاط الارتباط على لوحة الشبكة.
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? AppColors.oliveSoft : AppColors.olive).withValues(
        alpha: 0.45,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final dotPaint = Paint()
      ..color = (isDark ? AppColors.oliveSoft : AppColors.olive).withValues(
        alpha: 0.8,
      )
      ..style = PaintingStyle.fill;

    for (final pos in positions.values) {
      // Subtle smooth curve toward center
      final path = Path();
      path.moveTo(center.dx, center.dy);

      final controlX = (center.dx + pos.dx) / 2;
      final controlY = (center.dy + pos.dy) / 2;

      path.quadraticBezierTo(controlX, controlY, pos.dx, pos.dy);
      canvas.drawPath(path, linePaint);

      // Decorative mini junction dot
      canvas.drawCircle(pos, 3.5, dotPaint);
    }
  }

  /// يحدد ما إذا كان يجب إعادة رسم الخطوط عند تغير المواضع أو السمة.
  @override
  bool shouldRepaint(covariant _NetworkConnectionsPainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.isDark != isDark;
  }
}

/// العقدة المركزية التي تمثل عنوان ومحور رابط الآيات.
///
/// Central Node representing the overall Ayah Link theme/title.
class _CenterThemeNode extends StatelessWidget {
  final String title;
  final String? description;
  final int versesCount;
  final bool isDark;

  /// ينشئ العقدة المركزية لرابط الآيات.
  const _CenterThemeNode({
    required this.title,
    this.description,
    required this.versesCount,
    required this.isDark,
  });

  /// يبني بطاقة العقدة المركزية مع عنوان الرابط وعدد الآيات المرتبطة.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hub_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.l10n.isArabic
                  ? '$versesCount آيات مرتبطة'
                  : '$versesCount linked verses',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: isDark
                      ? AppColors.nightSubtitle
                      : AppColors.daySubtitle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// عقدة آية تفاعلية قابلة للسحب والضغط داخل لوحة الشبكة.
///
/// Interactive Verse Node on the Canvas with draggable gestures.
class _VerseCanvasNode extends StatelessWidget {
  final AyahLinkVerse verse;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  /// ينشئ عقدة آية تفاعلية على لوحة الشبكة.
  const _VerseCanvasNode({
    required this.verse,
    required this.isDark,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// يبني بطاقة عقدة الآية مع مقتطف النص وملاحظة التدبر.
  @override
  Widget build(BuildContext context) {
    final surah = QuranRepository.instance.getSurah(verse.surahNumber);
    final ayah = QuranRepository.instance.getAyah(
      verse.surahNumber,
      verse.ayahNumber,
    );
    final effectiveNote = verse.getEffectiveNote();
    final hasNote = effectiveNote != null && effectiveNote.isNotEmpty;
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (_) => onPanEnd(),
      child: Container(
        width: nodeWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasNote
                ? AppColors.olive
                : (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder),
            width: hasNote ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.isArabic
                        ? '${surah.name} · ${ArabicSearchNormalizer.toArabicDigits(verse.ayahNumber)}'
                        : '${surah.name} · ${verse.ayahNumber}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.olive,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasNote)
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: AppColors.olive,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Full verse text
            if (ayah != null)
              Text(
                '﴿ ${ayah.text} ﴾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: fontSize * 0.78,
                  height: 1.6,
                  color: isDark
                      ? AppColors.nightQuranText
                      : AppColors.dayQuranText,
                ),
              ),

            // Note snippet under verse (if present, compact otherwise)
            if (hasNote) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 13,
                    color: isDark ? AppColors.oliveSoft : AppColors.olive,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.isArabic ? 'ملاحظتي' : 'My note',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.oliveSoft : AppColors.olive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                effectiveNote,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: isDark
                      ? AppColors.nightSubtitle
                      : AppColors.daySubtitle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// عقدة كرت ملاحظة تفاعلية قابلة للسحب والضغط داخل لوحة الشبكة.
class _NoteCanvasNode extends StatelessWidget {
  final AyahLinkNote note;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  /// ينشئ عقدة كرت ملاحظة تفاعلية على لوحة الشبكة.
  const _NoteCanvasNode({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// يبني واجهة عقدة كرت الملاحظة على لوحة الشبكة.
  @override
  Widget build(BuildContext context) {
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (_) => onPanEnd(),
      child: Container(
        width: nodeWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node Header
            Row(
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasTitle
                        ? note.title!.trim()
                        : (context.l10n.isArabic
                            ? 'كرت ملاحظة تدبرية'
                            : 'Reflection Note'),
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: AppColors.border(context)),
            const SizedBox(height: 6),

            // Note Content
            Text(
              note.content,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark
                    ? AppColors.nightSubtitle
                    : AppColors.daySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// دوال مساعدة لتحريك وتكبير مصفوفة التحويل ثنائية الأبعاد.
extension on Matrix4 {
  /// يطبق إزاحة ثنائية الأبعاد على مصفوفة التحويل.
  void translate2D(double x, double y) {
    translateByDouble(x, y, 0.0, 1.0);
  }

  /// يطبق تكبيراً متماثلاً ثنائي الأبعاد على مصفوفة التحويل.
  void scale2D(double s) {
    scaleByDouble(s, s, 1.0, 1.0);
  }
}
