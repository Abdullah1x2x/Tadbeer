import 'dart:async';
import 'dart:ui';

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
import '../../focus/focus_mode_screen.dart';
import '../../search/search_screen.dart';
import 'quran_page_view.dart';
import '../qcf/qcf_layout.dart';
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

  /// الصفحة الحالية من ٠؛ وفي العرض المزدوج أولى الصفحتين عادةً.
  late int _currentPageIndex;

  /// صفحتان متقابلتان في الشاشات العريضة، فعناصر [PageView] أزواج لا صفحات.
  bool _wide = false;
  bool _tickerEnabled = true;
  static const _spreadMinWidth = 900.0;

  /// عنصر [PageView] الذي يعرض [pageIndex].
  int _itemFor(int pageIndex) => _wide ? pageIndex ~/ 2 : pageIndex;

  /// صفحات العنصر [item]، مرقمة من ١.
  List<int> _pagesOf(int item) =>
      _wide ? [item * 2 + 1, item * 2 + 2] : [item + 1];

  int _pageOf(Ayah ayah) => QcfLayout.instance.pageFor(
    ayah,
    UserDataStore.instance.settings.mushafStyle,
  );

  List<Ayah> _ayahsOfMushafPage(int pageNumber) {
    final repo = QuranRepository.instance;
    if (UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah) {
      final qcf = [
        for (final (s, a) in QcfLayout.instance.ayahsStartingOn(pageNumber))
          ?repo.getAyah(s, a),
      ];
      if (qcf.isNotEmpty) return qcf;
    }
    return repo.getPage(pageNumber).ayahs;
  }
  Ayah? _activeSelectedAyah;
  bool _showTopBar = false;
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
  final ValueNotifier<int?> _sliderPage = ValueNotifier(null);
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
  String? _pagerSettingsSig;

  String _settingsSignature() {
    final s = UserDataStore.instance.settings;
    return '${s.quranFontFamilyName}|${s.mushafStyle}|${s.flowingTextScale}|${s.mushafPaperTone}|${s.quranFontSize}';
  }

  /// يُضبط قبل انتقال لم يقم به القارئ (كمزامنة التبويب)، فلا يُحسب ولا يُحفظ
  /// ثانية.
  bool _ignoreNextPageChange = false;

  /// الصفحة المطلوب تثبيتها بعد قفزة برمجية (كي تبقى الزوجية في العرض المزدوج).
  int? _pendingJumpPageIndex;

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
    final fromItem = _itemFor(fromIndex);
    if (_itemFor(toIndex) != fromItem + 1) return;
    if (DateTime.now().difference(_pageShownAt) < _readDwell) return;
    _pagesToCount.addAll(_pagesOf(fromItem));
    _pageToPersist = toIndex + 1;
  }

  /// الحفظ يُعلم كل مستمعي المخزن، فينتظر حتى تستقر الصفحة ولا يقطع حركة التقليب.
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
    final pages = _pagesOf(_itemFor(_currentPageIndex));
    final dwell = pages.last == 604 ? _lastPageDwell : _autoCountDwell;
    _autoCountTimer = Timer(dwell, () async {
      // فقط حين يكون المصحف التبويب أو الصفحة الظاهرة.
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (_currentPageIndex + 1 != page) return;
      for (final shown in pages) {
        await _recordPage(shown);
      }
      _persistCurrentPagePosition(pages.last);
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
        startPage = _pageOf(targetAyah);
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
    }
    _pagerSettingsSig = _settingsSignature();
    UserDataStore.instance.addListener(_onStoreChanged);

    _startAutoCount();
    QuranAudio.instance.addListener(_onAudio);
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachPagerScrolling();
    });
  }

  /// يعرف عرض الشاشة وتغيّر إظهار التبويب، فيحوّل العرض بأمان ويعيد عدّاد الصفحة.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (tickerEnabled != _tickerEnabled) {
      _tickerEnabled = tickerEnabled;
      if (tickerEnabled) {
        _pageShownAt = DateTime.now();
        _startAutoCount();
      } else {
        _autoCountTimer?.cancel();
      }
    }

    final wide = MediaQuery.sizeOf(context).width >= _spreadMinWidth;
    if (wide == _wide) return;
    _wide = wide;
    _pager = null;
    _pagerPosition?.isScrollingNotifier.removeListener(_onPagerScrolling);
    _pagerPosition = null;
    _pageSnapshots.allowSnapshotting = false;
    final oldController = _pageController;
    _pageController = PageController(initialPage: _itemFor(_currentPageIndex));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      _attachPagerScrolling();
    });
  }

  void _attachPagerScrolling() {
    if (!mounted || !_pageController.hasClients) return;
    final position = _pageController.position;
    if (identical(_pagerPosition, position)) return;
    _pagerPosition?.isScrollingNotifier.removeListener(_onPagerScrolling);
    _pagerPosition = position;
    position.isScrollingNotifier.addListener(_onPagerScrolling);
    _pageSnapshots.allowSnapshotting = position.isScrollingNotifier.value;
  }

  void _onPagerScrolling() {
    final scrolling = _pagerPosition?.isScrollingNotifier.value ?? false;
    _pageSnapshots.allowSnapshotting = scrolling;
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
      final targetIndex = (_pageOf(ayah) - 1).clamp(0, 603);
      final targetItem = _itemFor(targetIndex);
      if (visible &&
          targetItem != _itemFor(_currentPageIndex) &&
          _pageController.hasClients) {
        _ignoreNextPageChange = true;
        _pendingJumpPageIndex = targetIndex;
        final animate = AppMotion.shouldAnimate(context);
        // في الإطار التالي، فلا تشارك الحركة إعادة بناء الصفحات للآية الجديدة.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          if (animate) {
            _pageController.animateToPage(
              targetItem,
              duration: AppMotion.normal,
              curve: AppMotion.emphasized,
            );
          } else {
            _pageController.jumpToPage(targetItem);
          }
        });
      } else if (visible &&
          targetItem == _itemFor(_currentPageIndex) &&
          targetIndex != _currentPageIndex) {
        _currentPageIndex = targetIndex;
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
    final ayahs = _ayahsOfMushafPage(pageNumber);
    if (ayahs.isEmpty) return;
    audio.playFrom(_activeSelectedAyah ?? ayahs.first);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    UserDataStore.instance.removeListener(_onStoreChanged);
    QuranAudio.instance.removeListener(_onAudio);
    _suppressTimer?.cancel();
    _autoCountTimer?.cancel();
    _saveTimer?.cancel();
    if (_pagesToCount.isNotEmpty) _saveCountedPages();
    _pagerPosition?.isScrollingNotifier.removeListener(_onPagerScrolling);
    _pageSnapshots.dispose();
    _sliderPage.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// يتتبع تغيّر موضع القراءة وإعدادات الخط والعرض.
  void _onStoreChanged() {
    if (!mounted) return;
    if (widget.controlsVisible != null) {
      final page = UserDataStore.instance.readingPosition.page.clamp(1, 604);
      if (page != _lastSavedPage) {
        _lastSavedPage = page;
        final targetIndex = page - 1;
        final targetItem = _itemFor(targetIndex);
        if (targetItem != _itemFor(_currentPageIndex) &&
            _pageController.hasClients) {
          _ignoreNextPageChange = true;
          _pendingJumpPageIndex = targetIndex;
          _pageController.jumpToPage(targetItem);
        } else if (targetIndex != _currentPageIndex) {
          setState(() {
            _currentPageIndex = targetIndex;
            _activeSelectedAyah = null;
          });
        }
      }
    }
    final nextSig = _settingsSignature();
    if (nextSig != _pagerSettingsSig) {
      setState(() {
        _pagerSettingsSig = nextSig;
        _pager = null;
      });
    }
  }

  /// عند تقليب الصفحة: يحدّث رقمها ويحفظ الموضع.
  void _onPageChanged(int item) {
    if (item < 0 || item >= (_wide ? 302 : 604)) return;
    final from = _currentPageIndex;
    final pending = _pendingJumpPageIndex;
    _pendingJumpPageIndex = null;
    // الصفحة الزوجية في العرض المزدوج تبقى موضع القراءة عند القفز إليها أو حين لا يتغير الزوج.
    final int index;
    if (pending != null && _itemFor(pending) == item) {
      index = pending;
    } else if (item == _itemFor(from)) {
      index = from;
    } else {
      index = _pagesOf(item).first - 1;
    }
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
    final ayahs = _ayahsOfMushafPage(pageNumber);
    if (ayahs.isNotEmpty) {
      final firstAyah = ayahs.first;
      // حفظ هذا القارئ لا يحرّكه: ربما تقدّم صفحة أخرى منذ بدأ الانتظار.
      _lastSavedPage = pageNumber;
      UserDataStore.instance.saveReadingPosition(
        page: pageNumber,
        surahNumber: firstAyah.surahNumber,
        ayahNumber: firstAyah.ayahNumber,
      );
    }
  }

  /// اسم أول سورة في الصفحة [page].
  String _surahOfPage(int page) {
    final repo = QuranRepository.instance;
    final ayahs = _ayahsOfMushafPage(page);
    if (ayahs.isNotEmpty) {
      return repo.getSurah(ayahs.first.surahNumber).name;
    }
    final pageData = repo.getPage(page);
    if (pageData.surahNumbers.isNotEmpty) {
      return repo.getSurah(pageData.surahNumbers.first).name;
    }
    return '';
  }

  bool get _canGoPrevious =>
      _wide ? _itemFor(_currentPageIndex) > 0 : _currentPageIndex > 0;

  bool get _canGoNext =>
      _wide ? _itemFor(_currentPageIndex) < 301 : _currentPageIndex < 603;

  /// يتقدّم أو يرجع بمقدار عنصر واحد (صفحة أو صفحتين متقابلتين).
  void _stepPage(int delta) {
    final maxItem = _wide ? 301 : 603;
    final currentItem = _itemFor(_currentPageIndex);
    final targetItem = (currentItem + delta).clamp(0, maxItem);
    if (targetItem == currentItem) return;
    _pendingJumpPageIndex = _pagesOf(targetItem).first - 1;
    _pageController.jumpToPage(targetItem);
  }

  /// يعالج مفاتيح الاتجاه وتقليب الصفحات على سطح المكتب عندما يكون القارئ ظاهراً ونشطاً.
  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (!mounted || !_tickerEnabled) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) return false;
    final primaryFocusContext = FocusManager.instance.primaryFocus?.context;
    if (primaryFocusContext != null &&
        (primaryFocusContext.widget is EditableText ||
            primaryFocusContext
                    .findAncestorWidgetOfExactType<EditableText>() !=
                null ||
            (_showTopBar &&
                primaryFocusContext.findAncestorWidgetOfExactType<Slider>() !=
                    null))) {
      return false;
    }
    final key = event.logicalKey;
    // المصحف يبدأ من اليمين إلى اليسار: السهم الأيسر وPageDown للتقدّم، والأيمن وPageUp للرجوع.
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageDown) {
      _stepPage(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageUp) {
      _stepPage(-1);
      return true;
    }
    return false;
  }

  void _jumpToPageIndex(int targetIndex, {Ayah? selectedAyah}) {
    final targetItem = _itemFor(targetIndex);
    if (!_pageController.hasClients ||
        targetItem == _itemFor(_currentPageIndex)) {
      _pendingJumpPageIndex = null;
      if (targetIndex == _currentPageIndex &&
          selectedAyah == _activeSelectedAyah) {
        return;
      }
      setState(() {
        _currentPageIndex = targetIndex;
        _activeSelectedAyah = selectedAyah;
      });
      _pageShownAt = DateTime.now();
      _startAutoCount();
      return;
    }
    _pendingJumpPageIndex = targetIndex;
    _pageController.jumpToPage(targetItem);
    if (selectedAyah != null) {
      setState(() {
        _activeSelectedAyah = selectedAyah;
      });
    }
  }

  /// ينتقل إلى الصفحة [mushafPage] (١..٦٠٤).
  void _jumpToMushafPage(int mushafPage) {
    _jumpToPageIndex(mushafPage.clamp(1, 604) - 1);
  }

  /// ينتقل إلى صفحة الآية ويميّزها.
  void _jumpToAyah(Ayah ayah) {
    _jumpToPageIndex((_pageOf(ayah) - 1).clamp(0, 603), selectedAyah: ayah);
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

    unawaited(HapticFeedback.mediumImpact());

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

    return ClipRect(
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                .withValues(alpha: isDark ? 0.85 : 0.88),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.8),
                width: AppTokens.borderRegular,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
            tooltip: context.l10n.mushafMenu,
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
                  final ayahs = _ayahsOfMushafPage(currentPageNumber);
                  if (ayahs.isEmpty) return;
                  FocusModeScreen.open(
                    context,
                    _activeSelectedAyah ?? ayahs.first,
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
    ),
    ),
    );
  }

  /// الشريط السفلي: السورة والجزء، والانتقال بين الصفحات.
  Widget _buildBottomBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
    // أثناء السحب يُظهر الشريط الصفحة المقصودة، ويقفز المصحف إليها عند رفع
    // الإصبع.
    final l10n = context.l10n;
    final displayedAyahs = _ayahsOfMushafPage(currentPageNumber);
    final firstAyah = displayedAyahs.isNotEmpty ? displayedAyahs.first : null;
    final surahName = firstAyah != null
        ? repo.getSurah(firstAyah.surahNumber).name
        : '';
    final juzNumber =
        firstAyah?.juz ?? repo.getPage(currentPageNumber).juzNumber;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            boxShadow: AppTokens.cardShadow(isDark: isDark, glowColor: primary),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            child: BackdropFilter.grouped(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                      .withValues(alpha: isDark ? 0.85 : 0.88),
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: AppTokens.borderRegular,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // السورة والجزء، وشارة الصفحة.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      surahName.isNotEmpty
                          ? '$surahName • ${l10n.juzNumber(juzNumber)}'
                          : l10n.juzNumber(juzNumber),
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
                  // الصفحة الحالية (تفتح حوار الانتقال).
                  InkWell(
                    onTap: _showJumpToPageDialog,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: ValueListenableBuilder<int?>(
                      valueListenable: _sliderPage,
                      builder: (context, dragged, _) => FuturisticBadge(
                        label: l10n.pageAbbrOfTotal(
                          dragged ?? currentPageNumber,
                          604,
                        ),
                        color: isDark
                            ? AppColors.electricGold
                            : AppColors.lightPrimary,
                        showDot: true,
                        isCompact: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // الصفحة السابقة، والشريط، والتالية.
              Row(
                children: [
                  // السابقة: الأيقونة تنعكس في RTL فتشير لليمين.
                  FuturisticIconButton(
                    icon: AppIcons.caretLeft,
                    tooltip: context.l10n.previousPage,
                    size: 36,
                    iconSize: 22,
                    isEnabled: _canGoPrevious,
                    onTap: () => _stepPage(-1),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9,
                          elevation: 2,
                          pressedElevation: 4,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ),
                        overlayColor:
                            (isDark
                                    ? AppColors.cyberEmerald
                                    : AppColors.lightPrimary)
                                .withValues(alpha: 0.14),
                        // رقم الصفحة واسم السورة فوق الإصبع أثناء السحب.
                        showValueIndicator: ShowValueIndicator.onDrag,
                        valueIndicatorShape:
                            const RectangularSliderValueIndicatorShape(),
                        valueIndicatorColor: isDark
                            ? AppColors.cyberEmerald
                            : AppColors.lightPrimary,
                        valueIndicatorTextStyle: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
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
                      // الشريط وحده يُعاد بناؤه أثناء السحب.
                      child: ValueListenableBuilder<int?>(
                        valueListenable: _sliderPage,
                        builder: (context, dragged, _) {
                          final page = dragged ?? currentPageNumber;
                          return Slider(
                            value: page.toDouble().clamp(1.0, 604.0),
                            min: 1.0,
                            max: 604.0,
                            // بلا divisions: ٦٠٣ علامة كانت تُرسم في كل إطار
                            // من السحب، والرقم يُقرّب في onChanged.
                            label:
                                '${l10n.pageAbbr(page)} · ${_surahOfPage(page)}',
                            onChanged: (val) => _sliderPage.value = val.round(),
                            onChangeEnd: (val) {
                              _sliderPage.value = null;
                              final targetPage = val.round();
                              if (targetPage != currentPageNumber) {
                                _jumpToMushafPage(targetPage);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // التالية: الأيقونة تنعكس في RTL فتشير لليسار.
                  FuturisticIconButton(
                    icon: AppIcons.caretRight,
                    tooltip: context.l10n.nextPage,
                    size: 36,
                    iconSize: 22,
                    isEnabled: _canGoNext,
                    onTap: () => _stepPage(1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    ),
    );
  }

  /// صفحات المصحف، ولا تُبنى من جديد إلا إن تغيّرت الآية المحددة أو السطوع أو إعدادات الخط والعرض.
  Widget _pagerFor(bool isDark) {
    final selected = (_activeSelectedAyah ?? QuranAudio.instance.current)?.id;
    final settingsSig = _settingsSignature();
    if (_pager == null ||
        selected != _pagerSelectedAyah ||
        isDark != _pagerIsDark ||
        settingsSig != _pagerSettingsSig) {
      _pagerSelectedAyah = selected;
      _pagerIsDark = isDark;
      _pagerSettingsSig = settingsSig;
      _pager = _buildPager(isDark);
    }
    return _pager!;
  }

  /// صفحة المصحف [pageNumber]، تتحرّك صورةً أثناء السحب.
  Widget _mushafPage(int pageNumber) => SnapshotWidget(
    controller: _pageSnapshots,
    mode: SnapshotMode.permissive,
    child: QuranPageView(
      key: ValueKey('mushaf_page_${pageNumber}_$_pagerSettingsSig'),
      page: QuranRepository.instance.getPage(pageNumber),
      pageNumber: pageNumber,
      selectedAyah: _activeSelectedAyah ?? QuranAudio.instance.current,
      onAyahTap: _handleAyahTap,
      onAyahLongPress: _handleAyahLongPress,
      onAyahHighlight: _handleAyahHighlight,
      onAyahHighlightClear: _handleAyahHighlightClear,
    ),
  );

  Widget _buildPager(bool isDark) {
    return SafeArea(
      // تبويب المصحف يمتد تحت الشريط السفلي، فالحافة حافة الشاشة لا الشريط.
      bottom: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleTopBar,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            key: ValueKey('mushaf_pager_$_wide'),
            controller: _pageController,
            physics: const _MushafPagePhysics(),
            // العنصران المجاوران جاهزان قبل أن يبدأ السحب.
            allowImplicitScrolling: true,
            itemCount: _wide ? 302 : 604,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => RepaintBoundary(
              child: _SettledPage(
                key: ValueKey('settled_${index}_$_pagerSettingsSig'),
                controller: _pageController,
                index: index,
                child: _wide
                    ? _mushafSpread(index, isDark)
                    : _mushafPage(index + 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// صفحتان متقابلتان كالمصحف المطبوع: الفردية يميناً والزوجية يساراً.
  Widget _mushafSpread(int spread, bool isDark) {
    final [right, left] = _pagesOf(spread);
    return Row(
      children: [
        Expanded(child: _mushafPage(right)),
        Container(
          width: 1.0,
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.5),
        ),
        Expanded(child: _mushafPage(left)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPageNumber = _currentPageIndex + 1;
    final shouldAnimate = AppMotion.shouldAnimate(context);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        drawer: QuranSideMenu(
          currentPage: currentPageNumber,
          onPageSelected: _jumpToMushafPage,
        ),
        onDrawerChanged: (isOpen) {
          widget.controlsVisible?.value = isOpen ? false : _showTopBar;
        },
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
                  child: AnimatedOpacity(
                    opacity: _showTopBar ? 1.0 : 0.0,
                    duration: shouldAnimate ? AppMotion.chrome : Duration.zero,
                    curve: Curves.easeInOut,
                    child: _buildTopBar(context, currentPageNumber),
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
                  child: AnimatedOpacity(
                    opacity: _showTopBar ? 1.0 : 0.0,
                    duration: shouldAnimate ? AppMotion.chrome : Duration.zero,
                    curve: Curves.easeInOut,
                    child: KeyedSubtree(
                      key: _bottomBarKey,
                      child: _buildBottomBar(context, currentPageNumber),
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

            // التلاوة، تتلاشى مع بقية عناصر التحكم في موضع ثابت دون أي حركة.
            Positioned(
              left: 12,
              right: 12,
              bottom:
                  MediaQuery.paddingOf(context).bottom + _bottomBarHeight + 16,
              child: IgnorePointer(
                ignoring: !_showTopBar,
                child: AnimatedOpacity(
                  opacity: _showTopBar ? 1.0 : 0.0,
                  duration: shouldAnimate ? AppMotion.chrome : Duration.zero,
                  curve: Curves.easeInOut,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: const AudioBar(),
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

/// تقليب صفحة ينتهي بسرعة ودون ارتداد، فيتبع الإصبع مباشرة.
class _MushafPagePhysics extends PageScrollPhysics {
  const _MushafPagePhysics({super.parent});

  @override
  _MushafPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _MushafPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.4,
    stiffness: 180,
    ratio: 1.05,
  );
}

/// صفحة تُخلق أثناء السحب تُرجأ حتى يهدأ، فلا يقطع بناؤها حركة الصفحة الظاهرة.
///
/// تقع خارج الشاشة، فلا يرى القارئ انتظارها؛ وإن واصل التقليب بُنيت قبل أن
/// تظهر.
class _SettledPage extends StatefulWidget {
  final PageController controller;
  final int index;
  final Widget child;

  const _SettledPage({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  State<_SettledPage> createState() => _SettledPageState();
}

class _SettledPageState extends State<_SettledPage> {
  bool _ready = true;

  ScrollPosition get _position => widget.controller.position;

  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasClients) return;
    if (!_position.isScrollingNotifier.value) return;
    _ready = false;
    widget.controller.addListener(_check);
    _position.isScrollingNotifier.addListener(_check);
  }

  void _stopListening() {
    widget.controller.removeListener(_check);
    if (widget.controller.hasClients) {
      _position.isScrollingNotifier.removeListener(_check);
    }
  }

  void _check() {
    final page = widget.controller.page;
    final near = page != null && (page - widget.index).abs() < 1;
    if (_position.isScrollingNotifier.value && !near) return;
    _stopListening();
    // قد يأتي الإعلام أثناء تخطيط الإطار (عند تدوير الشاشة مثلاً).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    if (!_ready) _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : const SizedBox.expand();
}
