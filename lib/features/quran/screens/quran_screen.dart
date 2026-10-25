import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import '../widgets/ayah_action_sheet.dart';
import '../widgets/word_meanings_panel.dart';
import '../../focus/focus_mode_screen.dart';
import '../../search/search_screen.dart';
import 'quran_page_view.dart';
import '../widgets/quran_side_menu.dart';
import '../../settings/user_settings_model.dart';

/// Fullscreen Medina Mushaf reading experience for Tadbeer (1421H layout, 604 pages).
/// شاشة قراءة المصحف المدني الكاملة (٦٠٤ صفحات) مع أدوات التدبر والبحث والتنقل.
class QuranScreen extends StatefulWidget {
  final int? initialPage;
  final int? targetSurahNumber;
  final int? targetAyahNumber;

  /// When the reader is hosted as a tab, it mirrors its controls visibility
  /// here so the shell can hide the bottom bar while reading. Null when the
  /// reader is pushed as a standalone page.
  final ValueNotifier<bool>? controlsVisible;

  /// وضع القراءة: يحفظ موضع القراءة ويحتسب الصفحات في الختمة والإحصاءات.
  ///
  /// When false (viewing mode, the default) the reader only shows a verse
  /// opened from search, bookmarks, notes and so on: it never moves the
  /// user's reading position or counts pages, and offers a "continue reading
  /// from here" action instead.
  final bool readingMode;

  /// ينشئ شاشة قراءة المصحف الشريف مع إمكانية تحديد الصفحة أو الآية المستهدفة.
  const QuranScreen({
    super.key,
    this.initialPage,
    this.targetSurahNumber,
    this.targetAyahNumber,
    this.controlsVisible,
    this.readingMode = false,
  });

  /// ينشئ الحالة التفاعلية لشاشة قراءة المصحف.
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

/// الحالة التفاعلية لشاشة قراءة المصحف الشريف.
class _QuranScreenState extends State<QuranScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;
  late int _currentPageIndex;
  Ayah? _activeSelectedAyah;
  bool _showTopBar = false;
  bool _showMeaningsPanel = false;
  bool _suppressNextPageTap = false;
  Timer? _suppressTimer;

  /// A page counts as read when the reader moves forward past it after
  /// spending at least this long on it (skimming and going back don't count).
  static const _readDwell = Duration(seconds: 3);
  DateTime _pageShownAt = DateTime.now();

  /// Set before a jump the user did not make (syncing the tab), so that page
  /// change is neither counted nor saved again.
  bool _ignoreNextPageChange = false;

  /// Page just counted, shown briefly as a confirmation chip.
  int? _countedPage;
  Timer? _countedTimer;

