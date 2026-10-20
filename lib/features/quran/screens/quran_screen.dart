import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import '../widgets/ayah_action_sheet.dart';
import '../widgets/word_meanings_panel.dart';
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

  /// ينشئ شاشة قراءة المصحف الشريف مع إمكانية تحديد الصفحة أو الآية المستهدفة.
  const QuranScreen({
    super.key,
    this.initialPage,
    this.targetSurahNumber,
    this.targetAyahNumber,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _persistCurrentPagePosition(startPage);
      }
    });
  }

  /// يحرر المؤقت ومتحكم الصفحات عند إغلاق الشاشة.
  @override
  void dispose() {
    _suppressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// يحدث رقم الصفحة الحالية عند تقليب الصفحات ويحفظ موضع القراءة الجديد.
  void _onPageChanged(int index) {
    if (index < 0 || index >= 604) return;
    setState(() {
      _currentPageIndex = index;
      _activeSelectedAyah = null;
    });
    _persistCurrentPagePosition(index + 1);
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
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.mushafBackground,
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
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.mushafQuranText,
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
  }

  /// يبني الشريط العلوي العائم الذي يضم القائمة الجانبية والبحث ومعاني الكلمات وحجم الخط.
  Widget _buildTopBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.comsilkLight)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Drawer menu button (☰) (at the start / right in RTL)
          IconButton(
            icon: const Icon(Icons.menu, size: 22),
            tooltip: 'القائمة',
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          // Actions group (at the end / left in RTL)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 2. Search button (🔍)
              IconButton(
                icon: const Icon(Icons.search, size: 22),
                tooltip: l10n.search,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                onPressed: _openSearch,
              ),
              const SizedBox(width: 4),
              // 3. Word meanings button (📖)
              IconButton(
                icon: Icon(
                  _showMeaningsPanel
                      ? Icons.auto_stories_rounded
                      : Icons.auto_stories_outlined,
                  size: 22,
                ),
                tooltip: 'معاني كلمات الصفحة',
                color: _showMeaningsPanel
                    ? (isDark ? AppColors.oliveLight : AppColors.olive)
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                onPressed: () {
                  setState(() {
                    _showMeaningsPanel = !_showMeaningsPanel;
                  });
                },
              ),
              const SizedBox(width: 4),
              // 4. Quran font size button (Aa)
              IconButton(
                icon: const Icon(Icons.format_size_rounded, size: 22),
                tooltip: 'حجم الخط',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                onPressed: _showFontSizeDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// يبني الشريط السفلي العائم الذي يعرض معلومات السورة والجزء وشريط التمرير السريع بين الصفحات.
  Widget _buildBottomBar(BuildContext context, int currentPageNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
    final pageDigits = ArabicSearchNormalizer.toArabicDigits(currentPageNumber);
    final pageData = repo.getPage(currentPageNumber);
    final firstAyah = pageData.ayahs.isNotEmpty ? pageData.ayahs.first : null;
    final surahName = firstAyah != null ? repo.getSurah(firstAyah.surahNumber).name : '';
    final juzNumber = firstAyah?.juz ?? 1;
    final juzDigits = ArabicSearchNormalizer.toArabicDigits(juzNumber);
    final meaningsCount = repo.getWordMeaningsForPage(currentPageNumber).length;
    final meaningsDigits = ArabicSearchNormalizer.toArabicDigits(meaningsCount);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.comsilkLight)
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.8),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Word meanings toggle button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showMeaningsPanel = !_showMeaningsPanel;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (_showMeaningsPanel
                                ? (isDark ? AppColors.oliveLight : AppColors.olive)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder))
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_books_rounded,
                            size: 15,
                            color: isDark ? AppColors.oliveLight : AppColors.olive,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المعاني ($meaningsDigits)',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Current page badge (opens jump dialog on tap)
                  InkWell(
                    onTap: _showJumpToPageDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'ص $pageDigits من ٦٠٤',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Bottom row: Previous page button, Slider, Next page button
              Row(
                children: [
                  // Previous page (in Arabic RTL, points right towards earlier pages)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    tooltip: 'الصفحة السابقة',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    onPressed: currentPageNumber > 1
                        ? () => _jumpToMushafPage(currentPageNumber - 1)
                        : null,
                  ),
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
                        activeTrackColor:
                            isDark ? AppColors.oliveLight : AppColors.olive,
                        inactiveTrackColor: (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)
                            .withValues(alpha: 0.5),
                        thumbColor:
                            isDark ? AppColors.oliveLight : AppColors.olive,
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
                  // Next page (in Arabic RTL, points left towards later pages)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'الصفحة التالية',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    onPressed: currentPageNumber < 604
                        ? () => _jumpToMushafPage(currentPageNumber + 1)
                        : null,
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
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: QuranPageView(
                                  page: repo.getPage(1),
                                  pageNumber: 1,
                                  selectedAyah: _activeSelectedAyah,
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
                                  selectedAyah: _activeSelectedAyah,
                                  onAyahTap: _handleAyahTap,
                                  onAyahLongPress: _handleAyahLongPress,
                                  onAyahHighlight: _handleAyahHighlight,
                                  onAyahHighlightClear: _handleAyahHighlightClear,
                                ),
                              ),
                              Container(
                                width: 1.0,
                                color: (isDark
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
                  child: AnimatedOpacity(
                    opacity: _showTopBar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _buildTopBar(context, currentPageNumber),
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
                  child: AnimatedOpacity(
                    opacity: _showTopBar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _buildBottomBar(context, currentPageNumber),
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
          ],
        ),
      ),
    );
  }
}
