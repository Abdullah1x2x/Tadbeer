import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/motion/app_motion.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../widgets/ayah_rosette.dart';
import '../widgets/text_scale_control.dart';
import '../../audio/audio_bar.dart';
import '../../audio/quran_audio.dart';
import '../widgets/word_meanings_panel.dart';
import '../../focus/focus_mode_screen.dart';
import '../../search/search_screen.dart';
import 'quran_page_view.dart';
import '../widgets/quran_side_menu.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../core/design_system/app_icons.dart';
import '../../onboarding/tour/section_guide.dart';

part 'quran_screen_dialogs.dart';

/// شاشة المصحف (٦٠٤ صفحات) بأدوات التدبر والبحث والتنقل والتلاوة.
class QuranScreen extends StatefulWidget {
  final int? initialPage;
  final int? targetSurahNumber;
  final int? targetAyahNumber;

  /// حين يُعرض المصحف تبويباً، يعكس هنا ظهور أدواته ليخفي الهيكل الشريط السفلي
  /// أثناء القراءة؛ وnull حين يُفتح صفحة مستقلة.
  final ValueNotifier<bool>? controlsVisible;

  const QuranScreen({
    super.key,
    this.initialPage,
    this.targetSurahNumber,
    this.targetAyahNumber,
    this.controlsVisible,
  });

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;
  late int _currentPageIndex;
  Ayah? _activeSelectedAyah;
  bool _showTopBar = false;
  bool _showMeaningsPanel = false;
  bool _suppressNextPageTap = false;
  Timer? _suppressTimer;

  /// تُحسب الصفحة مقروءة حين يتقدم القارئ بعدها وقد بقي عليها هذه المدة على
  /// الأقل؛ التصفح السريع والرجوع لا يُحسبان.
  static const _readDwell = Duration(seconds: 3);
  DateTime _pageShownAt = DateTime.now();

  /// وتُحسب أيضاً إن بقيت على الشاشة هذه المدة، فتُحسب آخر صفحة في الجلسة دون
  /// تقليبها.
  static const _autoCountDwell = Duration(seconds: 40);

  /// آخر صفحة قصيرة ولا صفحة بعدها يُتقدّم إليها، فتُحسب بانتظار أقصر.
  static const _lastPageDwell = Duration(seconds: 15);

  /// ما يُنتظر بعد آخر تقليب قبل الحفظ.
  static const _settleDelay = Duration(milliseconds: 500);

  /// الصفحة المعروضة على شريط التمرير أثناء سحبه.
  int? _sliderPage;
  Timer? _autoCountTimer;
  Timer? _saveTimer;
  final List<int> _pagesToCount = [];
  int? _pageToPersist;

  /// حروف المصحف ثقيلة الرسم، فتُرسم مرة في صورة تتحرّك أثناء السحب.
  final _pageSnapshots = SnapshotController();
  ScrollPosition? _pagerPosition;

  /// شجرة الصفحات محفوظة، فتغيّر رقم الصفحة لا يعيد بناءها أثناء السحب.
  Widget? _pager;
  int? _pagerSelectedAyah;
  bool? _pagerIsDark;

  /// يُضبط قبل انتقال لم يقم به القارئ (كمزامنة التبويب)، فلا يُحسب ولا يُحفظ
  /// ثانية.
  bool _ignoreNextPageChange = false;

  /// آخر موضع قراءة تبعه المصحف، لتمييز تغيّر الموضع من غيره.
  int? _lastSavedPage;

  /// آخر آية رُئيت عليها التلاوة، لتتبعها صفحة بصفحة.
  int? _audioAyahId;

  /// يقيس الشريط السفلي، ليقع شريط التلاوة فوقه مباشرة.
  final _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 120;

  /// يقرأ ارتفاع الشريط السفلي بعد رصفه.
  void _measureBottomBar(Duration _) {
    if (!mounted) return;
    final height = _bottomBarKey.currentContext?.size?.height;
    if (height != null && height != _bottomBarHeight) {
      setState(() => _bottomBarHeight = height);
    }
  }

