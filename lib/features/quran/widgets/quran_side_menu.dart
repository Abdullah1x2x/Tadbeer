import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../settings/settings_screen.dart';

import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../../../core/design_system/app_icons.dart';

/// القائمة الجانبية للمصحف: الانتقال إلى السور والأجزاء، والرئيسية والإعدادات.
class QuranSideMenu extends StatefulWidget {
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  const QuranSideMenu({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<QuranSideMenu> createState() => _QuranSideMenuState();
}

class _QuranSideMenuState extends State<QuranSideMenu>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  /// يُنشآن مع أول رصف للقائمة، مفتوحين على السورة والجزء الحاليين، فلا قفزة
  /// بعد ظهورها.
  ScrollController? _surahsScrollController;
  ScrollController? _juzsScrollController;
  String _filter = '';

  /// أسماء السور مطبّعة مرة، لا مع كل حرف في البحث.
  late final List<String> _surahKeys = [
    for (final s in QuranRepository.instance.surahs)
      ArabicSearchNormalizer.normalize(s.name),
  ];

  /// صفحة بداية كل جزء، تُحسب مرة.
  late final _juzStarts = [
    for (var juz = 1; juz <= 30; juz++)
      QuranRepository.instance.pages.firstWhere((p) => p.juzNumber == juz),
  ];

  static const _itemHeight = 60.0;
  static const _listPadding = 4.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _surahsScrollController?.dispose();
    _juzsScrollController?.dispose();
    super.dispose();
  }

  /// موضع التمرير الذي يضع العنصر [index] من [count] في وسط قائمة ارتفاعها
  /// [viewport].
  static double _centred(int index, int count, double viewport) {
    final end = count * _itemHeight + 2 * _listPadding - viewport;
    final top = _listPadding + index * _itemHeight;
    return (top - (viewport - _itemHeight) / 2).clamp(0.0, math.max(0.0, end));
  }

  int get _currentSurahIndex {
    final page = QuranRepository.instance.getPage(widget.currentPage);
    return (page.surahNumbers.isNotEmpty ? page.surahNumbers.first : 1) - 1;
  }

