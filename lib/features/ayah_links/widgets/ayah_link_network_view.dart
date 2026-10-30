import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/ayah_link_model.dart';
import '../data/ayah_link_repository.dart';
import 'ayah_link_edit_dialogs.dart';
import '../../../data/quran/quran_repository.dart';
import '../../quran/screens/quran_screen.dart';
import '../../../core/design_system/app_icons.dart';

part 'ayah_link_network_nodes.dart';

/// شبكة الرابط: عقدة المحور في المركز والآيات حولها.
///
/// ترتيب دائري تلقائي لا تتداخل فيه العقد، وسحب يدوي يُحفظ، وتحريك وتكبير
/// بـ[InteractiveViewer]، وتركيز سلس على الآية المنقورة مع لوحة تفاصيلها.
class AyahLinkNetworkView extends StatefulWidget {
  final AyahLinkItem link;

  /// عند الضغط على زر إضافة آية.
  final VoidCallback onAddVerse;

  const AyahLinkNetworkView({
    super.key,
    required this.link,
    required this.onAddVerse,
  });

  @override
  State<AyahLinkNetworkView> createState() => AyahLinkNetworkViewState();
}

class AyahLinkNetworkViewState extends State<AyahLinkNetworkView>
    with SingleTickerProviderStateMixin {
  static const double _canvasSize = 3000.0;
  static const double _centerCoord = _canvasSize / 2; // 1500.0

  late TransformationController _transformController;
  late AnimationController _animController;
  Animation<Matrix4>? _matrixAnimation;

  // مواضع محلية تتحدث فوراً أثناء السحب.
  final Map<String, Offset> _positions = {};

  final AyahLinkRepository _repo = AyahLinkRepository();

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

  /// يعيد مزامنة المواضع حين تتغير الآيات أو الترتيب.
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

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// يأخذ المواضع المحفوظة، أو يحسب الترتيب التلقائي.
  void _syncPositionsFromLink() {
    final existing = widget.link.positions;
    final verses = widget.link.verses;
    final notes = widget.link.notes;

    if (!widget.link.isManualLayout || existing.isEmpty) {
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
      // العناصر الجديدة بلا موضع محفوظ تأخذ موضعاً تلقائياً.
      _assignMissingPositions(verses, notes);
    }
  }

  /// مواضع دائرية حول المركز في حلقات متحدة المركز، ونصف القطر يتبع حجم الخط
  /// فلا تتداخل البطاقات.
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
      // حلقات متحدة المركز بحد أدنى للمسافة الزاوية.
      int assigned = 0;
      int ringIndex = 0;

      while (assigned < count) {
        final radius = (280.0 + (ringIndex * 210.0)) * scaleRatio;
        // كم عقدة تتسع براحة على هذا المحيط.
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

  /// يعطي موضعاً افتراضياً لكل آية أو خاطرة جديدة بلا موضع محفوظ.
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

  /// يستعيد الإزاحة والتكبير المحفوظين، أو يوسّط اللوحة.
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
      _centerViewport(size, animate: false);
    }
  }

  /// يوسّط اللوحة في مساحة العرض.
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

  /// يحرّك الكاميرا بسلاسة إلى [target].
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

  void _onMatrixAnim() {
    if (_matrixAnimation != null) {
      _transformController.value = _matrixAnimation!.value;
    }
  }

  /// يعيد الكاميرا إلى العقدة المركزية بحركة سلسة، ويحفظ الحالة.
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

  /// يعيد ترتيب العقد تلقائياً حول المركز، ويحفظ المواضع.
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
          content: Text(context.l10n.linksReordered),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// يقرّب الكاميرا من عقدة الآية، ثم يفتح لوحة تفاصيلها.
  void _focusAyahNode(AyahLinkVerse verse) {
    final pos = _positions[verse.ayahKey];
    if (pos == null) return;

    final viewportSize = MediaQuery.of(context).size;
    const focusScale = 1.15;

    // المركز فوق منتصف الشاشة قليلاً، لتتسع اللوحة السفلية.
    final targetCenterY = viewportSize.height * 0.42;

    final targetX = (viewportSize.width / 2) - (pos.dx * focusScale);
    final targetY = targetCenterY - (pos.dy * focusScale);

    final targetMatrix = Matrix4.identity()
      ..translate2D(targetX, targetY)
      ..scale2D(focusScale);

    _animateToMatrix(targetMatrix);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _showVerseInspectorSheet(verse);
      }
    });
  }

  /// لوحة الآية: نصها الكامل وخاطرتها والإجراءات.
  void _showVerseInspectorSheet(AyahLinkVerse verse) {
    final surah = QuranRepository.instance.getSurah(verse.surahNumber);
    final ayah = QuranRepository.instance.getAyah(
      verse.surahNumber,
      verse.ayahNumber,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showInspectorSheet(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.ayahReference(surah.name, verse.ayahNumber),
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.olive,
            ),
          ),
          Text(
            context.l10n.pageAbbr(verse.page),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ayah != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.comsilk,
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

          // الخاطرة: من الرابط، أو خاطرة القارئ، أو وقفة
          // التدبر.
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
                          Icon(AppIcons.note, size: 16, color: AppColors.olive),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.reflectionNoteColon,
                            style: TextStyle(
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
      actions: (bottomSheetCtx) => Row(
        children: [
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
              icon: const Icon(AppIcons.bookOpenFill, size: 18),
              label: Text(
                context.l10n.openInQuran,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),

          IconButton.filledTonal(
            icon: const Icon(AppIcons.notePencil, size: 20),
            tooltip: context.l10n.reflectionNote,
            onPressed: () {
              Navigator.pop(bottomSheetCtx);
              editAyahLinkVerseNote(context, widget.link.id, verse);
            },
          ),
          const SizedBox(width: 6),

          IconButton.filledTonal(
            icon: const Icon(AppIcons.trash, size: 20, color: Colors.redAccent),
            tooltip: context.l10n.removeVerseFromLink,
            onPressed: () {
              Navigator.pop(bottomSheetCtx);
              confirmRemoveAyahLinkVerse(context, widget.link.id, verse);
            },
          ),
        ],
      ),
    );
  }

  /// يقرّب الكاميرا من بطاقة الخاطرة، ويعرض تفاصيلها.
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

  /// لوحة بطاقة الخاطرة: نصها الكامل والتعديل والنسخ والحذف.
  void _showNoteInspectorSheet(AyahLinkNote note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;

    _showInspectorSheet(
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              AppIcons.noteFill,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasTitle ? note.title!.trim() : (context.l10n.reflectionNoteCard),
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.comsilk,
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
      actions: (bottomSheetCtx) => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(bottomSheetCtx);
                Clipboard.setData(ClipboardData(text: note.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.noteCopiedToClipboard),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
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
              icon: const Icon(AppIcons.copy, size: 18),
              label: Text(
                context.l10n.copyText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),

          IconButton.filledTonal(
            icon: const Icon(AppIcons.notePencil, size: 20),
            tooltip: context.l10n.editVerseNote,
            onPressed: () {
              Navigator.pop(bottomSheetCtx);
              editAyahLinkNoteCard(context, widget.link.id, note);
            },
          ),
          const SizedBox(width: 6),

          IconButton.filledTonal(
            icon: const Icon(AppIcons.trash, size: 20, color: Colors.redAccent),
            tooltip: context.l10n.deleteNote,
            onPressed: () {
              Navigator.pop(bottomSheetCtx);
              confirmDeleteAyahLinkNoteCard(context, widget.link.id, note);
            },
          ),
        ],
      ),
    );
  }

  /// إطار لوحة تفاصيل العقدة: مقبض، ورأس، ومحتوى يُمرَّر، وصف أزرار.
  ///
  /// [actions] تأخذ سياق اللوحة لتغلقها.
  void _showInspectorSheet({
    required Widget header,
    required Widget body,
    required Widget Function(BuildContext sheetContext) actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => Directionality(
        textDirection: context.currentLanguage.direction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  header,
                  const SizedBox(height: 12),
                  Flexible(child: SingleChildScrollView(child: body)),
                  const SizedBox(height: 12),
                  actions(bottomSheetCtx),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// يحفظ المواضع بعد انتهاء السحب.
  void _persistManualPositions() {
    final map = <String, LinkNodePosition>{};
    for (final entry in _positions.entries) {
      map[entry.key] = LinkNodePosition(dx: entry.value.dx, dy: entry.value.dy);
    }
    _repo.updatePositions(widget.link.id, map, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verses = widget.link.verses;
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          minScale: 0.25,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(500),
          onInteractionEnd: (details) {
            // يحفظ الإزاحة والتكبير.
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
                CustomPaint(
                  size: const Size(_canvasSize, _canvasSize),
                  painter: _NetworkConnectionsPainter(
                    center: const Offset(_centerCoord, _centerCoord),
                    positions: _positions,
                    isDark: isDark,
                  ),
                ),

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

        // حالة فارغة حين لا آيات ولا خواطر.
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
                  Icon(AppIcons.graph, size: 48, color: AppColors.olive),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noAyahsAddedToLink,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                    icon: const Icon(AppIcons.plus, size: 18),
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

/// إزاحة وتكبير ثنائيا الأبعاد لمصفوفة التحويل.
extension on Matrix4 {
  void translate2D(double x, double y) {
    translateByDouble(x, y, 0.0, 1.0);
  }

  void scale2D(double s) {
    scaleByDouble(s, s, 1.0, 1.0);
  }
}