  /// لا يتحرك موضع القراءة (ومعه الختمة) إلا بقراءة فعلية: التقدم بعد قراءة
  /// الصفحة، أو البقاء عليها. النظرة ونتيجة البحث وقفزة الشريط لا تحرّك شيئاً.
  void _maybeCountPage(int fromIndex, int toIndex) {
    if (toIndex != fromIndex + 1) return;
    if (DateTime.now().difference(_pageShownAt) < _readDwell) return;
    _pagesToCount.add(fromIndex + 1);
    _pageToPersist = toIndex + 1;
  }

  /// الحفظ يكتب ملف القارئ كله، فينتظر حتى تستقر الصفحة ولا يقطع حركة التقليب.
  void _saveAfterSettling() {
    _saveTimer?.cancel();
    if (_pagesToCount.isEmpty) return;
    _saveTimer = Timer(_settleDelay, _saveCountedPages);
  }

  Future<void> _saveCountedPages() async {
    final pages = List.of(_pagesToCount);
    final next = _pageToPersist;
    _pagesToCount.clear();
    _pageToPersist = null;
    // يُحسب أولاً، فتكتمل الختمة بقراءة صفحتها الأخيرة.
    for (final page in pages) {
      await _recordPage(page);
    }
    if (next != null) _persistCurrentPagePosition(next);
  }

  /// يحسب الصفحة مقروءة، ويهنّئ القارئ إن أتمّت ختمته.
  Future<void> _recordPage(int page) async {
    final store = UserDataStore.instance;
    final before = store.journey.completedKhatmas;
    await store.recordPageRead(page);
    final completed = store.journey.completedKhatmas;
    if (completed == before || !mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.completedKhatmas(completed),
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// يعيد بدء الانتظار الذي تُحسب بعده الصفحة المعروضة مقروءة.
  void _startAutoCount() {
    _autoCountTimer?.cancel();
    final page = _currentPageIndex + 1;
    final dwell = page == 604 ? _lastPageDwell : _autoCountDwell;
    _autoCountTimer = Timer(dwell, () {
      // فقط حين يكون المصحف التبويب أو الصفحة الظاهرة.
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (_currentPageIndex + 1 == page) {
        _recordPage(page).then((_) => _persistCurrentPagePosition(page));
      }
    });
  }

  /// يحدد صفحة البداية والآية المستهدفة.
  @override
  void initState() {
    super.initState();
    final repo = QuranRepository.instance;
    final saved = UserDataStore.instance.readingPosition;

    int startPage = widget.initialPage ?? saved.page;
    if (widget.targetSurahNumber != null && widget.targetAyahNumber != null) {
      final targetAyah = repo.getAyah(
        widget.targetSurahNumber!,
        widget.targetAyahNumber!,
      );
      if (targetAyah != null) {
        startPage = targetAyah.page;
        _activeSelectedAyah = targetAyah;
      }
    }

    startPage = startPage.clamp(1, 604);
    _currentPageIndex = startPage - 1;
    _pageController = PageController(initialPage: _currentPageIndex);

    if (widget.controlsVisible != null) {
      // كتبويب: تبدأ الأدوات والشريط السفلي ظاهرة ليعرف القارئ كيف يخرج، ويتبع
      // تغيّر الموضع من قارئ فُتح في مكان آخر (من فاصل مثلاً).
      _showTopBar = true;
      widget.controlsVisible!.value = true;
      _lastSavedPage = UserDataStore.instance.readingPosition.page;
      UserDataStore.instance.addListener(_syncToSavedPosition);
    }

    _startAutoCount();
    QuranAudio.instance.addListener(_onAudio);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pagerPosition = _pageController.position;
      _pagerPosition!.isScrollingNotifier.addListener(_onPagerScrolling);
    });
  }

  void _onPagerScrolling() {
    _pageSnapshots.allowSnapshotting =
        _pagerPosition!.isScrollingNotifier.value;
  }

