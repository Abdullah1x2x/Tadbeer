import 'dart:async';
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
import '../../../app/localization.dart';

part 'quran_page_parts.dart';

/// يميّز النقر من الضغط المطوّل على آية داخل نص الصفحة، دون أن يتعارض مع سحب
/// الصفحات.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onPointerDown;
  VoidCallback? onPointerUpEarly;
  VoidCallback? onTap;

  /// مهلة تأخير إبراز الآية لتفادي وميض التظليل أثناء السحب أو النقر السريع.
  final Duration highlightDelay;

  Timer? _highlightTimer;
  bool _highlightShown = false;
  bool _longPressFired = false;

  /// [duration] مهلة الضغط المطوّل؛ الافتراضي 1100 مللي ثانية.
  AyahGestureRecognizer({
    this.onPointerDown,
    this.onPointerUpEarly,
    this.onTap,
    VoidCallback? onLongPress,
    super.duration = const Duration(milliseconds: 1100),
    this.highlightDelay = const Duration(milliseconds: 180),
    super.debugOwner,
  }) {
    this.onLongPress = onLongPress;
  }

  @override
  void didExceedDeadline() {
    _longPressFired = true;
    super.didExceedDeadline();
  }

  void _cancelHighlightTimer() {
    _highlightTimer?.cancel();
    _highlightTimer = null;
  }

  /// يميّز النقر السريع من الضغط المطوّل.
  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      _longPressFired = false;
      _highlightShown = false;
      _cancelHighlightTimer();
      _highlightTimer = Timer(highlightDelay, () {
        if (!_longPressFired) {
          _highlightShown = true;
          onPointerDown?.call();
        }
      });
    } else if (event is PointerUpEvent) {
      _cancelHighlightTimer();
      if (!_longPressFired) {
        if (_highlightShown) {
          _highlightShown = false;
          onPointerUpEarly?.call();
        }
        resolve(GestureDisposition.accepted);
        onTap?.call();
        return;
      }
    } else if (event is PointerCancelEvent) {
      _cancelHighlightTimer();
      if (!_longPressFired && _highlightShown) {
        _highlightShown = false;
        onPointerUpEarly?.call();
      }
    }
    super.handlePrimaryPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    _cancelHighlightTimer();
    if (_highlightShown) {
      _highlightShown = false;
      onPointerUpEarly?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void dispose() {
    _cancelHighlightTimer();
    super.dispose();
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
    final memorized = HifzStore.ids();
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
                                                    semanticLabel:
                                                        context.l10n.scrollDown,
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

  static final RegExp _standaloneWaqfRegex = RegExp(r' ([\u06D6-\u06DB]) ');

  /// يربط علامات الوقف بالكلمة قبلها، فلا تنفصل إلى بداية سطر.
  static String _formatAyahText(String text) {
    return text.replaceAllMapped(
      _standaloneWaqfRegex,
      (m) => '\u00A0\u00A0${m.group(1)} ',
    );
  }
}
