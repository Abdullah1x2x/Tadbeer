import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import '../widgets/ayah_action_sheet.dart';
import '../widgets/surah_header_banner.dart';

/// Gesture recognizer specifically designed for inline Quranic Ayahs.
///
/// Subclasses [LongPressGestureRecognizer] so that Flutter's semantics / accessibility
/// engine recognizes it natively, while simultaneously supporting both quick taps
/// and sustained 700ms long-presses without gesture conflicts.
/// متعرف إيماءات مخصص للآيات القرآنية المدمجة يدعم النقر السريع والضغط المطول معاً.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onPointerDown;
  VoidCallback? onPointerUpEarly;
  VoidCallback? onTap;

  /// ينشئ متعرف إيماءات مخصص للتفاعل مع الآية القرآنية.
  AyahGestureRecognizer({
    this.onPointerDown,
    this.onPointerUpEarly,
    this.onTap,
    VoidCallback? onLongPress,
    super.duration = const Duration(milliseconds: 1100),
    super.debugOwner,
  }) {
    this.onLongPress = onLongPress;
  }

  bool _longPressFired = false;

  /// يسجل تجاوز المهلة الزمنية لتفعيل إيماءة الضغط المطول.
  @override
  void didExceedDeadline() {
    _longPressFired = true;
    super.didExceedDeadline();
  }

  /// يعالج أحداث المؤشر الأساسي للتمييز بين النقر السريع والضغط المطول.
  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      _longPressFired = false;
      onPointerDown?.call();
    } else if (event is PointerUpEvent) {
      if (!_longPressFired) {
        onPointerUpEarly?.call();
        resolve(GestureDisposition.accepted);
        onTap?.call();
        return;
      }
    } else if (event is PointerCancelEvent) {
      if (!_longPressFired) {
        onPointerUpEarly?.call();
      }
    }
    super.handlePrimaryPointer(event);
  }
}

/// Helper model representing consecutive Ayahs from the same Surah on a given page.
/// نموذج مساعد يمثل مجموعة آيات متتالية تنتمي لسورة واحدة داخل الصفحة.
class _SurahPageBlock {
  final int surahNumber;
  final bool isStartOfSurah;
  final List<Ayah> ayahs;

  /// ينشئ كتلة آيات متتالية لسورة واحدة في الصفحة.
  const _SurahPageBlock({
    required this.surahNumber,
    required this.isStartOfSurah,
    required this.ayahs,
  });
}

/// Responsive Medina Mushaf Page Reader (1..604).
///
/// Renders authentic Uthmani text with natural, responsive typography using
/// the user's selected open-source Quran font.
///
/// Key Architectural Guarantees:
/// 1. Authentic Tanzil Uthmani text with 100% intact diacritics, pauses, and stops.
/// 2. Natural RTL Arabic text flow with authentic Ayah end rosettes ﴿#﴾.
/// 3. Zero RenderFlex overflow on all device sizes (phones, foldables, tablets, landscape).
/// 4. Dynamic Quran font scaling driven by UserSettings with live reactivity.
/// 5. Full support for highlights, bookmarks, notes, tadbeer, and ayah action sheet.
/// عارض صفحة المصحف المدني المتجاوب (للصفحات من ١ إلى ٦٠٤) بالرسم العثماني الأصيل.
class QuranPageView extends StatefulWidget {
  final QuranPage? page;
  final int? pageNumber;
  final double? fontSize;
  final Ayah? selectedAyah;
  final ValueChanged<Ayah>? onAyahTap;
  final ValueChanged<Ayah>? onAyahLongPress;
  final ValueChanged<Ayah>? onAyahHighlight;
  final ValueChanged<Ayah>? onAyahHighlightClear;
  final bool showHeader;
  final bool showFooter;

  /// ينشئ ودجت عرض صفحة من صفحات المصحف الشريف.
  const QuranPageView({
    super.key,
    this.page,
    this.pageNumber,
    this.fontSize,
    this.selectedAyah,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onAyahHighlight,
    this.onAyahHighlightClear,
    this.showHeader = true,
    this.showFooter = true,
  }) : assert(
         page != null || pageNumber != null,
         'Either page or pageNumber must be provided',
       );

  /// ينشئ الحالة التفاعلية لعارض صفحة المصحف.
  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

/// الحالة التفاعلية لودجت عرض صفحة المصحف الشريف.
class _QuranPageViewState extends State<QuranPageView> {
  final Map<int, AyahGestureRecognizer> _recognizers = {};