  /// يتبع التلاوة: يقلب إلى صفحة الآية المتلوّة (دون حسابها مقروءة)، ويقول إن
  /// تعذّر تشغيلها.
  void _onAudio() {
    if (!mounted) return;
    final audio = QuranAudio.instance;
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (audio.failed && visible) {
      audio.failed = false;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.l10n.audioFailed, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    final ayah = audio.current;
    if (ayah != null && ayah.id != _audioAyahId) {
      _audioAyahId = ayah.id;
      if (visible &&
          ayah.page - 1 != _currentPageIndex &&
          _pageController.hasClients) {
        _ignoreNextPageChange = true;
        _pageController.animateToPage(
          ayah.page - 1,
          duration: AppMotion.normal,
          curve: AppMotion.emphasized,
        );
      }
    }
    if (ayah == null) _audioAyahId = null;
    setState(() {});
    _measureSoon();
  }

  /// يبدأ قياس الشريط السفلي حين تحتاجه التلاوة.
  void _measureSoon() =>
      WidgetsBinding.instance.addPostFrameCallback(_measureBottomBar);

  /// يبدأ التلاوة من الآية المختارة أو أول الصفحة، أو يوقفها مؤقتاً.
  void _toggleListening(int pageNumber) {
    final audio = QuranAudio.instance;
    if (audio.active) {
      audio.toggle();
      return;
    }
    final page = QuranRepository.instance.getPage(pageNumber);
    if (page.ayahs.isEmpty) return;
    audio.playFrom(_activeSelectedAyah ?? page.ayahs.first);
  }

  @override
  void dispose() {
    if (widget.controlsVisible != null) {
      UserDataStore.instance.removeListener(_syncToSavedPosition);
    }
    QuranAudio.instance.removeListener(_onAudio);
    _suppressTimer?.cancel();
    _autoCountTimer?.cancel();
    _saveTimer?.cancel();
    if (_pagesToCount.isNotEmpty) _saveCountedPages();
    _pagerPosition?.isScrollingNotifier.removeListener(_onPagerScrolling);
    _pageSnapshots.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// ينقل مصحف التبويب إلى الموضع المحفوظ حين يحرّكه قارئ آخر.
  void _syncToSavedPosition() {
    final page = UserDataStore.instance.readingPosition.page.clamp(1, 604);
    // المخزن يُعلم بكل تغيير؛ وحفظ القارئ أو الإعدادات لا يحرّك الصفحة.
    if (page == _lastSavedPage) return;
    _lastSavedPage = page;
    if (page - 1 != _currentPageIndex && _pageController.hasClients) {
      _ignoreNextPageChange = true;
      _pageController.jumpToPage(page - 1);
    }
  }

  /// عند تقليب الصفحة: يحدّث رقمها ويحفظ الموضع.
  void _onPageChanged(int index) {
    if (index < 0 || index >= 604) return;
    final from = _currentPageIndex;
    final programmatic = _ignoreNextPageChange;
    _ignoreNextPageChange = false;
    setState(() {
      _currentPageIndex = index;
      _activeSelectedAyah = null;
    });
    _startAutoCount();
    if (programmatic) {
      _pageShownAt = DateTime.now();
      _saveAfterSettling();
      return;
    }
    _maybeCountPage(from, index);
    _pageShownAt = DateTime.now();
    _saveAfterSettling();
  }

  /// يحفظ موضع القراءة: الصفحة والسورة والآية.
  void _persistCurrentPagePosition(int pageNumber) {
    final repo = QuranRepository.instance;
    final page = repo.getPage(pageNumber);
    if (page.ayahs.isNotEmpty) {
      final firstAyah = page.ayahs.first;
      // حفظ هذا القارئ لا يحرّكه: ربما تقدّم صفحة أخرى منذ بدأ الانتظار.
      _lastSavedPage = pageNumber;
      UserDataStore.instance.saveReadingPosition(
        page: pageNumber,
        surahNumber: firstAyah.surahNumber,
        ayahNumber: firstAyah.ayahNumber,
      );
    }
  }

  /// ينتقل إلى الصفحة [mushafPage] (١..٦٠٤).
  void _jumpToMushafPage(int mushafPage) {
    final target = mushafPage.clamp(1, 604);
    _pageController.jumpToPage(target - 1);
  }

  /// ينتقل إلى صفحة الآية ويميّزها.
  void _jumpToAyah(Ayah ayah) {
    _pageController.jumpToPage(ayah.page - 1);
    setState(() {
      _activeSelectedAyah = ayah;
    });
  }

  /// يبرز الآية لحظة لمسها.
  void _handleAyahHighlight(Ayah ayah) {
    setState(() {
      _activeSelectedAyah = ayah;
    });
  }

  /// يزيل الإبراز إن رُفع الإصبع مبكراً.
  void _handleAyahHighlightClear(Ayah ayah) {
    if (_activeSelectedAyah?.id == ayah.id) {
      setState(() {
        _activeSelectedAyah = null;
      });
    }
  }

  /// النقر على الآية: يلغي التحديد، أو يُظهر الأدوات ويخفيها.
  void _handleAyahTap(Ayah ayah) {
    if (_activeSelectedAyah != null) {
      setState(() {
        _activeSelectedAyah = null;
      });
    }
    _suppressNextPageTap = false;
    _toggleTopBar();
  }

  /// الضغط المطوّل: يفتح الوردة الثمانية عند الإصبع مع اهتزاز خفيف.
  Future<void> _handleAyahLongPress(Ayah ayah, {Offset? at}) async {
    _suppressNextPageTap = true;
    setState(() {
      _activeSelectedAyah = ayah;
    });

    HapticFeedback.mediumImpact();

    await AyahRosette.show(context, ayah, at: at);

    if (mounted) {
      setState(() {
        _activeSelectedAyah = null;
      });
      _suppressTimer?.cancel();
      _suppressTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _suppressNextPageTap = false;
      });
    }
  }

