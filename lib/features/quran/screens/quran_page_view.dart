import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../memorization/memorization_model.dart';
import '../widgets/ayah_rosette.dart';
import '../widgets/mushaf_frame_painter.dart';
import '../widgets/surah_header_banner.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../data/models/user_settings_model.dart';
import '../qcf/qcf_page_body.dart';

/// يميّز النقر من الضغط المطوّل على آية داخل نص الصفحة، دون أن يتعارض مع سحب
/// الصفحات.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onPointerDown;
  VoidCallback? onPointerUpEarly;
  VoidCallback? onTap;

  /// [duration] مهلة الضغط المطوّل؛ الافتراضي 1100 مللي ثانية.
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

  @override
  void didExceedDeadline() {
    _longPressFired = true;
    super.didExceedDeadline();
  }

  /// يميّز النقر السريع من الضغط المطوّل.
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

/// آيات متتالية من سورة واحدة في الصفحة.
class _SurahPageBlock {
  final int surahNumber;
  final bool isStartOfSurah;
  final List<Ayah> ayahs;

  const _SurahPageBlock({
    required this.surahNumber,
    required this.isStartOfSurah,
    required this.ayahs,
  });
}

/// صفحة المصحف (١..٦٠٤): صفحات مصحف المدينة، أو النص العثماني المتدفق بخط
/// القارئ.
///
/// النص من مشروع تنزيل بتشكيله وعلامات وقفه كاملة، يتجاوب مع أي شاشة دون أن
/// يفيض، ويعرض التظليل والفواصل والخواطر والتدبر.
class QuranPageView extends StatefulWidget {
  final QuranPage? page;
  final int? pageNumber;
  final double? fontSize;
  final Ayah? selectedAyah;
  final ValueChanged<Ayah>? onAyahTap;

  /// الضغط المطوّل على آية، مع موضع الإصبع إن جاء منه (فقد ينزلق بعدها على
  /// الوردة التي تُفتح هناك).
  final void Function(Ayah ayah, {Offset? at})? onAyahLongPress;
  final ValueChanged<Ayah>? onAyahHighlight;
  final ValueChanged<Ayah>? onAyahHighlightClear;
  final bool showHeader;
  final bool showFooter;

  /// حجم النص المتدفق لصفحة بعرض [width]: نحو 21 كلمة متوسطة في السطر على
  /// الهاتف، ويكبر مع الشاشات الأعرض حتى حجم قراءة مريح. ومقياس النص في النظام
  /// يُطبّق فوقه.
  static double textSizeFor(double width) =>
      width.isFinite ? (width / 21).clamp(16.0, 28.0) : 20.0;

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

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  final Map<int, AyahGestureRecognizer> _recognizers = {};

  /// تمرير محتوى الصفحة رأسياً داخل الإطار.
  final ScrollController _scrollController = ScrollController();

  /// هل يظهر التدرج السفلي، لوجود نص تحت الشاشة.
  final ValueNotifier<bool> _showBottomGradient = ValueNotifier<bool>(false);

  /// هل يظهر سهم السحب للأسفل.
  final ValueNotifier<bool> _showScrollHint = ValueNotifier<bool>(false);

  /// ما تعرضه الصفحة من بيانات القارئ، كقيمة واحدة تُقارن.
  String? _signature;

  /// حفظ موضع القراءة وعدّ الصفحة يُعلمان المخزن مع كل تقليب؛ والصفحة لا تُعاد
  /// بناؤها إلا إن تغيّر شيء تعرضه (الإعدادات، أو علامة على إحدى آياتها).
  void _onStoreChanged() {
    final next = _contentSignature();
    if (next != _signature && mounted) setState(() => _signature = next);
  }

  String _contentSignature() {
    final store = UserDataStore.instance;
    final s = store.settings;
    final pageNumber = widget.page?.pageNumber ?? widget.pageNumber!;
    final page = widget.page ?? QuranRepository.instance.getPage(pageNumber);
    final memorized = HifzStore.all().keys.toSet();
    final out = StringBuffer(
      '${s.quranFontSize}|${s.flowingTextScale}|${s.quranFontFamilyName}|${s.mushafPaperTone}|'
      '${s.mushafStyle}',
    );
    for (final a in page.ayahs) {
      final reflection = store.getTadbeer(a.surahNumber, a.ayahNumber);
      out
        ..write('|')
        ..write(store.getHighlight(a.surahNumber, a.ayahNumber)?.colorIndex)
        ..write(store.isBookmarked(a.surahNumber, a.ayahNumber) ? 'b' : '')
        ..write(store.getNotesForAyah(a.surahNumber, a.ayahNumber).length)
        ..write(reflection != null && !reflection.isEmpty ? 't' : '')
        ..write(
          memorized.contains('${a.surahNumber}:${a.ayahNumber}') ? 'h' : '',
        );
    }
    return out.toString();
  }