  /// يحرر موارد متعرفات الإيماءات عند إزالة الودجت.
  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  /// يتخلص من جميع متعرفات الإيماءات المخزنة وينظف القائمة.
  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// يعيد متعرف إيماءات الآية المحددة أو ينشئ واحداً جديداً عند الحاجة.
  AyahGestureRecognizer _getOrCreateRecognizer(Ayah ayah) {
    if (_recognizers.containsKey(ayah.id)) {
      return _recognizers[ayah.id]!;
    }

    final recognizer = AyahGestureRecognizer(
      duration: const Duration(milliseconds: 1100),
      onPointerDown: () {
        widget.onAyahHighlight?.call(ayah);
      },
      onPointerUpEarly: () {
        widget.onAyahHighlightClear?.call(ayah);
      },
      onTap: () {
        widget.onAyahTap?.call(ayah);
      },
      onLongPress: () {
        if (widget.onAyahLongPress != null) {
          widget.onAyahLongPress!(ayah);
        } else {
          AyahActionSheet.show(context, ayah);
        }
      },
    );

    _recognizers[ayah.id] = recognizer;
    return recognizer;
  }

  /// يجمع آيات الصفحة المتتالية في كتل مستقلة بحسب السورة.
  List<_SurahPageBlock> _groupAyahsBySurah(List<Ayah> ayahs) {
    if (ayahs.isEmpty) return const [];
    final blocks = <_SurahPageBlock>[];

    int currentSurah = ayahs.first.surahNumber;
    var currentList = <Ayah>[ayahs.first];

    for (int i = 1; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      if (ayah.surahNumber == currentSurah) {
        currentList.add(ayah);
      } else {
        blocks.add(
          _SurahPageBlock(
            surahNumber: currentSurah,
            isStartOfSurah: currentList.first.ayahNumber == 1,
            ayahs: currentList,
          ),
        );
        currentSurah = ayah.surahNumber;
        currentList = [ayah];
      }
    }

    blocks.add(
      _SurahPageBlock(
        surahNumber: currentSurah,
        isStartOfSurah: currentList.first.ayahNumber == 1,
        ayahs: currentList,
      ),
    );

    return blocks;
  }

  /// يبني واجهة صفحة المصحف بما يشمل الترويسة والنص القرآني والتذييل.
  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final pageNumber = widget.page?.pageNumber ?? widget.pageNumber!;
    final quranPage = widget.page ?? repo.getPage(pageNumber);

    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final storage = UserDataStore.instance;
        final effectiveFontSize =
            widget.fontSize ?? storage.settings.quranFontSize;

        final isOpeningPage = pageNumber <= 2;
        final firstSurahNumber = quranPage.surahNumbers.isNotEmpty
            ? quranPage.surahNumbers.first
            : (quranPage.ayahs.isNotEmpty
                ? quranPage.ayahs.first.surahNumber
                : 1);
        final surah = repo.getSurah(firstSurahNumber);
        final surahBlocks = _groupAyahsBySurah(quranPage.ayahs);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.mushafBackground,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                      : AppColors.lightBorder,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(6),
                color: isDark ? AppColors.darkSurface : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top Page Header (Surah name & Juz number)
                            if (widget.showHeader)
                              _buildPageHeader(
                                context,
                                surah: surah,
                                juzNumber: quranPage.juzNumber,
                                isDark: isDark,
                              )
                            else
                              const SizedBox(height: 4),

                            const SizedBox(height: 6),

                            // 2. Main Quranic Text Body
                            Expanded(
                              child: isOpeningPage
                                  ? _buildOpeningPageContent(
                                      context: context,
                                      blocks: surahBlocks,
                                      fontSize: effectiveFontSize,
                                      isDark: isDark,
                                      storage: storage,
                                    )
                                  : _buildStandardPageContent(
                                      context: context,
                                      blocks: surahBlocks,
                                      fontSize: effectiveFontSize,
                                      isDark: isDark,
                                      storage: storage,
                                    ),
                            ),

                            const SizedBox(height: 6),