  /// يعود إلى السورة الحالية بعد مسح البحث.
  void _showCurrentSurah() {
    final controller = _surahsScrollController;
    if (controller == null || !controller.hasClients) return;
    controller.jumpTo(
      _centred(_currentSurahIndex, 114, controller.position.viewportDimension),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;
    final topPadding = MediaQuery.paddingOf(context).top;
    final accent = _accent(isDark);

    return Drawer(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.comsilkLight,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: topPadding),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.comsilk,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDrawerHeader(context, isDark, l10n),

                  // التبويب: السور / الأجزاء.
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.comsilkLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.olive,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(text: l10n.surahs),
                        Tab(text: l10n.juzs),
                      ],
                    ),
                  ),

                  // تصفية السور، في تبويبها وحده.
                  ListenableBuilder(
                    listenable: _tabController,
                    builder: (context, field) => _tabController.index == 0
                        ? field!
                        : const SizedBox.shrink(),
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _filter = val.trim());
                        if (val.trim().isNotEmpty) {
                          if (_surahsScrollController?.hasClients ?? false) {
                            _surahsScrollController!.jumpTo(0.0);
                          }
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _showCurrentSurah();
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchSurahsHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.nightSubtitle
                              : AppColors.daySubtitle,
                        ),
                        prefixIcon: Icon(
                          AppIcons.magnifyingGlass,
                          size: 18,
                          color: accent,
                        ),
                        suffixIcon: _filter.isNotEmpty
                            ? IconButton(
                                tooltip: context.l10n.clearText,
                                icon: const Icon(AppIcons.x, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filter = '');
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) _showCurrentSurah();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.comsilkLight,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
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
                  ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahsList(context, repo, isDark),
                  _buildJuzsList(context, repo, isDark),
                ],
              ),
            ),
          ],
        ),
      );
    }

  /// ترويسة القائمة: اسم التطبيق وزر الإعدادات.
  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDark,
    AppStrings l10n,
  ) {
    final accent = _accent(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FlutterIslamicIcons.quran2,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                  ),
                ),
                Text(
                  l10n.offlineQuranAndReflection,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.gear),
            tooltip: l10n.settings,
            color: accent,
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
    );
  }

  /// السور، مع تصفية وانتقال مباشر وتمرير لموضع السورة الحالية.
  Widget _buildSurahsList(
    BuildContext context,
    QuranRepository repo,
    bool isDark,
  ) {
    final surahs = repo.surahs;
    final query = ArabicSearchNormalizer.normalize(_filter);
    final latinQuery = ArabicSearchNormalizer.toEnglishDigits(_filter)
        .trim()
        .toLowerCase();
    final filteredSurahs = _filter.isEmpty
        ? surahs
        : [
            for (final (i, s) in surahs.indexed)
              if (_surahKeys[i].contains(query) ||
                  '${s.number}' == latinQuery ||
                  (latinQuery.isNotEmpty &&
                      (s.transliteration.toLowerCase().contains(latinQuery) ||
                          s.translation.toLowerCase().contains(latinQuery))))
                s,
          ];

    return LayoutBuilder(
      builder: (context, box) {
        _surahsScrollController ??= ScrollController(
          initialScrollOffset: _centred(
            _currentSurahIndex,
            surahs.length,
            box.maxHeight,
          ),
        );
        return _surahsList(context, filteredSurahs, isDark);
      },
    );
  }

  Widget _surahsList(
    BuildContext context,
    List<Surah> filteredSurahs,
    bool isDark,
  ) {
    return ListView.builder(
      controller: _surahsScrollController,
      itemExtent: _itemHeight,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = filteredSurahs[index];
        final isCurrent =
            widget.currentPage >= surah.pageStart &&
            widget.currentPage <= surah.pageEnd;

        return Container(
          height: 60.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: index == filteredSurahs.length - 1 || isCurrent
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
          ),
          child: _IndexTile(
            number: surah.number,
            title: surah.name,
            titleFontSize: 16,
            subtitle:
                '${surah.isMeccan ? context.l10n.meccan : context.l10n.medinan} · ${context.l10n.ayahsCount(_digits(context, surah.ayahCount))}',
            page: surah.pageStart,
            isCurrent: isCurrent,
            onTap: () {
              Navigator.pop(context);
              widget.onPageSelected(surah.pageStart);
            },
          ),
        );
      },
    );
  }

  /// الأجزاء الثلاثون، تنقل إلى بداية كل جزء مع تمرير لموضع الجزء الحالي.
  Widget _buildJuzsList(
    BuildContext context,
    QuranRepository repo,
    bool isDark,
  ) {
    final currentJuz = repo.getPage(widget.currentPage).juzNumber;
    return LayoutBuilder(
      builder: (context, box) {
        _juzsScrollController ??= ScrollController(
          initialScrollOffset: _centred(currentJuz - 1, 30, box.maxHeight),
        );
        return _juzsList(context, repo, isDark, currentJuz);
      },
    );
  }

  Widget _juzsList(
    BuildContext context,
    QuranRepository repo,
    bool isDark,
    int currentJuz,
  ) {
    return ListView.builder(
      controller: _juzsScrollController,
      itemExtent: _itemHeight,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNum = index + 1;
        final startPage = _juzStarts[index];

        final firstAyah = startPage.ayahs.first;
        final surah = repo.getSurah(firstAyah.surahNumber);
        final isCurrent = currentJuz == juzNum;

        return Container(
          height: 60.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: index == 29 || isCurrent
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
          ),
          child: _IndexTile(
            number: juzNum,
            title: context.l10n.juzAbbr(_digits(context, juzNum)),
            titleFontSize: 14,
            subtitle: context.l10n.ayahReference(
              surah.name,
              _digits(context, firstAyah.ayahNumber),
            ),
            page: startPage.pageNumber,
            isCurrent: isCurrent,
            onTap: () {
              Navigator.pop(context);
              widget.onPageSelected(startPage.pageNumber);
            },
          ),
        );
      },
    );
  }
}

/// لون التمييز، فاتحاً في الوضع الداكن ليُقرأ على الخلفية الداكنة.
Color _accent(bool isDark) =>
    isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

/// الرقم بأرقام الواجهة: عربية هندية في الواجهة العربية.
String _digits(BuildContext context, int n) => context.l10n.digits(n);

/// سطر في فهرس السور أو الأجزاء: رقمه، واسمه، وصفحة بدايته.
class _IndexTile extends StatelessWidget {
  final int number;
  final String title;
  final double titleFontSize;
  final String subtitle;
  final int page;

  /// هل الصفحة الحالية داخل هذا القسم.
  final bool isCurrent;
  final VoidCallback onTap;

  const _IndexTile({
    required this.number,
    required this.title,
    required this.titleFontSize,
    required this.subtitle,
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    return ListTile(
      dense: true,
      selected: isCurrent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedTileColor: isDark
          ? AppColors.oliveDark.withValues(alpha: 0.25)
          : AppColors.olive.withValues(alpha: 0.12),
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.olive
              : (isDark ? AppColors.darkSurface : AppColors.comsilk),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? accent
                : accent.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          _digits(context, number),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isCurrent
                ? Colors.white
                : (isDark ? AppColors.comsilk : AppColors.oliveDark),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: titleFontSize,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
          color: isCurrent
              ? accent
              : (isDark ? AppColors.nightQuranText : AppColors.dayQuranText),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
        ),
      ),
      trailing: Text(
        context.l10n.pageAbbr(_digits(context, page)),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
      onTap: onTap,
    );
  }
}