  @override
  void initState() {
    super.initState();
    _signature = _contentSignature();
    UserDataStore.instance.addListener(_onStoreChanged);
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollIndicators();
    });
  }

  /// يعود إلى أعلى الصفحة حين يتغير رقمها.
  @override
  void didUpdateWidget(covariant QuranPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPage = oldWidget.page?.pageNumber ?? oldWidget.pageNumber;
    final newPage = widget.page?.pageNumber ?? widget.pageNumber;
    if (oldPage != newPage) {
      _signature = _contentSignature();
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0.0);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollIndicators();
    });
  }

  @override
  void dispose() {
    UserDataStore.instance.removeListener(_onStoreChanged);
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    _showBottomGradient.dispose();
    _showScrollHint.dispose();
    _disposeRecognizers();
    super.dispose();
  }

  /// يحدّث ظهور التدرج والسهم بحسب موضع التمرير.
  void _updateScrollIndicators() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final offset = position.pixels;

    final canScroll = maxScroll > 3.0;
    final atBottom = offset >= (maxScroll - 4.0);

    final showIndicators = canScroll && !atBottom;

    if (_showBottomGradient.value != showIndicators) {
      _showBottomGradient.value = showIndicators;
    }
    if (_showScrollHint.value != showIndicators) {
      _showScrollHint.value = showIndicators;
    }
  }

  /// يمرّر خطوة للأسفل عند النقر على السهم.
  void _scrollDownOneStep() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = math.min(_scrollController.offset + 140.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// متعرّف الإيماءات للآية، يُنشأ عند الحاجة.
  AyahGestureRecognizer _getOrCreateRecognizer(Ayah ayah) {
    if (_recognizers.containsKey(ayah.id)) {
      return _recognizers[ayah.id]!;
    }

    final recognizer = AyahGestureRecognizer(
      // مدة الضغط المطوّل لخيارات الآية؛ والنقر على رقم الآية يفتحها فوراً.
      duration: const Duration(milliseconds: 500),
      onPointerDown: () {
        widget.onAyahHighlight?.call(ayah);
      },
      onPointerUpEarly: () {
        widget.onAyahHighlightClear?.call(ayah);
      },
      onTap: () {
        widget.onAyahTap?.call(ayah);
      },
    );
    // نفس الضغطة تستمر لتوجيه الوردة التي تُفتح تحتها.
    recognizer
      ..onLongPressStart = (details) {
        final at = details.globalPosition;
        if (widget.onAyahLongPress != null) {
          widget.onAyahLongPress!(ayah, at: at);
        } else {
          AyahRosette.show(context, ayah, at: at);
        }
      }
      ..onLongPressMoveUpdate = (details) {
        AyahRosette.dragTo(details.globalPosition);
      }
      ..onLongPressEnd = (details) {
        AyahRosette.releaseAt(details.globalPosition);
      };

    _recognizers[ayah.id] = recognizer;
    return recognizer;
  }

  /// يجمع آيات الصفحة في كتل بحسب السورة.
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

  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final pageNumber = widget.page?.pageNumber ?? widget.pageNumber!;
    final quranPage = widget.page ?? repo.getPage(pageNumber);

    // يعيد _onStoreChanged بناءها فقط حين يتغير محتوى هذه الصفحة.
    return LayoutBuilder(
      builder: (context, box) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final storage = UserDataStore.instance;
        // بحجم الشاشة، مكبّراً بقدر ما طلب القارئ؛ وصفحات المدينة تتجاهله وتتسع
        // للشاشة دائماً.
        final effectiveFontSize =
            widget.fontSize ??
            QuranPageView.textSizeFor(box.maxWidth) *
                storage.settings.flowingTextScale;
        final palette = MushafPalette.of(
          isDark: isDark,
          tone: storage.settings.mushafPaperTone,
        );

        final isOpeningPage = pageNumber <= 2;
        final firstSurahNumber = quranPage.surahNumbers.isNotEmpty
            ? quranPage.surahNumbers.first
            : (quranPage.ayahs.isNotEmpty
                  ? quranPage.ayahs.first.surahNumber
                  : 1);
        final surah = repo.getSurah(firstSurahNumber);
        final surahBlocks = _groupAyahsBySurah(quranPage.ayahs);

        final marginStamps = MarginStampData.forPage(quranPage);
        final useQcf = storage.settings.mushafStyle == MushafStyle.madinah;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: palette.outer,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? palette.page : null,
                    ),
                    child: CustomPaint(
                      painter: MushafPageFramePainter(
                        isDark: isDark,
                        palette: palette,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 7.0,
                        ),
                        child: useQcf
                            ? _buildQcfPage(
                                context,
                                pageNumber: pageNumber,
                                surah: surah,
                                juzNumber: quranPage.juzNumber,
                                marginStamps: marginStamps,
                                isDark: isDark,
                                palette: palette,
                                storage: storage,
                                fontSize: effectiveFontSize,
                                fallback: SingleChildScrollView(
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
                              )
                            : Stack(
                                children: [
                                  NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification
                                              is ScrollUpdateNotification ||
                                          notification
                                              is OverscrollNotification ||
                                          notification
                                              is UserScrollNotification) {
                                        _updateScrollIndicators();
                                      }
                                      return false;
                                    },
                                    child: RawScrollbar(
                                      controller: _scrollController,
                                      thumbColor:
                                          (isDark
                                                  ? AppColors.darkAccentGold
                                                  : AppColors.lightAccentGold)
                                              .withValues(alpha: 0.65),
                                      radius: const Radius.circular(3),
                                      thickness: 2.5,
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 1.0,
                                        top: 4.0,
                                        bottom: 4.0,
                                      ),
                                      child: SingleChildScrollView(
                                        controller: _scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: math.max(
                                              0.0,
                                              constraints.maxHeight - 22.0,
                                            ),
                                          ),
                                          child: IntrinsicHeight(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // ١. الترويسة: اسم السورة ورقم
                                                // الجزء.
                                                if (widget.showHeader)
                                                  _buildPageHeader(
                                                    context,
                                                    surah: surah,
                                                    juzNumber:
                                                        quranPage.juzNumber,
                                                    isDark: isDark,
                                                    palette: palette,
                                                    marginStamps: marginStamps,
                                                  )
                                                else
                                                  const SizedBox(height: 4),

                                                const SizedBox(height: 4),

                                                // ٢. النص القرآني.
                                                Expanded(
                                                  child: isOpeningPage
                                                      ? _buildOpeningPageContent(
                                                          context: context,
                                                          blocks: surahBlocks,
                                                          fontSize:
                                                              effectiveFontSize,
                                                          isDark: isDark,
                                                          storage: storage,
                                                        )
                                                      : _buildStandardPageContent(
                                                          context: context,
                                                          blocks: surahBlocks,
                                                          fontSize:
                                                              effectiveFontSize,
                                                          isDark: isDark,
                                                          storage: storage,
                                                        ),
                                                ),

                                                const SizedBox(height: 4),

                                                // ٣. التذييل: رقم الصفحة.
                                                if (widget.showFooter)
                                                  _buildPageFooter(
                                                    context,
                                                    pageNumber: pageNumber,
                                                    isDark: isDark,
                                                    palette: palette,
                                                  )
                                                else
                                                  const SizedBox(height: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // التدرج السفلي الخافت.
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    height: 36,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _showBottomGradient,
                                      builder: (context, show, _) {
                                        final pageBg = palette.page;
                                        return IgnorePointer(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: show ? 1.0 : 0.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            builder: (context, opacity, child) {
                                              if (opacity <= 0.001) {
                                                return const SizedBox.shrink();
                                              }
                                              return Opacity(
                                                opacity: opacity,
                                                child: child,
                                              );
                                            },
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    pageBg.withValues(
                                                      alpha: 0.0,
                                                    ),
                                                    pageBg.withValues(
                                                      alpha: 0.65,
                                                    ),
                                                    pageBg.withValues(
                                                      alpha: 0.95,
                                                    ),
                                                  ],
                                                  stops: const [0.0, 0.55, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // سهم السحب الصغير.
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 3,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _showScrollHint,
                                      builder: (context, show, _) {
                                        return IgnorePointer(
                                          ignoring: !show,
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: show ? 1.0 : 0.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            builder: (context, opacity, child) {
                                              if (opacity <= 0.001) {
                                                return const SizedBox.shrink();
                                              }
                                              return Opacity(
                                                opacity: opacity,
                                                child: child,
                                              );
                                            },
                                            child: Center(
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: _scrollDownOneStep,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 1.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: palette.page
                                                        .withValues(
                                                          alpha: 0.92,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          (isDark
                                                                  ? AppColors
                                                                        .darkAccentGold
                                                                  : AppColors
                                                                        .lightAccentGold)
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                      width: 0.8,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.35
                                                                  : 0.08,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    AppIcons.caretDown,
                                                    size: 16,
                                                    color: isDark
                                                        ? AppColors
                                                              .darkAccentGold
                                                        : AppColors.oliveDark,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// صفحة مصحف المدينة: الترويسة والأسطر المطبوعة والتذييل.
  Widget _buildQcfPage(
    BuildContext context, {
    required int pageNumber,
    required Surah surah,
    required int juzNumber,
    required List<MarginStampData> marginStamps,
    required bool isDark,
    required MushafPalette palette,
    required UserDataStore storage,
    required double fontSize,
    required Widget fallback,
  }) {
    final memorized = HifzStore.all().keys.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          _buildPageHeader(
            context,
            surah: surah,
            juzNumber: juzNumber,
            isDark: isDark,
            palette: palette,
            marginStamps: marginStamps,
          )
        else
          const SizedBox(height: 4),
        const SizedBox(height: 4),
        Expanded(
          child: QcfPageBody(
            pageNumber: pageNumber,
            // الصفحة المطبوعة تتسع للشاشة وحدها؛ ولا يكبّرها إلا حجم صريح (في
            // الاختبارات).
            zoom: widget.fontSize == null
                ? 1
                : fontSize / UserSettings.defaultQuranFontSize,
            textColor: palette.text,
            markerColor: isDark
                ? AppColors.darkAccentGold
                : AppColors.lightAccentGold,
            backgroundFor: (s, a) {
              final selected = widget.selectedAyah;
              if (selected != null &&
                  selected.surahNumber == s &&
                  selected.ayahNumber == a) {
                return isDark
                    ? AppColors.darkSelectedAyah
                    : const Color(0x36B89745);
              }
              final highlight = storage.getHighlight(s, a);
              if (highlight == null) return null;
              final base = AppColors.highlightColors[highlight.colorIndex];
              return base.withValues(alpha: isDark ? 0.35 : 0.25);
            },
            isMarked: (s, a) {
              final reflection = storage.getTadbeer(s, a);
              return storage.isBookmarked(s, a) ||
                  storage.getNotesForAyah(s, a).isNotEmpty ||
                  (reflection != null && !reflection.isEmpty) ||
                  memorized.contains('$s:$a');
            },
            recognizerFor: _getOrCreateRecognizer,
            fallback: fallback,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.showFooter)
          _buildPageFooter(
            context,
            pageNumber: pageNumber,
            isDark: isDark,
            palette: palette,
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  /// الترويسة: اسم السورة ورقم الجزء وعلامات الهامش إن وُجدت.
  Widget _buildPageHeader(
    BuildContext context, {
    required Surah surah,
    required int juzNumber,
    required bool isDark,
    required MushafPalette palette,
    List<MarginStampData> marginStamps = const [],
  }) {
    final frameColor = palette.frame;
    final headerColor = isDark ? AppColors.darkTextPrimary : palette.frame;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: frameColor.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 0.75,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '❖ ',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: frameColor.withValues(alpha: 0.8),
                  ),
                ),
                Flexible(
                  child: Text(
                    'سُورَةُ ${surah.name}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (marginStamps.isNotEmpty) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: marginStamps
                  .map(
                    (stamp) => MarginStampMedallion(
                      stamp: stamp,
                      isDark: isDark,
                      palette: palette,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 4),
          ] else
            const SizedBox(width: 4),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'الجزء ${ArabicSearchNormalizer.toArabicDigits(juzNumber)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  ' ❖',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: frameColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// التذييل: رقم الصفحة بالأرقام العربية.
  Widget _buildPageFooter(
    BuildContext context, {
    required int pageNumber,
    required bool isDark,
    required MushafPalette palette,
  }) {
    final frameColor = palette.frame;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: frameColor.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 0.75,
          ),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: frameColor.withValues(alpha: isDark ? 0.45 : 0.55),
              width: 0.7,
            ),
            color:
                (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface)
                    .withValues(alpha: 0.35),
          ),
          child: Text(
            ArabicSearchNormalizer.toArabicDigits(pageNumber),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightPrimary,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  /// الصفحتان الافتتاحيتان (الفاتحة وأول البقرة) متمركزتين داخل إطار المصحف.
  Widget _buildOpeningPageContent({
    required BuildContext context,
    required List<_SurahPageBlock> blocks,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
  }) {
    return Center(
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
    );
  }

  /// الصفحات العادية: ترويسات السور والبسملة والآيات المتصلة.
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

  /// يربط علامات الوقف بالكلمة قبلها، فلا تنفصل إلى بداية سطر.
  static String _formatAyahText(String text) {
    return text.replaceAllMapped(
      _standaloneWaqfRegex,
      (m) => '\u00A0\u00A0${m.group(1)} ',
    );
  }

  /// فقرة الآيات المتصلة: أرقامها وتظليلها وشارات الفواصل والخواطر.
  Widget _buildAyahsParagraph({
    required BuildContext context,
    required List<Ayah> ayahs,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
    required bool isCentered,
  }) {
    final textColor = MushafPalette.of(
      isDark: isDark,
      tone: storage.settings.mushafPaperTone,
    ).text;
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final fontFamily = storage.settings.quranFontFamilyName;

    final spanChildren = <InlineSpan>[];
    // تُقرأ مرة للصفحة، وتُفحص لكل آية أدناه.
    final memorized = HifzStore.all().keys.toSet();

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
      final reflection = storage.getTadbeer(ayah.surahNumber, ayah.ayahNumber);
      final hasReflection = reflection != null && !reflection.isEmpty;
      final inHifz = memorized.contains(
        '${ayah.surahNumber}:${ayah.ayahNumber}',
      );
      final markerColor = isDark
          ? AppColors.darkAccentGold
          : AppColors.lightAccentGold;
      final markers = <(IconData, Color)>[
        if (isBookmarked)
          (
            AppIcons.bookmarkSimpleFill,
            isDark ? AppColors.darkAccentGold : AppColors.lightPrimary,
          ),
        if (hasNote) (AppIcons.notePencil, markerColor),
        if (hasReflection) (AppIcons.flowerLotusFill, markerColor),
        if (inHifz) (AppIcons.brainFill, AppColors.statusSuccess),
      ];
      final hasIndicators = markers.isNotEmpty;

      final ayahText = _formatAyahText(ayah.text);
      final rosetteText =
          '\u00A0﴿${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}﴾';
      const trailingSpace = ' ';

      Color? highlightColor;
      if (isSelected) {
        highlightColor = isDark
            ? AppColors.darkSelectedAyah
            : const Color(0x36B89745);
      } else if (highlight != null) {
        final baseColor = AppColors.highlightColors[highlight.colorIndex];
        highlightColor = isDark
            ? baseColor.withValues(alpha: 0.35)
            : baseColor.withValues(alpha: 0.25);
      }

      final recognizer = _getOrCreateRecognizer(ayah);

      spanChildren.add(
        TextSpan(
          text: ayahText,
          recognizer: recognizer,
          style: TextStyle(color: textColor, backgroundColor: highlightColor),
        ),
      );
      spanChildren.add(
        TextSpan(
          text: rosetteText,
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            height: 1.95,
            backgroundColor: highlightColor,
            color: isSelected
                ? (isDark ? const Color(0xFFDFCA94) : const Color(0xFF7A5C1E))
                : goldColor,
          ),
        ),
      );

      if (hasIndicators) {
        final iconSize = (fontSize * 0.62).clamp(13.0, 20.0);
        final iconCount = markers.length;
        final badgeWidth =
            4.0 + 12.0 + (iconCount * iconSize) + (iconCount > 1 ? 4.0 : 0.0);
        final badgeHeight = (iconSize + 6.0).clamp(18.0, 26.0);

        spanChildren.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
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
                      AyahRosette.show(context, ayah);
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
                        color:
                            (isDark
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
                            for (var i = 0; i < markers.length; i++) ...[
                              if (i > 0) const SizedBox(width: 3.0),
                              Icon(
                                markers[i].$1,
                                size: iconSize,
                                color: markers[i].$2,
                              ),
                            ],
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

      spanChildren.add(const TextSpan(text: trailingSpace));
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

    return Text.rich(
      rootSpan,
      textAlign: isCentered ? TextAlign.center : TextAlign.justify,
      textDirection: TextDirection.rtl,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }
}

/// الاسم القديم، يبقى للتوافق.
typedef QuranPageWidget = QuranPageView;