                            // 3. Bottom Page Footer (Arabic page number)
                            if (widget.showFooter)
                              _buildPageFooter(
                                context,
                                pageNumber: pageNumber,
                                isDark: isDark,
                              )
                            else
                              const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// يبني ترويسة الصفحة العلوية التي تعرض اسم السورة ورقم الجزء.
  Widget _buildPageHeader(
    BuildContext context, {
    required Surah surah,
    required int juzNumber,
    required bool isDark,
  }) {
    final headerColor = isDark
        ? AppColors.nightSubtitle
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'سُورَةُ ${surah.name}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
          Text(
            'الجزء ${ArabicSearchNormalizer.toArabicDigits(juzNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
        ],
      ),
    );
  }

  /// يبني تذييل الصفحة السفلي الذي يعرض رقم الصفحة بالأرقام العربية.
  Widget _buildPageFooter(
    BuildContext context, {
    required int pageNumber,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Center(
        child: Text(
          ArabicSearchNormalizer.toArabicDigits(pageNumber),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.nightSubtitle
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  /// يبني محتوى الصفحتين الافتتاحيتين (الفاتحة وأول البقرة) بتصميم مؤطر ومتمركز.
  Widget _buildOpeningPageContent({
    required BuildContext context,
    required List<_SurahPageBlock> blocks,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
  }) {
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: goldColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface)
              .withValues(alpha: 0.35),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final block in blocks) ...[
              if (block.isStartOfSurah) ...[
                SurahHeaderBanner(
                  surah: QuranRepository.instance.getSurah(block.surahNumber),
                ),
                const SizedBox(height: 4),
                if (block.surahNumber != 1 && block.surahNumber != 9) ...[
                  const BismillahBanner(),
                  const SizedBox(height: 6),
                ],
              ],
              _buildAyahsParagraph(
                context: context,
                ayahs: block.ayahs,
                fontSize: fontSize,
                isDark: isDark,
                storage: storage,
                isCentered: true,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// يبني محتوى صفحات المصحف القياسية مع ترويسات السور والبسملة والآيات المتصلة.
  Widget _buildStandardPageContent({
    required BuildContext context,
    required List<_SurahPageBlock> blocks,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks) ...[
          if (block.isStartOfSurah) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SurahHeaderBanner(
                surah: QuranRepository.instance.getSurah(block.surahNumber),
              ),
            ),
            if (block.surahNumber != 1 && block.surahNumber != 9) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: BismillahBanner(),
              ),
            ],
          ],
          _buildAyahsParagraph(
            context: context,
            ayahs: block.ayahs,
            fontSize: fontSize,
            isDark: isDark,
            storage: storage,
            isCentered: false,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  static final RegExp _standaloneWaqfRegex = RegExp(r' ([\u06D6-\u06DB]) ');

  /// ينسق نص الآية بربط علامات الوقف بالكلمة السابقة لمنع انفصالها في بداية السطر.
  static String _formatAyahText(String text) {
    return text.replaceAllMapped(
      _standaloneWaqfRegex,
      (m) => '\u00A0\u00A0${m.group(1)} ',
    );
  }

  /// يبني فقرة الآيات القرآنية المتصلة مع فواصل الآيات والتظليل وشارات العلامات والملاحظات.
  Widget _buildAyahsParagraph({
    required BuildContext context,
    required List<Ayah> ayahs,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
    required bool isCentered,
  }) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.mushafQuranText;
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final fontFamily = storage.settings.quranFontFamilyName;

    int currentOffset = 0;
    final ranges = <_AyahHighlightRange>[];
    final spanChildren = <InlineSpan>[];
    final placeholderDimensions = <PlaceholderDimensions>[];

    for (final ayah in ayahs) {
      final isSelected = widget.selectedAyah?.id == ayah.id;
      final highlight = storage.getHighlight(ayah.surahNumber, ayah.ayahNumber);
      final isBookmarked = storage.isBookmarked(
        ayah.surahNumber,
        ayah.ayahNumber,
      );
      final hasNote = storage
          .getNotesForAyah(ayah.surahNumber, ayah.ayahNumber)
          .isNotEmpty;
      final hasIndicators = isBookmarked || hasNote;

      final ayahText = _formatAyahText(ayah.text);
      final rosetteText =
          '\u00A0﴿${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}﴾';
      const trailingSpace = ' ';

      final startOffset = currentOffset;
      final endOffset = currentOffset + ayahText.length + rosetteText.length;

      if (isSelected || highlight != null) {
        Color color;
        if (isSelected) {
          color = AppColors.selectedAyah(context);
        } else {
          final baseColor = AppColors.highlightColors[highlight!.colorIndex];
          color = isDark
              ? baseColor.withValues(alpha: 0.40)
              : baseColor.withValues(alpha: 0.32);
        }

        ranges.add(
          _AyahHighlightRange(
            startOffset: startOffset,
            endOffset: endOffset,
            color: color,
            isSelected: isSelected,
          ),
        );
      }

      currentOffset =
          endOffset + (hasIndicators ? 1 : 0) + trailingSpace.length;
      final recognizer = _getOrCreateRecognizer(ayah);

      spanChildren.add(
        TextSpan(
          text: ayahText,
          recognizer: recognizer,
          style: TextStyle(
            color: textColor,
          ),
        ),
      );
      spanChildren.add(
        TextSpan(
          text: rosetteText,
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontWeight: FontWeight.bold,
            fontSize: fontSize * 0.94,
            color: isSelected
                ? (isDark
                    ? AppColors.darkAccentGold
                    : AppColors.oliveDark)
                : goldColor,
          ),
        ),
      );

      if (hasIndicators) {
        final iconSize = (fontSize * 0.62).clamp(13.0, 20.0);
        final iconCount = (isBookmarked ? 1 : 0) + (hasNote ? 1 : 0);
        final badgeWidth =
            4.0 + 12.0 + (iconCount * iconSize) + (iconCount > 1 ? 4.0 : 0.0);
        final badgeHeight = (iconSize + 6.0).clamp(18.0, 26.0);

        placeholderDimensions.add(
          PlaceholderDimensions(
            size: Size(badgeWidth, badgeHeight),
            alignment: ui.PlaceholderAlignment.middle,
          ),
        );

        spanChildren.add(
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.middle,
            child: SizedBox(
              width: badgeWidth,
              height: badgeHeight,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onAyahLongPress != null) {
                      widget.onAyahLongPress!(ayah);
                    } else {
                      AyahActionSheet.show(context, ayah);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccentGold.withValues(alpha: 0.16)
                          : AppColors.lightPrimary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: (isDark
                                ? AppColors.darkAccentGold
                                : AppColors.lightAccentGold)
                            .withValues(alpha: isDark ? 0.45 : 0.55),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBookmarked)
                              Icon(
                                Icons.bookmark_rounded,
                                size: iconSize,
                                color: isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.lightPrimary,
                              ),
                            if (isBookmarked && hasNote)
                              const SizedBox(width: 3.0),
                            if (hasNote)
                              Icon(
                                Icons.edit_note_rounded,
                                size: iconSize,
                                color: isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.lightAccentGold,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      spanChildren.add(
        const TextSpan(
          text: trailingSpace,
        ),
      );
    }

    final rootSpan = TextSpan(
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.95,
        color: textColor,
      ),
      children: spanChildren,
    );

    final textWidget = Text.rich(
      rootSpan,
      textAlign: isCentered ? TextAlign.center : TextAlign.justify,
      textDirection: TextDirection.rtl,
    );

    if (ranges.isEmpty) {
      return textWidget;
    }

    return CustomPaint(
      painter: _AyahHighlightPainter(
        textSpan: rootSpan,
        textAlign: isCentered ? TextAlign.center : TextAlign.justify,
        textDirection: TextDirection.rtl,
        textScaler: MediaQuery.textScalerOf(context),
        ranges: ranges,
        placeholderDimensions: placeholderDimensions,
        isDark: isDark,
      ),
      child: textWidget,
    );
  }
}

/// Model capturing character offsets and color styling for an Ayah highlight.
/// نموذج يحدد نطاق الحروف ولون التظليل الخاص بالآية داخل الفقرة النصية.
class _AyahHighlightRange {
  final int startOffset;
  final int endOffset;
  final Color color;
  final bool isSelected;

  /// ينشئ نطاق تظليل لآية محددة.
  const _AyahHighlightRange({
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.isSelected,
  });
}

/// Custom painter that draws neatly calibrated, rounded highlight ribbons
/// behind Ayah text runs with immaculate line-by-line wrapping and padding.
/// رسام مخصص يرسم أشرطة التظليل المستديرة خلف نص الآيات بدقة سطراً بسطر.
class _AyahHighlightPainter extends CustomPainter {
  final TextSpan textSpan;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final List<_AyahHighlightRange> ranges;
  final List<PlaceholderDimensions> placeholderDimensions;
  final bool isDark;

  /// ينشئ رسام تظليل الآيات القرآنية.
  _AyahHighlightPainter({
    required this.textSpan,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.ranges,
    this.placeholderDimensions = const [],
    required this.isDark,
  });

  /// يرسم مستطيلات التظليل الخلفية للآيات المحددة أو المظللة على لوحة الرسم.
  @override
  void paint(Canvas canvas, Size size) {
    if (ranges.isEmpty || size.width <= 0) return;

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    if (placeholderDimensions.isNotEmpty) {
      textPainter.setPlaceholderDimensions(placeholderDimensions);
    }
    textPainter.layout(maxWidth: size.width);

    for (final range in ranges) {
      if (range.startOffset >= range.endOffset) continue;

      final boxes = textPainter.getBoxesForSelection(
        TextSelection(
          baseOffset: range.startOffset,
          extentOffset: range.endOffset,
        ),
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.tight,
      );

      final lineRects = _mergeTextBoxes(boxes, size.width);
      if (lineRects.isEmpty) continue;

      final fillPaint = Paint()
        ..color = range.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      Paint? borderPaint;
      if (range.isSelected) {
        borderPaint = Paint()
          ..color = (isDark ? AppColors.darkAccentGold : AppColors.oliveDark)
              .withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..isAntiAlias = true;
      }

      for (final rect in lineRects) {
        final vInset = (rect.height * 0.05).clamp(1.0, 2.0);
        // AmiriQuran has a tall ascender-to-descent metric (~3:1 ratio), causing
        // raw selection bounds to sit higher than the visual text center.
        // A ~11% downward shift perfectly centers the highlight ribbon over the
        // baseline, tashkeel, and descenders.
        final vShift = rect.height * 0.11;
        const hPadding = 2.0;

        final adjustedRect = Rect.fromLTRB(
          (rect.left - hPadding).clamp(0.0, size.width),
          rect.top + vInset + vShift,
          (rect.right + hPadding).clamp(0.0, size.width),
          rect.bottom - vInset + vShift,
        );

        if (adjustedRect.width <= 1.0 || adjustedRect.height <= 1.0) continue;

        final rrect = RRect.fromRectAndRadius(
          adjustedRect,
          const Radius.circular(5.0),
        );

        canvas.drawRRect(rrect, fillPaint);
        if (borderPaint != null) {
          canvas.drawRRect(rrect, borderPaint);
        }
      }
    }
  }

  /// يدمج صناديق التحديد النصية المتجاورة في السطر الواحد لتكوين شريط تظليل متصل.
  List<Rect> _mergeTextBoxes(List<TextBox> boxes, double maxWidth) {
    if (boxes.isEmpty) return const [];

    final lineGroups = <List<Rect>>[];

    for (final box in boxes) {
      var rect = box.toRect();
      rect = Rect.fromLTRB(
        rect.left.clamp(0.0, maxWidth),
        rect.top,
        rect.right.clamp(0.0, maxWidth),
        rect.bottom,
      );
      if (rect.width <= 0.1 || rect.height <= 0.1) continue;

      bool foundLine = false;
      for (final group in lineGroups) {
        final sample = group.first;
        final vOverlap =
            math.min(sample.bottom, rect.bottom) - math.max(sample.top, rect.top);
        if (vOverlap > (sample.height * 0.45)) {
          group.add(rect);
          foundLine = true;
          break;
        }
      }

      if (!foundLine) {
        lineGroups.add([rect]);
      }
    }

    final mergedLines = <Rect>[];
    for (final group in lineGroups) {
      final minLeft = group.map((r) => r.left).reduce(math.min);
      final maxRight = group.map((r) => r.right).reduce(math.max);
      final minTop = group.map((r) => r.top).reduce(math.min);
      final maxBottom = group.map((r) => r.bottom).reduce(math.max);

      if (maxRight > minLeft) {
        mergedLines.add(Rect.fromLTRB(minLeft, minTop, maxRight, maxBottom));
      }
    }

    mergedLines.sort((a, b) => a.top.compareTo(b.top));
    return mergedLines;
  }

  /// يحدد ما إذا كان يلزم إعادة رسم التظليل عند تغير النطاقات أو إعدادات العرض.
  @override
  bool shouldRepaint(covariant _AyahHighlightPainter oldDelegate) {
    if (oldDelegate.ranges.length != ranges.length ||
        oldDelegate.placeholderDimensions.length !=
            placeholderDimensions.length ||
        oldDelegate.isDark != isDark ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.textScaler != textScaler) {
      return true;
    }
    for (int i = 0; i < ranges.length; i++) {
      if (ranges[i].startOffset != oldDelegate.ranges[i].startOffset ||
          ranges[i].endOffset != oldDelegate.ranges[i].endOffset ||
          ranges[i].color != oldDelegate.ranges[i].color ||
          ranges[i].isSelected != oldDelegate.ranges[i].isSelected) {
        return true;
      }
    }
    return false;
  }
}

/// Backward compatibility alias for QuranPageView
/// اسم بديل متوافق مع الإصدارات السابقة لودجت عرض صفحة المصحف.
typedef QuranPageWidget = QuranPageView;