  /// يفتح البحث، وينتقل إلى الآية المختارة عند العودة.
  Future<void> _openSearch() async {
    final selectedAyah = await Navigator.of(context).push<Ayah>(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(returnToCaller: true),
      ),
    );
    if (selectedAyah != null && mounted) {
      _jumpToAyah(selectedAyah);
    }
  }

  /// النقر على الصفحة يُظهر الأدوات أو يخفيها.
  void _toggleTopBar() {
    if (_suppressNextPageTap) {
      _suppressNextPageTap = false;
      return;
    }
    // إن كانت آية محددة، يُلغى التحديد دون تبديل الأدوات.
    if (_activeSelectedAyah != null) {
      setState(() {
        _activeSelectedAyah = null;
      });
      return;
    }
    setState(() {
      _showTopBar = !_showTopBar;
    });
    widget.controlsVisible?.value = _showTopBar;
  }

  /// الشريط العلوي: القائمة، والاستماع، ووضع التأمل، والبحث، والمعاني، وطريقة
  /// العرض.
  Widget _buildTopBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.8),
            width: AppTokens.borderRegular,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FuturisticIconButton(
            icon: AppIcons.list,
            tooltip: 'القائمة',
            size: 38,
            iconSize: 20,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الاستماع من الآية المختارة، أو أول الصفحة.
              ListenableBuilder(
                listenable: QuranAudio.instance,
                builder: (context, _) {
                  final audio = QuranAudio.instance;
                  return FuturisticIconButton(
                    icon: audio.playing
                        ? AppIcons.pauseFill
                        : (audio.active
                              ? AppIcons.headphonesFill
                              : AppIcons.headphones),
                    tooltip: audio.playing ? l10n.pauseAudio : l10n.listen,
                    size: 38,
                    iconSize: 20,
                    iconColor: audio.active ? primary : null,
                    onTap: () => _toggleListening(currentPageNumber),
                  );
                },
              ),
              const SizedBox(width: 8),
              // وضع التأمل: آية واحدة في كل مرة.
              FuturisticIconButton(
                icon: AppIcons.personSimpleTaiChi,
                tooltip: l10n.focusMode,
                size: 38,
                iconSize: 20,
                onTap: () {
                  final page = QuranRepository.instance.getPage(
                    currentPageNumber,
                  );
                  if (page.ayahs.isEmpty) return;
                  FocusModeScreen.open(
                    context,
                    _activeSelectedAyah ?? page.ayahs.first,
                  );
                },
              ),
              const SizedBox(width: 8),
              FuturisticIconButton(
                icon: AppIcons.magnifyingGlass,
                tooltip: l10n.search,
                size: 38,
                iconSize: 20,
                onTap: _openSearch,
              ),
              const SizedBox(width: 8),
              FuturisticIconButton(
                icon: _showMeaningsPanel
                    ? AppIcons.bookOpenTextFill
                    : AppIcons.bookOpenText,
                tooltip: 'معاني كلمات الصفحة',
                size: 38,
                iconSize: 20,
                iconColor: _showMeaningsPanel
                    ? (isDark ? AppColors.cyberEmerald : primary)
                    : null,
                onTap: () {
                  setState(() {
                    _showMeaningsPanel = !_showMeaningsPanel;
                  });
                },
              ),
              const SizedBox(width: 8),
              // طريقة عرض المصحف (Aa)؛ والحجم تلقائي.
              FuturisticIconButton(
                icon: AppIcons.textAa,
                tooltip: l10n.mushafStyleTitle,
                size: 38,
                iconSize: 20,
                onTap: _showFontSizeDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// الشريط السفلي: السورة والجزء، والانتقال بين الصفحات.
  Widget _buildBottomBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
    // أثناء السحب يُظهر الشريط الصفحة المقصودة، ويقفز المصحف إليها عند رفع
    // الإصبع.
    final sliderPage = _sliderPage ?? currentPageNumber;
    final pageDigits = ArabicSearchNormalizer.toArabicDigits(sliderPage);
    final pageData = repo.getPage(currentPageNumber);
    final firstAyah = pageData.ayahs.isNotEmpty ? pageData.ayahs.first : null;
    final surahName = firstAyah != null
        ? repo.getSurah(firstAyah.surahNumber).name
        : '';
    final juzNumber = firstAyah?.juz ?? 1;
    final juzDigits = ArabicSearchNormalizer.toArabicDigits(juzNumber);
    final meaningsCount = repo.getWordMeaningsForPage(currentPageNumber).length;
    final meaningsDigits = ArabicSearchNormalizer.toArabicDigits(meaningsCount);
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: AppTokens.borderRegular,
            ),
            boxShadow: AppTokens.cardShadow(isDark: isDark, glowColor: primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // السورة والجزء، وشارة المعاني، وشارة الصفحة.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      surahName.isNotEmpty
                          ? '$surahName • الجزء $juzDigits'
                          : 'الجزء $juzDigits',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showMeaningsPanel = !_showMeaningsPanel;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: FuturisticBadge(
                      label: 'المعاني ($meaningsDigits)',
                      icon: AppIcons.books,
                      color: _showMeaningsPanel
                          ? (isDark ? AppColors.cyberEmerald : primary)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // الصفحة الحالية (تفتح حوار الانتقال).
                  InkWell(
                    onTap: _showJumpToPageDialog,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: FuturisticBadge(
                      label: 'ص $pageDigits من ٦٠٤',
                      color: isDark
                          ? AppColors.electricGold
                          : AppColors.lightPrimary,
                      showDot: true,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // الصفحة السابقة، والشريط، والتالية.
              Row(
                children: [
                  // السابقة: في RTL يشير لليمين نحو الصفحات الأولى.
                  FuturisticIconButton(
                    icon: AppIcons.caretRight,
                    tooltip: 'الصفحة السابقة',
                    size: 36,
                    iconSize: 22,
                    isEnabled: currentPageNumber > 1,
                    onTap: () => _jumpToMushafPage(currentPageNumber - 1),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: isDark
                            ? AppColors.cyberEmerald
                            : AppColors.lightPrimary,
                        inactiveTrackColor:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.5),
                        thumbColor: isDark
                            ? AppColors.cyberEmerald
                            : AppColors.lightPrimary,
                      ),
                      child: Slider(
                        value: sliderPage.toDouble().clamp(1.0, 604.0),
                        min: 1.0,
                        max: 604.0,
                        divisions: 603,
                        label: 'ص $pageDigits',
                        onChanged: (val) =>
                            setState(() => _sliderPage = val.round()),
                        onChangeEnd: (val) {
                          setState(() => _sliderPage = null);
                          final targetPage = val.round();
                          if (targetPage != currentPageNumber) {
                            _jumpToMushafPage(targetPage);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // التالية: في RTL يشير لليسار نحو الصفحات اللاحقة.
                  FuturisticIconButton(
                    icon: AppIcons.caretLeft,
                    tooltip: 'الصفحة التالية',
                    size: 36,
                    iconSize: 22,
                    isEnabled: currentPageNumber < 604,
                    onTap: () => _jumpToMushafPage(currentPageNumber + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// صفحات المصحف، ولا تُبنى من جديد إلا إن تغيّرت الآية المحددة أو السطوع.
  Widget _pagerFor(bool isDark) {
    final selected = (_activeSelectedAyah ?? QuranAudio.instance.current)?.id;
    if (_pager == null ||
        selected != _pagerSelectedAyah ||
        isDark != _pagerIsDark) {
      _pagerSelectedAyah = selected;
      _pagerIsDark = isDark;
      _pager = _buildPager(isDark);
    }
    return _pager!;
  }

  Widget _buildPager(bool isDark) {
    final repo = QuranRepository.instance;
    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleTopBar,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideSpread = constraints.maxWidth >= 900;
            return PageView.builder(
              controller: _pageController,
              // الصفحتان المجاورتان جاهزتان قبل أن يبدأ السحب.
              allowImplicitScrolling: true,
              itemCount: 604,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                if (!isWideSpread) {
                  final page = repo.getPage(pageNumber);
                  return RepaintBoundary(
                    child: SnapshotWidget(
                      controller: _pageSnapshots,
                      mode: SnapshotMode.permissive,
                      child: QuranPageView(
                        page: page,
                        pageNumber: pageNumber,
                        selectedAyah:
                            _activeSelectedAyah ?? QuranAudio.instance.current,
                        onAyahTap: _handleAyahTap,
                        onAyahLongPress: _handleAyahLongPress,
                        onAyahHighlight: _handleAyahHighlight,
                        onAyahHighlightClear: _handleAyahHighlightClear,
                      ),
                    ),
                  );
                }

                // صفحتان متجاورتان في الشاشات العريضة (900 بكسل
                // فأكثر).
                if (pageNumber == 1) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: QuranPageView(
                        page: repo.getPage(1),
                        pageNumber: 1,
                        selectedAyah:
                            _activeSelectedAyah ?? QuranAudio.instance.current,
                        onAyahTap: _handleAyahTap,
                        onAyahLongPress: _handleAyahLongPress,
                        onAyahHighlight: _handleAyahHighlight,
                        onAyahHighlightClear: _handleAyahHighlightClear,
                      ),
                    ),
                  );
                }

                final int rightPageNum;
                final int leftPageNum;
                if (pageNumber.isEven) {
                  leftPageNum = pageNumber;
                  rightPageNum = (pageNumber + 1).clamp(1, 604);
                } else {
                  rightPageNum = pageNumber;
                  leftPageNum = (pageNumber - 1).clamp(1, 604);
                }

                return Row(
                  children: [
                    Expanded(
                      child: QuranPageView(
                        page: repo.getPage(rightPageNum),
                        pageNumber: rightPageNum,
                        selectedAyah:
                            _activeSelectedAyah ?? QuranAudio.instance.current,
                        onAyahTap: _handleAyahTap,
                        onAyahLongPress: _handleAyahLongPress,
                        onAyahHighlight: _handleAyahHighlight,
                        onAyahHighlightClear: _handleAyahHighlightClear,
                      ),
                    ),
                    Container(
                      width: 1.0,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: QuranPageView(
                        page: repo.getPage(leftPageNum),
                        pageNumber: leftPageNum,
                        selectedAyah:
                            _activeSelectedAyah ?? QuranAudio.instance.current,
                        onAyahTap: _handleAyahTap,
                        onAyahLongPress: _handleAyahLongPress,
                        onAyahHighlight: _handleAyahHighlight,
                        onAyahHighlightClear: _handleAyahHighlightClear,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPageNumber = _currentPageIndex + 1;
    final shouldAnimate = AppMotion.shouldAnimate(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: QuranSideMenu(
          currentPage: currentPageNumber,
          onPageSelected: _jumpToMushafPage,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _pagerFor(isDark)),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: IgnorePointer(
                  ignoring: !_showTopBar,
                  child: AnimatedSlide(
                    offset: (_showTopBar || !shouldAnimate)
                        ? Offset.zero
                        : const Offset(0, -0.08),
                    duration: shouldAnimate ? AppMotion.normal : Duration.zero,
                    curve: AppMotion.emphasized,
                    child: AnimatedOpacity(
                      opacity: _showTopBar ? 1.0 : 0.0,
                      duration: shouldAnimate
                          ? AppMotion.normal
                          : Duration.zero,
                      curve: AppMotion.standard,
                      child: _buildTopBar(context, currentPageNumber),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: IgnorePointer(
                  ignoring: !_showTopBar,
                  child: AnimatedSlide(
                    offset: (_showTopBar || !shouldAnimate)
                        ? Offset.zero
                        : const Offset(0, 0.08),
                    duration: shouldAnimate ? AppMotion.normal : Duration.zero,
                    curve: AppMotion.emphasized,
                    child: AnimatedOpacity(
                      opacity: _showTopBar ? 1.0 : 0.0,
                      duration: shouldAnimate
                          ? AppMotion.normal
                          : Duration.zero,
                      curve: AppMotion.standard,
                      child: KeyedSubtree(
                        key: _bottomBarKey,
                        child: _buildBottomBar(context, currentPageNumber),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // شرح المصحف عند أول فتح.
            const Positioned(
              left: 0,
              top: 0,
              child: GuideAutoShow(topic: GuideTopic.mushaf),
            ),

            // التلاوة، فوق الشريط السفلي مباشرة حين يظهر.
            AnimatedPositioned(
              duration: shouldAnimate ? AppMotion.normal : Duration.zero,
              curve: AppMotion.emphasized,
              left: 12,
              right: 12,
              // مرفوع قليلاً عن الحافة؛ لا يلاصق أسفل الشاشة ولا الشريط.
              bottom:
                  MediaQuery.paddingOf(context).bottom +
                  (_showTopBar ? _bottomBarHeight + 16 : 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: const AudioBar(),
                ),
              ),
            ),

            // النقر خارج لوحة المعاني يُغلقها.
            if (_showMeaningsPanel)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _showMeaningsPanel = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  ),
                ),
              ),

            // لوحة المعاني في الأسفل.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: IgnorePointer(
                  ignoring: !_showMeaningsPanel,
                  child: AnimatedOpacity(
                    opacity: _showMeaningsPanel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: WordMeaningsPanel(
                          pageNumber: currentPageNumber,
                          isExpanded: _showMeaningsPanel,
                          onToggle: () {
                            setState(() {
                              _showMeaningsPanel = !_showMeaningsPanel;
                            });
                          },
                          onClose: () {
                            setState(() {
                              _showMeaningsPanel = false;
                            });
                          },
                          onDismiss: () {
                            setState(() {
                              _showMeaningsPanel = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
