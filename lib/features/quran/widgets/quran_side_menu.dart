import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
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
  final ScrollController _surahsScrollController = ScrollController();
  final ScrollController _juzsScrollController = ScrollController();
  String _filter = '';
  bool _initialJuzScrolled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrentSurah(animate: false);
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_initialJuzScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentJuz(animate: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _surahsScrollController.dispose();
    _juzsScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentSurah({bool animate = false}) {
    if (!_surahsScrollController.hasClients || _filter.isNotEmpty) return;
    final repo = QuranRepository.instance;
    final page = repo.getPage(widget.currentPage);
    final surahNum = page.surahNumbers.isNotEmpty ? page.surahNumbers.first : 1;
    final surahIndex = (surahNum - 1).clamp(0, repo.surahs.length - 1);

    const itemHeight = 60.0;
    const topPadding = 4.0;
    final viewport = _surahsScrollController.position.viewportDimension;
    final itemTop = topPadding + (surahIndex * itemHeight);
    final target = math.max(
      0.0,
      itemTop - (viewport > itemHeight ? (viewport - itemHeight) / 2 : 0.0),
    );
    final clamped = target.clamp(
      0.0,
      _surahsScrollController.position.maxScrollExtent,
    );

    if (animate) {
      _surahsScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _surahsScrollController.jumpTo(clamped);
    }
  }

  void _scrollToCurrentJuz({bool animate = false}) {
    if (!_juzsScrollController.hasClients) return;
    final repo = QuranRepository.instance;
    final page = repo.getPage(widget.currentPage);
    final juzIndex = (page.juzNumber - 1).clamp(0, 29);

    const itemHeight = 60.0;
    const topPadding = 4.0;
    final viewport = _juzsScrollController.position.viewportDimension;
    final itemTop = topPadding + (juzIndex * itemHeight);
    final target = math.max(
      0.0,
      itemTop - (viewport > itemHeight ? (viewport - itemHeight) / 2 : 0.0),
    );
    final clamped = target.clamp(
      0.0,
      _juzsScrollController.position.maxScrollExtent,
    );

    if (animate) {
      _juzsScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _juzsScrollController.jumpTo(clamped);
    }
    _initialJuzScrolled = true;
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

                  // تصفية السور.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _filter = val.trim());
                        if (val.trim().isNotEmpty) {
                          if (_surahsScrollController.hasClients) {
                            _surahsScrollController.jumpTo(0.0);
                          }
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _scrollToCurrentSurah(animate: false);
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
                          color: AppColors.olive,
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
                                    if (mounted) {
                                      _scrollToCurrentSurah(animate: false);
                                    }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FlutterIslamicIcons.quran2,
              color: AppColors.olive,
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
            color: AppColors.olive,
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
    final filteredSurahs = repo.surahs.where((s) {
      if (_filter.isEmpty) return true;
      final query = ArabicSearchNormalizer.normalize(_filter);
      final normName = ArabicSearchNormalizer.normalize(s.name);
      return normName.contains(query) || s.number.toString() == _filter;
    }).toList();

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      controller: _surahsScrollController,
      itemExtent: 60.0,
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.fromLTRB(8, 4, 8, math.max(8.0, bottomPadding)),
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
            border: index == filteredSurahs.length - 1
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
    if (!_initialJuzScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentJuz(animate: false);
        }
      });
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      controller: _juzsScrollController,
      itemExtent: 60.0,
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.fromLTRB(8, 4, 8, math.max(8.0, bottomPadding)),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNum = index + 1;
        final startPage = repo.pages.firstWhere(
          (p) => p.juzNumber == juzNum,
          orElse: () => repo.pages.first,
        );

        final firstAyah = startPage.ayahs.first;
        final surah = repo.getSurah(firstAyah.surahNumber);
        final isCurrent = repo.getPage(widget.currentPage).juzNumber == juzNum;

        return Container(
          height: 60.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: index == 29
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

/// الرقم بأرقام الواجهة: عربية هندية في الواجهة العربية.
Object _digits(BuildContext context, int n) =>
    context.currentLanguage == AppLanguage.arabic
    ? ArabicSearchNormalizer.toArabicDigits(n)
    : n;

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
    return ListTile(
      dense: true,
      selected: isCurrent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedTileColor: AppColors.olive.withValues(alpha: 0.12),
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
                ? AppColors.olive
                : AppColors.olive.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${_digits(context, number)}',
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
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
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
          color: AppColors.olive,
        ),
      ),
      onTap: onTap,
    );
  }
}