  void _maybeCountPage(int fromIndex, int toIndex) {
    if (!widget.readingMode || toIndex != fromIndex + 1) return;
    if (DateTime.now().difference(_pageShownAt) < _readDwell) return;
    final page = fromIndex + 1;
    UserDataStore.instance.recordPageRead(page);
    HapticFeedback.lightImpact();
    _countedTimer?.cancel();
    setState(() => _countedPage = page);
    _countedTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _countedPage = null);
    });
  }

  /// Makes the page shown in viewing mode the user's reading position.
  void _continueReadingFromHere() {
    HapticFeedback.mediumImpact();
    _persistCurrentPagePosition(_currentPageIndex + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.readingPositionMoved(_currentPageIndex + 1),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// يهيئ متحكم الصفحات ويحدد صفحة البداية والآية المستهدفة عند فتح الشاشة.
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
      // As a tab, start with the controls (and the bottom bar) visible so the
      // reader can see how to leave, and follow position changes made by
      // readers opened elsewhere (e.g. from a bookmark).
      _showTopBar = true;
      widget.controlsVisible!.value = true;
      UserDataStore.instance.addListener(_syncToSavedPosition);
    }

    if (widget.readingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _persistCurrentPagePosition(startPage);
      });
    }
  }

  /// يحرر المؤقت ومتحكم الصفحات عند إغلاق الشاشة.
  @override
  void dispose() {
    if (widget.controlsVisible != null) {
      UserDataStore.instance.removeListener(_syncToSavedPosition);
    }
    _suppressTimer?.cancel();
    _countedTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Jumps the tab reader to the saved position when another reader moved it.
  void _syncToSavedPosition() {
    final page = UserDataStore.instance.readingPosition.page.clamp(1, 604);
    if (page - 1 != _currentPageIndex && _pageController.hasClients) {
      _ignoreNextPageChange = true;
      _pageController.jumpToPage(page - 1);
    }
  }

  /// يحدث رقم الصفحة الحالية عند تقليب الصفحات ويحفظ موضع القراءة الجديد.
  void _onPageChanged(int index) {
    if (index < 0 || index >= 604) return;
    final from = _currentPageIndex;
    final programmatic = _ignoreNextPageChange;
    _ignoreNextPageChange = false;
    setState(() {
      _currentPageIndex = index;
      _activeSelectedAyah = null;
    });
    if (programmatic) {
      _pageShownAt = DateTime.now();
      return;
    }
    _maybeCountPage(from, index);
    _pageShownAt = DateTime.now();
    if (widget.readingMode) _persistCurrentPagePosition(index + 1);
  }

  /// يحفظ موضع القراءة الحالي (الصفحة والسورة والآية) في التخزين المحلي.
  void _persistCurrentPagePosition(int pageNumber) {
    final repo = QuranRepository.instance;
    final page = repo.getPage(pageNumber);
    if (page.ayahs.isNotEmpty) {
      final firstAyah = page.ayahs.first;
      UserDataStore.instance.saveReadingPosition(
        page: pageNumber,
        surahNumber: firstAyah.surahNumber,
        ayahNumber: firstAyah.ayahNumber,
      );
    }
  }

  /// ينتقل مباشرة إلى صفحة محددة في المصحف الشريف (١ إلى ٦٠٤).
  void _jumpToMushafPage(int mushafPage) {
    final target = mushafPage.clamp(1, 604);
    _pageController.jumpToPage(target - 1);
  }

  /// ينتقل إلى صفحة الآية المحددة ويقوم بتمييزها بصرياً.
  void _jumpToAyah(Ayah ayah) {
    _pageController.jumpToPage(ayah.page - 1);
    setState(() {
      _activeSelectedAyah = ayah;
    });
  }

  /// يبرز الآية المحددة مؤقتاً عند بدء لمسها.
  void _handleAyahHighlight(Ayah ayah) {
    setState(() {
      _activeSelectedAyah = ayah;
    });
  }

  /// يزيل التمييز المؤقت عن الآية عند رفع الإصبع مبكراً.
  void _handleAyahHighlightClear(Ayah ayah) {
    if (_activeSelectedAyah?.id == ayah.id) {
      setState(() {
        _activeSelectedAyah = null;
      });
    }
  }

  /// يعالج النقر السريع على الآية لإلغاء التحديد أو إظهار وإخفاء أشرطة التحكم.
  void _handleAyahTap(Ayah ayah) {
    if (_activeSelectedAyah != null) {
      setState(() {
        _activeSelectedAyah = null;
      });
    }
    _suppressNextPageTap = false;
    _toggleTopBar();
  }

  /// يعالج الضغط المطول على الآية لفتح نافذة إجراءات الآية مع اهتزاز خفيف.
  Future<void> _handleAyahLongPress(Ayah ayah) async {
    _suppressNextPageTap = true;
    setState(() {
      _activeSelectedAyah = ayah;
    });

    HapticFeedback.mediumImpact();

    await AyahActionSheet.show(context, ayah);

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

  /// يفتح شاشة البحث في القرآن الكريم وينتقل إلى الآية المختارة عند العودة.
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

  /// يعرض نافذة حوار للانتقال السريع إلى صفحة مصحف محددة برقمها.
  void _showJumpToPageDialog() {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: '${_currentPageIndex + 1}');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.comsilkLight,
        title: Text(
          l10n.jumpToPage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل رقم الصفحة بين ١ و ٦٠٤',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '1 - 604',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = ArabicSearchNormalizer.toEnglishDigits(
                controller.text.trim(),
              );
              final val = int.tryParse(raw);
              if (val != null && val >= 1 && val <= 604) {
                Navigator.pop(dialogCtx);
                _jumpToMushafPage(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.go,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// يعرض لوحة سفلية لاختيار نوع خط المصحف وضبط حجمه مع معاينة حية.
  void _showFontSizeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (ctx, _) {
            final settings = UserDataStore.instance.settings;
            final currentSize = settings.quranFontSize;
            final currentFamily = settings.quranFontFamily;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'نوع خط المصحف',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final fontOpt in QuranFontFamilyOption.values)
                          ChoiceChip(
                            label: Text(
                              fontOpt.labelArabic,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: currentFamily == fontOpt
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: currentFamily == fontOpt,
                            onSelected: (_) {
                              UserDataStore.instance.setQuranFontFamily(
                                fontOpt,
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'حجم خط المصحف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${ArabicSearchNormalizer.toArabicDigits(currentSize.round())} نقطة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: currentSize,
                      min: UserSettings.minQuranFontSize,
                      max: UserSettings.maxQuranFontSize,
                      divisions: 16,
                      label: '${currentSize.round()}',
                      onChanged: (newSize) {
                        UserDataStore.instance.setQuranFontSize(newSize);
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: MushafPalette.of(
                          isDark: isDark,
                          tone: settings.mushafPaperTone,
                        ).outer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: settings.quranFontFamilyName,
                          fontSize: currentSize,
                          color: MushafPalette.of(
                            isDark: isDark,
                            tone: settings.mushafPaperTone,
                          ).text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            UserDataStore.instance.setQuranFontSize(
                              UserSettings.defaultQuranFontSize,
                            );
                          },
                          child: const Text('إعادة للوضع الافتراضي (٢٠)'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('تم'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// يبدل حالة إظهار أو إخفاء أشرطة التحكم العلوية والسفلية عند النقر على الصفحة.
  void _toggleTopBar() {
    if (_suppressNextPageTap) {
      _suppressNextPageTap = false;
      return;
    }
    // If an Ayah was highlighted, cancel the highlight and do not toggle bars
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

  /// يبني الشريط العلوي العائم الذي يضم القائمة الجانبية والبحث ومعاني الكلمات وحجم الخط بتصميم مستقبلي.
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
          // 1. Drawer menu button (☰)
          FuturisticIconButton(
            icon: Icons.menu,
            tooltip: 'القائمة',
            size: 38,
            iconSize: 20,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          // Actions group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1b. Focus mode: one verse at a time
              FuturisticIconButton(
                icon: Icons.self_improvement_rounded,
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
              // 2. Search button (🔍)
              FuturisticIconButton(
                icon: Icons.search,
                tooltip: l10n.search,
                size: 38,
                iconSize: 20,
                onTap: _openSearch,
              ),
              const SizedBox(width: 8),
              // 3. Word meanings button (📖)
              FuturisticIconButton(
                icon: _showMeaningsPanel
                    ? Icons.auto_stories_rounded
                    : Icons.auto_stories_outlined,
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
              // 4. Quran font size button (Aa)
              FuturisticIconButton(
                icon: Icons.format_size_rounded,
                tooltip: 'حجم الخط',
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

  /// يبني الشريط السفلي العائم الذي يعرض معلومات السورة والجزء وشريط التمرير السريع بين الصفحات بتصميم رقمي متطور.
  Widget _buildBottomBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
    final pageDigits = ArabicSearchNormalizer.toArabicDigits(currentPageNumber);
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
              // Top info row: Surah & Juz, meanings badge, page jump badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Surah & Juz
                  Flexible(
                    child: Text(
                      surahName.isNotEmpty
                          ? '$surahName • الجزء $juzDigits'
                          : 'الجزء $juzDigits',
                      style: TextStyle(
                        fontFamily: 'Amiri',
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
                  // Word meanings toggle badge
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showMeaningsPanel = !_showMeaningsPanel;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: FuturisticBadge(
                      label: 'المعاني ($meaningsDigits)',
                      icon: Icons.library_books_rounded,
                      color: _showMeaningsPanel
                          ? (isDark ? AppColors.cyberEmerald : primary)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Current page badge (opens jump dialog on tap)
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
              // Bottom row: Previous page button, Slider, Next page button
              Row(
                children: [
                  // Previous page (in Arabic RTL, points right towards earlier pages)
                  FuturisticIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'الصفحة السابقة',
                    size: 36,
                    iconSize: 22,
                    isEnabled: currentPageNumber > 1,
                    onTap: () => _jumpToMushafPage(currentPageNumber - 1),
                  ),
                  const SizedBox(width: 4),
                  // Slider across pages 1 to 604
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
                        value: currentPageNumber.toDouble().clamp(1.0, 604.0),
                        min: 1.0,
                        max: 604.0,
                        divisions: 603,
                        label: 'ص $pageDigits',
                        onChanged: (val) {
                          final targetPage = val.round();
                          if (targetPage != currentPageNumber) {
                            _jumpToMushafPage(targetPage);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Next page (in Arabic RTL, points left towards later pages)
                  FuturisticIconButton(
                    icon: Icons.chevron_left_rounded,
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

  /// يبني واجهة شاشة المصحف الكاملة مع دعم العرض الفردي أو المزدوج والأشرطة العائمة.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
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
            // Fullscreen Mushaf page area
            Positioned.fill(
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleTopBar,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideSpread = constraints.maxWidth >= 900;
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: 604,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final pageNumber = index + 1;
                          if (!isWideSpread) {
                            final page = repo.getPage(pageNumber);
                            return QuranPageView(
                              page: page,
                              pageNumber: pageNumber,
                              selectedAyah: _activeSelectedAyah,
                              onAyahTap: _handleAyahTap,
                              onAyahLongPress: _handleAyahLongPress,
                              onAyahHighlight: _handleAyahHighlight,
                              onAyahHighlightClear: _handleAyahHighlightClear,
                            );
                          }

                          // Dual-page spread on wide tablets/screens (>= 900px)
                          if (pageNumber == 1) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: QuranPageView(
                                  page: repo.getPage(1),
                                  pageNumber: 1,
                                  selectedAyah: _activeSelectedAyah,
                                  onAyahTap: _handleAyahTap,
                                  onAyahLongPress: _handleAyahLongPress,
                                  onAyahHighlight: _handleAyahHighlight,
                                  onAyahHighlightClear:
                                      _handleAyahHighlightClear,
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
                                  selectedAyah: _activeSelectedAyah,
                                  onAyahTap: _handleAyahTap,
                                  onAyahLongPress: _handleAyahLongPress,
                                  onAyahHighlight: _handleAyahHighlight,
                                  onAyahHighlightClear:
                                      _handleAyahHighlightClear,
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
                                  selectedAyah: _activeSelectedAyah,
                                  onAyahTap: _handleAyahTap,
                                  onAyahLongPress: _handleAyahLongPress,
                                  onAyahHighlight: _handleAyahHighlight,
                                  onAyahHighlightClear:
                                      _handleAyahHighlightClear,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Smooth floating top bar overlay
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

            // Smooth floating bottom navigation bar overlay
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
                      child: _buildBottomBar(context, currentPageNumber),
                    ),
                  ),
                ),
              ),
            ),

            // Outside tap backdrop dismiss detector for Word Meanings Window
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

            // Word Meanings Window at the bottom
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

            // Viewing mode: a verse opened from elsewhere. Offer to make this
            // the reading position instead of moving it silently.
            if (!widget.readingMode && !_showTopBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: SafeArea(
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _continueReadingFromHere,
                      icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                      label: Text(context.l10n.continueReadingFromHere),
                    ),
                  ),
                ),
              ),

            // Brief confirmation that the page was counted.
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.readingMode ? 110 : 84,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: a, child: child),
                    ),
                    child: _countedPage == null
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(_countedPage),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimaryDark.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.electricGold,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.pageCounted(_countedPage!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
